# Hyperplane VPU - Next Session TODO
## Date: 2026-01-30
## Current Version: v1.6d (timing fix INCOMPLETE)

---

## 🔴 CRITICAL: READ THIS FIRST

### Work Saving Protocol
**SAVE YOUR WORK FREQUENTLY** - Long debug sessions cause:
- Context compaction (Claude loses work)
- Connection drops
- Lost progress

```bash
# After ANY significant change:
tar -czf /mnt/user-data/outputs/vpu_checkpoint_N.tar.gz hyperplane_vpu_v1.6d
```

Save checkpoints at:
1. After RTL compiles successfully
2. After tests pass
3. BEFORE starting debug (if tests fail)
4. After each bug fix

---

## 🎯 THE GOAL

Break the **32×32 multiply** critical path to meet:
- **FPGA**: 100 MHz (10ns cycle)
- **ASIC**: Fast library (~8-10 logic levels)

**Portable solution required** - not Xilinx DSP48E1 specific.

---

## 📊 CURRENT TIMING FAILURE

```
Source:      u_lanes/e1_a_reg[48]/C
Destination: u_lanes/e2_mul_partial_reg[127]/D
Delay:       10.726ns (need ≤10ns)
Logic:       DSP48E1=2, CARRY4=12, LUT2=1, LUT5=1
```

**Root Cause**: 32×32 multiply requires two DSP48E1s (each is 25×18 max).
The 12 CARRY4s chain them together. This path is 10.7ns.

```
e1_a_reg ──→ [DSP48E1 #1] ──→ [CARRY4 ×12] ──→ [DSP48E1 #2] ──→ e2_mul_partial_reg
             └─────────────── 10.726ns ────────────────────┘
```

---

## ✅ CORRECT SOLUTION: Balanced Pipeline Split

Add a register stage **in the middle of the multiply**:

### Current (BROKEN):
```
E1:  Operands in registers (e1_a, e1_b)
     ↓
     [FULL 32×32 MULTIPLY: 10.7ns] ← FAILS
     ↓
E2:  e2_mul_partial captured
```

### Fixed (NEEDED):
```
E1:  Operands in registers (e1_a, e1_b)
     ↓
     [Partial multiply: ~5ns]
     ↓
E1m: e1m_mul_partial (NEW REGISTER) ← ADD THIS
     ↓
     [Complete multiply: ~5ns]
     ↓
E2:  e2_mul_partial captured
```

### Implementation Steps:

1. **Add e1m pipeline stage registers**:
   ```systemverilog
   // After E1, before E2
   logic [DLEN-1:0] e1m_mul_partial_lo;  // Lower partial products
   logic [DLEN-1:0] e1m_mul_partial_hi;  // Upper partial products
   logic            e1m_valid;
   // ... other e1m_* signals to forward through pipeline
   ```

2. **Split the multiply operation**:
   - E1→E1m: Compute partial products (DSP48E1 #1)
   - E1m→E2: Accumulate partials (DSP48E1 #2 + CARRY4)

3. **Update all pipeline control**:
   - Stall signals must include E1m
   - Hazard detection must check E1m
   - Valid propagation: E1 → E1m → E2 → E3

4. **Test both configurations**:
   - 256/256 with ENABLE_VMADD=1: Must pass 109/109
   - 64/64 with ENABLE_VMADD=0: Must pass 107/107

---

## ⚠️ CROSS-PIPELINE INTERACTIONS (LEARNED THE HARD WAY)

The VPU has **THREE parallel pipelines**:

```
1. Normal/MAC:  E1 → (E1m) → E2 → (E2m) → E3 → WB
2. Reduction:   R1 → R2 → R3
3. Widening:    W1 → W2
```

### What Went Wrong in v1.6:

I added a stall-based MAC fix that broke the throughput test:

**Bug 1: OF (Operand Fetch) Clearing**
```
When mac_stall=1:
  - stall_dec=1 (decode stalls)
  - stall_exec=0 (only SRAM stall)
  - Condition `!stall_exec && of_valid` cleared OF
  - But lanes DIDN'T consume OF (they were frozen)
  - Instruction LOST!

Fix: Added `&& !mac_stall` to OF clearing condition
```

**Bug 2: E3 Double-Write**
```
When mac_stall=1:
  - E3 was frozen but e3_valid stayed high
  - Previous instruction got written back MULTIPLE times

Fix: E3 must insert bubble (valid=0) during mac_stall
```

**Bug 3: Cross-pipeline timing**
```
If MAC stalls while Reduction or Widening is in flight:
  - Their pipelines must continue (they don't stall for MAC)
  - Results must not collide at writeback
  - Hazard detection must account for all three
```

### Rules for Pipeline Changes:

1. **Any stall signal must consider ALL THREE pipelines**
2. **Writeback mux priority**: widening > reduction > normal
3. **Hazard check**: OF, E1, E1m(?), E2, E3, R1, R2, R3, W1, W2
4. **Valid propagation**: Don't lose instructions, don't duplicate

---

## 📁 KEY FILES TO MODIFY

### rtl/hp_vpu_lanes.sv
- Lines 127-150: MAC stall FSM (may need rework for E1m)
- Lines ~800-1000: Multiply partial product generation
- Lines ~2000-2100: e2_mul_partial capture
- Lines ~2700-2760: E3 stage and writeback

### rtl/hp_vpu_top.sv
- Line ~376: OF clearing logic (watch for stall interactions)
- Lines ~390-430: Pipeline stage wiring

### rtl/hp_vpu_hazard.sv
- Add E1m stage to hazard detection if new stage added

---

## 🧪 TEST REQUIREMENTS

### Two configurations MUST pass:

**Config 1: Full features (256/256)**
```bash
cp config/vpu_config_256.json config/vpu_config.json
python3 scripts/gen_pkg.py
# Compile and run
# Expected: 109/109 tests passed
```

**Config 2: Reduced features (64/64)**
```bash
cp config/vpu_config_arty7.json config/vpu_config.json
python3 scripts/gen_pkg.py
# Compile and run
# Expected: 107/107 tests passed (vmadd/vnmsub skipped)
```

### Critical Tests:
- **Pipeline throughput test**: 100 back-to-back instructions
- **Random tests**: 100, 300, 500, 1000 instructions
- **MAC tests**: vmacc.vv, vnmsac.vv (if ENABLE_VMADD=1: vmadd, vnmsub too)

---

## 🔧 STEP-BY-STEP PROCEDURE

### Phase 1: Understand Current State
```bash
tar -xzf hyperplane_vpu_v1.6d.tar.gz
cd hyperplane_vpu_v1.6d
cat docs/MAC_TIMING_FIX_STATUS.md
cat docs/NEXT_SESSION_TODO.md  # This file
```

### Phase 2: Implement E1m Pipeline Stage
1. Declare e1m_* registers in hp_vpu_lanes.sv
2. Split multiply: partial products in E1→E1m, accumulate in E1m→E2
3. Update valid/stall propagation
4. **SAVE CHECKPOINT**

### Phase 3: Update Pipeline Control
1. Add E1m to stall logic
2. Add E1m to hazard detection
3. Update OF clearing if needed
4. **SAVE CHECKPOINT**

### Phase 4: Test Config 1 (256/256)
```bash
cp config/vpu_config_256.json config/vpu_config.json
python3 scripts/gen_pkg.py
iverilog -g2012 -DSIMULATION -o sim/vpu_tb generated/hp_vpu_pkg.sv rtl/*.sv tb/hp_vpu_tb.sv
vvp sim/vpu_tb
# Must pass 109/109
```
**SAVE CHECKPOINT** (even if failing - for debug resume)

### Phase 5: Test Config 2 (64/64)
```bash
cp config/vpu_config_arty7.json config/vpu_config.json
python3 scripts/gen_pkg.py
# Recompile and run
# Must pass 107/107
```
**SAVE CHECKPOINT**

### Phase 6: Timing Verification
Run Vivado synthesis with step2_vpu_synthesis.sh
Check: `results/synthesis/timing_summary.txt`
Target: All paths ≤ 10ns

---

## 🚫 WHAT NOT TO DO

1. **DON'T** just add stalls without splitting the datapath
   - v1.6 mistake: stalled for MAC add but multiply was the problem

2. **DON'T** assume one pipeline fix won't affect others
   - Reduction and Widening pipelines run in parallel

3. **DON'T** debug for hours without saving
   - Context compaction will lose your work

4. **DON'T** forget to test both configs
   - 256/256 AND 64/64 must pass

5. **DON'T** change LUT ROM setup
   - Simulation: hp_vpu_lut_rom.sv (distributed)
   - Synthesis: hp_vpu_lut_rom_bram.sv (step2 script handles this)

---

## 📋 CHECKLIST

- [ ] Read this document completely
- [ ] Understand the three pipelines
- [ ] Implement E1m stage for multiply split
- [ ] Save checkpoint after compile
- [ ] Test 256/256 config (109/109)
- [ ] Save checkpoint
- [ ] Test 64/64 config (107/107)
- [ ] Save checkpoint
- [ ] Run Vivado timing (target ≤10ns)
- [ ] Create final tarball with version bump

---

## 📦 FILE STRUCTURE

```
hyperplane_vpu_v1.6d/
├── config/
│   ├── vpu_config.json          # Active config (copy from below)
│   ├── vpu_config_256.json      # Full: VLEN=256, VMADD=1
│   └── vpu_config_arty7.json    # Small: VLEN=64, VMADD=0
├── docs/
│   ├── MAC_TIMING_FIX_STATUS.md # Problem analysis
│   ├── NEXT_SESSION_TODO.md     # THIS FILE
│   └── ...
├── rtl/
│   ├── hp_vpu_lanes.sv          # Main execution - MODIFY THIS
│   ├── hp_vpu_top.sv            # Top level - check stall wiring
│   ├── hp_vpu_hazard.sv         # Hazard unit - add E1m check
│   └── ...
├── scripts/
│   └── gen_pkg.py               # Regenerate after config change
├── tb/
│   └── hp_vpu_tb.sv             # Testbench
└── step2_vpu_synthesis.sh       # Vivado synthesis
```

---

## Summary

**Goal**: Split 32×32 multiply across E1→E1m→E2 for timing closure.

**Key insight**: The MULTIPLY is 10.7ns, not the MAC add. Must split the multiply datapath itself.

**Watch out for**: Cross-pipeline interactions (Normal, Reduction, Widening).

**Save often**: Checkpoints prevent lost work.

**Test both**: 256/256 (109 tests) AND 64/64 (107 tests).
