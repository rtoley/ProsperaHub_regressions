# BUG: WAW Hazard Detection Missing

## Date Identified: 2025-01-31

## Status: IDENTIFIED - FIX NEEDED

## Root Cause

The `rtl/hp_vpu_hazard.sv` module ONLY checks for RAW (Read-After-Write) hazards.
It does NOT check for WAW (Write-After-Write) hazards.

## The Problem

Different pipeline paths have different latencies to VRF write:

```
Pipeline paths from OF:
  OF -> E1 -> E1m -> E2 -> E3 -> VRF  (MAC/MUL: 5 stages)
  OF -> E1 -> E2 -> E3 -> VRF         (non-MAC: 4 stages)
  OF -> W1 -> W2 -> VRF               (widening: 3 stages)
  OF -> R1 -> R2 -> R3 -> VRF         (reduction: 4 stages)
```

If instruction A (MAC) enters pipeline writing to vd=5, then instruction B (non-MAC)
enters 1-2 cycles later ALSO writing to vd=5, instruction B will reach VRF BEFORE
instruction A, causing corruption.

## Current hp_vpu_hazard.sv

Only has these inputs:
- d_vd_i, d_vs1_i, d_vs2_i, d_vs3_i (decode stage)
- of_vd_i (operand fetch)
- e1_vd_i, e2_vd_i, e3_vd_i (execute stages)
- w_vd_i (writeback)

Missing inputs:
- e1m_vd_i, e1m_valid_i (MAC pipeline stage)
- w1_vd_i, w1_valid_i, w2_vd_i, w2_valid_i (widening pipeline)
- r1_vd_i, r1_valid_i, r2_vd_i, r2_valid_i, r3_vd_i, r3_valid_i (reduction pipeline)
- is_mul_op (to know which path new instruction takes)

## Required Fix

1. Add inputs for all pipeline stages (E1m, W1, W2, R1, R2, R3)
2. Add input for new instruction's operation type
3. Add WAW hazard logic:

```systemverilog
// WAW hazard: new instruction would reach VRF before in-flight instruction
// Must stall at OF->E1 transition

// If new instruction is non-MAC (4 stages) and E1m has MAC (2 stages left)
// Non-MAC would arrive in 4 cycles, MAC in 2 cycles - OK, no hazard

// If new instruction is non-MAC (4 stages) and E1 has MAC (3 stages left to E1m->E2->E3)
// Non-MAC: 4 cycles, MAC: 3 cycles - MAC arrives first, OK

// PROBLEM CASE:
// If E1 has MAC going to E1m, and we let non-MAC into E1 next cycle:
// - MAC: E1m(now) -> E2 -> E3 -> VRF = 3 more cycles
// - non-MAC: E1(now) -> E2 -> E3 -> VRF = 3 more cycles
// SAME CYCLE - contention!

// If E1m has MAC and we let non-MAC into E1:
// - MAC: E2 -> E3 -> VRF = 2 more cycles
// - non-MAC: E1 -> E2 -> E3 -> VRF = 3 more cycles
// MAC arrives first - OK

// The dangerous case is when non-MAC enters E1 while MAC is ALSO in E1
// (about to hand off to E1m) - they'll race.
```

4. Key WAW checks needed:
   - `d_vd == e1_vd && is_mul_op_e1 && !is_mul_op_new` -> STALL
   - `d_vd == e1m_vd` -> check timing
   - `d_vd == w1_vd || d_vd == w2_vd` -> STALL (widening is shorter path)
   - `d_vd == r1_vd || d_vd == r2_vd` -> check timing

## Test to Reproduce

```bash
# This passes (waits between instructions):
./step1_vpu_rtl_validate.sh   # Random tests pass

# This fails (back-to-back issue):
iverilog -g2012 -DSIMULATION -I generated -o sim/hp_vpu_tb.vvp \
  generated/hp_vpu_pkg.sv rtl/*.sv tb/hp_vpu_tb.sv
vvp sim/hp_vpu_tb.vvp +throughput=50 +seed=99999
```

## Files to Modify

1. `rtl/hp_vpu_hazard.sv` - Add WAW detection logic and new inputs
2. `rtl/hp_vpu_top.sv` - Connect new signals to hazard unit
3. `rtl/hp_vpu_lanes.sv` - Export e1m_vd, w1_vd, w2_vd, r1_vd, r2_vd, r3_vd signals

## Related Files

- `docs/BUG_E1_HANDOFF_DUPLICATE.md` - Related issue (partial fix applied)
- `tb/hp_vpu_tb.sv` - Has hazard tests (test_mac_hazard_dist*)

## Updated Understanding (Session 2)

The WAW hazard is more complex than just MUL vs non-MUL:

### Pipeline Latencies (cycles from entering their first stage to VRF):
- **MAC/MUL**: E1 -> E1m -> E2 -> E3 -> VRF = **4 cycles**
- **Normal ALU**: E1 -> E2 -> E3 -> VRF = **3 cycles**
- **Reduction**: R1 -> R2 -> R3 -> VRF = **3 cycles**
- **Widening**: W1 -> W2 -> VRF = **2 cycles**

### Dangerous Combinations (shorter path following longer path to same vd):

| In-flight (ahead) | New instruction (behind) | Danger? |
|------------------|-------------------------|---------|
| MAC (4 cyc)      | Normal ALU (3 cyc)      | YES - overtake by 1 |
| MAC (4 cyc)      | Reduction (3 cyc)       | YES - overtake by 1 |
| MAC (4 cyc)      | Widening (2 cyc)        | YES - overtake by 2 |
| Normal (3 cyc)   | Widening (2 cyc)        | YES - overtake by 1 |
| Reduction (3 cyc)| Widening (2 cyc)        | YES - overtake by 1 |

### Required Stall Logic at OF Stage:

```
of_is_widening = (of_op is widening op)
of_is_reduction = (of_op is reduction op)
of_is_normal = !(of_is_mul || of_is_widening || of_is_reduction)

// Stall if OF would overtake any in-flight instruction to same vd
waw_stall =
  // MAC in E1 (4 cycles left) - stall widening(2), reduction(3), normal(3)
  (e1_valid && e1_is_mul && of_vd == e1_vd && (of_is_widening || of_is_reduction || of_is_normal)) ||

  // MAC in E1m (3 cycles left) - stall widening(2) only
  (e1m_valid && of_vd == e1m_vd && of_is_widening) ||

  // Normal/Reduction in E1 (3 cycles left) - stall widening(2)
  (e1_valid && !e1_is_mul && of_vd == e1_vd && of_is_widening) ||

  // Reduction in R1 (3 cycles left) - stall widening(2)
  (r1_valid && of_vd == r1_vd && of_is_widening) ||

  // Reduction in R2 (2 cycles left) - stall widening(2) - same time = conflict!
  (r2_valid && of_vd == r2_vd && of_is_widening)
```

Need to pass `of_op` or decoded type flags to hazard unit.
