# BUG: Reduction Operations Ignore vs1[0] Scalar

## Summary
The VPU's reduction operations (vredand, vredor, vredxor) do not use `vs1[0]` as the initial scalar accumulator as required by RVV 1.0 specification.

## RVV 1.0 Spec Behavior
According to the RISC-V Vector Extension 1.0 specification, reduction operations should compute:
```
vd[0] = vs1[0] op reduce(vs2[*])
```

For example:
- `vredsum.vs vd, vs2, vs1` → `vd[0] = vs1[0] + sum(vs2[i])`
- `vredand.vs vd, vs2, vs1` → `vd[0] = vs1[0] & and(vs2[i])`
- `vredor.vs vd, vs2, vs1` → `vd[0] = vs1[0] | or(vs2[i])`
- `vredxor.vs vd, vs2, vs1` → `vd[0] = vs1[0] ^ xor(vs2[i])`
- `vredmax.vs vd, vs2, vs1` → `vd[0] = max(vs1[0], max(vs2[i]))`

## Current VPU Behavior
Based on compliance test results:

| Operation | Uses vs1[0]? | Status |
|-----------|--------------|--------|
| vredsum.vs | Yes | ✓ Compliant |
| vredand.vs | **No** | ❌ Bug |
| vredor.vs | **No** | ❌ Bug |
| vredxor.vs | **No** | ❌ Bug |
| vredmax.vs | Yes | ✓ Compliant |
| vredmin.vs | Yes | ✓ Compliant |
| vredmaxu.vs | Yes | ✓ Compliant |
| vredminu.vs | Yes | ✓ Compliant |

## Evidence
From test logs:
```
# vredand test: vs2_elem=0xf0, vs1_scalar=0x0f
# Expected (spec): 0xf0 & 0x0f = 0x00
# Actual (VPU):    0xf0 (vs1[0] ignored)
FAIL: test_vredand_vs_sew8_002 - v3[0] = 0xf0 (expected 0x00)
```

## Root Cause
The reduction pipeline (R1→R2→R3 stages) in `hp_vpu_lanes.sv` likely does not properly incorporate `vs1[0]` into the final reduction result for AND/OR/XOR operations.

## Fix Location
File: `rtl/hp_vpu_lanes.sv`
- Look for the R3 (reduction writeback) stage
- Ensure vs1[0] is combined with the reduced result before writing to vd[0]

## Priority
Medium - This is a compliance issue that would cause failures in RVV compliance test suites.

## Workaround (Not Recommended)
Applications could work around by initializing vs1[0] to identity elements, but this masks the bug rather than fixing it.

## Action Required
**FIX THE RTL** - Do not modify the golden model to match buggy hardware behavior.

## ROOT CAUSE IDENTIFIED

In `rtl/hp_vpu_lanes.sv`, lines 502-504:

**Current (BUGGY):**
```verilog
OP_VREDAND:  r3_final8 = r2_part8[0] & r2_part8[1];
OP_VREDOR:   r3_final8 = r2_part8[0] | r2_part8[1];
OP_VREDXOR:  r3_final8 = r2_part8[0] ^ r2_part8[1];
```

**Fixed (add vs1[0]):**
```verilog
OP_VREDAND:  r3_final8 = r2_part8[0] & r2_part8[1] & r2_vs1[7:0];
OP_VREDOR:   r3_final8 = r2_part8[0] | r2_part8[1] | r2_vs1[7:0];
OP_VREDXOR:  r3_final8 = r2_part8[0] ^ r2_part8[1] ^ r2_vs1[7:0];
```

Same fix needed for SEW=16 and SEW=32 cases (search for similar patterns).

## Lines to Fix in hp_vpu_lanes.sv

1. SEW=8 (lines ~502-504): Add `& r2_vs1[7:0]`, `| r2_vs1[7:0]`, `^ r2_vs1[7:0]`
2. SEW=16 (lines ~525-527): Add `& r2_vs1[15:0]`, `| r2_vs1[15:0]`, `^ r2_vs1[15:0]`
3. SEW=32 (lines ~548-550): Add `& r2_vs1[31:0]`, `| r2_vs1[31:0]`, `^ r2_vs1[31:0]`
