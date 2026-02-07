# HP-VPU Integration Guide (v0.3d)

## Overview

The Hyperplane VPU is a RISC-V Vector Extension (RVV) coprocessor designed for LLM inference workloads. It connects to a RISC-V scalar core via the CV-X-IF (Core-V eXtension Interface) protocol.

## Key Features

- **VLEN**: 64 bits (configurable)
- **Supported SEW**: 8, 16, 32 bits
- **LMUL**: 1, 2, 4, 8 (via micro-ops), 1/2, 1/4, 1/8
- **32 vector registers** (v0-v31)
- **Custom LLM ops**: vexp, vrecip, vrsqrt, vgelu, vpack4, vunpack4

## CV-X-IF Interface

### Issue Interface (Scalar → VPU)

| Signal | Direction | Description |
|--------|-----------|-------------|
| `x_issue_valid_i` | Input | CPU has instruction to issue |
| `x_issue_ready_o` | Output | VPU can accept instruction |
| `x_issue_accept_o` | Output | **VPU supports this instruction** |
| `x_issue_instr_i` | Input | 32-bit instruction |
| `x_issue_id_i` | Input | Transaction ID |
| `x_issue_rs1_i` | Input | Scalar operand 1 |
| `x_issue_rs2_i` | Input | Scalar operand 2 |

### Critical: Handling `x_issue_accept_o`

```verilog
if (x_issue_valid_i && x_issue_ready_o) begin
  if (x_issue_accept_o) begin
    // VPU accepts - instruction will be executed
  end else begin
    // VPU REJECTS - CPU MUST raise ILLEGAL INSTRUCTION trap
    // This is a firm contract - do not ignore!
  end
end
```

**v0.3d Change**: The VPU now performs early decode at issue stage. If an instruction is:
- Not a vector instruction (opcode != 1010111): `accept=0`
- A vector instruction but NOT supported: `accept=0`
- A supported vector instruction: `accept=1`

### Result Interface (VPU → Scalar)

| Signal | Direction | Description |
|--------|-----------|-------------|
| `x_result_valid_o` | Output | VPU has result |
| `x_result_ready_i` | Input | CPU can accept result |
| `x_result_id_o` | Output | Transaction ID |
| `x_result_data_o` | Output | Result data (for vsetvl*) |
| `x_result_we_o` | Output | Write enable |

## CSR Register Interface (v0.3d)

The VPU provides a memory-mapped CSR interface for capability discovery, status, and control:

| Signal | Direction | Description |
|--------|-----------|-------------|
| `csr_req_i` | Input | CSR access request |
| `csr_gnt_o` | Output | Request granted |
| `csr_we_i` | Input | Write enable (0=read) |
| `csr_addr_i[11:0]` | Input | Register address |
| `csr_wdata_i[31:0]` | Input | Write data |
| `csr_rdata_o[31:0]` | Output | Read data |
| `csr_rvalid_o` | Output | Read data valid |
| `csr_error_o` | Output | Access error |

### CSR Address Map

| Address | Name | Access | Description |
|---------|------|--------|-------------|
| 0x000 | VPU_ID | RO | VPU ID / Version (0x48500003 = "HP" v0.3) |
| 0x004 | VPU_CONFIG | RO | VLEN, NLANES configuration |
| 0x020 | CAP0 | RO | ALU/shift capabilities |
| 0x024 | CAP1 | RO | Multiply/MAC capabilities |
| 0x028 | CAP2 | RO | Widening/narrowing capabilities |
| 0x02C | CAP3 | RO | Reduction/mask/permute |
| 0x030 | CAP4 | RO | Custom LLM ops |
| 0x040 | STATUS | RO | Current status |
| 0x044 | ERR_INSTR | RO/W1C | Last illegal instruction |
| 0x048 | ERR_CNT | RO/W1C | Illegal instruction count |
| 0x04C | EXC_PENDING | RO/W1C | Exception pending |
| 0x060 | PERF_CYCLES | RO/W1C | Active cycles |
| 0x064 | PERF_INSTRS | RO | Instructions retired |
| 0x080 | CTRL | RW | Control register |
| 0x084 | EXC_CTRL | RW | Exception control |

### Capability Values

| CSR | Value | Meaning |
|-----|-------|---------|
| CAP0 | 0x3F | ALU: add, sub, logic, shift, minmax, merge ✓ |
| CAP1 | 0x07 | MUL/MAC ✓, Divide ✗ |
| CAP2 | 0x1F | Widening/narrowing ✓ |
| CAP3 | 0x9F | Reduction ✓, Mask ✓, Permute ✓, Compress ✗, Iota ✗ |
| CAP4 | 0xFF | LLM ops ✓, Fixed-point ✓ |

## Exception Interface (v0.3d)

| Signal | Direction | Description |
|--------|-----------|-------------|
| `exc_valid_o` | Output | Exception pending |
| `exc_cause_o[31:0]` | Output | Illegal instruction encoding |
| `exc_ack_i` | Input | Exception acknowledged |

### Exception Control (EXC_CTRL register)

| Mode | Value | Behavior |
|------|-------|----------|
| Ignore | 0b00 | Don't track illegal instructions |
| Flag | 0b01 | Track in ERR_INSTR/ERR_CNT, no interrupt |
| Interrupt | 0b10 | Assert exc_valid_o, wait for exc_ack_i |

## Unsupported Instructions

The following RVV 1.0 instructions will be **REJECTED** (accept=0):

- `vdiv.vv/vx`, `vdivu.vv/vx` - Integer divide
- `vrem.vv/vx`, `vremu.vv/vx` - Integer remainder
- `vcompress.vm` - Compress
- `viota.m` - Iota (prefix sum)
- All floating-point instructions
- All load/store instructions (handled via memory interface)

## Example Integration

```systemverilog
hp_vpu_top #(
  .VLEN        (64),
  .NLANES      (1),
  .ELEN        (32)
) u_vpu (
  .clk              (clk),
  .rst_n            (rst_n),

  // CV-X-IF Issue
  .x_issue_valid_i  (cpu_issue_valid),
  .x_issue_ready_o  (vpu_issue_ready),
  .x_issue_accept_o (vpu_issue_accept),  // CHECK THIS!
  .x_issue_instr_i  (cpu_issue_instr),
  .x_issue_id_i     (cpu_issue_id),
  .x_issue_rs1_i    (cpu_rs1),
  .x_issue_rs2_i    (cpu_rs2),

  // CV-X-IF Result
  .x_result_valid_o (vpu_result_valid),
  .x_result_ready_i (cpu_result_ready),
  .x_result_id_o    (vpu_result_id),
  .x_result_data_o  (vpu_result_data),
  .x_result_we_o    (vpu_result_we),

  // Vector CSRs (RVV standard)
  .csr_vtype_i      (vtype_csr),
  .csr_vl_i         (vl_csr),
  .csr_vtype_o      (vtype_from_vpu),
  .csr_vl_o         (vl_from_vpu),
  .csr_vl_valid_o   (vl_update_valid),

  // VPU CSR Interface (memory-mapped)
  .csr_req_i        (vpu_csr_req),
  .csr_gnt_o        (vpu_csr_gnt),
  .csr_we_i         (vpu_csr_we),
  .csr_addr_i       (vpu_csr_addr),
  .csr_wdata_i      (vpu_csr_wdata),
  .csr_rdata_o      (vpu_csr_rdata),
  .csr_rvalid_o     (vpu_csr_rvalid),
  .csr_error_o      (vpu_csr_error),

  // Exception Interface
  .exc_valid_o      (vpu_exc_valid),
  .exc_cause_o      (vpu_exc_cause),
  .exc_ack_i        (vpu_exc_ack),

  // Debug (optional)
  .mem_vrf_wr_en_i  (1'b0),
  .mem_vrf_addr_i   (5'd0),
  .mem_vrf_wdata_i  ('0),
  .mem_vrf_rdata_o  (),

  // Status
  .busy_o           (vpu_busy),
  .perf_cnt_o       (vpu_perf_cnt)
);

// Handle accept signal
always_ff @(posedge clk) begin
  if (cpu_issue_valid && vpu_issue_ready && !vpu_issue_accept) begin
    // VPU rejected instruction - raise illegal instruction trap
    raise_illegal_instruction_trap(cpu_issue_instr);
  end
end
```
