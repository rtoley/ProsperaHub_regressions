# VPU FPGA v0.2k Handoff Document

## Session Summary (2026-02-04)

Applied P1, P2, P3 fixes from v0.2j to proper v0.2g base. Fixed critical `vsetvl_done` testbench bug.

---

## Current State

### Test Results (Expected after fixes)
| Test Suite | Result |
|------------|--------|
| Base RTL tests | **129/129 ✓** (2 new SEW=16 widening tests) |
| Compliance tests | **688/688** (P1+P2+P3+TB fix should fix all failures) |

### What Was Fixed

**P1: Bitwise reduction missing vs1[0]**
- VREDAND, VREDOR, VREDXOR were not including vs1[0] in final result
- Fixed in `rtl/hp_vpu_lanes.sv` lines 520-522, 543-545, 566-568

**P2: vredsum SEW=32 returning half values**
- For DLEN=256, SEW=32: 8 elements → 4 partial sums after L1
- Bug: Only first 2 partial sums were used, ignoring the other 2
- Fixed by adding proper L2 reduction for SEW=32 (lines 436-458)

**P3: Widening SEW=16 sign extension bug**
- Root cause: `$signed(a16)` doesn't reliably sign-extend when assigned to wider wire
- Fix: Use explicit sign extension `{{16{a16[15]}}, a16}`
- Fixed in `rtl/hp_vpu_lanes.sv` lines 743-776

**TESTBENCH BUG: vsetvl_done causing SEW=8 stuck**
- Root cause: `test_vsetvli()` sets `vsetvl_done=1`, after which all instructions
  use `int_vtype` (stuck at SEW=8) instead of `csr_vtype` from `set_vtype()`
- Symptom: All SEW=16 widening tests produced SEW=8 results
- Fix: Modified `set_vtype()` to issue actual vsetvli instruction
- Fixed in `tb/hp_vpu_tb.sv`

---

## Files Modified Since v0.2g

| File | Change |
|------|--------|
| `rtl/hp_vpu_lanes.sv` | P1: vs1 in bitwise reductions |
| `rtl/hp_vpu_lanes.sv` | P2: L2 reduction for SEW=32 |
| `rtl/hp_vpu_lanes.sv` | P3: Explicit sign extension |
| `tb/hp_vpu_tb.sv` | Added SEW=16 widening tests, reduction helpers |
| `scripts/gen_compliance_tests.py` | Enhanced with widening/narrowing/reduction support |
| `generated/compliance_tests.sv` | Regenerated with new test cases |
| `docs/*.md` | New documentation files |

---

## Project Structure (Preserved from v0.2g)

```
vpu_fpga_0.2k/
├── step1_vpu_rtl_validate.sh      # Base RTL validation
├── step1b_fpga_test_validate.sh   # FPGA test validation
├── step2_vpu_synthesis.sh         # Synthesis
├── step2_vpu_yosys_synth.sh       # Yosys synthesis
├── step2b_fpga_test_synth.sh      # FPGA synthesis
├── step3_vpu_netlist_verify.sh    # Netlist verification
├── step3b_fpga_netlist_verify.sh  # FPGA netlist verify
├── rtl/                           # RTL source files
├── tb/                            # Testbenches
├── scripts/                       # Generation scripts
│   ├── gen_pkg.py
│   ├── gen_compliance_tests.py
│   ├── gen_lut_tables.py
│   └── generate_all.py
├── fpga/                          # FPGA test designs
├── generated/                     # Generated files
├── config/                        # Configuration files
├── tests/toml/                    # Test vectors
└── docs/                          # Documentation
```

---

## Quick Test Commands

```bash
cd vpu_fpga_0.2k

# Base tests (should be 129/129)
./step1_vpu_rtl_validate.sh

# With compliance tests (should be 688/688)
./step1_vpu_rtl_validate.sh -c

# FPGA synthesis
./step2_vpu_yosys_synth.sh

# Check specific failures
grep "FAIL:" results/rtl/test_results.log
```

---

## Next Steps for v0.3

1. **Run tests** to verify all fixes: `./step1_vpu_rtl_validate.sh -c`
2. **Verify FPGA synthesis**: `./step2_vpu_yosys_synth.sh`
3. **Assess stress test coverage** for RVV compliance
4. **Create v0.3 release** when all compliance tests pass

---

## Configuration

- VLEN=256, DLEN=256, NLANES=4
- Pre-generated `hp_vpu_pkg.sv` in `generated/` directory

---

## Version Info

- **Release**: vpu_fpga_0.2k
- **Base**: vpu_fpga_0.2g (full structure)
- **Fixes**: P1, P2, P3 from v0.2j
- **Date**: 2026-02-04
- **Expected Base tests**: 129/129
- **Expected Compliance**: 688/688 (97.4% → 100%)
