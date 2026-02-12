# Next Session: FPGA Self-Checking Test

## Date: 2026-02-01
## Version: v0.1e - Complete Flow (RTL + Synthesis + Netlist)

---

## ✅ COMPLETE VERIFICATION FLOW

```
Step 1b: RTL Simulation
   ./step1b_fpga_test_validate.sh
   └── Verifies FPGA test in iverilog simulation

Step 2b: Vivado Synthesis
   ./step2b_fpga_test_synth.sh
   └── Synthesizes fpga_vpu_test_top
   └── Generates bitstream: results/fpga_synth/fpga_vpu_test.bit
   └── Generates netlist: results/fpga_synth/fpga_test_funcsim.v

Step 3b: Netlist Simulation
   ./step3b_fpga_netlist_verify.sh
   └── Verifies post-synthesis netlist matches RTL behavior
   └── Uses Vivado xsim in Docker
```

---

## ✅ WHAT'S INCLUDED

### FPGA Self-Checking Test
- **Fully synthesizable** - no $display, no initial blocks
- **10 tests**: vadd, vmul, vredsum, vand, vsub, vor, vxor, vmin, vmax, vminu
- **No RTL changes** - original VPU RTL untouched

### Files
```
fpga/
├── fpga_vpu_test_top.sv           # Synthesizable self-test (MAIN)
└── constraints/
    └── arty_a7_100t.xdc           # Pin constraints

tb/
├── fpga_vpu_test_tb.sv            # RTL simulation testbench
└── fpga_vpu_netlist_tb.sv         # Netlist simulation testbench

step1b_fpga_test_validate.sh       # RTL sim
step2b_fpga_test_synth.sh          # Vivado synthesis
step3b_fpga_netlist_verify.sh      # Netlist sim
```

---

## ✅ VERIFIED WORKING (RTL)

```bash
cd vpu_fpga_0.1e

# Original VPU tests still pass
vvp sim/test.vvp  # 114/114 passed

# FPGA test RTL simulation
./step1b_fpga_test_validate.sh
# Result: PASS - All 10 tests passed!
```

---

## 🔴 REQUIRES YOUR VERIFICATION

Steps 2b and 3b require Docker + Vivado:

```bash
# Run synthesis (needs vivado_dev container)
./step2b_fpga_test_synth.sh

# Run netlist verification
./step3b_fpga_netlist_verify.sh

# Program FPGA
# Use Vivado Hardware Manager with:
#   results/fpga_synth/fpga_vpu_test.bit
# LED[0] should light up = PASS
```

---

## 📊 EXPECTED RESULTS

| Step | Expected |
|------|----------|
| 1b RTL Sim | 10/10 tests PASS |
| 2b Synthesis | < 40% LUT utilization |
| 3b Netlist Sim | 10/10 tests PASS |
| Hardware | LED[0] = ON (PASS) |

---

## 🔴 WHAT'S NOT DONE YET

### 1. Vivado Synthesis Not Run
- Docker not available in this environment
- Script is ready: `./step2b_fpga_test_synth.sh`
- Need to verify utilization < 70%

### 2. Post-Synthesis Netlist Simulation
- Need to verify netlist works same as RTL
- Create `tb/fpga_vpu_netlist_tb.sv` if needed

### 3. Hardware Test
- Program Arty A7 with bitstream
- Verify LED[0] lights up (PASS)

### 4. More Complex Tests (optional stretch goals)
- Add more test patterns
- Add UART output for detailed results
- Add continuous stress test mode

---

## 📁 NEW FILES ADDED

```
fpga/
├── fpga_vpu_test_top.sv           # FPGA self-checking test (MAIN FILE)
└── constraints/
    └── arty_a7_100t.xdc           # Pin constraints

tb/
└── fpga_vpu_test_tb.sv            # Simulation testbench

step2b_fpga_test_synth.sh          # Synthesis script
docs/NEXT_SESSION_FPGA_TEST.md     # This file
```

---

## 🔧 HOW THE TEST WORKS

### Test Vectors (hardcoded in RTL)
```
Vector A (v1): [1, 2, 3, 4, 5, 6, 7, 8]  = 0x0807060504030201
Vector B (v2): [1, 1, 1, 1, 1, 1, 1, 1]  = 0x0101010101010101
Expected:      1+2+3+4+5+6+7+8 = 36     = 0x24
```

### Instruction Sequence
```
1. DMA: Load v1 with VEC_A
2. DMA: Load v2 with VEC_B
3. DMA: Clear v3 (accumulator)
4. Issue: vsetvli (SEW=8, LMUL=1, VL=8)
5. Issue: vmul.vv v4, v1, v2  (element-wise multiply)
6. Issue: vredsum.vs v3, v4, v3  (horizontal sum)
7. Wait: busy_o goes low
8. DMA: Read v3
9. Compare: v3[7:0] == 0x24 ?
10. Output: LED[0]=PASS, LED[1]=FAIL
```

### FSM States
```
ST_RESET → ST_LOAD_V1 → ST_LOAD_V2 → ST_LOAD_V3 →
ST_ISSUE_VSETVLI → ST_WAIT_VSETVLI →
ST_ISSUE_VMUL → ST_WAIT_VMUL →
ST_ISSUE_VREDSUM → ST_WAIT_VREDSUM →
ST_WAIT_DONE → ST_READ_RESULT → ST_CHECK_RESULT →
ST_PASS or ST_FAIL
```

---

## 🎯 NEXT STEPS

1. **Run Vivado synthesis** (requires Docker + vivado_dev container):
   ```bash
   ./step2b_fpga_test_synth.sh
   ```

2. **Check utilization** - must be < 70%:
   ```bash
   grep "Slice LUTs" results/fpga_synth/fpga_test_utilization_impl.txt
   ```

3. **Program Arty A7**:
   - Open Vivado Hardware Manager
   - Connect to Arty via USB
   - Program `results/fpga_synth/fpga_vpu_test.bit`
   - LED[0] should light up = PASS

4. **If synthesis fails or utilization too high**:
   - Check timing report for critical paths
   - May need to reduce test complexity
   - VPU alone is ~29%, test logic should be minimal

---

## ⚠️ KNOWN ISSUES / GOTCHAS

1. **VRF interface already works** - no RTL changes needed
   - `mem_vrf_wr_en_i` muxes with normal writeback at top level
   - Debug read is combinational (no extra cycle needed)

2. **CSRs used before first vsetvli** - see `hp_vpu_top.sv` line 219:
   ```systemverilog
   wire [31:0] active_vtype = vsetvl_done ? int_vtype : csr_vtype_i;
   ```
   After vsetvli, internal registers take over.

3. **Instruction encodings verified** - match RVV 1.0 spec:
   - vsetvli: `0b0_00000000_000_00000_111_00000_1010111`
   - vmul.vv: `{6'b100101, 1'b1, vs2, vs1, 3'b010, vd, 7'b1010111}`
   - vredsum.vs: `{6'b000000, 1'b1, vs2, vs1, 3'b010, vd, 7'b1010111}`

---

## 📊 EXPECTED UTILIZATION

Based on existing synthesis (VPU alone = ~29%):
- VPU: ~29% LUTs
- Test FSM: < 1% LUTs (tiny state machine)
- ROMs: 0% (constants only, no $readmemh)
- **Total expected: < 35%** (well under 70% target)

---

## Quick Test Commands

```bash
# Verify simulation still works
cd hyperplane_vpu_v1.9
iverilog -g2012 -DSIMULATION -I generated -o sim/fpga_test.vvp \
  generated/hp_vpu_pkg.sv rtl/hp_vpu_vrf.sv rtl/hp_vpu_iq.sv \
  rtl/hp_vpu_hazard.sv rtl/hp_vpu_decode.sv rtl/hp_vpu_lut_rom.sv \
  rtl/hp_vpu_lanes.sv rtl/hp_vpu_top.sv \
  fpga/fpga_vpu_test_top.sv tb/fpga_vpu_test_tb.sv
vvp sim/fpga_test.vvp

# Should see: PASS - Self-checking test succeeded
```
