# HP-VPU FPGA v0.4 Release Notes

**Release Date:** 2026-02-05
**Previous Release:** v0.3e

---

## Summary

HP-VPU v0.4 is a verification and timing-closure release. The reduction pipeline is split for 300 MHz Ultrascale+ timing, all known hazard scenarios are stress-tested, and documentation is consolidated.

---

## Changes from v0.3e

### Pipeline & RTL

- **R2A/R2B pipeline split** (from v0.3e): Reduction tree R2 stage split into R2A + R2B, reducing per-stage combinational depth from 2 levels to 1 level. R-pipe is now 8 stages (IF→IQ→D1→D2→OF→R1→R2A→R2B→R3→WB). Adds 1 cycle latency to reductions.
- **drain_stall_o fix** (v0.3f): Changed from registered to combinational `waiting_for_drain` to prevent a 1-cycle race where `hp_vpu_top` could clear `of_valid` before the multicycle op was captured.
- **Makefile fix:** Added `hp_vpu_issue_check.sv` to `RTL_FILES` — was missing for standalone compile targets.

### Verification

- **8 new stress tests** (`tb/test_r2ab_stress.sv`): Back-to-back reductions, RAW/WAW across pipe types, SEW sweep, 8x burst, dependency chains, pipeline drain verification. All 22 assertions pass at VLEN=256/NLANES=4.
- **CV-X-IF handshake fix** in stress/timing testbenches: Issue task corrected to assert `valid` first, then wait for `ready` (per spec). Main testbenches were already correct.
- **Hazard audit** (`docs/AUDIT_R2AB_HAZARD.md`): Full RAW/WAW analysis of the deepened R-pipe. RAW detection is correct. WAW relies on `multicycle_busy` serialization (documented, safe, but limits throughput).

### Documentation

- **Consolidated from 28 files to 7** — historical handoffs, resolved bugs, and stale TODOs moved to `docs/archive/`.
- **New: `TIMING_DEPTH_ANALYSIS.md`** — per-stage critical path analysis, scaling projections, 300 MHz closure rationale.

---

## Test Results

| Test Suite | Config | Result |
|-----------|--------|--------|
| Full modular (vpu_top) | VLEN=64, NLANES=1 | **1351/1356 passed** (99.6%) |
| Full modular (vpu_top) | VLEN=256, NLANES=4 | **1351/1356 passed** (99.6%) |
| R2A/R2B stress (vpu_top) | VLEN=256, NLANES=4 | **22/22 passed** (100%) |
| FPGA simple instruction (fpga_top) | VLEN=64, NLANES=1 | **10/10 passed** (100%) |
| FPGA LLM inference (fpga_top) | VLEN=64, NLANES=1 | **PASS** |
| CSR + issue checker (unit) | — | **17/17 passed** (100%) |

### Known Failures (5, all pre-existing)

1. `vmnand.mm` — test checker uses 256-bit patterns on 64-bit VLEN (test bug, not RTL)
2. `vmorn.mm` — same issue
3. `vrecip` (3x) — LUT zero-output, documented in KNOWN_FAILURES.md (test/LUT content issue)

### Known Limitations

1. **No explicit WAW detection** — relies on `multicycle_busy` serialization. Safe but limits throughput for mixed E+R workloads.
2. **R3 hazard gap** — 1-cycle window where R3 is active but tracked through WB. Safe due to `multicycle_busy`.
3. **`SPLIT_REDUCTION_PIPELINE` ifdef** — parameter exists but no conditional guard. Pipeline split is always active.
4. **Hazard test (`hp_vpu_hazard_test.sv`)** — has iverilog compile errors (nested for loop limitation). Does not affect RTL correctness.

---

## Pipeline Architecture (v0.4)

```
                          ┌─ E1 ─ E1m ─ E2 ─ E3 ─┐
                          │   (ALU)   (MUL)        │
  IF → IQ → D1 → D2 → OF├─ R1 ─ R2A ─ R2B ─ R3 ─┤─ WB → Result
                          │      (Reduction)       │
                          └─ W1 ─ W2 ──────────────┘
                               (Widening)
```

| Pipe | Depth | Latency |
|------|-------|---------|
| E-pipe (ALU) | 9 stages | 7 cycles |
| E-pipe (MUL) | 10 stages | 8 cycles |
| R-pipe | 10 stages | 8 cycles |
| W-pipe | 8 stages | 6 cycles |

**Target:** 300 MHz on Xilinx Ultrascale+. All stages ≤ 4 LUT levels.

---

## File Manifest

### RTL (`rtl/`)
| File | Description |
|------|-------------|
| `hp_vpu_top.sv` | Top-level: CV-X-IF interface, pipeline control, result mux |
| `hp_vpu_lanes.sv` | Execution lanes: E/R/W pipes, VRF write, hazard outputs |
| `hp_vpu_decode.sv` | 2-stage decode: D1 pre-decode, D2 full decode, LMUL µop |
| `hp_vpu_hazard.sv` | RAW hazard detection: OF/E1/E2/R2A/R2B/E3/WB stages |
| `hp_vpu_iq.sv` | Instruction queue: 8-deep FIFO with bypass |
| `hp_vpu_issue_check.sv` | Fast combinational instruction classifier |
| `hp_vpu_vrf.sv` | Vector register file: 2R1W, 32×VLEN |
| `hp_vpu_lut_rom.sv` | LUT ROM for vrecip/vrsqrt approximation |
| `hp_vpu_lut_rom_bram.sv` | BRAM variant for FPGA |
| `hp_vpu_lut_rom_stub.sv` | Stub for builds without LUT |
| `hp_vpu_csr.sv` | Optional CSR module (ENABLE_CSR) |

### Documentation (`docs/`)
| File | Description |
|------|-------------|
| `VPU_ARCHITECTURE.md` | Pipeline, blocks, hazard logic, configuration |
| `RVV_COMPLIANCE.md` | RVV 1.0 instruction coverage and known gaps |
| `SCALING_AND_PERFORMANCE.md` | Timing, throughput, ASIC projections |
| `INTEGRATION_GUIDE.md` | CV-X-IF integration, FPGA, memory interface |
| `KNOWN_FAILURES.md` | Open test failures with root cause |
| `TIMING_DEPTH_ANALYSIS.md` | Per-stage critical path for 300 MHz target |
| `AUDIT_R2AB_HAZARD.md` | R2A/R2B hazard audit findings |

---

## Upgrade Notes

- Drop-in replacement for v0.3e. No interface changes.
- Reduction latency increased by 1 cycle (7→8). Software-visible only if polling cycle counts.
- `multicycle_busy` behavior unchanged — reductions still fully serialize.
