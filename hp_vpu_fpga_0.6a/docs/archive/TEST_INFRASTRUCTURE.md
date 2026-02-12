# VPU v0.3b Test Infrastructure

## Quick Start (Docker)

All tests run through the step1_vpu_rtl_validate.sh script in Docker:

```bash
# Quick smoke test (9 tests, <5 sec)
./step1_vpu_rtl_validate.sh --quick

# Full modular suite (946 tests, ~60 sec)
./step1_vpu_rtl_validate.sh --full

# Full suite at 256-bit
./step1_vpu_rtl_validate.sh --full --256

# Specific category
./step1_vpu_rtl_validate.sh --test alu

# Original compliance tests
./step1_vpu_rtl_validate.sh -c

# Base testbench only (default)
./step1_vpu_rtl_validate.sh
```

## Test Modes

| Mode | Command | Tests | Time |
|------|---------|-------|------|
| Quick | `--quick` | 9 | <5s |
| Full | `--full` | 946 | ~60s |
| ALU | `--test alu` | 438 | ~30s |
| MUL | `--test mul` | 60 | ~5s |
| MAC | `--test mac` | 36 | ~3s |
| SAT | `--test sat` | 60 | ~5s |
| CMP | `--test cmp` | 192 | ~15s |
| RED | `--test red` | 120 | ~10s |
| LUT | `--test lut` | 40 | ~5s |
| Compliance | `-c` | 1273 | ~90s |
| Base | (default) | ~150 | ~30s |

## Configuration Options

```bash
# 64-bit (default)
./step1_vpu_rtl_validate.sh --full --64

# 256-bit
./step1_vpu_rtl_validate.sh --full --256
```

## Other Options

| Option | Description |
|--------|-------------|
| `-z, --hazard` | Run only hazard pattern tests |
| `-s, --seed N` | Set random seed (default: 99999) |
| `-l, --long` | Enable 10K instruction stress test |
| `-h, --help` | Show help |

## Test Results

Results are saved to `results/rtl/test_results_<VLEN>.log`

### Expected Results

| Mode | Tests | Expected |
|------|-------|----------|
| --quick | 9 | 9/9 (100%) |
| --full | 946 | 943/946 (99.7%) |
| --test alu | 438 | 438/438 (100%) |
| -c | 1273 | varies |

### Known Failures (3)

The `--full` mode has 3 known failures in LUT tests:
- `test_vrecip_v_sew8_000/001` - zero output is valid
- `test_vrsqrt_v_sew8_000` - zero output is valid

See `docs/KNOWN_FAILURES.md` for details.

## File Structure

```
vpu_fpga_0.3b/
├── step1_vpu_rtl_validate.sh   # Main test entry point
├── config/
│   ├── vpu_config.json         # 64-bit config
│   └── vpu_config_256.json     # 256-bit config
├── generated/tests/
│   ├── tests_modular.sv        # Master include
│   ├── tests_alu_vv.sv         # ALU .vv tests
│   ├── tests_alu_vx.sv         # ALU .vx tests
│   ├── tests_alu_vi.sv         # ALU .vi tests
│   ├── tests_mul.sv            # MUL tests
│   ├── tests_mac.sv            # MAC tests
│   ├── tests_sat.sv            # SAT tests
│   ├── tests_cmp.sv            # CMP tests
│   ├── tests_red.sv            # RED tests
│   ├── tests_lut.sv            # LUT tests
│   └── tests_known_fail.sv     # Known failures
├── results/rtl/
│   ├── test_results_64.log
│   └── test_results_256.log
└── docs/
    ├── TEST_INFRASTRUCTURE.md
    └── KNOWN_FAILURES.md
```

## Common Workflows

### Daily Development
```bash
# Quick check after RTL change
./step1_vpu_rtl_validate.sh --quick
```

### Before Commit
```bash
# Full tests at both configs
./step1_vpu_rtl_validate.sh --full --64
./step1_vpu_rtl_validate.sh --full --256
```

### Debugging Specific Category
```bash
# Run just that category
./step1_vpu_rtl_validate.sh --test mul

# Check log
cat results/rtl/test_results_64.log | grep FAIL
```

### Full Validation
```bash
# Everything
./step1_vpu_rtl_validate.sh --full -c -l --64
./step1_vpu_rtl_validate.sh --full -c -l --256
```

## Regenerating Tests

```bash
# Regenerate modular tests
python3 scripts/gen_modular_tests.py

# Regenerate package
python3 scripts/gen_pkg.py config/vpu_config.json
python3 scripts/gen_pkg.py config/vpu_config_256.json
```

## Test Coverage

| Operation | .vv | .vx | .vi | Status |
|-----------|-----|-----|-----|--------|
| vadd/vsub | ✓   | ✓   | ✓   | 100% |
| vand/vor/vxor | ✓ | ✓ | ✓ | 100% |
| vsll/vsrl/vsra | ✓ | ✓ | ✓ | 100% |
| vmin/vmax | ✓   | ✓   | -   | 100% |
| vmul/vmulh | ✓  | -   | -   | 100% |
| vmacc/vnmsac | ✓ | - | -   | 100% |
| vmadd/vnmsub | ✓ | - | -   | 100% |
| vsadd/vssub | ✓ | -   | -   | 100% |
| vmseq/vmslt etc | ✓ | - | - | 100% |
| vredsum etc | ✓ | -   | -   | 100% |
| vexp/vrecip etc | ✓ | - | - | 92.5% |
