# Next Session: FPGA LLM Test Infrastructure

## Goal

Build a synthesizable LLM test infrastructure that proves the VPU has no bugs by:
1. Loading VRF via DMA interface (like real system)
2. Running a GEMV-like kernel
3. Reading back results via DMA
4. Comparing against golden values
5. Outputting PASS/FAIL on hardware (LED or UART)

**Target: Arty A7-100T @ 100 MHz**

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     fpga_vpu_dma_llm_top                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────────────┐   │
│  │   Test       │     │     VPU      │     │    Golden            │   │
│  │   Sequencer  │────►│   (hp_vpu_   │────►│    Checker           │   │
│  │   (FSM)      │     │    top)      │     │                      │   │
│  └──────┬───────┘     └──────────────┘     └──────────┬───────────┘   │
│         │                    ▲                        │               │
│         │ DMA Interface      │ CV-X-IF                │               │
│         │ (mem_vrf_*)        │ (x_issue_*)            │               │
│         │                    │                        │               │
│  ┌──────▼───────┐     ┌──────┴───────┐     ┌─────────▼───────────┐   │
│  │   Weight     │     │  Instruction │     │    Result           │   │
│  │   ROM        │     │  ROM         │     │    Comparator       │   │
│  │  (BRAM)      │     │  (BRAM)      │     │                     │   │
│  └──────────────┘     └──────────────┘     └─────────────────────┘   │
│                                                       │               │
│                                            ┌──────────▼───────────┐   │
│                                            │   PASS/FAIL Output   │   │
│                                            │   - LED[0] = PASS    │   │
│                                            │   - LED[1] = FAIL    │   │
│                                            │   - UART (optional)  │   │
│                                            └──────────────────────┘   │
│                                                                         │
│  External:                                                             │
│  - clk_100mhz (from Arty oscillator)                                  │
│  - rst_n (active low, directly active high from BTN0 directly active high from BTN0)                                           │
│  - led[3:0] (status)                                                  │
│  - uart_tx (optional, for detailed results)                           │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Test Kernel: GEMV (Matrix-Vector Multiply)

### Operation
```
y[i] = Σ W[i,j] * x[j]   for j = 0..N-1

Simplified for VLEN=64, SEW=8:
- Weight matrix W: 8x8 INT8 (fits in one v register per row)
- Input vector x: 8 INT8 elements
- Output vector y: 8 INT8 elements (after narrowing from INT16)
```

### Instruction Sequence
```
Phase 1: DMA Load (via mem_vrf_* interface)
  - Load W[0,:] into v1  (8 INT8 weights)
  - Load W[1,:] into v2
  - Load W[2,:] into v3
  - Load W[3,:] into v4
  - Load W[4,:] into v5
  - Load W[5,:] into v6
  - Load W[6,:] into v7
  - Load x[:] into v8    (8 INT8 inputs)
  - Clear v16-v23        (accumulators)

Phase 2: Compute (via x_issue_* interface)
  - vsetvli (SEW=8, LMUL=1)
  - vmul.vv v16, v1, v8   ; y[0] partial
  - vmul.vv v17, v2, v8   ; y[1] partial
  - vmul.vv v18, v3, v8   ; y[2] partial
  - vmul.vv v19, v4, v8   ; y[3] partial
  - vmul.vv v20, v5, v8   ; y[4] partial
  - vmul.vv v21, v6, v8   ; y[5] partial
  - vmul.vv v22, v7, v8   ; y[6] partial
  - vmul.vv v23, v0, v8   ; y[7] partial (v0 has W[7,:])

  ; Horizontal reduction needed for each row
  ; Or use vwmaccu for accumulation pattern

Phase 3: DMA Read (via mem_vrf_* interface)
  - Read v16-v23 results
  - Compare against precomputed golden values

Phase 4: Result
  - If all match: LED[0] = 1, LED[1] = 0 (PASS)
  - If mismatch: LED[0] = 0, LED[1] = 1 (FAIL)
```

### Alternative: Simpler Dot Product Test
```
Phase 1: DMA Load
  - Load a[0:7] into v1
  - Load b[0:7] into v2
  - Clear v3 (accumulator scalar = 0)

Phase 2: Compute
  - vsetvli x0, x0, e8, m1
  - vmul.vv v4, v1, v2      ; element-wise multiply
  - vredsum.vs v3, v4, v3   ; reduce to scalar

Phase 3: DMA Read
  - Read v3[0] (scalar result)
  - Compare against golden dot product

This is simpler and still exercises:
  - DMA load path
  - Multiply pipeline
  - Reduction pipeline
  - DMA read path
```

---

## File Structure

```
hyperplane_vpu_v1.9/
├── rtl/
│   ├── hp_vpu_top.sv          (existing)
│   ├── hp_vpu_*.sv            (existing)
│   └── ...
├── fpga/
│   ├── fpga_vpu_dma_llm_top.sv    (NEW - top level for Arty)
│   ├── test_sequencer.sv          (NEW - FSM drives DMA + CV-X-IF)
│   ├── golden_checker.sv          (NEW - compares results)
│   ├── weight_rom.sv              (NEW - preloaded test weights)
│   ├── instr_rom.sv               (NEW - preloaded instructions)
│   └── constraints/
│       └── arty_a7_100t.xdc       (NEW - pin constraints)
├── tb/
│   ├── hp_vpu_tb.sv               (existing RTL sim)
│   ├── fpga_llm_tb.sv             (NEW - RTL sim of FPGA top)
│   └── fpga_llm_netlist_tb.sv     (NEW - post-synth netlist sim)
├── scripts/
│   ├── gen_test_vectors.py        (NEW - generate weight/golden data)
│   └── vivado_build.tcl           (NEW - synthesis script)
└── docs/
    └── NEXT_SESSION_FPGA_LLM_TEST.md (this file)
```

---

## Implementation Plan

### Step 1: Generate Test Vectors (Python)
```python
# gen_test_vectors.py
import numpy as np

# Simple 8x8 GEMV
W = np.random.randint(-128, 127, (8, 8), dtype=np.int8)
x = np.random.randint(-128, 127, (8,), dtype=np.int8)
y = np.dot(W.astype(np.int16), x.astype(np.int16))  # INT16 result

# Or simpler dot product
a = np.array([1, 2, 3, 4, 5, 6, 7, 8], dtype=np.int8)
b = np.array([1, 1, 1, 1, 1, 1, 1, 1], dtype=np.int8)
golden = np.dot(a.astype(np.int16), b.astype(np.int16))  # = 36

# Output as SystemVerilog parameters or $readmemh files
```

### Step 2: Create Test Sequencer FSM
```systemverilog
// test_sequencer.sv
module test_sequencer (
  input  logic        clk,
  input  logic        rst_n,

  // DMA interface to VPU
  output logic        mem_vrf_wr_en,
  output logic [4:0]  mem_vrf_addr,
  output logic [63:0] mem_vrf_wdata,
  input  logic [63:0] mem_vrf_rdata,

  // CV-X-IF interface to VPU
  output logic        x_issue_valid,
  input  logic        x_issue_ready,
  output logic [31:0] x_issue_instr,
  output logic [7:0]  x_issue_id,

  input  logic        x_result_valid,
  output logic        x_result_ready,

  input  logic        vpu_busy,

  // Result
  output logic        test_done,
  output logic        test_pass
);

  typedef enum logic [3:0] {
    IDLE,
    DMA_LOAD_WEIGHTS,
    DMA_LOAD_INPUT,
    WAIT_DMA_DONE,
    ISSUE_VSETVLI,
    ISSUE_COMPUTE,
    WAIT_COMPUTE_DONE,
    DMA_READ_RESULT,
    CHECK_RESULT,
    DONE_PASS,
    DONE_FAIL
  } state_e;

  state_e state, next_state;
  // ... FSM implementation

endmodule
```

### Step 3: Create FPGA Top
```systemverilog
// fpga_vpu_dma_llm_top.sv
module fpga_vpu_dma_llm_top (
  input  logic       clk_100mhz,
  input  logic       btn0,        // Reset
  output logic [3:0] led,
  output logic       uart_tx      // Optional
);

  logic clk, rst_n;
  assign clk = clk_100mhz;
  assign rst_n = ~btn0;

  // Instantiate VPU
  hp_vpu_top #(
    .VLEN(64),
    .DLEN(64)
  ) u_vpu (
    .clk(clk),
    .rst_n(rst_n),
    // ... connect to sequencer
  );

  // Instantiate test sequencer
  test_sequencer u_seq (
    // ...
  );

  // LED outputs
  assign led[0] = test_pass;
  assign led[1] = test_done & ~test_pass;  // FAIL
  assign led[2] = vpu_busy;
  assign led[3] = test_done;

endmodule
```

### Step 4: Create Testbenches

**RTL Testbench** (`fpga_llm_tb.sv`):
- Instantiate `fpga_vpu_dma_llm_top`
- Provide clock
- Wait for `test_done`
- Check `test_pass`
- Report PASS/FAIL

**Netlist Testbench** (`fpga_llm_netlist_tb.sv`):
- Same as RTL but uses post-synthesis netlist
- Includes SDF timing annotation (optional)
- Validates gate-level behavior

### Step 5: Vivado Build Script
```tcl
# vivado_build.tcl
create_project vpu_llm_test ./vivado_proj -part xc7a100tcsg324-1

# Add RTL sources
add_files -fileset sources_1 [glob ../rtl/*.sv]
add_files -fileset sources_1 [glob ../fpga/*.sv]
add_files -fileset sources_1 ../generated/hp_vpu_pkg.sv

# Add constraints
add_files -fileset constrs_1 ../fpga/constraints/arty_a7_100t.xdc

# Synthesis
synth_design -top fpga_vpu_dma_llm_top -part xc7a100tcsg324-1

# Implementation
opt_design
place_design
route_design

# Generate bitstream
write_bitstream -force vpu_llm_test.bit

# Generate netlist for simulation
write_verilog -force -mode funcsim vpu_llm_test_netlist.v
```

---

## Success Criteria

### RTL Simulation
- [ ] `fpga_llm_tb.sv` passes with VPU RTL
- [ ] All test vectors produce correct golden results
- [ ] No X/Z propagation in results

### Netlist Simulation
- [ ] `fpga_llm_netlist_tb.sv` passes with post-synth netlist
- [ ] Timing clean at 100 MHz
- [ ] Same results as RTL simulation

### FPGA Hardware
- [ ] Bitstream programs successfully to Arty A7-100T
- [ ] LED[0] lights up (PASS)
- [ ] LED[1] stays off (no FAIL)
- [ ] Optional: UART outputs detailed test results

---

## Stretch Goals

1. **Multiple Test Patterns**: Run several different weight/input combinations
2. **Stress Test**: Loop continuously, count passes/fails
3. **UART Output**: Print detailed results to terminal
4. **Performance Counter**: Measure actual cycles for kernel
5. **Larger GEMV**: Use more of the 32 vector registers

---

## Hardware Setup (Arty A7-100T)

```
Connections:
- USB cable for programming and UART
- No external connections needed for basic test

Pin Mapping (in .xdc):
- clk_100mhz: E3 (onboard 100MHz oscillator)
- btn0: D9 (reset button)
- led[0]: H5 (LD4 - green, PASS)
- led[1]: J5 (LD5 - green, FAIL)
- led[2]: T9 (LD6 - green, BUSY)
- led[3]: T10 (LD7 - green, DONE)
- uart_tx: D10 (optional)
```

---

## Session Checklist

- [ ] Create `gen_test_vectors.py` - generate weights, inputs, golden values
- [ ] Create `test_sequencer.sv` - FSM for DMA + CV-X-IF control
- [ ] Create `golden_checker.sv` - compare results
- [ ] Create `fpga_vpu_dma_llm_top.sv` - FPGA top level
- [ ] Create `arty_a7_100t.xdc` - pin constraints
- [ ] Create `fpga_llm_tb.sv` - RTL simulation
- [ ] Create `fpga_llm_netlist_tb.sv` - netlist simulation
- [ ] Create `vivado_build.tcl` - synthesis script
- [ ] Run RTL simulation - verify PASS
- [ ] Run Vivado synthesis - verify timing
- [ ] Run netlist simulation - verify PASS
- [ ] Program Arty A7 - verify LED[0] = PASS

---

## Notes

- Start with simplest possible test (dot product) before GEMV
- VPU v1.9 at 29% utilization leaves room for test infrastructure
- 100 MHz target already verified in synthesis
- Keep test deterministic - same result every reset
- Golden values computed offline, hardcoded in ROM
