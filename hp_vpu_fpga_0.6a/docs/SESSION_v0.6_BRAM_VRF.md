# v0.6 / v0.6a: BRAM-Friendly VRF + Fully Separated DMA/Compute Ports

**Date:** February 6, 2026
**Predecessor:** v0.5e

---

## Summary

Separated DMA and compute VRF write ports to eliminate WB stealing.
Restructured VRF for Xilinx block RAM inference. Fixed all TBs and FPGA
tops for 2-cycle DMA read latency.

## RTL Changes

### `rtl/hp_vpu_vrf.sv`
- Flattened 8-way gen_bank (24 tiny arrays → FFs) into 3 monolithic arrays
- `(* ram_style = "block" *)` on `base_mem`, `weight_a`, `weight_b`
- Each array: single muxed write port (compute priority, else DMA)
  - Never 2 writers to same array same cycle (verified by design)
- All reads registered (BRAM output register compatible)
- Debug/DMA read registered (was combinational)
- Port 2 renamed: `shadow_wr_*` → `dma_wr_*` (handles ALL DMA writes)
- New input: `dma_dbuf_en_i` (VRF routes DMA internally)

### `rtl/hp_vpu_top.sv`
- Removed `vrf_wr_en = dma_to_normal ? 1'b1 : wb_we` mux (DMA stealing WB)
- Port 1: `wb_we`/`wb_vd`/`wb_data` direct to VRF (compute only)
- Port 2: `dma_wr_accept`/`dma_addr_i`/`dma_wdata_i` to VRF (all DMA)
- DMA read: 2-cycle pipeline (`dma_rd_pipe` stage register)

## TB/FPGA Changes

| File | Change |
|------|--------|
| `tb/hp_vpu_tb.sv` | `vrf_read` +1 cycle (3 waits total) |
| `tb/hp_vpu_tb_modular.sv` | `vrf_read` +1 cycle |
| `tb/hp_vpu_hazard_test.sv` | `vrf_read_reg` +1 cycle |
| `tb/hp_vpu_tb_bench.sv` | `run_gemv_dbuf` → fork/join concurrent DMA+issue |
| `fpga/fpga_vpu_test_top.sv` | Added `ST_WAIT_RDATA` state |
| `fpga/fpga_vpu_llm_test_top.sv` | Added `ST_WAIT_RDATA`, fixed `result_reg` capture |

## Verification Results

| Suite | Result |
|-------|--------|
| Quick (17 tests) | **17/17 PASS** |
| MAC (38 tests) | **38/38 PASS**, 0 stalls |
| Full (1274 tests) | **1274/1274 PASS** |
| Hazard test | **PASS** |
| FPGA test (10 ops) | **10/10 PASS** |
| FPGA LLM test | **PASS** |

## Benchmark

| Test | v0.5e | v0.6 |
|------|------:|------:|
| Pure MAC 8-acc K=128 | 0.988 | 0.988 |
| Seq GEMV 8-acc K=128 | 0.499 | 0.499 |
| **DBUF GEMV 8-acc K=128** | **0.251** | **0.880** |

DBUF theoretical max with swaps: 0.890. Measured: 0.880. Near-optimal.
