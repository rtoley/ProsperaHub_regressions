# Hazard Audit: R2A/R2B Pipeline Split (v0.3e)

**Date:** 2026-02-05
**Auditor:** Claude (session 2, picking up interrupted audit)

---

## Pipeline Depths After v0.3e

```
E pipe:  IF → ID → OF → E1  → E2  → E3 → WB   (7 stages)
R pipe:  IF → ID → OF → R1  → R2A → R2B → R3 → WB   (8 stages)  ← DEEPEST
W pipe:  IF → ID → OF → W1  → W2  → WB   (6 stages)  ← SHALLOWEST
```

**R is now 1 stage deeper than E, and 2 deeper than W.** The pipelines are unbalanced.

---

## RAW Hazard Detection: CORRECT ✅

The hazard unit (`hp_vpu_hazard.sv`) has dedicated R2A and R2B ports that are properly wired:

| Signal | Source (hp_vpu_lanes.sv) | Wired Through (hp_vpu_top.sv) | Checked in hazard? |
|--------|--------------------------|-------------------------------|-------------------|
| `r2a_valid_o` | `red_state == RED_R2A` | → `r2a_valid_i` | ✅ vs1, vs2, vs3 |
| `r2a_vd_o` | `r2a_vd` register | → `r2a_vd_i` | ✅ |
| `r2b_valid_o` | `red_state == RED_R2B` | → `r2b_valid_i` | ✅ vs1, vs2, vs3 |
| `r2b_vd_o` | `r2b_vd` register | → `r2b_vd_i` | ✅ |

R2A was correctly removed from e2_valid_o (fix #2 in STATUS_v0.3e.md). The combined RAW hazard OR tree includes all stages: OF, E1, E2, R2A, R2B, E3, WB.

**However:** R3 stage is NOT separately tracked in the hazard unit. R3 produces `valid_o` which flows to `e3_valid` in `hp_vpu_top.sv` where it becomes `wb_valid` one cycle later. So R3 completion is covered by the WB check, but there is a **1-cycle window** where R3 is valid but not yet in WB and not separately checked. This is safe ONLY because `multicycle_busy_o` prevents any new instruction from reaching decode while reduction is in flight. If `multicycle_busy` is ever relaxed (e.g., for throughput), R3 needs its own hazard port.

---

## WAW Hazard Detection: IMPLICIT ONLY ⚠️

There is **no explicit WAW detection** in the hazard unit. WAW safety relies entirely on:

1. **`multicycle_busy_o`** — prevents new instructions from issuing while reduction, widening, MAC, or E1m is active
2. **`pipeline_drained`** — reduction/widening won't start until E1, E1m, E2 are all empty
3. **VRF write contention checker** (simulation-only `$display` in lanes) — catches but doesn't prevent

This works today because:
- Reductions serialize (multicycle_busy blocks everything)
- E-pipe drains before R-pipe starts
- W-pipe drains before W-pipe starts

**Risk:** If you ever allow overlapping E and R instructions (pipelining different vd), you need explicit WAW detection. The current `multicycle_busy` is a big stall hammer that prevents it, but at a throughput cost.

---

## Missing Hazard: R3 Stage Gap

```
R pipe completion: R3 sets valid_o → hp_vpu_top captures as e3_valid → next cycle wb_valid
```

When `red_state == RED_R3`, the instruction is in R3 stage but:
- `r2b_valid_o` is already deasserted (state moved past R2B)
- `e3_valid_i` in hazard = the lanes `e3_valid` signal (normal E-pipe), NOT R3
- `w_valid_i` = `wb_valid` which is the registered version of the muxed valid_o

So R3 is covered through the `valid_o → e3_valid → wb_valid` path in hp_vpu_top, which means hazard checking catches it at the WB stage. The gap is 1 cycle where R3 is active but only seen as WB next cycle. Safe due to multicycle_busy, but fragile.

---

## Pipeline Balance Question

Should we add dummy stages to balance E/R/W?

**Current depths:** E=7, R=8, W=6

**Option A: Balance all to 8 (add dummy stages)**
- Add 1 dummy stage to E-pipe (E2→E2B or similar)
- Add 2 dummy stages to W-pipe
- Pro: Uniform latency, simpler hazard reasoning, easier to relax multicycle_busy later
- Con: +1 cycle latency on E-pipe (most common path), +2 on W-pipe, more flops

**Option B: Leave unbalanced, keep multicycle_busy serialization**
- Pro: No wasted cycles on common E-pipe path, already working
- Con: Asymmetric hazard reasoning, harder to optimize throughput later

**Option C: Balance E and R to 8, leave W at 6** (recommended)
- Add 1 dummy to E-pipe so E=R=8
- W stays short (widening is rare, already serialized)
- Pro: The two most common paths (arithmetic + reduction) have same depth, simplifies hazard analysis
- Con: +1 cycle on every E-pipe instruction

**Recommendation:** Option B for now (ship what works), Option C when you want to overlap E and R for throughput. The current serialization through multicycle_busy makes the depth difference irrelevant for correctness.

---

## Stress Tests Needed

The existing `test_reduction_timing.sv` only tests:
1. Single reduction latency (cycle count)
2. One back-to-back hazard case

**Missing stress scenarios (from interrupted audit):**

| # | Test | Why |
|---|------|-----|
| 1 | Back-to-back reductions, different vd | Verify multicycle_busy serializes properly |
| 2 | Reduction → arithmetic RAW (same vd) | Stall until R3→WB completes |
| 3 | Arithmetic → reduction WAW (same vd) | E-pipe must drain before R-pipe starts |
| 4 | Reduction → widening (same vd) | Cross-pipe WAW through multicycle_busy |
| 5 | SEW=8/16/32 sweep in single test | R2A array sizing stress (the bug Jules had) |
| 6 | 8x reduction burst | Pipeline throughput under sustained load |
| 7 | RAW chain: red→add→red→add | Dependency chain crossing pipe types |
| 8 | E3 in-flight when reduction issues | Verify pipeline_drained gate works |

**These tests have NOT been written yet.** The interrupted session acknowledged this gap.

---

## Summary

| Area | Status | Notes |
|------|--------|-------|
| RAW for R2A | ✅ Correct | Dedicated port, properly wired |
| RAW for R2B | ✅ Correct | Dedicated port, properly wired |
| RAW for R3 | ⚠️ Implicit | Covered via WB, safe only due to multicycle_busy |
| WAW all pipes | ⚠️ Implicit | No explicit detection, relies on serialization |
| R2A array sizing | ✅ Fixed | Jules bug corrected in v0.3e |
| e2_valid_o cleanup | ✅ Fixed | R2A removed from e2 |
| Stress tests | ❌ Missing | 8 scenarios identified, none written |
| Pipeline balance | ℹ️ Unbalanced | E=7, R=8, W=6 — safe but limits future throughput |
