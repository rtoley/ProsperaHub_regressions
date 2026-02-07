# HP-VPU v0.3e Status

**Date:** 2026-02-05
**Base:** v0.3d + Jules pipeline split session
**Change:** 300 MHz timing closure — split R2 reduction pipeline into R2A + R2B

---

## What Changed

### Core Change: R2 Pipeline Split (from WORK_300MHZ_TIMING.md)

The reduction tree's R2 stage was split into two stages (R2A and R2B) to halve the combinational depth, enabling 300 MHz on Ultrascale+.

**Pipeline (reduction path):**
```
v0.3d:  IF → ID → OF → R1 → R2  → R3 → WB   (7 stages)
v0.3e:  IF → ID → OF → R1 → R2A → R2B → R3 → WB  (8 stages, +1 cycle latency)
```

### Files Modified

| File | Change |
|------|--------|
| `rtl/hp_vpu_lanes.sv` | FSM 2-bit→3-bit, R2A/R2B stages, hazard outputs, R2A array sizing fix |
| `rtl/hp_vpu_hazard.sv` | New R2A/R2B RAW hazard detection ports (Option A from work plan) |
| `rtl/hp_vpu_top.sv` | Wire R2A/R2B signals between lanes ↔ hazard |
| `scripts/gen_pkg.py` | Added SPLIT_REDUCTION_PIPELINE parameter |
| `config/vpu_config_256.json` | Added `split_reduction_pipeline: true` |
| `tb/test_reduction_timing.sv` | New timing test (from Jules) |

### v0.3e Fixes over Jules Session

1. **R2A array undersizing (BUG FIX):** Jules sized R2A arrays as `NUM_ELEM_X/8` which was too small for DLEN=64 (and DLEN=128 for larger SEWs), causing lost reduction data. Fixed with proper `R2A_N*` localparams that compute `max(R1_count/2, R1_count)` based on whether reduction is needed.

2. **R2A double-reported in hazard (CLEANUP):** `e2_valid_o` redundantly included `RED_R2A` alongside the new dedicated `r2a_valid_o`. Removed from `e2_valid_o`.

3. **e2_vd_o mux fix (CLEANUP):** Removed stale `RED_R2A` priority from `e2_vd_o` mux.

---

## Test Results

### VLEN=64 (DLEN=64, NLANES=1)
```
Test Results: 1351/1356 passed (99.6%)
Failures: 5 (all pre-existing)
  - 3x LUT known failures (vrecip/vrsqrt zero outputs — test issue, not RTL)
  - 2x mask test expectation bugs (vmnand/vmorn — 256-bit patterns on 64-bit VLEN)
```

### VLEN=256 (DLEN=256, NLANES=4)
```
Test Results: 1351/1356 passed (99.6%)
Failures: 5 (same pre-existing set)
```

### Reduction-specific: All SEW=8/16/32 variants pass on both configurations.

---

## Combinational Depth (DLEN=256, SEW=8 worst case)

| Stage | v0.3d | v0.3e | Comb Levels |
|-------|-------|-------|-------------|
| R1 | 32→8 | 32→8 | 2 (unchanged) |
| R2 | 8→2 | — | Eliminated |
| R2A | — | 8→4 | **1 level** |
| R2B | — | 4→2 | **1 level** |
| R3 | 2→1+accum | 2→1+accum | 2 (unchanged) |

Max per-stage: 2 levels → well within 3.33 ns budget at 300 MHz.

---

## Known Issues (Pre-existing)

1. **vmnand.mm / vmorn.mm test failures:** Test checker uses 256-bit expected patterns regardless of VLEN. Bottom byte is correct. Test issue, not RTL.
2. **3x LUT zero-output failures:** Documented in KNOWN_FAILURES.md.
3. **Conditional compilation not implemented:** `SPLIT_REDUCTION_PIPELINE` parameter exists in gen_pkg but no `ifdef` guard in RTL. Pipeline split is always active.
4. **Category test naming:** `make red` / `make cmp` may fail due to task name mismatches between `tests_reduction.sv`→`tests_red.sv`. Full suite works correctly.
