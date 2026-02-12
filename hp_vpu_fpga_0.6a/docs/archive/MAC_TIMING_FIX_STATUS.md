# MAC Timing Fix - Problem Statement & Status

## Date: 2026-01-30
## Version: v1.6d (attempted fix, incomplete)

---

## THE GOAL (NOT ACHIEVED)

Break the MAC critical path to meet:
- **FPGA**: 100 MHz (10ns cycle)
- **ASIC**: Fast library logic depth (~8-10 levels)

The fix should be **portable** (not Xilinx DSP48E1 specific).

---

## ORIGINAL PROBLEM (v1.4)

The MAC operation (vmacc: `vd = vd + vs1 * vs2`) had this timing path:

```
E1: Operands ready (vs1, vs2, vd_old in registers)
    ↓
    [MULTIPLY: ~6ns]  ← vs1 * vs2
    ↓
    [ADD: ~5ns]       ← product + vd_old
    ↓
E2: Capture result

Total: ~11ns > 10ns requirement ✗
```

**Root cause**: Multiply + Add in single combinational path between pipeline registers.

---

## WHAT v1.6 ATTEMPTED (HALF-FIX)

I added a **stall-based approach**:

```
Cycle N:   E1 → E2 (multiply completes, captured in e2_mul_partial)
Cycle N+1: MAC stall (add computed from registered multiply, captured in e2m_*)
Cycle N+2: Result flows to E3
```

**Problems with this approach:**

1. **Didn't fix the actual critical path** - The Vivado report shows:
   ```
   Source:      e1_a_reg[48]/C
   Destination: e2_mul_partial_reg[127]/D
   Delay:       10.726ns  ← STILL FAILS
   Logic:       DSP48E1=2, CARRY4=12
   ```
   The **multiply itself** is 10.7ns, before any add!

2. **Cross-pipeline stall corruption** - Three pipelines exist:
   - Normal/MAC: E1 → E2 → (e2m) → E3
   - Reduction: R1 → R2 → R3
   - Widening: W1 → W2

   When mac_stall fires, it interacts badly with:
   - OF (operand fetch) clearing logic
   - E3 writeback (double-write bug)
   - Other pipelines in flight

3. **Added latency without fixing timing** - MAC ops now take +1 cycle but still fail timing.

---

## WHAT ACTUALLY NEEDS TO BE DONE

### Option A: Balanced Pipeline Split (Recommended, Portable)

Split multiply into two stages:

```
E1:  Operand prep
     ↓
E1m: Multiply stage 1 (partial products) [~5ns]
     ↓
E2:  Multiply stage 2 (accumulate partials) + capture [~5ns]
     ↓
E2m: MAC add (product + accumulator) [~5ns]
     ↓
E3:  Result mux, masking, writeback
```

Each stage: ~5ns ≤ 10ns ✓

**Key insight**: Don't just stall - actually split the datapath with balanced register stages.

### Option B: DSP48E1 Internal Pipeline (Xilinx Only)

Use DSP48E1 with:
- AREG=1, BREG=1 (input registers)
- MREG=1 (multiply register) ← THIS IS KEY
- PREG=1 (output register)

The DSP has internal pipeline registers that Vivado doesn't use by default.

### Option C: Reduce Multiply Width

For FPGA prototype, limit to SEW=16 max. 32×32 multiply requires two DSP48E1s stitched with carry chains (the 12 CARRY4s in the report).

---

## CURRENT VIVADO PATH ANALYSIS

```
Source:      u_lanes/e1_a_reg[48]/C
Destination: u_lanes/e2_mul_partial_reg[127]/D
Delay:       10.726ns (need ≤10ns)
Logic:       DSP48E1=2, CARRY4=12, LUT2=1, LUT5=1
             ^^^^^^^^^ ^^^^^^^^^^
             Two DSPs   Stitching for 32-bit multiply
```

The 12 CARRY4s are from stitching two DSP48E1s for 32×32 multiply. This is the real problem, not the MAC add.

---

## FILES MODIFIED IN v1.6d (FOR REFERENCE)

### rtl/hp_vpu_lanes.sv
- Lines ~127-150: MAC stall FSM (mac_stall, mac_add_done, is_mac_op_e2)
- Lines ~2000-2010: e2m_* register declarations
- Lines ~2490-2525: e2m register capture during stall
- Lines ~2700-2760: E3 stage with e2m_valid path and bubble insertion

### rtl/hp_vpu_top.sv
- Line ~393: mac_stall wire declaration
- Line ~430: mac_stall_o port connection
- Line ~376: OF clearing fix (`&& !mac_stall`)

---

## RECOMMENDATIONS FOR NEXT SESSION

1. **Start fresh from v1.4** - The stall-based approach added complexity without fixing timing.

2. **Implement Option A (balanced pipeline split)**:
   - Add E1m stage register after partial products
   - This is portable to any target

3. **OR implement DSP48E1 instantiation** if Xilinx-only is acceptable:
   - Instantiate DSP48E1 directly with MREG=1
   - Much simpler than RTL pipeline split

4. **Test with widening disabled first** - The 12 CARRY4s may be from widening multiply, not base 32×32.

5. **Beware cross-pipeline interactions** - Any pipeline change must consider:
   - Reduction pipeline (R1/R2/R3)
   - Widening pipeline (W1/W2)
   - Stall propagation to OF, D2
   - Writeback conflicts

---

## TEST STATUS

| Config | Tests | Status |
|--------|-------|--------|
| 256/256, VMADD=1, WIDENING=1 | 109/109 | Functional ✓, Timing ✗ |
| 64/64, VMADD=0, WIDENING=1 | 107/107 | Functional ✓, Timing ✗ |
| 64/64, VMADD=0, WIDENING=0 | ?/? | Pending timing check |

---

## SUMMARY

**What was asked**: Break MAC timing path for 100MHz FPGA / fast ASIC.

**What was delivered**: Stall-based workaround that:
- Doesn't fix the actual critical path (multiply is 10.7ns)
- Adds complexity with cross-pipeline stall handling
- Adds latency without timing benefit

**What's needed**: True pipeline split with balanced stages, either:
- RTL-level register insertion (portable)
- DSP48E1 MREG usage (Xilinx-specific)

---

## UPDATE: Widening Test Result

**Test**: VLEN=64, DLEN=64, WIDENING=0, VMADD=0
**Result**: NO CHANGE - still fails timing

**Conclusion**: The problem is **base 32×32 multiply**, not widening.

Two DSP48E1s are required for 32×32 (each DSP is 25×18 max). The 12 CARRY4s chain them together.

### Next Session Options (in order of preference):

1. **SEW≤16 mode for timing closure**
   - Quick config change, passes timing
   - Lose 32-bit operations

2. **RTL pipeline split for 32×32 multiply**
   - Add `e1m_mul_partial` register between DSP stages
   - Portable to all targets
   - Preserves 32-bit support

3. **DSP48E1 instantiation with MREG=1**
   - Xilinx-specific but cleanest for FPGA
   - Use DSP internal pipeline register
