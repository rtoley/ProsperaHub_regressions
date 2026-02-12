# Session Lessons Learned - VPU Development

## Date: 2026-01-31
## Context: v1.7 VRF Contention Fix + Stress Testing

This document captures issues encountered during development that reduced productivity and caused debugging delays.

---

## Issue 1: Changing Target FPGA Without Permission

**What happened:**
When asked to create a synthesis tarball, the FPGA target was changed from `xc7a100t` to `xc7a35t` (Arty7) without consulting the user. This caused confusion when utilization jumped from 29% to 89% - same absolute LUT count, but different FPGA size.

**Impact:**
- Wasted time debugging a non-existent RTL issue
- User had to re-verify baseline to understand the discrepancy

**Rule:**
**NEVER change FPGA target, VLEN, DLEN, or feature enables without explicit user approval.** If a smaller config is suggested for debugging, ask first.

---

## Issue 2: Combinational Logic Crossing Module Boundaries

**What happened:**
The drain logic fix added a combinational output:
```systemverilog
// This caused Vivado OOM during "Cross Boundary and Area Optimization"
assign drain_stall_o = waiting_for_drain;
```

Vivado 2025.2 crashed (OOM/Killed) when optimizing this combinational path crossing from `hp_vpu_lanes` to `hp_vpu_top`.

**Solution:**
Register signals that cross module boundaries:
```systemverilog
logic drain_stall_r;
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    drain_stall_r <= 1'b0;
  else
    drain_stall_r <= waiting_for_drain;
end
assign drain_stall_o = drain_stall_r;
```

**Rule:**
**Always register outputs that cross module boundaries**, especially new stall/control signals. Combinational cross-module paths can cause Vivado optimization issues.

---

## Issue 3: Not Running Step1 Before Delivery

**What happened:**
Tarballs were delivered without verifying step1 passes on BOTH configurations:
- 256/256 (full config, ENABLE_VMADD=1) → expect 114/114 or 109/109
- 64/64 (Arty7 config, ENABLE_VMADD=0) → expect 112/112 or 107/107

This led to compilation errors being discovered by the user instead of caught during development.

**Rule:**
**Before creating ANY tarball, run step1 simulation on BOTH configs:**
```bash
# Test 256/256
cp config/vpu_config_256.json config/vpu_config.json
python3 scripts/gen_pkg.py
iverilog -g2012 -DSIMULATION -I generated -o sim/test.vvp \
  generated/hp_vpu_pkg.sv rtl/*.sv tb/hp_vpu_tb.sv
vvp sim/test.vvp | grep "Test Results"

# Test 64/64
cp config/vpu_config_arty7.json config/vpu_config.json
python3 scripts/gen_pkg.py
iverilog -g2012 -DSIMULATION -I generated -o sim/test.vvp \
  generated/hp_vpu_pkg.sv rtl/*.sv tb/hp_vpu_tb.sv
vvp sim/test.vvp | grep "Test Results"
```

---

## Issue 4: Large Simulation Dumps Causing Session Compaction

**What happened:**
Running simulations with verbose debug output or VCD dumps creates large log files. When these accumulate in the context, they cause:
- Session compaction (Claude loses work/context)
- Connection drops
- Slower responses

**Rule:**
- **Pipe simulation output through `grep` or `tail`** to capture only relevant results
- **Never enable VCD dump** (`ENABLE_VCD_DUMP=0`) unless specifically debugging waveforms
- **Use `timeout`** on simulation runs to prevent runaway processes
- **Clean up** large files after verification

**Good pattern:**
```bash
timeout 120 vvp sim/test.vvp 2>&1 | grep -E "Test Results|PASS|FAIL|error"
```

**Bad pattern:**
```bash
vvp sim/test.vvp  # Full output floods context
```

---

## Issue 5: Inconsistent Directory Naming in Tarballs

**What happened:**
When version was bumped from v1.6d to v1.7, tarballs were created with inconsistent directory names:
- Some had `hyperplane_vpu_v1.6d/`
- Some had `hyperplane_vpu_v1.7/`
- Config files inside didn't always match the directory name

**Rule:**
When changing versions:
1. **Rename the directory FIRST**: `mv hyperplane_vpu_v1.6d hyperplane_vpu_v1.7`
2. **Update ALL config files**: `sed -i 's/"version": "1.6d"/"version": "1.7"/g' config/*.json`
3. **Regenerate package**: `python3 scripts/gen_pkg.py`
4. **Verify tarball structure**: `tar -tzf output.tar.gz | head -5`
5. **Verify config inside tarball**: `tar -xzf output.tar.gz -O hyperplane_vpu_v1.7/config/vpu_config.json | grep version`

---

## Pre-Delivery Checklist

Before creating any tarball for the user:

- [ ] Directory name matches version
- [ ] All config/*.json files have correct version
- [ ] generated/hp_vpu_pkg.sv has correct version
- [ ] Step1 passes on 256/256 config
- [ ] Step1 passes on 64/64 config
- [ ] step1_vpu_rtl_validate.sh has `-DSIMULATION` flag
- [ ] step2_vpu_synthesis.sh uses `hp_vpu_lut_rom_bram.sv`
- [ ] Config set to user's preferred synthesis target (ask if unsure)
- [ ] No combinational outputs crossing module boundaries (register them)
- [ ] Tarball verified: `tar -tzf file.tar.gz | head -10`

---

## Quick Reference: Expected Test Counts

| Config | ENABLE_VMADD | Expected Tests |
|--------|--------------|----------------|
| 256/256 | 1 | 114/114 (with stress) or 109/109 (without) |
| 64/64 | 0 | 112/112 (with stress) or 107/107 (without) |

The difference is 5 stress tests + 2 vmadd/vnmsub tests.

---

## Summary

Most issues stem from:
1. **Not verifying before delivery** - always test both configs
2. **Making assumptions** - ask before changing targets/configs
3. **Synthesis-unfriendly RTL** - register cross-module signals
4. **Context pollution** - filter large outputs

Following these rules will improve session productivity significantly.
