# v0.5e Session Plan: MAC Pipeline Structural Stall Removal

**Date:** February 5, 2026
**Status:** Analysis complete, NO RTL changes made yet
**Working directory:** hp_vpu_fpga_0.5/
**Key file:** rtl/hp_vpu_lanes.sv

---

## Problem Statement

With 8 rotating accumulators (zero RAW hazards), MAC throughput is **0.324 vec MACs/cycle** —
only 1 MAC every 3 cycles. This is caused by two structural pipeline stalls that fire even
when there are NO data dependencies between consecutive instructions.

Benchmark proves it: `run_bench.sh` with `tb/hp_vpu_tb_bench.sv` (already in the tree).

### Benchmark Numbers (current, pre-fix)

| Accumulators | Vec MACs/cycle | % of theoretical 1/cycle |
|:---:|:---:|:---:|
| 1 | 0.119 | 12% |
| 2 | 0.211 | 21% |
| 4 | 0.315 | 32% |
| 8 | 0.324 | 32% |

ALU baseline (vadd.vv, no stalls): 0.853 vec ops/cycle — proves the issue/decode front-end
can sustain near 1 op/cycle. The MAC pipeline is the bottleneck.

---

## Root Cause Analysis: Two Structural Stalls

### Stall 1: `mac_stall` (hp_vpu_lanes.sv line ~198)

```verilog
assign mac_stall = is_mac_op_e2 && !mac_add_done;
```

**What it does:** When a MAC op arrives in E2, freezes the ENTIRE pipeline for 1 cycle so
the accumulate addition (`mul_result + old_vd`) can be registered into `e2m_*` registers.

**Why it's unnecessary:** The MAC add is already **combinational**:
```verilog
// Line ~3250: These are pure combinational wires, NOT registered
assign mac_add_8[i*8 +: 8] = mul_lo_8[i*8 +: 8] + e2_c[i*8 +: 8];
```
The `mac_add_res` result is available the **same cycle** the multiply result enters E2.
The stall cycle just re-registers an already-ready value into `e2m_*`.

**The e2m registers (line ~3290-3330):** During `mac_stall`, these capture the combinational
MAC add result:
```verilog
end else if (mac_stall && is_mac_op_e2) begin
    e2m_mac_res   <= mac_add_res;
    e2m_valid     <= e2_valid;
    ...
```
Then E3 reads from `e2m_*` when `e2m_valid` is high (line ~3550).

**Fix approach:** Route MAC results directly through E2→E3 without the e2m staging registers.
The `mac_add_res` combinational result can feed straight into E3 capture, same as non-MAC ops
feed through `final_result` → `masked_result` → E3. The e2m registers and mac_stall FSM
become dead code.

**Lines involved:**
- Lines 177-199: `is_mac_op_e2`, `mac_stall` FSM, `mac_add_done` — remove
- Lines 2502-2516: `e2m_*` register declarations — remove
- Lines 3290-3330: `e2m_*` capture during `mac_stall` — remove
- Lines 3275-3282: `mac_final_result` mux (uses `e2m_op`) — reroute to use `e2_op`
- Lines 3494-3521: `mac_masked_result` (uses `e2m_vmask`, `e2m_old_vd`) — reroute to `e2_*`
- Lines 3545-3570: E3 capture `if (e2m_valid)` branch — remove, fold MAC into normal path
- Lines 3377-3380: `final_result` mux already has MAC entries using `e2m_*` — change to
  use direct `mac_add_res` wire

### Stall 2: `mul_stall` (hp_vpu_lanes.sv line ~1347)

```verilog
wire mul_stall = e1_valid && e1m_valid;
```

**What it does:** Blocks E1 from accepting a new instruction whenever E1m is occupied.
This means E1m can either drain to E2 OR capture from E1, but not both in the same cycle.

**Why it's unnecessary:** In a properly pipelined design, when `!mac_stall`, E1m drains
to E2 on the same clock edge that E1 captures into E1m. Standard pipeline register behavior.

**Current structure (line ~2802):**
```verilog
end else if (!stall_i && !mac_stall) begin
    if (is_mul_op_e1 && !e1m_valid) begin
        // Capture from E1 → E1m
        e1m_valid <= e1_valid;
        ...
    end else if (e1m_valid) begin
        // Drain E1m → E2, clear E1m
        e1m_valid <= 1'b0;
    end
```
The `if/else if` makes capture and drain mutually exclusive.

**Fix approach:** Allow simultaneous drain+capture. When E1m is valid AND E1 has a multiply
AND E2 can accept (no mac_stall): E1m content goes to E2 while E1 content goes to E1m,
all on the same clock edge.

```verilog
// Pseudocode for fixed logic:
if (is_mul_op_e1 && e1m_valid && !mac_stall) begin
    // SIMULTANEOUS: E1m drains to E2 AND E1 captures into E1m
    e1m_valid <= e1_valid;  // E1's multiply replaces E1m content
    e1m_* <= e1_*;          // (E2 captures old e1m_* on same edge)
end else if (is_mul_op_e1 && !e1m_valid) begin
    // E1m empty, just capture
    e1m_valid <= e1_valid;
    e1m_* <= e1_*;
end else if (e1m_valid) begin
    // No multiply in E1, just drain
    e1m_valid <= 1'b0;
end
```

**IMPORTANT dependency:** If `mac_stall` is removed first (Stall 1), then `mac_stall` is
always 0, which simplifies the `mul_stall` fix. **Do Stall 1 first.**

**Lines involved:**
- Line 1347: `mul_stall` definition — after mac_stall removal, this becomes the only stall
- Lines 2802-2870: E1m `always_ff` block — restructure for simultaneous drain+capture
- Line 2232: E1 capture condition `!stall_i && !mac_stall && !mul_stall` — update
- Lines 2395-2460: E1 "branch2" logic (E1 capture during handoff) — may simplify

---

## Cycle-by-Cycle Trace (current, broken)

Back-to-back MACs to different vd registers (e.g., `vmacc v0..v7`):

| Cycle | E1 | E1m | E2 | E3 | Stall | Why |
|-------|-----|------|-----|-----|-------|-----|
| 1 | A captures | — | — | — | — | |
| 2 | B captures | A captures | — | — | — | E1→E1m handoff, E1 takes B |
| 3 | B **stalls** | — drains | A captures | — | `mul_stall` | E1m draining, can't capture B |
| 4 | B **stalls** | — | A stalls | — | `mac_stall` | E2 MAC add registering |
| 5 | C captures | B captures | — drains | A captures | — | Everything advances |
| 6 | C stalls | — drains | B captures | — | `mul_stall` | Same pattern repeats |
| 7 | C stalls | — | B stalls | — | `mac_stall` | |

Result: 1 MAC issued every 3 cycles = 0.333 vec MACs/cycle theoretical max.
Measured: 0.324 (97% of this broken ceiling).

## Expected After Fix

| Cycle | E1 | E1m | E2 | E3 |
|-------|-----|------|-----|-----|
| 1 | A captures | — | — | — |
| 2 | B captures | A captures | — | — |
| 3 | C captures | B captures | A to E3 | — |
| 4 | D captures | C captures | B to E3 | A writes back |
| 5 | E captures | D captures | C to E3 | B writes back |

Result: 1 MAC issued every cycle. **3× throughput.**

At VLEN=256: 32 elem MACs/cycle × 2 GHz = **64 INT8 GOPS** (up from ~20.8).

---

## Execution Order

1. **Remove `mac_stall`** — eliminate the E2 stall cycle for MAC add
   - Route MAC add results directly through `final_result` → E3
   - Remove `e2m_*` staging registers
   - Remove `mac_add_done` FSM

2. **Fix `mul_stall`** — allow E1m simultaneous drain+capture
   - Restructure E1m always_ff for pipelined handoff
   - With mac_stall gone, E2 always accepts, making this simpler

3. **Run regression** — all 1,419+ tests must pass
   - MAC hazard tests (test_mac_hazard_*) are the critical ones
   - Benchmark should show ~1.0 vec MACs/cycle at 8 accumulators

4. **Re-run benchmark** — confirm 3× throughput improvement

---

## Files in Tree (already committed)

- `tb/hp_vpu_tb_bench.sv` — GEMV benchmark testbench (new)
- `run_bench.sh` — one-step benchmark runner (new)
- `docs/BENCH_GEMV_RESULTS.md` — results summary (will need update after fix)
- Tarball: `hp_vpu_fpga_0.5d_bench.tar.gz` in outputs (pre-fix baseline)

---

## Risk Assessment

**Low risk:** Both stalls are purely structural, not correctness features. The actual
data-hazard protection is in `mac_vd_in_flight` (hp_vpu_top.sv line ~660), which tracks
which vd registers have MACs in-flight and blocks issue at the top level. That mechanism
is untouched by this change.

**Medium risk:** The `e2m_*` removal changes the E2→E3 datapath for MAC ops. Need to ensure
the masking logic (`mac_masked_result`) works correctly when driven from E2 signals instead
of E2m signals. The mask/old_vd data is the same — just needs re-wiring.

**Test coverage:** The existing MAC hazard tests (`test_mac_hazard_basic`,
`test_mac_hazard_sequential`, etc.) plus the modular random tests cover the correctness
angle. The benchmark covers the performance angle.
