# VPU FPGA v0.3 Handoff Document

## Session Summary (2026-02-04)

**Achievement**: 702/702 tests passing (100%)

### Fixes Applied (from v0.2k)
| Bug | Root Cause | Fix Location |
|-----|------------|--------------|
| P4 | Reduction min/minu filler=0 at DLEN=64 | rtl/hp_vpu_lanes.sv:431-443,467-479 |
| T1 | LUT tests expect non-zero for zero results | scripts/gen_compliance_tests_v3.py |

### Key Improvements
- Test count: 690 → 702 (with smarter LUT filtering)
- Operations tested: 23 → 45 (+96%)
- Multi-SEW coverage for all major ops

---

## Quick Start

```bash
# Install iverilog
apt-get install iverilog

# Run full validation
cd vpu_fpga_0.3
iverilog -g2012 -DSIMULATION -DCOMPLIANCE_TESTS \
  -I rtl -I generated -I tb -o sim/vpu_tb.vvp \
  generated/hp_vpu_pkg.sv rtl/hp_vpu_top.sv rtl/hp_vpu_decode.sv \
  rtl/hp_vpu_lanes.sv rtl/hp_vpu_hazard.sv rtl/hp_vpu_iq.sv \
  rtl/hp_vpu_vrf.sv rtl/hp_vpu_lut_rom.sv tb/hp_vpu_tb.sv

vvp sim/vpu_tb.vvp +seed=99999
# Expected: Test Results: 702/702 passed
```

---

## Project Structure

```
vpu_fpga_0.3/
├── rtl/                          # RTL source
│   ├── hp_vpu_top.sv             # Top-level
│   ├── hp_vpu_decode.sv          # Decoder
│   ├── hp_vpu_lanes.sv           # Execution (FIXED: reduction filler)
│   ├── hp_vpu_hazard.sv          # Hazard detection
│   ├── hp_vpu_iq.sv              # Instruction queue
│   ├── hp_vpu_vrf.sv             # Vector register file
│   └── hp_vpu_lut_rom.sv         # LUT for custom ops
│
├── tb/                           # Testbenches
│   └── hp_vpu_tb.sv              # Main TB (127 base + 575 compliance)
│
├── generated/                    # Auto-generated
│   ├── hp_vpu_pkg.sv             # Package
│   └── compliance_tests.sv       # 575 tests (REGENERATED)
│
├── scripts/                      # Generation scripts
│   ├── gen_pkg.py                # Package generator
│   └── gen_compliance_tests_v3.py # Test generator (FIXED)
│
├── docs/                         # Documentation
│   ├── HANDOFF_v0.3.md           # This file
│   └── COVERAGE_REPORT_v0.3.md   # Detailed coverage
│
├── step1_vpu_rtl_validate.sh     # Docker-based validation
├── step2_vpu_yosys_synth.sh      # Yosys synthesis (needs sv2v)
└── step3_vpu_netlist_verify.sh   # Netlist verification
```

---

## Test Coverage Summary

| Category | Coverage | Notes |
|----------|----------|-------|
| ALU (13 ops) | ★★★ | Full multi-SEW |
| MUL (4 ops) | ★★★ | Full multi-SEW |
| MAC (2/4 ops) | ★★☆ | vmacc, vnmsac only |
| Saturating (4/8) | ★★☆ | vsadd/sub variants |
| Widening (10 ops) | ★★★ | All tested |
| Reductions (8 ops) | ★★★ | All tested, filler bug FIXED |
| Custom LUT (4 ops) | ★★☆ | SEW=8,16 tested |
| Compare/Mask | ☆☆☆ | Base tests only |
| Permutation | ☆☆☆ | Base tests only |

See `docs/COVERAGE_REPORT_v0.3.md` for full details.

---

## What's Remaining for v0.4

### Priority 1: More Compliance Tests
- vnclip/vnclipu (requantization)
- vnsrl/vnsra (narrowing shifts)
- Compare operations (vmseq, vmslt, etc.)

### Priority 2: Synthesis Verification
- Run step2_vpu_yosys_synth.sh (needs Docker with sv2v)
- Run step3_vpu_netlist_verify.sh
- Timing analysis

### Priority 3: Format Variants
- .vx (scalar operand) variants
- .vi (immediate) variants

---

## Version History

| Version | Date | Tests | Changes |
|---------|------|-------|---------|
| v0.2k | 2026-02-04 | 690/690 | P1/P2/P3 fixes |
| v0.3 | 2026-02-04 | 702/702 | P4 fix, expanded coverage |
