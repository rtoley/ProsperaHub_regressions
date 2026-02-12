# WAW Hazard Fix Plan

## Problem Statement

The VPU has multiple pipeline paths with different latencies to VRF write:
- **Normal ALU**: OF → E1 → E2 → E3 → VRF (3 cycles from OF)
- **MAC/MUL**: OF → E1 → E1m → E2m → E3 → VRF (4 cycles from OF)
- **Reduction**: OF → R1 → R2 → R3 → VRF (3 cycles from OF)
- **Widening**: OF → W1 → W2 → VRF (2 cycles from OF)

A shorter-latency instruction entering OF can "overtake" a longer-latency instruction
already in the pipeline, causing a WAW (Write-After-Write) hazard where the wrong
value ends up in the VRF.

## Dangerous Scenarios

| OF instruction | In-flight instruction | Cycles remaining | Overtake? |
|----------------|----------------------|------------------|-----------|
| Widening (2)   | MAC in E1 (4)        | 4                | YES - 2 < 4 |
| Widening (2)   | Normal in E1 (3)     | 3                | YES - 2 < 3 |
| Widening (2)   | Reduction in R1 (3)  | 3                | YES - 2 < 3 |
| Normal (3)     | MAC in E1 (4)        | 4                | YES - 3 < 4 |
| Normal (3)     | MAC in E1m (3)       | 3                | NO - same |

## Required Fix

When OF has an instruction with same vd as an in-flight instruction that has more
cycles remaining, stall OF until the in-flight instruction has progressed enough.

## Clean Implementation Approach

### Step 1: Export pipeline state from lanes (REGISTERED signals only)

Add outputs from `hp_vpu_lanes.sv`:
```systemverilog
output logic        e1_is_mul_o,    // E1 has multiply (4 cycles remaining)
output logic        e1m_valid_o,    // E1m stage valid (3 cycles remaining)
output logic [4:0]  e1m_vd_o,       // E1m destination
output logic        r1_active_o,    // Reduction R1 active (3 cycles remaining)
output logic [4:0]  r1_vd_o,        // R1 destination
output logic        w1_active_o,    // Widening W1 active (2 cycles remaining)
output logic [4:0]  w1_vd_o,        // W1 destination
```

These are all **registered** signals - no combinational loops.

### Step 2: Detect OF instruction type in top module

```systemverilog
// In hp_vpu_top.sv - decode OF op type
wire of_is_widening = (of_op == OP_VWMULU) || (of_op == OP_VWMUL) || ...;
wire of_is_mul = (of_op == OP_VMUL) || (of_op == OP_VMACC) || ...;
wire of_is_normal = !of_is_widening && !of_is_mul && !of_is_reduction;

// Latency from OF to VRF
wire [2:0] of_latency = of_is_widening ? 3'd2 :
                        of_is_mul ? 3'd4 : 3'd3;
```

### Step 3: Add WAW stall logic to hazard module

```systemverilog
// In hp_vpu_hazard.sv - new inputs
input logic [2:0]  of_latency_i,    // Cycles for OF to reach VRF
input logic        e1_is_mul_i,     // E1 has multiply (4 cycles)
input logic        e1m_valid_i,     // E1m valid (3 cycles)
input logic [4:0]  e1m_vd_i,
input logic        r1_active_i,     // R1 active (3 cycles)
input logic [4:0]  r1_vd_i,

// WAW detection - OF would overtake in-flight instruction
wire waw_vs_e1_mul = of_valid_i && e1_valid_i && e1_is_mul_i &&
                     (of_vd_i == e1_vd_i) && (of_latency_i < 3'd4);

wire waw_vs_e1m = of_valid_i && e1m_valid_i &&
                  (of_vd_i == e1m_vd_i) && (of_latency_i < 3'd3);

wire waw_vs_r1 = of_valid_i && r1_active_i &&
                 (of_vd_i == r1_vd_i) && (of_latency_i < 3'd3);

wire waw_stall = waw_vs_e1_mul || waw_vs_e1m || waw_vs_r1;

// Add to stall outputs
assign stall_iq_o  = raw_hazard || waw_stall || ...;
assign stall_dec_o = raw_hazard || waw_stall || ...;
```

### Step 4: Gate OF advancement

In `hp_vpu_top.sv`, the OF stage should not advance when `waw_stall` is active:
```systemverilog
// OF valid should not clear when WAW stall
end else if (!stall_exec && of_valid && !mac_stall && !waw_stall && ...) begin
  of_valid <= 1'b0;  // Clear only when not WAW stalled
end
```

## Key Design Principles

1. **All inputs to hazard module must be registered** - no combinational paths
   that could create loops through valid_i

2. **WAW stall is combinational output** - this is fine, it feeds into stall
   logic which is already combinational

3. **Don't modify valid_i to lanes based on waw_stall** - this was the bug in
   v1.8a that may have caused the combinational loop

4. **Keep changes minimal** - only add what's needed, don't restructure

## Testing

After implementation:
1. Run `./step1_vpu_rtl_validate.sh` - verify 111/111 pass
2. Run `./step2_vpu_synthesis.sh` - verify Vivado completes without crash
3. Run `./step3_vpu_netlist_verify.sh` - verify netlist simulation matches

## Files to Modify

1. `rtl/hp_vpu_lanes.sv` - Add registered outputs for pipeline state
2. `rtl/hp_vpu_top.sv` - Connect new signals, add OF type detection
3. `rtl/hp_vpu_hazard.sv` - Add WAW detection logic

---

## Test Results (v1.9)

The v1.8 RTL (without explicit WAW detection) passes all WAW hazard tests!
This is because the existing `multicycle_busy` mechanism stalls the frontend
when any multi-cycle operation (MAC, reduction, widening) is in progress.

**Tests added in v1.9:**
- `test_waw_widening_vs_mac()` - Widening (2 cycles) vs MAC (4 cycles)
- `test_waw_widening_vs_alu()` - Widening (2 cycles) vs Normal ALU (3 cycles)
- `test_waw_multi_same_dest()` - Multiple instructions to same destination

All 12 hazard tests pass on 64/64 configuration.

The v1.8a explicit WAW detection logic was **unnecessary** and caused Vivado
synthesis crashes. The simpler v1.8 approach using `multicycle_busy` is both
correct and synthesizable.
