# Hyperplane VPU - Next Sessions TODO
## Date: 2026-01-30
## Current Version: v1.6d (timing fix incomplete, functional tests pass)

---

## ⚠️ CRITICAL: SAVE WORK FREQUENTLY

This debug involves multiple interacting pipelines. Long debug sessions risk:
- Context compaction losing work
- Connection drops losing progress

**BACKUP PROTOCOL:**
```bash
# After ANY significant change:
tar -czf /mnt/user-data/outputs/vpu_checkpoint_N.tar.gz hyperplane_vpu_v1.6d

# Name checkpoints descriptively:
# vpu_checkpoint_1_e1m_register_added.tar.gz
# vpu_checkpoint_2_stall_logic_updated.tar.gz
# vpu_checkpoint_3_tests_passing.tar.gz
```

---

## 🔴 THE PROBLEM: 32×32 Multiply Timing

### Vivado Report
```
Source:      u_lanes/e1_a_reg[48]/C
Destination: u_lanes/e2_mul_partial_reg[127]/D
Delay:       10.726ns  (need ≤10ns for 100MHz)
Logic:       DSP48E1=2, CARRY4=12, LUT2=1, LUT5=1
```

### Why It Fails
- Each DSP48E1 is 25×18 multiplier max
- 32×32 multiply needs TWO DSP48E1s stitched together
- The 12 CARRY4s chain the DSP outputs
- Total path: 10.7ns > 10ns requirement

### Current Pipeline (BROKEN)
```
E1: [operands ready]
    ↓
    ══════════════════════════════════════
    [DSP48E1 #1] → [CARRY4 ×12] → [DSP48E1 #2]  = 10.7ns ✗
    ══════════════════════════════════════
    ↓
E2: [capture in e2_mul_partial]
```

---

## 🟢 THE SOLUTION: Balanced Pipeline Split

### Target Pipeline (CORRECT)
```
E1: [operands ready]
    ↓
    [DSP48E1 #1 + partial carry] ~5ns
    ↓
E1m: [NEW REGISTER: e1m_mul_partial]  ← ADD THIS
    ↓
    [DSP48E1 #2 + remaining carry] ~5ns
    ↓
E2: [capture in e2_mul_partial]
```

Each stage ≤5ns, meets 10ns cycle time ✓

### Implementation Steps

#### Step 1: Add E1m Register Stage
```systemverilog
// After E1 stage, before E2
logic [DLEN*2-1:0] e1m_mul_partial;  // Partial product
logic              e1m_valid;
vpu_op_e           e1m_op;
// ... copy all E1 state needed by E2

always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    e1m_valid <= 1'b0;
    // ... reset all
  end else if (!stall_i) begin
    e1m_valid <= e1_valid;
    e1m_mul_partial <= partial_product_from_dsp1;
    // ... forward all E1 state
  end
end
```

#### Step 2: Split Multiply Logic
```systemverilog
// E1 stage: First DSP + partial carry
wire [47:0] dsp1_out = e1_a[15:0] * e1_b[31:0];  // Partial

// E1m stage: Second DSP + combine
wire [63:0] full_product = {dsp2_out, e1m_mul_partial[31:0]} + carry;
```

#### Step 3: Update Stall Propagation
- E1m must stall when E2 stalls
- E1 must stall when E1m stalls
- Hazard unit must track E1m stage

#### Step 4: Update Hazard Detection
```systemverilog
// In hp_vpu_hazard.sv - ADD E1m stage
input  logic        e1m_valid_i,
input  logic [4:0]  e1m_vd_i,

// RAW hazard must check E1m
logic raw_vs1_e1m, raw_vs2_e1m, raw_vs3_e1m;
assign raw_vs1_e1m = e1m_valid_i && (d_vs1_i == e1m_vd_i);
// ...
```

---

## 🟡 CROSS-PIPELINE INTERACTIONS

### Three Pipelines Exist
```
1. Normal/MAC:  E1 → E1m → E2 → E2m → E3 → WB
2. Reduction:   R1 → R2 → R3
3. Widening:    W1 → W2
```

### Interaction Matrix
| Event | Normal | Reduction | Widening | Action Needed |
|-------|--------|-----------|----------|---------------|
| E1m stall | Stalls E1 | - | - | Stall OF, D2 |
| MAC in E2m | Stalls E1,E1m,E2 | Continues | Continues | Don't corrupt R/W pipes |
| Reduction active | Continues | Owns result bus | - | Mux priority |
| Widening active | Continues | - | Owns result bus | Mux priority |

### Critical Bugs We Hit in v1.6

#### Bug 1: OF Clearing During Stall
```
WRONG: else if (!stall_exec && of_valid) begin
         of_valid <= 1'b0;  // Clears OF even though lanes didn't consume it!
       end

FIXED: else if (!stall_exec && of_valid && !mac_stall) begin
         of_valid <= 1'b0;  // Only clear if lanes actually consumed
       end
```

#### Bug 2: E3 Double-Writeback
```
WRONG: E3 frozen during mac_stall, but valid stays high
       → Same result written back multiple times

FIXED: Insert bubble (valid=0) during stall cycle:
       if (mac_stall) begin
         e3_valid <= 1'b0;  // Bubble
       end else if (e2m_valid) begin
         // MAC result path
       end else begin
         // Normal path
       end
```

#### Bug 3: Result Mux Using Wrong Op
```
WRONG: case (e2_op)  // e2_op changes to NEW instruction when stall ends!
         OP_VMACC: final_result = e2m_mac_res;

FIXED: Use e2m_op for MAC result selection:
       case (e2m_op)
         OP_VMACC: final_result = e2m_mac_res;
```

---

## 🔵 THROUGHPUT TEST

### What It Tests
- 100 back-to-back instructions with random ops
- Exercises pipeline hazards, stalls, all three pipelines
- Golden model tracks expected VRF state
- Compares all 32 registers at end

### Why It Catches Pipeline Bugs
- Instructions in flight simultaneously
- MAC stall affects following instructions
- Cross-pipeline interactions exercised
- Any dropped/duplicated instruction shows as VRF mismatch

### Test Command
```bash
vvp sim/vpu_tb 2>&1 | grep -E "THROUGHPUT|PASS|FAIL|error"
```

### Expected Output
```
=== PIPELINE THROUGHPUT TEST ===
[xxxxx] PASS: Pipeline throughput test - 100 instructions
Test Results: 109/109 passed (or 107/107 if VMADD=0)
```

---

## 📋 VALIDATION CHECKLIST

### Both Configs Must Pass

#### Config 1: 256/256 (Full Features)
```bash
cp config/vpu_config_256.json config/vpu_config.json
python3 scripts/gen_pkg.py
# Compile and run - expect 109/109
```

#### Config 2: 64/64 (Arty-7, VMADD=0)
```bash
cp config/vpu_config_arty7.json config/vpu_config.json
python3 scripts/gen_pkg.py
# Compile and run - expect 107/107 (vmadd/vnmsub skipped)
```

### Synthesis Must Use BRAM LUT ROM
```bash
# step2_vpu_synthesis.sh explicitly includes:
./rtl/hp_vpu_lut_rom_bram.sv   # NOT hp_vpu_lut_rom.sv

# Verify:
grep "lut_rom" step2_vpu_synthesis.sh
# Should show: hp_vpu_lut_rom_bram.sv
```

---

## 📁 FILE INVENTORY

### RTL Files to Modify
| File | Changes Needed |
|------|----------------|
| `rtl/hp_vpu_lanes.sv` | Add E1m stage registers, split multiply |
| `rtl/hp_vpu_hazard.sv` | Add E1m hazard checking |
| `rtl/hp_vpu_top.sv` | Wire E1m signals, update stall logic |

### Key Line Numbers (v1.6d)
- MAC stall FSM: `hp_vpu_lanes.sv` lines 127-152
- E2m registers: `hp_vpu_lanes.sv` lines 2000-2010, 2490-2525
- E3 capture: `hp_vpu_lanes.sv` lines 2700-2760
- OF clearing: `hp_vpu_top.sv` line 376
- Hazard unit: `hp_vpu_hazard.sv` (entire file, ~130 lines)

---

## 🎯 SUCCESS CRITERIA

### Timing
- [ ] Vivado: All paths ≤ 9.5ns (margin for 100MHz)
- [ ] No paths through E1→E2 multiply > 6ns per stage

### Functional
- [ ] 256/256 config: 109/109 tests pass
- [ ] 64/64 config: 107/107 tests pass
- [ ] Throughput test: 0 errors
- [ ] Random tests (100, 300, 500, 1000): 0 errors

### Code Quality
- [ ] No Xilinx-specific constructs in RTL (portable)
- [ ] Clean stall propagation (no multi-cycle hacks)
- [ ] Balanced pipeline stages (~5ns each)

---

## 🚨 THINGS TO WATCH OUT FOR

1. **Don't gate MAC stall by ENABLE_VMADD** - vmacc/vnmsac always need it, only vmadd/vnmsub multiplier is optional

2. **E3 must insert bubble during stall** - otherwise previous result written multiple times

3. **OF clearing must check mac_stall** - otherwise instruction in OF gets lost

4. **Use e2m_op for MAC result mux** - e2_op has new instruction when stall ends

5. **Test BOTH configs** - bugs often only appear in one

6. **Backup before debug** - long debug sessions lose work

7. **Synthesis uses different LUT ROM** - hp_vpu_lut_rom_bram.sv (945 bytes), not hp_vpu_lut_rom.sv (34KB)

---

## 📊 VERSION HISTORY

| Version | Changes | Status |
|---------|---------|--------|
| v1.4 | Original, timing fails 11.3ns | Functional ✓, Timing ✗ |
| v1.6 | MAC result path via e2m_op | Functional ✓, Timing ✗ |
| v1.6b | OF clearing fix, E3 bubble | Functional ✓, Timing ✗ |
| v1.6c | Incorrectly gated MAC stall | Broken |
| v1.6d | Reverted gating, documented | Functional ✓, Timing ✗ |
| v1.7 | **TODO: E1m pipeline split** | Needed |

---

## Quick Start for Next Session

```bash
# 1. Extract
tar -xzf hyperplane_vpu_v1.6d.tar.gz
cd hyperplane_vpu_v1.6d

# 2. Read this document
cat docs/NEXT_SESSIONS.md
cat docs/MAC_TIMING_FIX_STATUS.md

# 3. Verify current state
python3 scripts/gen_pkg.py
iverilog -g2012 -DSIMULATION -o sim/vpu_tb \
  generated/hp_vpu_pkg.sv rtl/*.sv tb/hp_vpu_tb.sv
vvp sim/vpu_tb | grep "Test Results"
# Expected: 109/109 passed

# 4. Implement E1m pipeline split (see THE SOLUTION above)

# 5. Backup frequently!
tar -czf /mnt/user-data/outputs/checkpoint_N.tar.gz hyperplane_vpu_v1.6d
```

---

## 🔴 MY MISTAKES IN THIS SESSION (LEARN FROM THESE)

### Mistake 1: Fixed the Wrong Path

**What was needed:**
```
Split the 32×32 MULTIPLY path (10.7ns) with E1m register
E1 → [partial multiply] → E1m → [complete multiply] → E2
```

**What I actually did:**
```
Added stall for MAC ADD path (which wasn't even the bottleneck!)
E1 → E2 (multiply still 10.7ns!) → stall → E2m (add) → E3
```

I confused the MAC operation (multiply + add) timing with just the multiply timing. The Vivado report clearly showed `e1_a_reg → e2_mul_partial_reg` as the failing path - that's MULTIPLY, not the add. I didn't read the timing report carefully.

### Mistake 2: Stall-Based Approach Instead of Pipeline Split

**What you asked for:**
- Balanced pipeline split
- Break the datapath with registers
- ~5ns per stage

**What I implemented:**
- Stall-based workaround
- Freeze pipeline for 1 cycle
- Compute add during stall, capture in e2m_*

This was fundamentally wrong because:
1. **Didn't touch the actual critical path** - multiply still 10.7ns
2. **Added latency** - MAC ops now +1 cycle slower
3. **Added complexity** - stall interactions with other pipelines
4. **No timing benefit** - same 10.7ns path, just delayed

### Mistake 3: Stall Interactions Broke Throughput

The stall approach created three bugs in the throughput test:

**Bug 1: Lost Instructions (OF Clearing)**
```
mac_stall=1 causes:
  - stall_dec=1 (from multicycle_busy)
  - stall_exec=0 (only checks SRAM)

OF clearing condition: `!stall_exec && of_valid`
  - This was TRUE during mac_stall
  - OF cleared, but lanes didn't consume (they were frozen)
  - Instruction LOST → VRF mismatch in throughput test
```

**Bug 2: Duplicate Writebacks (E3 Frozen)**
```
mac_stall=1 causes:
  - E3 register frozen (condition: !stall_i && !mac_stall)
  - But e3_valid stays HIGH
  - valid_o stays HIGH
  - Same result written back EVERY CYCLE during stall
  - Duplicate writes → VRF corruption
```

**Bug 3: Wrong Result Mux (e2_op vs e2m_op)**
```
When mac_stall ends:
  - e2_* registers get NEW instruction (pipeline advances)
  - e2m_* registers have MAC result
  - final_result mux used `case (e2_op)`
  - But e2_op is now the NEW instruction, not MAC!
  - Wrong result selected → VRF mismatch
```

### Mistake 4: Didn't Consider Other Pipelines

Three pipelines exist:
```
Normal/MAC:  E1 → E2 → E2m → E3
Reduction:   R1 → R2 → R3
Widening:    W1 → W2
```

When I added mac_stall:
- Normal pipeline freezes
- Reduction pipeline CONTINUES (not affected by mac_stall)
- Widening pipeline CONTINUES (not affected by mac_stall)

This creates race conditions:
- What if Reduction result ready while mac_stall active?
- What if Widening completes during mac_stall?
- Writeback mux priority must be maintained

I didn't think through these interactions, leading to 13 errors in throughput test.

### Mistake 5: Debug Without Checkpoints

The debug session was long. When I made a fix, I should have:
1. Saved checkpoint immediately
2. Tested
3. If broken, restore and try different approach

Instead, I kept modifying and lost track of what worked.

---

## 📊 COMPARISON: What I Did vs What Was Needed

| Aspect | What I Did (WRONG) | What Was Needed (CORRECT) |
|--------|-------------------|---------------------------|
| **Target path** | MAC add (mul + acc) | 32×32 multiply itself |
| **Approach** | Stall + capture | Pipeline register split |
| **New registers** | e2m_* (after multiply) | E1m (middle of multiply) |
| **Timing fix** | None (multiply still 10.7ns) | Splits 10.7ns → 5ns + 5ns |
| **Latency** | +1 cycle for MAC | +1 cycle for ALL multiplies |
| **Complexity** | High (stall interactions) | Low (just add register stage) |
| **Cross-pipeline** | Broken (bugs 1,2,3) | Clean (no stalls needed) |

---

## 🎯 WHAT NEXT SESSION SHOULD DO DIFFERENTLY

1. **Read timing report carefully** - the path `e1_a_reg → e2_mul_partial_reg` is MULTIPLY, not MAC add

2. **Split the datapath, don't stall** - add E1m register IN THE MIDDLE of multiply logic

3. **Keep all three pipelines in mind** - any change to Normal pipeline must consider Reduction and Widening

4. **Test incrementally:**
   - Add E1m register declarations → compile → checkpoint
   - Wire E1m into pipeline → compile → checkpoint
   - Update hazard detection → compile → checkpoint
   - Run tests → checkpoint (even if failing)

5. **Don't confuse MAC with multiply:**
   - MAC = multiply-accumulate = `vd + vs1 * vs2`
   - The ADD part (vd + product) is ~5ns, not the problem
   - The MULTIPLY part (vs1 * vs2) is 10.7ns, THE problem
