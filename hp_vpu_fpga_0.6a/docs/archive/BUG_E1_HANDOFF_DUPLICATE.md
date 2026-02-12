# BUG: E1 Handoff Duplicate Execution

## Status: UNFIXED as of v1.8a

## Reproduction
```bash
./step1_vpu_rtl_validate.sh -t 500 -s 99999
```

## Symptoms
- Throughput test fails with VRF mismatch
- Debug trace shows duplicate `E2_CAPTURE_FROM_E1` messages
- Same instruction executes twice, corrupting pipeline state

## Example Trace (from test_results.log)
```
[835000] E1_CAPTURE_WHILE_HANDOFF: vd=8 id=171 op=63
[841000] E2_CAPTURE_FROM_E1: vd=8 op=63 (non-mul)
[843000] E2_CAPTURE_FROM_E1: vd=8 op=63 (non-mul)  <-- DUPLICATE!
[845000] VRF_WRITE: vd=8 ...
[845000] E3_CAPTURE_FROM_E2: vd=8 op=63 ...        <-- DUPLICATE!
[847000] VRF_WRITE: vd=8 ...                       <-- DUPLICATE WRITE!
```

## Root Cause Analysis

### Pipeline Structure
```
OF (Operand Fetch) -> E1 -> E1m (multiply) -> E2 -> E3 -> VRF Write
                        \-> E2 (non-mul) ---/
```

### The Bug Scenario

**Cycle T:**
- E1 has multiply instruction M (e.g., vmacc)
- OF has non-multiply instruction X (e.g., vid.v, op=63)
- E1m is empty

**What happens in E1 always_ff (branch 2 at line 2078):**
- Condition: `!stall_i && !mac_stall && is_mul_op_e1 && !e1m_valid` = TRUE
- E1 hands off M to E1m
- E1 captures X from OF (valid_i && !is_mul_op)
- Debug shows: `E1_CAPTURE_WHILE_HANDOFF: vd=8 id=171 op=63`

**What happens in OF clearing (hp_vpu_top.sv line 382):**
- Condition: `!stall_exec && of_valid && !mac_stall && !mul_stall && !drain_stall`
- `mul_stall = (e1_valid && e1m_valid) || is_mul_op_e1`
- At cycle T start: `is_mul_op_e1 = 1` (E1 still has M)
- So `mul_stall = 1`, OF does NOT clear!

**Cycle T+1:**
- E1 has X (captured in cycle T)
- OF still has X (wasn't cleared!)
- E1m has M
- E2 captures X from E1 (normal path)
- Debug shows: `E2_CAPTURE_FROM_E1: vd=8 op=63`

**Cycle T+2:**
- E1m advances M to E2, clears
- mul_stall = 0 now
- E1 captures X from OF AGAIN!
- E2 captures previous X from E1 (but E1 already has new X)
- Debug shows another: `E2_CAPTURE_FROM_E1: vd=8 op=63` <-- DUPLICATE

**Result:** Instruction X executes twice, corrupting VRF state.

## The Fix

### Option A: Add handoff capture signal (RECOMMENDED)

In `hp_vpu_lanes.sv`, add combinational signal that detects when E1 branch 2 captures:

```systemverilog
// v1.8a FIX: Signal when E1 captures during multiply handoff
wire e1_branch2_fires = !stall_i && !mac_stall && is_mul_op_e1 && !e1m_valid;
wire e1_handoff_capture = e1_branch2_fires && valid_i && !is_reduction_op && !is_widening_op && !is_mul_op;
assign e1_handoff_capture_o = e1_handoff_capture;
```

In `hp_vpu_top.sv`, modify OF clearing:

```systemverilog
end else if (!stall_exec && of_valid && !mac_stall && !drain_stall &&
             (!mul_stall || e1_handoff_capture)) begin
  // v1.8a FIX: ALSO clear if e1_handoff_capture - E1 captured during multiply handoff
  of_valid <= 1'b0;
end
```

### Option B: Restructure mul_stall definition

Change `mul_stall` to not include `is_mul_op_e1` when E1m is empty:
```systemverilog
wire mul_stall = (e1_valid && e1m_valid) || (is_mul_op_e1 && e1m_valid);
```

This is simpler but may have other implications for the stall logic.

## Files to Modify

1. `rtl/hp_vpu_lanes.sv`:
   - Add output port `e1_handoff_capture_o`
   - Add combinational logic to generate signal

2. `rtl/hp_vpu_top.sv`:
   - Add wire declaration for `e1_handoff_capture`
   - Connect to lanes instance
   - Modify OF clearing condition

## Test Commands

After fix, verify with:
```bash
# The failing case
./step1_vpu_rtl_validate.sh -t 500 -s 99999

# More stress tests
./step1_vpu_rtl_validate.sh -t 1000 -s 99999
./step1_vpu_rtl_validate.sh -t 5000 -s 12345
./step1_vpu_rtl_validate.sh -t 10000 -s 88888

# Full test suite must still pass
./step1_vpu_rtl_validate.sh
./step1_vpu_rtl_validate.sh -c
```

## Related Code Locations

- E1 always_ff block: `hp_vpu_lanes.sv` lines 1925-2123
- E1 branch 2 (handoff): `hp_vpu_lanes.sv` lines 2078-2122
- mul_stall definition: `hp_vpu_lanes.sv` line 1159
- OF clearing: `hp_vpu_top.sv` lines 382-388
- Lanes instantiation: `hp_vpu_top.sv` lines 407-451
