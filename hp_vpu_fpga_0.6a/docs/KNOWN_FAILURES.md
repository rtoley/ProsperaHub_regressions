# VPU v0.4b - Known Test Failures

## Summary

**All known test failures from v0.3d have been resolved in v0.4b.**

| Category | Tests | Pass | Fail | Notes |
|----------|-------|------|------|-------|
| ALU .vv  | 234   | 234  | 0    | ✓ All pass |
| ALU .vx  | 108   | 108  | 0    | ✓ All pass |
| ALU .vi  | 96    | 96   | 0    | ✓ All pass |
| MUL      | 60    | 60   | 0    | ✓ All pass |
| MAC      | 36    | 36   | 0    | ✓ All pass |
| SAT      | 60    | 60   | 0    | ✓ All pass |
| CMP      | 192   | 192  | 0    | ✓ All pass |
| RED      | 120   | 120  | 0    | ✓ All pass |
| LUT      | 40    | 40   | 0    | ✓ Fixed in v0.4b |
| MASK     | 56    | 56   | 0    | ✓ Fixed in v0.4b |
| MASKOP   | 43    | 43   | 0    | ✓ All pass |
| PERM     | 54    | 54   | 0    | ✓ All pass |
| WIDE     | 82    | 82   | 0    | ✓ All pass |
| FIXPT    | 30    | 30   | 0    | ✓ All pass |
| INT4     | 16    | 16   | 0    | ✓ All pass |
| Base TB  | 131   | 131  | 0    | ✓ Fixed in v0.4b |
| Hazard   | 24    | 24   | 0    | ✓ Fixed in v0.4b |
| CSR      | 18    | 18   | 0    | ✓ Enabled in v0.4a |
| **Modular Total** | **1356** | **1356** | **0** | **100%** |

---

## Fixes Applied in v0.4b

### vmnand.mm / vmorn.mm (2 tests, both TBs)
**Was**: Test expected 256-bit repeated pattern (`0x0F0F...`) across full register.
**Fix**: Made VLEN-aware. Mask logical ops only write VL bits; tail is zero. Expected pattern now computed dynamically for active mask bits only.

### vrecip/vrsqrt SEW=8 (3 tests)
**Was**: `check_vrf_nonzero()` rejected legitimate zero outputs.
**Fix**: Replaced with `check_vrf()` comparing against known golden value (0x00). These LUT entries have 16-bit values with 0x00 in the lower byte (e.g., recip_table[1]=0x8000).

### Hazard testbench (compile failure)
**Was**: iverilog 12 cannot handle `integer` bit-selects (`f[4:0]`) in initial-block for loops.
**Fix**: Rewrote in Verilog-2001 style. Flattened nested loops into per-group tasks. Added missing CSR port connections for ENABLE_CSR=1.

---

## Not Yet in Suite

### Narrowing Clip Tests (vnclip, vnclipu)
These were excluded in v0.3a due to expected-value computation not matching RVV spec saturation rules. The RTL passes base-TB narrowing tests. Generating modular golden vectors for all SEW/rounding-mode combinations is deferred to Session 3+.
