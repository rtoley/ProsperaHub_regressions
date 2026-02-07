# VPU FPGA Changelog

## v0.4 - Timing Closure & Verification Release (2026-02-05)

### Pipeline
- **R2A/R2B split**: Reduction tree R2 stage split into R2A + R2B for 300 MHz Ultrascale+ timing closure
- **drain_stall combinational fix**: Prevents 1-cycle race on of_valid clearing during multicycle op capture
- R-pipe latency: 7→8 cycles. All stages ≤ 4 LUT levels deep.

### Verification
- **22 new R2A/R2B stress tests** (burst, RAW/WAW cross-pipe, SEW sweep, drain)
- **CV-X-IF handshake fix** in standalone testbenches
- FPGA-top tests verified: simple instruction (10/10), LLM inference (PASS)
- CSR + issue checker unit test: 17/17

### Test Results
- Full suite VLEN=64: 1351/1356 (99.6%)
- Full suite VLEN=256: 1351/1356 (99.6%)
- Stress R2A/R2B: 22/22 (100%)
- FPGA simple: 10/10, FPGA LLM: PASS, CSR: 17/17
- 5 pre-existing known failures (test bugs, not RTL)

### Documentation
- Consolidated 28 docs → 7 main + archive
- New: TIMING_DEPTH_ANALYSIS.md, AUDIT_R2AB_HAZARD.md

## v0.3c - Test Coverage Expansion (2026-02-04)

### Test Coverage
- **1227 total tests** across 15 categories
- **1224/1227 passing (99.8%)**
- 3 known LUT edge cases (vrecip/vrsqrt return 0 for out-of-range inputs)

### New Test Categories (6)
- **MASK** (56 tests): Mask logical operations (vmand, vmnand, vmandn, vmxor, vmor, vmnor, vmorn, vmxnor)
- **MASKOP** (43 tests): Mask manipulation (vcpop.m, vfirst.m, vmsbf.m, vmsif.m, vmsof.m, vid.v)
- **PERM** (54 tests): Permutation (vmv.v.v, vmv.v.x, vmv.v.i, vmerge.vvm)
- **WIDE** (82 tests): Widening arithmetic and multiply-accumulate
- **FIXPT** (30 tests): Fixed-point scaling shifts (vssrl, vssra)
- **INT4** (16 tests): INT4 pack/unpack operations

### RTL Fixes
1. **MASK logical ops**: Added mask_valid to NOT operations - upper bits now zeroed
2. **MASKOP edge cases**: Added mask_valid_e2 for vmsbf/vmsif all-zeros handling
3. **FIXPT scaling shifts**: Fixed overflow bug in rounding - use full rounded value

### Infrastructure Updates
- Updated gen_modular_tests.py with 6 new test generators
- Updated step1_vpu_rtl_validate.sh with new --test options
- Updated hp_vpu_tb.sv with new TEST_* defines
- Quick test: 15 tests, Full test: 1227 tests

## v0.3b - Modular Test Infrastructure
- 946 tests, 943/946 passing (3 known LUT edge cases)
- ALU, MUL, MAC, SAT, CMP, RED, LUT categories

## v0.3a - RVV Compliance Foundation
- Widening operation support
- INT4 pack/unpack operations
