# Next Session - Hyperplane VPU v1.8

## Current Status: v1.8 STABLE - Compliance Tests PASSING

### What's Working (DO NOT MODIFY without re-testing BOTH configs)
- **RTL**: All modules verified, synthesis-ready
- **Step1 Baseline Tests**:
  - 256/256 config: 114/114 passing ✅
  - 64/64 config: 112/112 passing ✅
- **Step1 with Compliance Tests (-DCOMPLIANCE_TESTS)**:
  - 256/256 config: 453/453 passing ✅
  - 64/64 config: 451/451 passing ✅
- **Synthesis**: 29.76% LUT utilization on xc7a100t (64/64 config)
- **VRF Contention Fix**: drain logic working (registered `drain_stall_o`)
- **Stress Tests**: All 5 stress tests passing

### Key Files
```
rtl/hp_vpu_lanes.sv              - Main datapath with drain logic fix
rtl/hp_vpu_top.sv                - Top module with drain_stall integration
tb/hp_vpu_tb.sv                  - Testbench with stress tests + compliance framework
scripts/gen_compliance_tests.py  - Industry-standard test generator (RVV 1.0 encodings)
generated/compliance_tests.sv    - Auto-generated compliance tests (339 tests)
step1_vpu_rtl_validate.sh        - Has -DSIMULATION flag + throughput test options
step2_vpu_synthesis.sh           - Uses hp_vpu_lut_rom_bram.sv
```

---

## Throughput Test (v1.8 Feature)

### Running Throughput Tests via step1

```bash
# Run throughput-only test with N instructions:
./step1_vpu_rtl_validate.sh -t 1000

# With specific seed:
./step1_vpu_rtl_validate.sh -t 5000 -s 12345

# With verbose output (shows each instruction):
./step1_vpu_rtl_validate.sh -t 500 -v

# Run all tests (default behavior):
./step1_vpu_rtl_validate.sh

# Run with compliance tests:
./step1_vpu_rtl_validate.sh -c

# Run with long stress test (10K instr):
./step1_vpu_rtl_validate.sh -l
```

### Debug Dump on Failure

When a throughput test fails, it automatically dumps:
1. **All instructions that wrote to the failing register**
2. **~100 instruction window around the last write**
3. **Full operand data** for each instruction in the window

Example debug output:
```
=== DEBUG DUMP ===
First failing register: v7

=== Instructions writing to v7 ===
[  12] vmacc.vv v7, v15, v3  instr=b67882d7
       vs1_data[7:0]=f3  vs2_data[7:0]=e7  old_vd[7:0]=f3  expected[7:0]=68

=== Instruction window around last write to v7 (instr 95) ===
    Window: [45 : 100]

[  45] vadd.vv    v12, v8, v15  exp[7:0]=ae            v7
[  46] vsub.vv    v19, v3, v21  exp[7:0]=11            v7
[  47] vmul.vv >>>v7,  v22, v8   exp[7:0]=70 <-- WRITES v7
...
```

---

## v1.8 Changes (from v1.7)

### Compliance Test Framework - COMPLETE
1. **Industry-standard instruction encodings**: All tests use real 32-bit RVV instruction words
2. **Proper vsetvli configuration**: Tests issue `vsetvli` instructions (not backdoor CSR writes)
3. **DLEN-parameterized**: Works on both 64-bit and 256-bit configurations
4. **339 compliance tests** from riscv-vector-tests TOML files

### Bug Fixed
- **SEW configuration issue**: After `test_vsetvli()` runs, VPU uses internal vtype register.
  Compliance tests now issue real `vsetvli` instructions instead of relying on `set_vtype()`.

---

## Running Tests

### Baseline (default)
```bash
# Uses step1_vpu_rtl_validate.sh or manually:
iverilog -g2012 -DSIMULATION -I generated -o sim/test.vvp \
  generated/hp_vpu_pkg.sv rtl/hp_vpu_top.sv rtl/hp_vpu_lanes.sv \
  rtl/hp_vpu_decode.sv rtl/hp_vpu_hazard.sv rtl/hp_vpu_iq.sv \
  rtl/hp_vpu_vrf.sv rtl/hp_vpu_lut_rom.sv tb/hp_vpu_tb.sv
vvp sim/test.vvp
# Expected: 114/114 (256/256) or 112/112 (64/64)
```

### With Compliance Tests
```bash
iverilog -g2012 -DSIMULATION -DCOMPLIANCE_TESTS -I generated -o sim/test.vvp \
  generated/hp_vpu_pkg.sv rtl/hp_vpu_top.sv rtl/hp_vpu_lanes.sv \
  rtl/hp_vpu_decode.sv rtl/hp_vpu_hazard.sv rtl/hp_vpu_iq.sv \
  rtl/hp_vpu_vrf.sv rtl/hp_vpu_lut_rom.sv tb/hp_vpu_tb.sv
vvp sim/test.vvp
# Expected: 453/453 (256/256) or 451/451 (64/64)
```

### Regenerate Compliance Tests
```bash
python3 scripts/gen_compliance_tests.py tests/toml generated/compliance_tests.sv
```

---

## Pre-Delivery Checklist

Before ANY tarball delivery:
- [x] Step1 passes on 256/256 config (114/114)
- [x] Step1 passes on 64/64 config (112/112)
- [x] Directory name matches version (hyperplane_vpu_v1.8/)
- [x] Config files have correct version
- [x] step1_vpu_rtl_validate.sh has `-DSIMULATION` flag
- [x] step2_vpu_synthesis.sh uses `hp_vpu_lut_rom_bram.sv`
- [ ] Tarball verified: `tar -tzf file.tar.gz | head -5`

---

## TOML Files Available (tests/toml/)
- vadd.vv/.vx/.vi, vsub.vv/.vx
- vand.vv/.vx, vor.vv/.vx, vxor.vv/.vx
- vsll.vv/.vx, vsra.vv/.vx
- vmul.vv/.vx, vmacc.vv/.vx

## Future TOML Files to Download
- vsrl.vv/.vx (missing from current set)
- Compare: vmseq, vmsne, vmslt, vmsltu, vmsle, vmsleu, vmsgt, vmsgtu
- Reductions: vredsum, vredmax, vredmin, vredand, vredor, vredxor
- Widening: vwaddu, vwadd, vwsubu, vwsub, vwmulu, vwmul
- Narrowing: vnsrl, vnsra

---

## Session Lessons Learned

See `docs/SESSION_LESSONS_LEARNED.md` for:
1. Don't change FPGA target without permission
2. Register signals crossing module boundaries
3. Always run step1 on BOTH configs before delivery
4. Filter large simulation output to avoid context pollution
5. Match directory names to versions
6. **NEW**: Use real vsetvli instructions in tests (not backdoor CSR writes)

## Pre-Delivery Checklist (ALWAYS DO THIS)

Before ANY tarball delivery:
- [ ] Step1 passes on 256/256 config (expect 114/114)
- [ ] Step1 passes on 64/64 config (expect 112/112)
- [ ] Directory name matches version (hyperplane_vpu_v1.8/)
- [ ] Config set to user's synthesis target (64/64, xc7a100t)
- [ ] step1_vpu_rtl_validate.sh has `-DSIMULATION` flag
- [ ] step2_vpu_synthesis.sh uses `hp_vpu_lut_rom_bram.sv`
- [ ] Tarball verified: `tar -tzf file.tar.gz | head -5`

---

## Session Lessons Learned

See `docs/SESSION_LESSONS_LEARNED.md` for:
1. Don't change FPGA target without permission
2. Register signals crossing module boundaries
3. Always run step1 on BOTH configs before delivery
4. Filter large simulation output to avoid context pollution
5. Match directory names to versions

---

## Quick Commands

```bash
# Test 256/256
cp config/vpu_config_256.json config/vpu_config.json
python3 scripts/gen_pkg.py
./step1_vpu_rtl_validate.sh  # or manual iverilog+vvp

# Test 64/64
cp config/vpu_config_arty7.json config/vpu_config.json
python3 scripts/gen_pkg.py
./step1_vpu_rtl_validate.sh

# Generate compliance tests (not yet integrated)
python3 scripts/gen_compliance_tests.py tests/toml generated/compliance_tests.sv
```

---

## Files Added This Session

```
docs/SESSION_LESSONS_LEARNED.md  - Productivity lessons
docs/NEXT_SESSION.md             - This file
tests/toml/*.toml                - riscv-vector-tests TOML files (19)
generated/compliance_tests.sv    - Generated tests (339, not integrated)
```
