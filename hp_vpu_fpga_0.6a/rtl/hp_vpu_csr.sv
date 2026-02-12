//==============================================================================
// Hyperplane VPU - Control/Status Register Block
//
// Standard CSR interface with full read/write capability:
// - Capability discovery (read-only)
// - Status/error reporting (read-only, write-to-clear)
// - Performance counters (read-only, write-to-clear)
// - Control registers (read/write)
//
// Memory-mapped register interface compatible with AXI-Lite/APB style access
//==============================================================================

module hp_vpu_csr
  import hp_vpu_pkg::*;
#(
  parameter int unsigned VLEN = 64,
  parameter int unsigned NLANES = 1
)(
  input  logic        clk,
  input  logic        rst_n,

  //==========================================================================
  // Register Interface (memory-mapped, from scalar core or bus)
  //==========================================================================
  input  logic        reg_req_i,        // Request valid
  output logic        reg_gnt_o,        // Request granted
  input  logic        reg_we_i,         // Write enable (0=read, 1=write)
  input  logic [11:0] reg_addr_i,       // Register address (12-bit)
  input  logic [31:0] reg_wdata_i,      // Write data
  input  logic [3:0]  reg_be_i,         // Byte enables
  output logic [31:0] reg_rdata_o,      // Read data
  output logic        reg_rvalid_o,     // Read data valid (1 cycle after gnt)
  output logic        reg_error_o,      // Access error (invalid address)

  //==========================================================================
  // Status inputs (from VPU pipeline)
  //==========================================================================
  input  logic        illegal_instr_i,      // Pulse: illegal instruction detected
  input  logic [31:0] illegal_instr_data_i, // The illegal instruction encoding
  input  logic        vpu_busy_i,           // VPU pipeline active
  input  logic [31:0] instr_cnt_i,          // Instructions completed (from perf counter)
  input  logic        stall_i,              // Pipeline stall active (for PERF_STALLS counter)

  //==========================================================================
  // Control outputs (to VPU pipeline)
  //==========================================================================
  output logic        sw_reset_o,           // Software reset request
  output logic        perf_cnt_en_o,        // Performance counter enable
  output logic [1:0]  exc_mode_o,           // Exception mode (00=ignore, 01=flag, 10=interrupt)

  //==========================================================================
  // Exception/Interrupt output
  //==========================================================================
  output logic        exc_valid_o,          // Exception/interrupt pending
  output logic [31:0] exc_cause_o,          // Exception cause (instruction encoding)
  input  logic        exc_ack_i             // Exception acknowledged (clears pending)
);

  //==========================================================================
  // CSR Address Map (12-bit address space, 0x000-0xFFF)
  //==========================================================================
  // 0x000-0x01F: Identification (read-only)
  localparam ADDR_VPU_ID       = 12'h000;  // VPU ID / Version
  localparam ADDR_VPU_CONFIG   = 12'h004;  // VLEN, NLANES, features

  // 0x020-0x03F: Capabilities (read-only)
  localparam ADDR_CAP0         = 12'h020;  // ALU/shift capabilities
  localparam ADDR_CAP1         = 12'h024;  // Multiply/MAC capabilities
  localparam ADDR_CAP2         = 12'h028;  // Widening/narrowing capabilities
  localparam ADDR_CAP3         = 12'h02C;  // Reduction/mask/permute
  localparam ADDR_CAP4         = 12'h030;  // Custom LLM ops

  // 0x040-0x05F: Status (read-only, some write-to-clear)
  localparam ADDR_STATUS       = 12'h040;  // Current status
  localparam ADDR_ERR_INSTR    = 12'h044;  // Last illegal instruction (W1C)
  localparam ADDR_ERR_CNT      = 12'h048;  // Illegal instruction count (W1C)
  localparam ADDR_EXC_PENDING  = 12'h04C;  // Exception pending (W1C)

  // 0x060-0x07F: Performance counters (read-only, write-to-clear)
  localparam ADDR_PERF_CYCLES  = 12'h060;  // Active cycles
  localparam ADDR_PERF_INSTRS  = 12'h064;  // Instructions retired
  localparam ADDR_PERF_STALLS  = 12'h068;  // Stall cycles

  // 0x080-0x09F: Control (read/write)
  localparam ADDR_CTRL         = 12'h080;  // Control register
  localparam ADDR_EXC_CTRL     = 12'h084;  // Exception control

  //==========================================================================
  // Fixed Capability Values
  //==========================================================================
  // VPU_ID: [31:16]=vendor, [15:8]=major, [7:0]=minor
  localparam logic [31:0] VPU_ID_VALUE = 32'h4850_0006;  // "HP" + v0.5a

  // VPU_CONFIG: [31:16]=VLEN, [15:8]=NLANES, [7:0]=features
  localparam logic [31:0] VPU_CONFIG_VALUE = {16'(VLEN), 8'(NLANES), 8'h01};

  // CAP0: ALU/shift/logic
  // [0]=add/sub, [1]=logic, [2]=shift, [3]=min/max signed, [4]=min/max unsigned, [5]=merge/mv
  localparam logic [31:0] CAP0_VALUE = 32'h0000_003F;

  // CAP1: Multiply/MAC
  // [0]=vmul, [1]=vmulh*, [2]=vmacc/vmadd, [3]=vdiv (NOT), [4]=vrem (NOT)
  localparam logic [31:0] CAP1_VALUE = 32'h0000_0007;

  // CAP2: Widening/narrowing
  // [0]=vwadd/sub, [1]=vwmul, [2]=vwmacc, [3]=vnsrl/a, [4]=vnclip
  localparam logic [31:0] CAP2_VALUE = 32'h0000_001F;

  // CAP3: Reduction/mask/permute
  // [0]=vredsum/and/or/xor, [1]=vredmin/max, [2]=mask logical, [3]=mask ops,
  // [4]=vrgather/slide, [5]=vcompress (NOT), [6]=viota (NOT), [7]=vid
  localparam logic [31:0] CAP3_VALUE = 32'h0000_009F;

  // CAP4: Custom/fixed-point
  // [0]=vexp, [1]=vrecip, [2]=vrsqrt, [3]=vgelu, [4]=vpack4/unpack4,
  // [5]=vsadd/sub, [6]=vssrl/a, [7]=compare
  localparam logic [31:0] CAP4_VALUE = 32'h0000_00FF;

  //==========================================================================
  // Registers
  //==========================================================================
  // Status registers
  logic [31:0] err_instr_q;       // Last illegal instruction
  logic [31:0] err_cnt_q;         // Illegal instruction count
  logic        exc_pending_q;     // Exception pending flag

  // Performance counters
  logic [31:0] perf_cycles_q;     // Cycles counter
  logic [31:0] perf_stalls_q;     // Stall cycles counter

  // Control registers
  logic [31:0] ctrl_q;            // Control register
  logic [31:0] exc_ctrl_q;        // Exception control

  // Control bit extraction
  assign sw_reset_o    = ctrl_q[0];           // Bit 0: Software reset
  assign perf_cnt_en_o = ctrl_q[1];           // Bit 1: Perf counter enable
  assign exc_mode_o    = exc_ctrl_q[1:0];     // Bits [1:0]: Exception mode

  //==========================================================================
  // Register Read Logic
  //==========================================================================
  logic [31:0] rdata_mux;
  logic        addr_valid;

  always_comb begin
    rdata_mux = 32'h0;
    addr_valid = 1'b1;

    case (reg_addr_i)
      // Identification
      ADDR_VPU_ID:      rdata_mux = VPU_ID_VALUE;
      ADDR_VPU_CONFIG:  rdata_mux = VPU_CONFIG_VALUE;

      // Capabilities (read-only)
      ADDR_CAP0:        rdata_mux = CAP0_VALUE;
      ADDR_CAP1:        rdata_mux = CAP1_VALUE;
      ADDR_CAP2:        rdata_mux = CAP2_VALUE;
      ADDR_CAP3:        rdata_mux = CAP3_VALUE;
      ADDR_CAP4:        rdata_mux = CAP4_VALUE;

      // Status
      ADDR_STATUS:      rdata_mux = {30'b0, exc_pending_q, vpu_busy_i};
      ADDR_ERR_INSTR:   rdata_mux = err_instr_q;
      ADDR_ERR_CNT:     rdata_mux = err_cnt_q;
      ADDR_EXC_PENDING: rdata_mux = {31'b0, exc_pending_q};

      // Performance counters
      ADDR_PERF_CYCLES: rdata_mux = perf_cycles_q;
      ADDR_PERF_INSTRS: rdata_mux = instr_cnt_i;
      ADDR_PERF_STALLS: rdata_mux = perf_stalls_q;

      // Control
      ADDR_CTRL:        rdata_mux = ctrl_q;
      ADDR_EXC_CTRL:    rdata_mux = exc_ctrl_q;

      default: begin
        rdata_mux = 32'hDEAD_BEEF;
        addr_valid = 1'b0;
      end
    endcase
  end

  //==========================================================================
  // Register Write Logic
  //==========================================================================
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      err_instr_q   <= 32'h0;
      err_cnt_q     <= 32'h0;
      exc_pending_q <= 1'b0;
      perf_cycles_q <= 32'h0;
      perf_stalls_q <= 32'h0;
      ctrl_q        <= 32'h0000_0002;  // Default: perf counters enabled
      exc_ctrl_q    <= 32'h0000_0001;  // Default: flag mode (report but don't interrupt)
    end else begin
      //----------------------------------------------------------------------
      // Illegal instruction tracking
      //----------------------------------------------------------------------
      if (illegal_instr_i) begin
        err_instr_q <= illegal_instr_data_i;
        err_cnt_q   <= err_cnt_q + 1;
        // Set exception pending based on mode
        if (exc_ctrl_q[1:0] != 2'b00) begin
          exc_pending_q <= 1'b1;
        end
      end

      // Exception acknowledge clears pending
      if (exc_ack_i) begin
        exc_pending_q <= 1'b0;
      end

      //----------------------------------------------------------------------
      // Performance counters
      //----------------------------------------------------------------------
      if (ctrl_q[1]) begin  // perf_cnt_en
        perf_cycles_q <= perf_cycles_q + 1;
        if (stall_i) perf_stalls_q <= perf_stalls_q + 1;
      end

      //----------------------------------------------------------------------
      // Register writes
      //----------------------------------------------------------------------
      if (reg_req_i && reg_gnt_o && reg_we_i) begin
        case (reg_addr_i)
          // Write-to-clear registers
          ADDR_ERR_INSTR: begin
            if (reg_wdata_i == 32'hFFFF_FFFF) err_instr_q <= 32'h0;
          end
          ADDR_ERR_CNT: begin
            if (reg_wdata_i == 32'hFFFF_FFFF) err_cnt_q <= 32'h0;
          end
          ADDR_EXC_PENDING: begin
            if (reg_wdata_i[0]) exc_pending_q <= 1'b0;  // W1C
          end
          ADDR_PERF_CYCLES: begin
            if (reg_wdata_i == 32'hFFFF_FFFF) perf_cycles_q <= 32'h0;
          end
          ADDR_PERF_STALLS: begin
            if (reg_wdata_i == 32'hFFFF_FFFF) perf_stalls_q <= 32'h0;
          end

          // Control registers (normal write)
          ADDR_CTRL:     ctrl_q <= reg_wdata_i;
          ADDR_EXC_CTRL: exc_ctrl_q <= reg_wdata_i;

          default: ;  // Read-only or invalid - ignore writes
        endcase
      end

      // Auto-clear software reset after 1 cycle
      if (ctrl_q[0]) begin
        ctrl_q[0] <= 1'b0;
      end
    end
  end

  //==========================================================================
  // Interface Handshake
  //==========================================================================
  // Grant immediately (single-cycle access)
  assign reg_gnt_o = reg_req_i;

  // Read data valid one cycle after grant
  logic rvalid_q;
  logic error_q;
  logic [31:0] rdata_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rvalid_q <= 1'b0;
      error_q  <= 1'b0;
      rdata_q  <= 32'h0;
    end else begin
      rvalid_q <= reg_req_i && reg_gnt_o && !reg_we_i;
      error_q  <= reg_req_i && reg_gnt_o && !addr_valid;
      rdata_q  <= rdata_mux;
    end
  end

  assign reg_rdata_o  = rdata_q;
  assign reg_rvalid_o = rvalid_q;
  assign reg_error_o  = error_q;

  //==========================================================================
  // Exception Output
  //==========================================================================
  // Generate interrupt when pending and mode is interrupt (2'b10)
  assign exc_valid_o = exc_pending_q && (exc_ctrl_q[1:0] == 2'b10);
  assign exc_cause_o = err_instr_q;

endmodule
