# v0.5e Session Plan: Double-Buffer DMA/IQ Throughput Stall Fix

**Date:** February 6, 2026
**Status:** Analysis complete, NO RTL changes made yet
**Working directory:** hp_vpu_fpga_0.5e/
**Key files:** rtl/hp_vpu_top.sv, rtl/hp_vpu_iq.sv, tb/hp_vpu_tb_bench.sv
**Predecessor:** SESSION_v0.5e_MAC_STALL_FIX.md (pipeline stalls — RESOLVED)

---

## What Was Done Before This Session

The previous session successfully removed two structural pipeline stalls in `hp_vpu_lanes.sv`:

1. **`mac_stall` — REMOVED.** Line 183: `wire mac_stall = 1'b0;` hardwired off. The MAC add result feeds combinationally through E2→E3 without staging registers or an extra cycle.

2. **`mul_stall` — FIXED.** Line 1332: narrowed to only stall when E1 has a non-multiply and E1m is full. The E1m always_ff block (line ~2787) was restructured for simultaneous drain+capture (the `is_mul_op_e1 && e1m_valid` branch).

3. **Double-buffer VRF — IMPLEMENTED.** `hp_vpu_vrf.sv` split into base (v0–v15) and dual-banked weight registers (v16–v31, banks A/B). `hp_vpu_top.sv` has shadow write port and `weight_bank_sel` swap logic. This is functionally correct.

### Verification State (this tarball)

- **Quick test (17/17):** `--quick` PASS
- **MAC tests (38/38):** `--test mac` PASS
- **Full test:** not re-run in this session, was 1351/1356 (99.6%) at v0.4
- **Reference tarball included:** `hp_vpu_fpga_0_5e_tar.gz` (pre-double-buffer) available for diffing

### RTL Diff Summary (working vs reference)

Only two RTL files changed from the reference (pre-double-buffer) baseline:

| File | Changes |
|------|---------|
| `rtl/hp_vpu_vrf.sv` | Split `bank_mem` → `base_mem[0:15]` + `weight_a[0:15]` + `weight_b[0:15]`. All 4 read ports mux active bank. Shadow write port added. |
| `rtl/hp_vpu_top.sv` | Added `dma_dbuf_en_i`, `dma_dbuf_swap_i` ports. `weight_bank_sel` FF. DMA write routing split into `dma_to_normal` (port 1) and `dma_to_shadow` (port 2). Shadow write port wired to VRF. |

`hp_vpu_lanes.sv` is **identical** between reference and working — the `mac_stall`/`mul_stall` fixes were already in the reference.

---

## Problem Statement

Pure MAC pipeline throughput is now **0.988 vec MACs/cycle** (8 accumulators, K=128) — essentially solved. But when double-buffered GEMV overlaps DMA weight writes with MAC compute, throughput drops to **0.251 vec MACs/cycle** — worse than sequential DMA-then-compute (0.499).

The double-buffer hardware works correctly (shadow bank receives DMA writes, bank swap functions), but the **system-level issue port** is the bottleneck.

### Benchmark Numbers (current, pre-fix)

| Test | Accum | K | Vec MACs/cycle | Elem MACs/cycle | Notes |
|------|:-----:|:---:|:--------------:|:---------------:|-------|
| Pure MAC (no DMA) | 1 | 16 | 0.136 | 1.1 | Pipeline latency dominates |
| Pure MAC (no DMA) | 2 | 16 | 0.269 | 2.2 | |
| Pure MAC (no DMA) | 4 | 16 | 0.529 | 4.2 | |
| Pure MAC (no DMA) | 8 | 16 | 0.914 | 7.3 | Near-peak ✅ |
| Pure MAC (no DMA) | 8 | 64 | 0.977 | 7.8 | Near-peak ✅ |
| Pure MAC (no DMA) | 8 | 128 | 0.988 | 7.9 | **Near-peak** ✅ |
| Sequential GEMV | 8 | 16 | 0.492 | 3.9 | DMA reload between K steps |
| Sequential GEMV | 8 | 128 | 0.499 | 4.0 | ~50% ceiling (DMA cost) |
| **DBUF GEMV (overlapped)** | 8 | 16 | **0.256** | 2.0 | ❌ Worse than sequential |
| **DBUF GEMV (overlapped)** | 8 | 64 | **0.251** | 2.0 | ❌ |
| **DBUF GEMV (overlapped)** | 8 | 128 | **0.251** | 2.0 | ❌ |
| **DBUF GEMV (overlapped)** | 4 | 128 | **0.250** | 2.0 | ❌ |

ALU baseline (vadd.vv, no stalls): ~0.85 vec ops/cycle — proves issue/decode can sustain near 1 op/cycle when no DMA contention.

---

## Root Cause Analysis: DMA/Instruction Issue Port Contention

### The Problem

The CV-X-IF interface is a **single shared port** for both:
- Vector instruction issue (MAC, ALU, etc.) → pushed into the 8-entry instruction queue (IQ)
- DMA weight write commands → pushed into the same issue path

When `run_gemv_dbuf` fires DMA writes to the shadow weight bank while MAC instructions are executing, they compete for the same issue cycle. The 8-entry IQ fills, backpressures the core, and every DMA write steals a cycle from MAC issue.

### Why It's Exactly 0.25 MACs/cycle

With overlapped DMA, the testbench interleaves:
1. DMA write cycle (weight to shadow bank)
2. MAC instruction issue cycle

But the IQ and issue logic serialize these — DMA writes consume issue slots. With roughly 1:1 DMA-to-MAC ratio and pipeline overheads, you get ~0.25 instead of the theoretical ~1.0.

### Why Sequential GEMV Gets 0.5

Sequential mode does all DMA writes first (filling weights), then all MACs. Each phase runs at its natural rate. The 50% overhead is just the time spent doing DMA between compute phases. The pipeline itself runs at near-peak during the compute phase.

### Key Insight

The double-buffer VRF hardware works — the shadow write port accepts DMA writes independently of the compute write port. The bottleneck is **upstream**: DMA commands and vector instructions share the CV-X-IF issue interface. The VRF can handle simultaneous compute-read + shadow-write, but the issue path can't feed both at once.

---

## Fix Options

### Option A: Separate DMA from the Instruction Path (Recommended)

Give DMA writes their own interface, bypassing the IQ entirely.

**Concept:** DMA weight writes don't need to go through CV-X-IF → IQ → decode → lanes. They just need `{addr, data, byte_enables}` routed to the VRF shadow write port. Add a small DMA command FIFO (or direct handshake) that accepts `{wr_en, addr, wdata, be}` and writes directly to the shadow port.

**In `hp_vpu_top.sv`:** The shadow write port (`shadow_wr_en`, `shadow_wr_addr`, `shadow_wr_data`, `shadow_wr_be`) already exists and is independent of the compute writeback path. The routing logic (`dma_to_shadow`) already distinguishes shadow writes. The fix is to **not** route these through the CV-X-IF issue path.

**What changes:**
- `hp_vpu_top.sv`: DMA shadow writes bypass IQ, go directly to VRF shadow port via separate handshake signals (new top-level ports or reuse existing `dma_*` ports with routing logic)
- `hp_vpu_iq.sv`: No changes needed — IQ now only sees real vector instructions
- Testbenches: `run_gemv_dbuf` needs to drive DMA writes on the separate port instead of through instruction issue

**Risk:** Low — the VRF shadow write port is already isolated. We're just changing how it's fed.

**Expected result:** DBUF GEMV should approach pure MAC throughput (~0.98) since DMA writes happen on a completely independent port.

### Option B: Widen/Split the IQ

Split the 8-entry IQ into separate DMA and compute queues, or widen to allow dual issue.

**Concept:** Keep DMA going through the issue path but give it its own queue so it doesn't block compute instructions.

**What changes:**
- `hp_vpu_iq.sv`: Duplicate into `hp_vpu_iq_compute` + `hp_vpu_iq_dma`, or add dual-push capability
- `hp_vpu_top.sv`: Arbitration logic for dual queues, priority to compute
- Decode: Must handle two instruction sources

**Risk:** Medium — more complex arbitration, potential for new hazards if DMA and compute both try to write VRF on same cycle (though shadow port isolation should prevent this)

**Not recommended** because it adds complexity without addressing the fundamental issue that DMA writes don't need the decode/execute pipeline at all.

### Option C: DMA Batching / Burst Mode

Keep shared issue path but batch DMA writes during pipeline bubbles.

**Concept:** Instead of interleaving 1:1, queue up all DMA writes and inject them only when the MAC pipeline has natural bubbles (e.g., between K-step boundaries).

**Risk:** Low complexity but limited upside — doesn't achieve true overlap, just better scheduling.

---

## Hazard Considerations

**Critical invariant:** When the VRF shadow port is being DMA-written, the compute pipeline must not read stale data from the **active** bank. This is already guaranteed by the bank-swap architecture:
- Active bank: read by compute, written by compute writeback
- Shadow bank: written by DMA only
- Swap only happens explicitly via `dma_dbuf_swap_i` pulse

**WAW hazard on swap:** After swap, the old shadow (now active) bank has new weights. The old active (now shadow) bank has compute results. If DMA immediately starts writing to the new shadow bank, there's no conflict — compute reads the new active bank, DMA writes the new shadow bank.

**No new hazards from Option A:** The shadow write port is already physically separate. Moving DMA off the issue path doesn't change any VRF access patterns.

---

## How to Verify (Quick Reference)

```bash
# Generate package
python3 scripts/gen_pkg.py config/vpu_config.json

# Quick smoke test (17 tests, ~5 sec)
# Compile:
iverilog -g2012 -DSIMULATION -DTEST_QUICK \
  -I rtl -I generated -I generated/tests -I tb \
  -o sim/quick_test.vvp \
  generated/hp_vpu_pkg.sv rtl/hp_vpu_csr.sv rtl/hp_vpu_issue_check.sv \
  rtl/hp_vpu_top.sv rtl/hp_vpu_lanes.sv rtl/hp_vpu_decode.sv \
  rtl/hp_vpu_hazard.sv rtl/hp_vpu_iq.sv rtl/hp_vpu_vrf.sv \
  rtl/hp_vpu_lut_rom.sv tb/hp_vpu_tb.sv
# Run:
vvp sim/quick_test.vvp +seed=99999
# Expect: 17/17 passed, ALL TESTS PASSED

# MAC-specific tests (38 tests)
# Same compile with -DTEST_MAC instead of -DTEST_QUICK
# Expect: 38/38 passed

# Full modular tests (1227 tests)
# Same compile with -DTEST_FULL
# Expect: ~1224/1227 (3 known LUT edge cases)

# Benchmark (throughput measurement)
iverilog -g2012 \
  -I rtl -I generated -I generated/tests -I tb \
  -o sim/bench_64.vvp \
  generated/hp_vpu_pkg.sv rtl/hp_vpu_csr.sv rtl/hp_vpu_issue_check.sv \
  rtl/hp_vpu_top.sv rtl/hp_vpu_lanes.sv rtl/hp_vpu_decode.sv \
  rtl/hp_vpu_hazard.sv rtl/hp_vpu_iq.sv rtl/hp_vpu_vrf.sv \
  rtl/hp_vpu_lut_rom.sv tb/hp_vpu_tb_bench.sv
vvp sim/bench_64.vvp
# Key metrics to watch:
#   Pure MAC 8-accum K=128: should be ~0.988 (already good)
#   DBUF GEMV 8-accum K=128: currently 0.251 (TARGET: ~0.9+)
```

No Docker required — iverilog 12.0 runs natively (`apt install iverilog`).

---

## Execution Order (Next Session)

1. **Back up current state** — `tar czf` before any RTL changes
2. **Implement Option A** — separate DMA write path bypassing IQ
   - Add direct DMA handshake ports to `hp_vpu_top.sv` (or restructure existing `dma_*` routing)
   - Ensure `dma_to_shadow` writes go directly to VRF, not through IQ/issue
   - Update testbench `run_gemv_dbuf` to use the separate DMA path
3. **Run regression** — quick (17), MAC (38), then full (1227)
4. **Run benchmark** — confirm DBUF GEMV approaches pure MAC throughput
5. **Back up post-fix state** — `tar czf` with results

---

## Files in Tree

- `rtl/hp_vpu_top.sv` — top level with DMA routing (WILL CHANGE)
- `rtl/hp_vpu_iq.sv` — instruction queue, 8-entry FIFO (may not need changes for Option A)
- `rtl/hp_vpu_vrf.sv` — VRF with shadow write port (SHOULD NOT CHANGE)
- `rtl/hp_vpu_lanes.sv` — pipeline with mac_stall/mul_stall fixes (SHOULD NOT CHANGE)
- `tb/hp_vpu_tb_bench.sv` — benchmark testbench (WILL CHANGE for new DMA path)
- `tb/hp_vpu_tb.sv` — main testbench (WILL CHANGE for new DMA ports)
- `docs/SESSION_v0.5e_MAC_STALL_FIX.md` — previous session notes (REFERENCE ONLY)
- `results/bench_64_current.log` — current benchmark baseline log
