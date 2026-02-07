# v0.5f: DMA/Compute VRF Port Separation + BRAM-Friendly VRF

**Date:** February 6, 2026
**Predecessor:** v0.5e (double-buffer VRF + MAC stall fixes)
**Status:** COMPLETE — all regressions passing, DBUF throughput 3.5× improvement

---

## Changes

### 1. `rtl/hp_vpu_vrf.sv` — BRAM-Friendly Flat Arrays + Separated Ports

**Structural overhaul:** Removed 8-way gen_bank loop (24 tiny 16×8-bit arrays → FFs).
Replaced with 3 flat monolithic arrays:
```
(* ram_style = "block" *) logic [DLEN-1:0] base_mem  [0:15];  // v0-v15
(* ram_style = "block" *) logic [DLEN-1:0] weight_a  [0:15];  // v16-v31 bank A
(* ram_style = "block" *) logic [DLEN-1:0] weight_b  [0:15];  // v16-v31 bank B
```

**Key insight — each array is truly 1W:**
- `base_mem`: compute writes accumulators during GEMV, DMA writes during init only.
  Single muxed always_ff: compute priority, else DMA. Never concurrent.
- `weight_a`: when A active → compute reads only; DMA writes B (shadow).
  When B active → DMA writes A (shadow); compute reads B.
  Single muxed always_ff per array. Never 2 simultaneous writers.
- `weight_b`: mirror of weight_a.

**BRAM inference pattern:**
- 1W (muxed) + 3R (registered) per array → Vivado replicates to 2 TDP BRAMs
- Byte-write enables via native BRAM WE pins (Vivado-recognized loop pattern)
- Debug/DMA read also registered (BRAM output register)
- `(* ram_style = "block" *)` pragma forces block RAM mapping
- Total: 3 arrays × 2 replicas = 6 BRAM18 (at any VLEN)

**Port interface (unchanged externally):**
- Port 1 (`wr_*`): compute pipeline WB ONLY
- Port 2 (`dma_wr_*`): ALL DMA writes (base, shadow, active)
- New input: `dma_dbuf_en_i` — VRF routes DMA writes internally

### 2. `rtl/hp_vpu_top.sv` — Separated Ports + 2-Cycle DMA Read

**Write path:** Removed DMA-steals-WB mux. Port 1 = `wb_*` directly. Port 2 = `dma_*` directly.

**Read path:** DMA read latency changed from 1 to 2 cycles:
- Cycle 0: address presented, VRF registered read starts
- Cycle 1: VRF output valid (BRAM output register)
- Cycle 2: `dma_rvalid_o` asserts, `dma_rdata_o` valid

Pipeline implemented via `dma_rd_pipe` stage register.

### 3. `tb/hp_vpu_tb.sv` — vrf_read latency fix

`vrf_read` task updated: 3 `@(posedge clk)` waits (was 2) to match 2-cycle DMA read.

### 4. `tb/hp_vpu_tb_bench.sv` — fork/join DBUF

`run_gemv_dbuf` uses `fork/join` for concurrent MAC issue + DMA shadow writes.

---

## Regression Results (VLEN=64)

| Suite | Result |
|-------|--------|
| Quick (smoke, 17 tests) | **17/17 PASS** |
| MAC (all ops, all SEW, 38 tests) | **38/38 PASS**, 0 stalls |
| Full (all instructions, 1274 tests) | **1274/1274 PASS** |

## Benchmark Results

| Test | v0.5e | v0.5f | Delta |
|------|------:|------:|------:|
| ALU vadd.vv ×64 | 0.853 | 0.853 | — |
| Pure MAC 8-acc K=128 | 0.988 | 0.988 | — |
| Seq GEMV 8-acc K=128 | 0.499 | 0.499 | — |
| **DBUF GEMV 8-acc K=16** | **0.256** | **0.826** | **3.2×** |
| **DBUF GEMV 8-acc K=64** | **0.251** | **0.872** | **3.5×** |
| **DBUF GEMV 8-acc K=128** | **0.251** | **0.880** | **3.5×** |

DBUF gap (0.880 vs 0.988): 1-cycle swap per K boundary. Theoretical max: 0.890.

---

## Files Changed (vs v0.5e)

| File | What changed |
|------|-------------|
| `rtl/hp_vpu_vrf.sv` | Flattened to 3 monolithic arrays with `(* ram_style = "block" *)`. Single muxed write per array. Registered debug read. |
| `rtl/hp_vpu_top.sv` | Removed DMA/WB mux. 2-cycle DMA read pipeline. |
| `tb/hp_vpu_tb.sv` | `vrf_read` +1 cycle for 2-cycle DMA latency. |
| `tb/hp_vpu_tb_bench.sv` | `run_gemv_dbuf` rewritten with fork/join. |

---

## FPGA Synthesis Notes

**VRF BRAM mapping:** Each of the 3 arrays has 1 muxed write port and 3 registered read ports.
Vivado auto-replicates to 2 TDP BRAM18 per array (portA: W+R1, portB: R2; second copy: W+R3, portB: debug).
At VLEN=64: 16×64b = 1Kbit/array, low BRAM utilization but clean timing.
At VLEN=256: 16×256b = 4Kbit/array, better utilization.

**DMA read latency:** Any consumer waiting for `dma_rvalid_o` gets data 2 cycles after request.
The FPGA LLM test state machine already has sufficient states to absorb this.

## How to Verify

```bash
# Quick smoke
iverilog -g2012 -DSIMULATION -DTEST_QUICK \
  -I rtl -I generated -I generated/tests -I tb -o sim/quick.vvp \
  generated/hp_vpu_pkg.sv rtl/hp_vpu_csr.sv rtl/hp_vpu_issue_check.sv \
  rtl/hp_vpu_top.sv rtl/hp_vpu_lanes.sv rtl/hp_vpu_decode.sv \
  rtl/hp_vpu_hazard.sv rtl/hp_vpu_iq.sv rtl/hp_vpu_vrf.sv \
  rtl/hp_vpu_lut_rom.sv tb/hp_vpu_tb.sv
vvp sim/quick.vvp +seed=99999   # Expect: 17/17

# Full regression
# Replace -DTEST_QUICK with -DTEST_FULL   # Expect: 1274/1274

# Benchmark
iverilog -g2012 -I rtl -I generated -I generated/tests -I tb -o sim/bench.vvp \
  generated/hp_vpu_pkg.sv rtl/hp_vpu_csr.sv rtl/hp_vpu_issue_check.sv \
  rtl/hp_vpu_top.sv rtl/hp_vpu_lanes.sv rtl/hp_vpu_decode.sv \
  rtl/hp_vpu_hazard.sv rtl/hp_vpu_iq.sv rtl/hp_vpu_vrf.sv \
  rtl/hp_vpu_lut_rom.sv tb/hp_vpu_tb_bench.sv
vvp sim/bench.vvp   # Key: DBUF 8-acc K=128 → 0.880
```
