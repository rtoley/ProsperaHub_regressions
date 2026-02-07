# VPU v0.3 Test Coverage Report

**Date**: 2026-02-04
**Test Result**: 702/702 (100% pass)
**Config**: VLEN=64, DLEN=64, NLANES=1

---

## 1. Coverage Summary

| Category | Ops Implemented | Ops Tested | Tests | Coverage |
|----------|-----------------|------------|-------|----------|
| Integer ALU | 14 | 13 | 273 | 93% |
| Integer MUL | 4 | 4 | 84 | 100% |
| Integer MAC | 4 | 2 | 42 | 50% |
| Saturating | 8 | 4 | 84 | 50% |
| Widening ALU | 4 | 4 | 52 | 100% |
| Widening MUL | 3 | 3 | 39 | 100% |
| Widening MAC | 3 | 3 | 39 | 100% |
| Reductions | 8 | 8 | 72 | 100% |
| Custom LUT | 4 | 4 | 40 | 100% |
| **TOTAL** | **52** | **45** | **575+127** | **87%** |

Base testbench adds 127 additional functional tests.

---

## 2. Detailed Operation Coverage

### FULL Coverage (Compliance + Multi-SEW + Edge Cases)

| Op | SEW-8 | SEW-16 | SEW-32 | Tests | Quality |
|----|-------|--------|--------|-------|---------|
| vadd.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vsub.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vrsub.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vand.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vor.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vxor.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vsll.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vsrl.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vsra.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vmin.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vmax.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vminu.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vmaxu.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vmul.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vmulh.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vmulhu.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vmulhsu.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vmacc.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vnmsac.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vsaddu.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vsadd.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vssubu.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vssub.vv | ✓ | ✓ | ✓ | 21 | ★★★ |
| vwadd.vv | ✓ | ✓ | - | 13 | ★★★ |
| vwaddu.vv | ✓ | ✓ | - | 13 | ★★★ |
| vwsub.vv | ✓ | ✓ | - | 13 | ★★★ |
| vwsubu.vv | ✓ | ✓ | - | 13 | ★★★ |
| vwmul.vv | ✓ | ✓ | - | 13 | ★★★ |
| vwmulu.vv | ✓ | ✓ | - | 13 | ★★★ |
| vwmulsu.vv | ✓ | ✓ | - | 13 | ★★★ |
| vwmacc.vv | ✓ | ✓ | - | 13 | ★★★ |
| vwmaccu.vv | ✓ | ✓ | - | 13 | ★★★ |
| vwmaccsu.vv | ✓ | ✓ | - | 13 | ★★★ |
| vredsum.vs | ✓ | ✓ | ✓ | 9 | ★★★ |
| vredmax.vs | ✓ | ✓ | ✓ | 9 | ★★★ |
| vredmaxu.vs | ✓ | ✓ | ✓ | 9 | ★★★ |
| vredmin.vs | ✓ | ✓ | ✓ | 9 | ★★★ |
| vredminu.vs | ✓ | ✓ | ✓ | 9 | ★★★ |
| vredand.vs | ✓ | ✓ | ✓ | 9 | ★★★ |
| vredor.vs | ✓ | ✓ | ✓ | 9 | ★★★ |
| vredxor.vs | ✓ | ✓ | ✓ | 9 | ★★★ |

### Custom LUT Operations

| Op | SEW-8 | SEW-16 | Tests | Quality |
|----|-------|--------|-------|---------|
| vexp.v | ✓ | ✓ | 10 | ★★☆ |
| vrecip.v | ✓ | ✓ | 8 | ★★☆ |
| vrsqrt.v | ✓ | ✓ | 9 | ★★☆ |
| vgelu.v | ✓ | ✓ | 12 | ★★★ |

### INT4 Pack/Unpack

| Op | Tests | Quality |
|----|-------|---------|
| vpack4 | 2 | ★★☆ |
| vunpack4 | 2 | ★★☆ |

---

## 3. PARTIAL Coverage (Base Tests Only)

These ops have functional tests but lack multi-SEW compliance coverage:

| Op | Base Test | Gap |
|----|-----------|-----|
| vmadd.vv | ✓ | Need compliance suite |
| vnmsub.vv | ✓ | Need compliance suite |
| vssrl.vv | ✓ | Need compliance suite |
| vssra.vv | ✓ | Need compliance suite |
| vnclip.wv | ✓ | Need compliance suite |
| vnclipu.wv | ✓ | Need compliance suite |
| vnsrl.wv | ✓ | Need compliance suite |
| vnsra.wv | ✓ | Need compliance suite |

---

## 4. NOT TESTED (Implemented but no compliance tests)

| Category | Operations |
|----------|------------|
| Compare | vmseq, vmsne, vmslt, vmsle, vmsgt (all variants) |
| Mask Logic | vmand, vmnand, vmandn, vmor, vmnor, vmorn, vmxor, vmxnor |
| Mask Special | vcpop, vfirst, vmsbf, vmsif, vmsof, vid |
| Permutation | vrgather, vslideup, vslidedown, vslide1up, vslide1down |
| Move | vmv.v.v, vmv.v.x, vmv.v.i, vmerge |

---

## 5. NOT IMPLEMENTED (By Design)

| Operation | Reason |
|-----------|--------|
| vdiv[u], vrem[u] | High area, rarely used in inference |
| viota.m | Complex prefix-sum |
| vcompress | Complex permutation |
| vwadd.wv, vwsub.wv | Less common variant |
| vwredsum[u] | Widening reductions |
| All FP ops | INT8 quantized inference only |

---

## 6. Test Quality Ratings

- ★★★ **Excellent**: Multi-SEW, signed/unsigned, edge cases, overflow
- ★★☆ **Good**: Multi-SEW, basic functional verification
- ★☆☆ **Basic**: Single SEW, smoke test only
- ☆☆☆ **None**: No dedicated test

---

## 7. Hazard/Stress Test Coverage

| Test Category | Count | Status |
|---------------|-------|--------|
| WAW Hazard | 5 | ✓ Pass |
| RAW Hazard | 8 | ✓ Pass |
| MAC Pipeline | 4 | ✓ Pass |
| E1/E3 Contention | 3 | ✓ Pass |
| Mixed Pipeline | 5 | ✓ Pass |
| Throughput Stress | 2 | ✓ Pass |

---

## 8. Recommendations for v0.4

### Priority 1: Add Compliance Tests
1. **vnclip/vnclipu** - Critical for output requantization
2. **vnsrl/vnsra** - Used in narrowing pipelines
3. **Compare ops** - Used in attention masking

### Priority 2: Expand LUT Testing
1. More input values for vexp/vrecip/vrsqrt
2. Boundary conditions (0, max, overflow)

### Priority 3: Format Variants
1. .vx variants (scalar operand)
2. .vi variants (immediate operand)

---

## 9. Files

```
Test Infrastructure:
├── tb/hp_vpu_tb.sv              # 127 base tests
├── generated/compliance_tests.sv # 575 compliance tests
└── scripts/gen_compliance_tests_v3.py

Results:
└── results/rtl/test_results.log  # 702/702 passed
```
