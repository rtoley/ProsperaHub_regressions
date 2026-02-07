# HANDOFF: E1 Handoff Duplicate Execution Bug

## STATUS: IN PROGRESS - FIX NOT WORKING YET

## Reproduction Command
```bash
./step1_vpu_rtl_validate.sh -t 500 -s 99999
```

## The Bug (100% Reproducible)

When E1 has a multiply instruction being handed off to E1m, and a non-multiply instruction arrives from OF, the non-multiply instruction gets executed TWICE.

### Trace Evidence
```
[835000] E1_CAPTURE_WHILE_HANDOFF: vd=8 id=171 op=63  <-- Branch 2 captures
[841000] E1_CAPTURE: vd=8 id=171 op=63 is_mul=0       <-- Branch 1 captures SAME instr!
[841000] E2_CAPTURE_FROM_E1: vd=8 op=63 (non-mul)
[843000] E2_CAPTURE_FROM_E1: vd=8 op=63 (non-mul)     <-- DUPLICATE E2 capture
[845000] VRF_WRITE: vd=8 ...
[847000] VRF_WRITE: vd=8 ...                          <-- DUPLICATE write
```

## Root Cause

In `hp_vpu_lanes.sv`, E1 always_ff has two branches that can capture instructions:

**Branch 1 (line ~1925):**
```systemverilog
end else if (!stall_i && !mac_stall && !mul_stall) begin
  e1_valid <= valid_i && !is_reduction_op && !is_widening_op;
  // ... captures from OF
```

**Branch 2 (line ~2078):**
```systemverilog
end else if (!stall_i && !mac_stall && is_mul_op_e1 && !e1m_valid) begin
  // E1's multiply going to E1m, can capture new non-multiply
  if (valid_i && !is_reduction_op && !is_widening_op && !is_mul_op) begin
    e1_valid <= 1'b1;
    // ... captures from OF
```

**The Problem:**

When branch 2 fires at cycle T:
- `mul_stall = is_mul_op_e1 = 1` (E1 has multiply)
- E1 captures the new instruction from OF
- But OF doesn't clear because it checks `!mul_stall`

At cycle T+1:
- mul_stall = 0 (E1 now has non-multiply, E1m has the old multiply)
- Branch 1 fires and captures FROM OF AGAIN (OF still has same instruction!)

## My Fix Attempt (NOT WORKING)

Added `e1_handoff_capture` signal in `hp_vpu_lanes.sv`:
```systemverilog
wire e1_branch2_fires = !stall_i && !mac_stall && is_mul_op_e1 && !e1m_valid;
wire e1_handoff_capture = e1_branch2_fires && valid_i && !is_reduction_op && !is_widening_op && !is_mul_op;
assign e1_handoff_capture_o = e1_handoff_capture;
```

Modified OF clearing in `hp_vpu_top.sv`:
```systemverilog
end else if (!stall_exec && of_valid && !mac_stall && !drain_stall &&
             (!mul_stall || e1_handoff_capture)) begin
  of_valid <= 1'b0;
```

**Why it's not working:**

The debug output `E1_BRANCH2_FIRES` never appears, meaning the combinational signal isn't being detected. Possible issues:
1. Timing - the signal evaluates at a different point than when I'm checking
2. The OF clearing branch isn't being taken (stall_dec might be 0)
3. Something else about the condition is wrong

## Key Insight About OF Clearing

The OF always block has TWO branches:
```systemverilog
if (!stall_dec) begin
  // D2 advancing - capture new value from D2
  of_valid <= d2_valid;
  // ...
end else if (!stall_exec && of_valid && ...) begin
  // D2 stalled but lanes consumed - just clear
  of_valid <= 1'b0;
end
```

If `stall_dec = 0`, the first branch always takes priority and OF gets a NEW value. The second branch (my fix target) only runs when `stall_dec = 1`.

## What Needs Investigation

1. **Check stall_dec at the critical time** - Is stall_dec = 0 or 1 when branch 2 fires?

2. **If stall_dec = 0**: The fix might need to go in the FIRST branch instead:
   ```systemverilog
   if (!stall_dec) begin
     if (e1_handoff_capture) begin
       // E1 already consumed OF, don't refill yet
       of_valid <= 1'b0;
     end else begin
       // Normal path
       of_valid <= d2_valid;
     end
   end
   ```

3. **If stall_dec = 1**: Debug why e1_handoff_capture isn't being seen

## Files Modified (Current State)

### rtl/hp_vpu_lanes.sv
- Line 60: Added output port `e1_handoff_capture_o`
- Lines 1168-1169: Added e1_handoff_capture signal generation
- Debug traces added around the signal

### rtl/hp_vpu_top.sv
- Line 408: Added wire declaration for `e1_handoff_capture`
- Line 449: Connected port in lanes instantiation
- Lines 385-399: Modified OF clearing condition (but may be wrong branch)
- Debug traces added

## Test Commands After Fix
```bash
# The failing case
./step1_vpu_rtl_validate.sh -t 500 -s 99999

# More stress tests
./step1_vpu_rtl_validate.sh -t 1000 -s 99999
./step1_vpu_rtl_validate.sh -t 5000 -s 12345
./step1_vpu_rtl_validate.sh -l   # 10K stress test

# Full test suite must still pass
./step1_vpu_rtl_validate.sh
./step1_vpu_rtl_validate.sh -c
```

## Alternative Fix Approach

Instead of adding a new signal, modify mul_stall to not block when E1m is empty:

```systemverilog
// Current (buggy):
wire mul_stall = (e1_valid && e1m_valid) || is_mul_op_e1;

// Proposed fix:
wire mul_stall = (e1_valid && e1m_valid);
// When is_mul_op_e1 && !e1m_valid, E1 can accept AND hand off simultaneously
```

This is simpler but needs careful analysis for side effects.

## Critical Code Locations

- E1 always_ff: `hp_vpu_lanes.sv` lines 1925-2123
- E1 branch 2: `hp_vpu_lanes.sv` lines 2078-2122
- mul_stall: `hp_vpu_lanes.sv` line 1160
- OF always_ff: `hp_vpu_top.sv` lines 345-400
- stall_dec: computed in `hp_vpu_hazard.sv` line 116
