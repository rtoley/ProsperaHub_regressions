# VPU FPGA v0.2g Handoff Document

## Session Summary (2026-02-03)

Fixed critical back-to-back vmacc RAW hazard bug. Full verification completed.

---

## What Was Fixed

### Bug: Back-to-back vmacc loses operations
**Symptom**: 6× `vmacc v16, v1, v2` produced `v16=6` instead of expected `v16=12`

**Root Cause**: RAW hazard detection at D2 stage worked, but instructions piled up in IQ before hazard was detected. By the time `stall_iq` triggered, multiple vmacc instructions were already queued with stale accumulator values.

**Fix**: Added MAC destination tracking at issue level in `hp_vpu_top.sv`:
```systemverilog
logic [31:0] mac_vd_in_flight;  // Bitmap for v0-v31
wire mac_conflict = issue_is_mac && mac_vd_in_flight[issue_vd];
assign x_issue_ready_o = ... && !mac_conflict;

always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) mac_vd_in_flight <= '0;
  else begin
    if (wb_we) mac_vd_in_flight[wb_vd] <= 1'b0;           // Clear on writeback
    if (iq_push && issue_is_mac) mac_vd_in_flight[issue_vd] <= 1'b1;  // Set on issue
  end
end
```

**No combinational loops** - `mac_vd_in_flight` is registered.

---

## Verification Results

### VLEN=64/DLEN=64 (Arty-7 target) - ALL PASS ✓
| Test Suite | Result |
|------------|--------|
| RTL tests | 125/125 |
| Compliance tests | 339/339 |
| **Total** | **464/464** |
| FPGA VPU test top | 10/10 |
| FPGA LLM test top | PASS |
| vmacc chain test | PASS (v16=0x0C) |

### VLEN=256/DLEN=256 (4-lane) - 4 FAILURES (testbench issues)
| Test Suite | Result |
|------------|--------|
| RTL tests | 121/125 |
| Compliance tests | 339/339 |
| **Total** | **460/464** |
| FPGA VPU test top | 10/10 |
| FPGA LLM test top | PASS |

Note: 4 failures are testbench expectation issues (hardcoded for DLEN=64), not RTL bugs.

---

## Outstanding Failures (VLEN=256/DLEN=256)

### E1 Handoff Tests - 4 Failures
```
[57377000] FAIL: E1 handoff duplicate test - 1 errors
[57595000] FAIL: E1 handoff stress test - 8 errors
[65587000] FAIL: E1 handoff duplicate test - 1 errors
[65805000] FAIL: E1 handoff stress test - 8 errors
```

### NOT RTL BUGS - Testbench Expectation Issues

**Root cause**: Testbench has hardcoded expected values for DLEN=64.

Example:
```
vid.v actual:   0x1f1e1d1c1b1a19...0706050403020100  (32 bytes, correct for DLEN=256)
vid.v expected: 0x00000000000000...0706050403020100  (hardcoded for DLEN=64)
```

The RTL correctly produces 32 sequential indices (0x00-0x1F) for DLEN=256, but the test expects only 8 indices (0x00-0x07) zero-padded.

**Fix needed**: Update testbench to use DLEN-aware expected values:
```systemverilog
// Instead of:
expected = 64'h0706050403020100;
// Use something like:
expected = generate_vid_expected(DLEN);  // Parameterized for DLEN
```

**Low priority** - only affects testing larger configs, RTL is correct.

---

## Files Modified This Session

| File | Change |
|------|--------|
| `rtl/hp_vpu_top.sv` | Added `mac_vd_in_flight` tracking (lines ~145-155, ~515-530) |
| `rtl/hp_vpu_lanes.sv` | Removed dead code: `vmacc_raw_hazard`, `e3_is_mac` |
| `tb/hp_vpu_tb.sv` | Added `test_vmacc_chain()` (from previous session) |
| `CHANGELOG.md` | Added v2.1d entry |
| `config/vpu_config.json` | Version bump 1.9 → 2.1d |

## Files NOT Modified

- All LUT ROM files (`hp_vpu_lut_rom*.sv`)
- `hp_vpu_decode.sv`
- `hp_vpu_hazard.sv`
- `hp_vpu_iq.sv`
- `hp_vpu_vrf.sv`
- All step1/step2/step3 scripts
- `generated/lut_tables.mem`

---

## Docker Verification Pending

The following should be verified in your docker environment:
1. `./step1_vpu_rtl_validate.sh` - RTL simulation
2. `./step1_vpu_rtl_validate.sh -c` - With compliance tests
3. `./step2_vpu_yosys_synth.sh` - Synthesis (uses BRAM LUT)
4. Vivado synthesis on Arty A7-100T

---

## Next Session Priorities

1. **Vivado synthesis and FPGA testing**
   - Run on actual Arty A7-100T hardware to verify vmacc fix works in silicon
   - The LLM test (`fpga_vpu_llm_test_top.sv`) specifically exercises back-to-back vmacc

2. **Fix testbench for DLEN>64** (low priority)
   - E1 handoff tests have hardcoded expected values for DLEN=64
   - RTL is correct; only testbench needs DLEN-parameterized expectations
   - Not blocking - only affects testing larger configs

3. **Consider forwarding optimization** (future)
   - Current fix serializes all MACs to same vd (~22 cycles between each)
   - Forwarding from E3/WB could reduce this penalty
   - Not urgent - correctness first, performance later

---

## Quick Test Commands

```bash
# Default config (VLEN=64/DLEN=64)
cd vpu_fpga_0.2g
python3 scripts/gen_pkg.py
iverilog -g2012 -DSIMULATION -I generated -o sim/test.vvp \
  generated/hp_vpu_pkg.sv rtl/*.sv tb/hp_vpu_tb.sv
vvp sim/test.vvp

# With compliance tests
iverilog -g2012 -DSIMULATION -DCOMPLIANCE_TESTS -I generated -o sim/test.vvp \
  generated/hp_vpu_pkg.sv rtl/*.sv tb/hp_vpu_tb.sv
vvp sim/test.vvp

# FPGA tests
iverilog -g2012 -DSIMULATION -I generated -o sim/fpga.vvp \
  generated/hp_vpu_pkg.sv rtl/*.sv fpga/fpga_vpu_test_top.sv tb/fpga_vpu_test_tb.sv
vvp sim/fpga.vvp

iverilog -g2012 -DSIMULATION -I generated -o sim/llm.vvp \
  generated/hp_vpu_pkg.sv rtl/*.sv fpga/fpga_vpu_llm_test_top.sv tb/fpga_vpu_llm_test_tb.sv
vvp sim/llm.vvp
```

---

## Version Info

- **Release**: vpu_fpga_0.2g
- **Config version**: 2.1d
- **Date**: 2026-02-03
- **Tarball**: `vpu_fpga_0.2g.tar.gz`
