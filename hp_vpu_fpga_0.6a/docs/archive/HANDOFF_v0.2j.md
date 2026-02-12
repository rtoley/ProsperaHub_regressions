# VPU FPGA v0.2j Handoff Document

## Session Summary (2026-02-04)

Applied P1 (bitwise reduction vs1 bug) and P2 (vredsum SEW=32 bug) fixes. Base tests now 127/127.

---

## Current State

### Test Results
| Test Suite | Result |
|------------|--------|
| Base RTL tests | **127/127 ✓** |
| Compliance tests | 670/688 (18 failures) |

### What Was Fixed (P1 + P2)

**P1: Bitwise reduction missing vs1[0]**
- VREDAND, VREDOR, VREDXOR were not including vs1[0] in final result
- Fixed in `rtl/hp_vpu_lanes.sv` for SEW=8, SEW=16, SEW=32

**P2: vredsum SEW=32 returning half values**
- For DLEN=256, SEW=32: 8 elements → 4 partial sums after L1
- Bug: Only first 2 partial sums were used, ignoring the other 2
- Fixed by adding proper L2 reduction for SEW=32 when NUM_ELEM_32/2 >= 2

---

## Remaining 18 Compliance Failures

All are **widening SEW=16 operations** (P3 - not yet fixed):
- vwadd.vv (3 failures)
- vwaddu.vv (4 failures)
- vwmacc.vv (3 failures)
- vwmaccu.vv (3 failures)
- vwmul.vv (2 failures)
- vwmulu.vv (3 failures)

**Pattern**: Upper bits wrong in 32-bit results from 16-bit sources.
Example: `0x00fefffe` actual vs `0x0000fffe` expected

**Likely cause**: Sign/zero extension issue in widening operations for multi-lane config.

---

## E1 Handoff Tests

The 4 E1 handoff test failures mentioned in v0.2g were **testbench issues**, not RTL bugs.
- Testbench had hardcoded expected values for DLEN=64
- Tests have been parameterized for DLEN in this version
- Now passing as part of 127/127

---

## Files Modified Since v0.2g

| File | Change |
|------|--------|
| `rtl/hp_vpu_lanes.sv` | P1: Added vs1 to bitwise reductions |
| `rtl/hp_vpu_lanes.sv` | P2: Added L2 reduction for SEW=32 |
| `tb/hp_vpu_tb.sv` | Parameterized E1 handoff test expectations |

---

## Next Session Priorities

1. **Fix P3: Widening SEW=16 bugs** (18 remaining compliance failures)
   - Investigate sign/zero extension in widening ops
   - Check `hp_vpu_lanes.sv` widening logic around lines 1700-1900

2. **Verify FPGA synthesis still works**
   - `./step2_vpu_yosys_synth.sh`

3. **Create v0.2k backup after P3 fix**

---

## Quick Test Commands

```bash
cd vpu_fpga_0.2j

# Base tests (should be 127/127)
./step1_vpu_rtl_validate.sh

# With compliance tests (currently 670/688)
./step1_vpu_rtl_validate.sh -c

# Check specific failures
grep "FAIL:" results/rtl/test_results.log
```

---

## Configuration

- VLEN=256, DLEN=256, NLANES=4
- Pre-generated `hp_vpu_pkg.sv` in `generated/` directory
- Tarball: `vpu_fpga_0.2j.tar.gz`

---

## Version Info

- **Release**: vpu_fpga_0.2j
- **Date**: 2026-02-04
- **Base tests**: 127/127 ✓
- **Compliance**: 670/688 (97.4%)
