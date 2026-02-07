# VPU Compliance Test Analysis - Next Session Fix List

## Test Results Summary
- **Total Tests**: 688 (125 baseline + 561 compliance + 2 stress)
- **Passing**: 632 (91.9%)
- **Failing**: 56

## Failure Categories

### Category 1: RTL BUG - Reduction vs1[0] Ignored (30 tests)
**Status**: RTL BUG - Fix Required

**Affected Operations**: vredand.vs, vredor.vs, vredxor.vs

**Root Cause**: In `rtl/hp_vpu_lanes.sv` lines 502-504, 525-527, 548-550
The bitwise reduction ops don't include vs1[0] in the final result.

**Current (buggy)**:
```verilog
OP_VREDAND:  r3_final8 = r2_part8[0] & r2_part8[1];
OP_VREDOR:   r3_final8 = r2_part8[0] | r2_part8[1];
OP_VREDXOR:  r3_final8 = r2_part8[0] ^ r2_part8[1];
```

**Fix Required**:
```verilog
OP_VREDAND:  r3_final8 = r2_part8[0] & r2_part8[1] & r2_vs1[7:0];
OP_VREDOR:   r3_final8 = r2_part8[0] | r2_part8[1] | r2_vs1[7:0];
OP_VREDXOR:  r3_final8 = r2_part8[0] ^ r2_part8[1] ^ r2_vs1[7:0];
```
Same fix needed for SEW=16 and SEW=32 variants.

---

### Category 2: RTL BUG - vredsum SEW=32 Wrong Count (4 tests)
**Status**: RTL BUG - Investigation Required

**Symptoms**:
- test_vredsum_vs_sew32_010: expected 8, got 4 (exactly half)
- test_vredsum_vs_sew32_011: expected 0x0008ffff, got 0x0004ffff (half)

**Analysis**: For VLEN=256, SEW=32, VLMAX=8 elements. The sum of 8 ones should be 8, but hardware returns 4.

**Likely Cause**: Either:
1. VL is being set to 4 instead of 8 for SEW=32
2. The reduction tree for SEW=32 is only summing half the elements
3. A bug in how the R-stage handles SEW=32 reductions

**Investigation Needed**: Check `hp_vpu_lanes.sv` reduction pipeline for SEW=32 path.

---

### Category 3: TEST BUG - Widening SEW=16 Incorrect Results (18 tests)
**Status**: TEST GENERATION BUG - Fix Required

**Affected Operations**: vwadd.vv, vwaddu.vv, vwmacc.vv, vwmaccu.vv, vwmul.vv, vwmulu.vv (SEW=16 variants only)

**Symptoms**:
- test_vwadd_vv_sew16_006: expected 0x0000fffe, got 0x00fefffe
- test_vwadd_vv_sew16_007: expected 0xffff0000, got 0xff000000
- test_vwaddu_vv_sew16_007: expected 0x00010000, got 0x01000000

**Analysis**: The 32-bit results have incorrect upper halves. The pattern suggests either:
1. VL is wrong for SEW=16→32 widening (should be 8 for VLEN=256)
2. The golden model computes wrong values
3. The replicate_32() function in check_vrf is misaligned

**Fix Needed**: Check test generator's VL calculation for SEW=16 widening:
```python
# Current: vl_for_widening = 256 // (2 * sew)
# For SEW=16: vl = 256 // 32 = 8 ✓
```

The VL looks correct. The issue might be in how the expected value is computed or how replicate_32() works.

**Investigation**: Compare built-in SEW=16 widening tests with generated ones.

---

### Category 4: Pre-existing - E1 Handoff (4 tests)
**Status**: Known Pre-existing Issue

Already documented in `docs/BUG_E1_HANDOFF_DUPLICATE.md`. Not related to compliance test work.

---

## Test Bugs Fixed This Session

### Fixed: vwadd/vwaddu/vwsub/vwsubu Encoding (TEST BUG)
**Problem**: OPMVV_OPS incorrectly included vwadd, vwaddu, vwsub, vwsubu
**Impact**: These ops were encoded with funct3=010 (OPMVV) instead of funct3=000 (OPIVV)
**Fix**: Removed these ops from OPMVV_OPS list
**Result**: 26 widening add/sub tests now pass

### Fixed: Widening VL Overflow (TEST BUG)
**Problem**: Widening tests inherited VL=VLMAX_8 from previous tests
**Impact**: VL=32 for SEW=8 widening caused 512-bit output (exceeds DLEN=256)
**Fix**: Added set_vtype() for widening ops with VL=VLEN/(2*SEW)
**Result**: Widening SEW=8 tests now work correctly

---

## Files Modified This Session

1. `scripts/gen_compliance_tests.py`:
   - Fixed OPMVV_OPS list (removed vwadd/vwaddu/vwsub/vwsubu)
   - Added set_vtype() for widening operations with correct VL
   - Spec-compliant golden model for all operations

2. `tb/hp_vpu_tb.sv`:
   - Added check_vrf_elem0_sew() for SEW-aware reduction checks
   - Added replicate_64() for widening verification

3. `tests/toml/*.toml`:
   - Added 14 new TOML test vector files for reduction/widening ops

4. `docs/`:
   - BUG_REDUCTION_VS1_IGNORED.md
   - SESSION_SUMMARY_COMPLIANCE_STRESS.md
   - NEXT_SESSION_RTL_FIX.md

---

## Next Session Priority List

### Priority 1: Fix RTL Reduction vs1[0] Bug
1. Edit `rtl/hp_vpu_lanes.sv`
2. Add vs1[0] to vredand/vredor/vredxor for all SEW variants
3. Run tests, expect 30 tests to change from FAIL to PASS

### Priority 2: Investigate vredsum SEW=32 Bug
1. Add debug prints to reduction pipeline for SEW=32
2. Verify VLMAX is correctly computed
3. Check R-stage accumulation logic

### Priority 3: Fix Widening SEW=16 Test Bug
1. Compare generated tests vs built-in tests for SEW=16 widening
2. Check replicate_32() function behavior
3. Verify golden model computation for 32-bit results

### Priority 4: Generate 100K+ Stress Tests
Once compliance tests pass, generate large stress test suite:
```bash
python3 scripts/gen_compliance_tests.py tests/toml generated/stress_tests.sv --stress 10000 --num 10
```

---

## Test Commands

```bash
# Run all tests with compliance
cd /home/claude/vpu_fpga_0.2g
./step1_vpu_rtl_validate.sh -c

# Expected after RTL fixes: 678+/688 passed (98%+)
```

## Backup Location
`/mnt/user-data/outputs/vpu_fpga_backup_20260203.tar.gz`
