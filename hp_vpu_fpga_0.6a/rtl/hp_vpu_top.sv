//==============================================================================
// Hyperplane VPU - Top Level (Phase 1: Arithmetic Only)
// Target: 2.0 GHz ASIC (8-stage pipeline)
// v0.5: DMA data interface, CV-X-IF commit, CSR enabled, byte enables
//==============================================================================


module hp_vpu_top
  import hp_vpu_pkg::*;
#(
  parameter int unsigned VLEN   = hp_vpu_pkg::VLEN,
  parameter int unsigned NLANES = hp_vpu_pkg::NLANES,
  parameter int unsigned ELEN   = hp_vpu_pkg::ELEN,
  parameter bit ENABLE_VMADD    = hp_vpu_pkg::ENABLE_VMADD,
  parameter bit ENABLE_CSR      = hp_vpu_pkg::ENABLE_CSR  // v0.3d: From JSON config
)(
  input  logic                      clk,
  input  logic                      rst_n,

  //==========================================================================
  // CV-X-IF Issue Interface (Scalar → VPU)
  //==========================================================================
  input  logic                      x_issue_valid_i,
  output logic                      x_issue_ready_o,
  output logic                      x_issue_accept_o,  // 1=supported, 0=unsupported (CPU should trap)
  input  logic [31:0]               x_issue_instr_i,
  input  logic [CVXIF_ID_W-1:0]     x_issue_id_i,
  input  logic [31:0]               x_issue_rs1_i,
  input  logic [31:0]               x_issue_rs2_i,

  //==========================================================================
  // CV-X-IF Result Interface (VPU → Scalar)
  //==========================================================================
  output logic                      x_result_valid_o,
  input  logic                      x_result_ready_i,
  output logic [CVXIF_ID_W-1:0]     x_result_id_o,
  output logic [31:0]               x_result_data_o,
  output logic                      x_result_we_o,

  //==========================================================================
  // Vector CSRs (RVV standard)
  //==========================================================================
  input  logic [31:0]               csr_vtype_i,
  input  logic [31:0]               csr_vl_i,

  // Vector CSR outputs (updated by vsetvl*)
  output logic [31:0]               csr_vtype_o,
  output logic [31:0]               csr_vl_o,
  output logic                      csr_vl_valid_o,

  //==========================================================================
  // v0.3d: VPU CSR Register Interface (memory-mapped)
  //==========================================================================
  input  logic                      csr_req_i,        // CSR read/write request
  output logic                      csr_gnt_o,        // Request granted
  input  logic                      csr_we_i,         // Write enable
  input  logic [11:0]               csr_addr_i,       // CSR address
  input  logic [31:0]               csr_wdata_i,      // Write data
  output logic [31:0]               csr_rdata_o,      // Read data
  output logic                      csr_rvalid_o,     // Read data valid
  output logic                      csr_error_o,      // Access error

  //==========================================================================
  // v0.3d: Exception/Interrupt Output
  //==========================================================================
  output logic                      exc_valid_o,      // Exception pending (illegal instruction)
  output logic [31:0]               exc_cause_o,      // The illegal instruction encoding
  input  logic                      exc_ack_i,        // Exception acknowledged

  //==========================================================================
  // DMA Data Interface (Primary data port for VRF fill/drain)
  // v0.5: Promoted from debug port to first-class DMA interface
  //==========================================================================
  input  logic                      dma_valid_i,      // Transaction request
  output logic                      dma_ready_o,      // Ready to accept
  input  logic                      dma_we_i,         // 1=write, 0=read
  input  logic [4:0]                dma_addr_i,       // VRF register address [0..31]
  input  logic [NLANES*64-1:0]      dma_wdata_i,      // Write data
  input  logic [NLANES*8-1:0]       dma_be_i,         // Byte enables for sub-register writes
  output logic                      dma_rvalid_o,     // Read response valid (2 cycles after accepted read)
  output logic [NLANES*64-1:0]      dma_rdata_o,      // Read data

  //==========================================================================
  // v0.5e: Weight Double-Buffer Control
  // Tie both to 0 for backward-compatible single-buffer operation
  //==========================================================================
  input  logic                      dma_dbuf_en_i,    // Enable weight double-buffering
  input  logic                      dma_dbuf_swap_i,  // Pulse to swap active/shadow weight banks

  //==========================================================================
  // CV-X-IF Commit Interface (Scalar → VPU)
  // v0.5: Minimal — accepts commits, errors on kill
  //==========================================================================
  input  logic                      x_commit_valid_i,
  input  logic [CVXIF_ID_W-1:0]    x_commit_id_i,
  input  logic                      x_commit_kill_i,

  //==========================================================================
  // Status
  //==========================================================================
  output logic                      busy_o,
  output logic [31:0]               perf_cnt_o
);

  localparam int unsigned DLEN = NLANES * 64;
  localparam int unsigned IQ_DEPTH = 4;        // Instruction queue depth
  localparam int unsigned VRF_ENTRIES = 32;    // Vector register file entries

  //==========================================================================
  // Pipeline Signals
  //==========================================================================

  // Instruction Queue
  logic                      iq_push, iq_pop, iq_full, iq_empty;
  logic [31:0]               iq_instr;
  logic [CVXIF_ID_W-1:0]     iq_id;
  logic [31:0]               iq_rs1, iq_rs2;

  // Decode (D2 output)
  logic                      d2_valid;
  logic                      d2_valid_op;    // v0.3c: Valid/supported operation
  vpu_op_e                   d2_op;
  logic [4:0]                d2_vd, d2_vs1, d2_vs2, d2_vs3;
  logic                      d2_vm;
  sew_e                      d2_sew;
  lmul_e                     d2_lmul;
  logic [31:0]               d2_scalar;
  logic [CVXIF_ID_W-1:0]     d2_id;
  logic                      d2_is_vx;

  // v1.2: LMUL micro-op support signals from decode
  logic                      dec_uop_busy;       // Decode busy with multi-µop sequence
  logic                      dec_is_last_uop;    // Last micro-op indicator
  logic [2:0]                dec_uop_index;      // Current micro-op index

  // v1.2a: Pipeline is_last_uop through OF for completion gating
  logic                      of_is_last_uop;
  logic                      e3_is_last_uop;     // From lanes

  // Operand Fetch (OF)
  logic                      of_valid;
  vpu_op_e                   of_op;
  logic [4:0]                of_vd;
  logic [DLEN-1:0]           of_vs1_data, of_vs2_data, of_vs3_data, of_vmask;
  logic [31:0]               of_scalar;
  sew_e                      of_sew;
  logic [CVXIF_ID_W-1:0]     of_id;
  logic                      of_is_vx;
  logic                      of_vm;  // vm=1 unmasked, vm=0 masked

  // Execute (E3 output)
  logic                      e3_valid;
  logic [DLEN-1:0]           e3_result;
  logic [4:0]                e3_vd;
  logic [CVXIF_ID_W-1:0]     e3_id;

  // Writeback
  logic                      wb_valid;
  logic [DLEN-1:0]           wb_data;
  logic [4:0]                wb_vd;
  logic                      wb_we;

  // Hazard control
  logic                      stall_iq, stall_dec, stall_exec, flush;

  //==========================================================================
  // vsetvl* Detection and Fast Path
  //==========================================================================
  // vsetvli: opcode=1010111, funct3=111, bit31=0
  // vsetivli: opcode=1010111, funct3=111, bit31=1, bit30=1
  // vsetvl: opcode=1010111, funct3=111, bit31=0, bit30=0 (and rs2 != x0)

  wire [6:0] issue_opcode = x_issue_instr_i[6:0];
  wire [2:0] issue_funct3 = x_issue_instr_i[14:12];
  wire issue_is_cfg = (issue_opcode == 7'b1010111) && (issue_funct3 == 3'b111);

  // v2.1d: MAC instruction detection at issue level for RAW hazard prevention
  // vmacc.vv:  funct6=101101, funct3=010, opcode=1010111
  // vnmsac.vv: funct6=101111, funct3=010, opcode=1010111
  // vmadd.vv:  funct6=101001, funct3=010, opcode=1010111
  // vnmsub.vv: funct6=101011, funct3=010, opcode=1010111
  wire [5:0] issue_funct6 = x_issue_instr_i[31:26];
  wire [4:0] issue_vd = x_issue_instr_i[11:7];
  wire issue_is_mac = (issue_opcode == 7'b1010111) && (issue_funct3 == 3'b010) &&
                      (issue_funct6 == 6'b101101 || issue_funct6 == 6'b101111 ||
                       issue_funct6 == 6'b101001 || issue_funct6 == 6'b101011);

  // Track which destination register has MAC in flight (bitmap for v0-v31)
  logic [31:0] mac_vd_in_flight;
  wire mac_conflict = issue_is_mac && mac_vd_in_flight[issue_vd];

  // Extract vtype from instruction (for vsetvli/vsetivli)
  // vsetvli: vtype in bits [30:20]
  // vsetivli: vtype in bits [29:20], bit30=1
  wire [10:0] vtype_imm = x_issue_instr_i[30:20];
  wire [2:0]  new_vsew  = vtype_imm[5:3];  // SEW encoding
  wire [2:0]  new_vlmul = vtype_imm[2:0];  // LMUL encoding

  // Compute VLMAX based on SEW, VLEN, and LMUL
  // VLMAX = (VLEN / SEW) * LMUL
  // v1.1: Support fractional LMUL (1/2, 1/4, 1/8)
  logic [31:0] vlmax_base;
  logic [31:0] vlmax;

  always_comb begin
    // Base VLMAX for LMUL=1
    case (new_vsew)
      3'b000:  vlmax_base = VLEN / 8;   // SEW=8
      3'b001:  vlmax_base = VLEN / 16;  // SEW=16
      3'b010:  vlmax_base = VLEN / 32;  // SEW=32
      3'b011:  vlmax_base = VLEN / 64;  // SEW=64 (not fully supported)
      default: vlmax_base = VLEN / 8;
    endcase

    // Apply LMUL scaling (v1.2: full LMUL>1 support via micro-ops)
    case (new_vlmul)
      3'b000:  vlmax = vlmax_base;       // LMUL=1
      3'b001:  vlmax = vlmax_base << 1;  // LMUL=2
      3'b010:  vlmax = vlmax_base << 2;  // LMUL=4
      3'b011:  vlmax = vlmax_base << 3;  // LMUL=8
      3'b111:  vlmax = vlmax_base >> 1;  // LMUL=1/2
      3'b110:  vlmax = vlmax_base >> 2;  // LMUL=1/4
      3'b101:  vlmax = vlmax_base >> 3;  // LMUL=1/8
      default: vlmax = vlmax_base;       // Reserved
    endcase
  end

  // AVL comes from rs1 (or immediate for vsetivli)
  wire [31:0] avl = x_issue_rs1_i;

  // Compute new VL = min(AVL, VLMAX)
  // Special case: if rs1=x0 (avl=0), set vl=vlmax (set maximum)
  wire [31:0] new_vl = (avl == 0) ? vlmax :
                       (avl > vlmax) ? vlmax : avl;

  // vsetvl* fast-path result
  logic        cfg_result_valid;
  logic [31:0] cfg_result_vl;
  logic [31:0] cfg_result_vtype;
  logic [CVXIF_ID_W-1:0] cfg_result_id;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cfg_result_valid <= 1'b0;
      cfg_result_vl    <= '0;
      cfg_result_vtype <= '0;
      cfg_result_id    <= '0;
    end else begin
      if (x_issue_valid_i && x_issue_ready_o && issue_is_cfg) begin
        cfg_result_valid <= 1'b1;
        cfg_result_vl    <= new_vl;
        cfg_result_vtype <= {21'b0, vtype_imm};
        cfg_result_id    <= x_issue_id_i;
      end else if (x_result_ready_i) begin
        cfg_result_valid <= 1'b0;
      end
    end
  end

  // Internal vtype/vl registers (updated by vsetvl*)
  logic [31:0] int_vtype, int_vl;
  logic        vsetvl_done;  // Set after first vsetvl* instruction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      int_vtype   <= 32'h0000_0000;  // Default: SEW=8, LMUL=1
      int_vl      <= VLEN / 8;       // Default: VLMAX at SEW=8
      vsetvl_done <= 1'b0;
    end else if (x_issue_valid_i && x_issue_ready_o && issue_is_cfg) begin
      int_vtype   <= {21'b0, vtype_imm};
      int_vl      <= new_vl;
      vsetvl_done <= 1'b1;
    end
  end

  // Use external CSRs until first vsetvl*, then use internal
  wire [31:0] active_vtype = vsetvl_done ? int_vtype : csr_vtype_i;
  wire [31:0] active_vl    = vsetvl_done ? int_vl    : csr_vl_i;

  // Output CSR values
  assign csr_vtype_o = int_vtype;
  assign csr_vl_o = int_vl;
  assign csr_vl_valid_o = cfg_result_valid;

  //==========================================================================
  // Instruction Queue
  //==========================================================================
  // Don't push vsetvl* to IQ - they complete immediately
  assign iq_push = x_issue_valid_i && x_issue_ready_o && !issue_is_cfg;
  // v1.2: Stall during multi-µop sequence, but allow config instructions through
  // v2.1d: Also stall when MAC conflict detected (same vd has MAC in flight)
  assign x_issue_ready_o = !iq_full && !stall_iq && (!dec_uop_busy || issue_is_cfg) && !mac_conflict;

  //==========================================================================
  // v0.3d: Issue Stage Instruction Checker
  //==========================================================================
  // Fast combinational check BEFORE accepting instruction
  // This allows proper CV-X-IF reject for unsupported instructions
  wire issue_is_vector;
  wire issue_is_supported;
  wire issue_check_is_cfg;  // From checker (same as issue_is_cfg above)

  hp_vpu_issue_check u_issue_check (
    .instr_i        (x_issue_instr_i),
    .is_vector_o    (issue_is_vector),
    .is_supported_o (issue_is_supported),
    .is_config_o    (issue_check_is_cfg)  // Not used - issue_is_cfg already defined
  );

  // Accept only if it's a vector instruction AND supported
  // If is_vector but NOT supported, reject so CPU can trap
  assign x_issue_accept_o = issue_is_vector && issue_is_supported;

  // Track illegal instruction attempts (when vector but not supported)
  wire illegal_instr_attempt = x_issue_valid_i && issue_is_vector && !issue_is_supported;

  //==========================================================================
  // v0.3d: CSR Module (Optional - controlled by ENABLE_CSR parameter)
  //==========================================================================
  // Provides capability discovery, status, error tracking, control
  // Can be disabled to save ~500 cells on resource-constrained FPGAs
  wire        csr_sw_reset;
  wire        csr_perf_cnt_en;
  wire [1:0]  csr_exc_mode;

  generate
    if (ENABLE_CSR) begin : gen_csr
      hp_vpu_csr #(
        .VLEN   (VLEN),
        .NLANES (NLANES)
      ) u_csr (
        .clk                  (clk),
        .rst_n                (rst_n),
        // Register interface
        .reg_req_i            (csr_req_i),
        .reg_gnt_o            (csr_gnt_o),
        .reg_we_i             (csr_we_i),
        .reg_addr_i           (csr_addr_i),
        .reg_wdata_i          (csr_wdata_i),
        .reg_be_i             (4'hF),           // Full word access
        .reg_rdata_o          (csr_rdata_o),
        .reg_rvalid_o         (csr_rvalid_o),
        .reg_error_o          (csr_error_o),
        // Status inputs
        .illegal_instr_i      (illegal_instr_attempt),
        .illegal_instr_data_i (x_issue_instr_i),
        .vpu_busy_i           (busy_o),
        .instr_cnt_i          (perf_cnt_o),
        .stall_i              (stall_exec || mac_stall || mul_stall),
        // Control outputs
        .sw_reset_o           (csr_sw_reset),
        .perf_cnt_en_o        (csr_perf_cnt_en),
        .exc_mode_o           (csr_exc_mode),
        // Exception output
        .exc_valid_o          (exc_valid_o),
        .exc_cause_o          (exc_cause_o),
        .exc_ack_i            (exc_ack_i)
      );
    end else begin : gen_no_csr
      // CSR disabled - tie off outputs with sensible defaults
      assign csr_gnt_o      = csr_req_i;  // Always grant (but ignore)
      assign csr_rdata_o    = 32'h0;
      assign csr_rvalid_o   = 1'b0;
      assign csr_error_o    = csr_req_i;  // Always error (CSR not present)
      assign csr_sw_reset   = 1'b0;
      assign csr_perf_cnt_en = 1'b1;      // Default: counters enabled
      assign csr_exc_mode   = 2'b00;      // Default: ignore exceptions
      assign exc_valid_o    = 1'b0;
      assign exc_cause_o    = 32'h0;
    end
  endgenerate

  hp_vpu_iq #(
    .DEPTH  (IQ_DEPTH),
    .ID_W   (CVXIF_ID_W)
  ) u_iq (
    .clk      (clk),
    .rst_n    (rst_n),
    .push_i   (iq_push),
    .instr_i  (x_issue_instr_i),
    .id_i     (x_issue_id_i),
    .rs1_i    (x_issue_rs1_i),
    .rs2_i    (x_issue_rs2_i),
    .pop_i    (iq_pop),
    .instr_o  (iq_instr),
    .id_o     (iq_id),
    .rs1_o    (iq_rs1),
    .rs2_o    (iq_rs2),
    .full_o   (iq_full),
    .empty_o  (iq_empty)
  );

  //==========================================================================
  // Decode Unit
  //==========================================================================
  // Multicycle execute signals (v0.13+)
  logic                      d2_is_multicycle;
  logic [2:0]                d2_multicycle_count;

  hp_vpu_decode #(
    .VLEN (VLEN)
  ) u_decode (
    .clk        (clk),
    .rst_n      (rst_n),
    .stall_i    (stall_dec),
    .flush_i    (flush),
    .valid_i    (!iq_empty),
    .instr_i    (iq_instr),
    .id_i       (iq_id),
    .rs1_i      (iq_rs1),
    .rs2_i      (iq_rs2),
    .vtype_i    (active_vtype),  // Use active vtype (external or internal)
    .vl_i       (active_vl),     // Use active vl (external or internal)
    .valid_o    (d2_valid),
    .valid_op_o (d2_valid_op),   // v0.3c: Valid/supported operation flag
    .op_o       (d2_op),
    .vd_o       (d2_vd),
    .vs1_o      (d2_vs1),
    .vs2_o      (d2_vs2),
    .vs3_o      (d2_vs3),
    .vm_o       (d2_vm),
    .sew_o      (d2_sew),
    .lmul_o     (d2_lmul),
    .scalar_o   (d2_scalar),
    .id_o       (d2_id),
    .is_load_o  (),  // Unused in Phase 1
    .is_store_o (),
    .is_vx_o    (d2_is_vx),
    .pop_iq_o   (iq_pop),
    .is_multicycle_o    (d2_is_multicycle),
    .multicycle_count_o (d2_multicycle_count),
    // v1.2: LMUL micro-op outputs
    .is_last_uop_o  (dec_is_last_uop),
    .uop_index_o    (dec_uop_index),
    .uop_busy_o     (dec_uop_busy)
  );

  //==========================================================================
  // Vector Register File
  //==========================================================================
  // v0.6: Fully separated write ports
  //   Port 1: compute pipeline WB only (never contested by DMA)
  //   Port 2: all DMA writes (base, shadow, active — routed inside VRF)

  // v0.5: DMA interface control
  logic                dma_wr_accept;  // DMA write accepted this cycle
  logic                dma_rd_accept;  // DMA read accepted this cycle

  assign dma_wr_accept = dma_valid_i && dma_ready_o && dma_we_i;
  assign dma_rd_accept = dma_valid_i && dma_ready_o && !dma_we_i;
  assign dma_ready_o   = 1'b1;  // Always ready (DMA has its own port)

  // v0.5e: Weight double-buffer bank selection
  logic weight_bank_sel;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      weight_bank_sel <= 1'b0;
    else if (dma_dbuf_swap_i)
      weight_bank_sel <= ~weight_bank_sel;
  end

  // v0.6: DMA read path — 2-cycle latency
  //   Cycle 0: address presented, VRF starts registered read
  //   Cycle 1: VRF output valid (BRAM output register)
  //   Cycle 2: top captures data, dma_rvalid_o asserts
  logic [DLEN-1:0]    dma_rdata_from_vrf;  // Registered output from VRF
  logic               dma_rd_pipe;         // Pipeline stage for rvalid

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dma_rd_pipe  <= 1'b0;
      dma_rvalid_o <= 1'b0;
      dma_rdata_o  <= '0;
    end else begin
      dma_rd_pipe  <= dma_rd_accept;       // Stage 1: VRF read in progress
      dma_rvalid_o <= dma_rd_pipe;         // Stage 2: data ready
      if (dma_rd_pipe)
        dma_rdata_o <= dma_rdata_from_vrf; // Capture when data valid
    end
  end

  hp_vpu_vrf #(
    .VLEN   (VLEN),
    .NLANES (NLANES),
    .NREGS  (VRF_ENTRIES)
  ) u_vrf (
    .clk      (clk),
    .rst_n    (rst_n),
    // Read
    .rd_en_i  (d2_valid && !stall_dec),
    .vs1_i    (d2_vs1),
    .vs2_i    (d2_vs2),
    .vs3_i    (d2_vd),  // Read old_vd for vmacc accumulator and masked ops
    .vm_i     (5'd0),   // Always read v0 for mask
    .vs1_o    (of_vs1_data),
    .vs2_o    (of_vs2_data),
    .vs3_o    (of_vs3_data),  // Contains old_vd value
    .vm_o     (of_vmask),
    // Write port 1: compute WB only (v0.5f)
    .wr_en_i  (wb_we),
    .vd_i     (wb_vd),
    .wd_i     (wb_data),
    .wr_be_i  ({(DLEN/8){1'b1}}),  // Pipeline always full-word
    // Write port 2: all DMA writes (v0.5f)
    .dma_wr_en_i   (dma_wr_accept),
    .dma_wr_addr_i (dma_addr_i),
    .dma_wr_data_i (dma_wdata_i),
    .dma_wr_be_i   (dma_be_i),
    // Weight bank control (v0.5e/f)
    .weight_bank_sel_i (weight_bank_sel),
    .dma_dbuf_en_i     (dma_dbuf_en_i),
    // DMA read (combinational, registered in top for timing)
    .mem_rd_addr_i (dma_addr_i),
    .mem_rd_data_o (dma_rdata_from_vrf)
  );

  //==========================================================================
  // Operand Fetch Pipeline Register (D2 → OF)
  // Key: when D2 stalls but lanes don't, OF is consumed and must clear
  //==========================================================================
  // Multicycle signals (v0.13+)
  logic        of_is_multicycle;
  logic [2:0]  of_multicycle_count;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      of_valid  <= 1'b0;
      of_op     <= OP_NOP;
      of_vd     <= '0;
      of_scalar <= '0;
      of_sew    <= SEW_8;
      of_id     <= '0;
      of_is_vx  <= 1'b0;
      of_vm     <= 1'b1;  // Default unmasked
      of_is_multicycle    <= 1'b0;
      of_multicycle_count <= '0;
      of_is_last_uop      <= 1'b1;  // v1.2a: Default to last (single µop)
    end else if (flush) begin
      of_valid <= 1'b0;
      of_is_multicycle <= 1'b0;
      of_is_last_uop   <= 1'b1;
    end else if (!stall_dec) begin
      // D2 advancing normally
      of_valid  <= d2_valid;
      of_op     <= d2_op;
      of_vd     <= d2_vd;
      of_scalar <= d2_scalar;
      of_sew    <= d2_sew;
      of_id     <= d2_id;
      of_is_vx  <= d2_is_vx;
      of_vm     <= d2_vm;  // vm=1 unmasked, vm=0 masked
      of_is_multicycle    <= d2_is_multicycle;
      of_multicycle_count <= d2_multicycle_count;
      of_is_last_uop      <= dec_is_last_uop;  // v1.2a: Track last µop

      // DEBUG: Trace specific IDs through decode
      `ifdef SIMULATION
      if (d2_valid && (d2_id == 32 || d2_id == 92))
        $display("[%0t] OF_CAPTURE: vd=%0d id=%0d op=%0d", $time, d2_vd, d2_id, d2_op);
      `endif

    end else if (!stall_exec && of_valid && !mac_stall && !drain_stall &&
                 !mul_stall) begin
      // D2 stalled but lanes consumed OF - clear valid to prevent double-exec
      // v1.6b: Don't clear if mac_stall - lanes didn't consume OF, just frozen
      // v1.7: Don't clear if mul_stall - lanes didn't consume OF due to E1m busy
      // v1.7: Don't clear if drain_stall - lanes waiting for pipeline drain before multicycle op
      // v1.9 FIX: ALSO clear if e1_handoff_capture - E1 captured from OF during multiply handoff
      //           even though mul_stall was high (is_mul_op_e1 was true)
      of_valid <= 1'b0;
    end
  end

  //==========================================================================
  // Vector Lanes
  //==========================================================================
  logic [31:0] e3_mask;
  logic        e3_mask_valid;

  // Hazard detection signals from lanes
  logic        e1_valid, e2_valid;
  logic [4:0]  e1_vd, e2_vd;
  // v0.5b: Separate E1m hazard signals
  logic        e1m_valid_haz;
  logic [4:0]  e1m_vd_haz;
  logic        r2a_valid, r2b_valid;
  logic [4:0]  r2a_vd, r2b_vd;

  // Multicycle busy signal from lanes (v0.13+)
  logic        multicycle_busy;
  logic        mac_stall;  // v1.6b: MAC stall for OF clearing logic
  logic        mul_stall;  // v1.7: E1m stall for OF clearing logic
  logic        e1_handoff_capture;  // v1.9: E1 captured from OF during multiply handoff
  logic        drain_stall;  // v1.7: Waiting for pipeline drain

  hp_vpu_lanes #(
    .NLANES      (NLANES),
    .ELEN        (ELEN),
    .ENABLE_VMADD(ENABLE_VMADD)
  ) u_lanes (
    .clk          (clk),
    .rst_n        (rst_n),
    .stall_i      (stall_exec),
    .valid_i      (of_valid),
    .op_i         (of_op),
    .vs1_i        (of_vs1_data),
    .vs2_i        (of_vs2_data),
    .vs3_i        (of_vs3_data),  // old_vd for masking/vmacc
    .vmask_i      (of_vmask),
    .vm_i         (of_vm),        // vm=1 unmasked, vm=0 masked
    .scalar_i     (of_scalar),
    .is_vx_i      (of_is_vx),
    .sew_i        (of_sew),
    .vd_i         (of_vd),
    .id_i         (of_id),
    // Multicycle control (v0.13+)
    .is_multicycle_i    (of_is_multicycle),
    .multicycle_count_i (of_multicycle_count),
    // v1.2a: LMUL micro-op tracking
    .is_last_uop_i      (of_is_last_uop),
    // Outputs
    .valid_o      (e3_valid),
    .result_o     (e3_result),
    .mask_o       (e3_mask),
    .mask_valid_o (e3_mask_valid),
    .vd_o         (e3_vd),
    .id_o         (e3_id),
    // v1.2a: LMUL micro-op tracking output
    .is_last_uop_o      (e3_is_last_uop),
    // Multicycle busy (v0.13+)
    .multicycle_busy_o (multicycle_busy),
    .mac_stall_o       (mac_stall),  // v1.6b: MAC stall
    .mul_stall_o       (mul_stall),  // v1.7: E1m stall
    .e1_handoff_capture_o (e1_handoff_capture),  // v1.9: E1 captured during handoff
    .drain_stall_o     (drain_stall),  // v1.7: Pipeline drain stall
    // Hazard detection outputs
    .e1_valid_o   (e1_valid),
    .e1_vd_o      (e1_vd),
    // v0.5b: Separate E1m hazard outputs
    .e1m_valid_o  (e1m_valid_haz),
    .e1m_vd_o     (e1m_vd_haz),
    .e2_valid_o   (e2_valid),
    .e2_vd_o      (e2_vd),
    .r2a_valid_o  (r2a_valid),
    .r2a_vd_o     (r2a_vd),
    .r2b_valid_o  (r2b_valid),
    .r2b_vd_o     (r2b_vd)
  );

  //==========================================================================
  // Writeback
  // For comparison ops, write mask to v0; else write result to vd
  //==========================================================================
  logic e3_mask_valid_q;
  logic [31:0] e3_mask_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wb_valid <= 1'b0;
      wb_data  <= '0;
      wb_vd    <= '0;
      wb_we    <= 1'b0;
      e3_mask_valid_q <= 1'b0;
      e3_mask_q <= '0;
    end else begin
      wb_valid <= e3_valid;
      wb_we    <= e3_valid;
      e3_mask_valid_q <= e3_mask_valid;
      e3_mask_q <= e3_mask;

      if (e3_mask_valid) begin
        // Comparison result: write mask to v0
        wb_vd   <= 5'd0;
        wb_data <= {{(DLEN-32){1'b0}}, e3_mask};
      end else begin
        // Normal result: write to vd
        wb_vd   <= e3_vd;
        wb_data <= e3_result;
      end
    end
  end

  //==========================================================================
  // v2.1d: MAC Destination In-Flight Tracking
  // Prevent RAW hazards by not accepting a MAC if the same vd has MAC in flight
  //==========================================================================
  // Set bit when MAC is issued, clear when ANY writeback to that vd
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mac_vd_in_flight <= '0;
    end else begin
      // Clear on writeback (any writeback, not just MAC - conservative but correct)
      if (wb_we) begin
        mac_vd_in_flight[wb_vd] <= 1'b0;
      end
      // Set when MAC is accepted into pipeline (after clear, so set takes priority)
      if (iq_push && issue_is_mac) begin
        mac_vd_in_flight[issue_vd] <= 1'b1;
      end
    end
  end

  //==========================================================================
  // Hazard Unit - Extended to check OF, E1, E2, E3, WB stages
  // v0.13: Added multicycle execute support
  //==========================================================================
  hp_vpu_hazard u_hazard (
    .clk          (clk),
    .rst_n        (rst_n),
    // Decode stage
    .d_valid_i    (d2_valid),
    .d_vd_i       (d2_vd),
    .d_vs1_i      (d2_vs1),
    .d_vs2_i      (d2_vs2),
    .d_vs3_i      (d2_vs3),     // Accumulator source for MAC ops
    // Operand Fetch stage
    .of_valid_i   (of_valid),
    .of_vd_i      (of_vd),
    // Execute stages
    .e1_valid_i   (e1_valid),
    .e1_vd_i      (e1_vd),
    // v0.5b: Separate E1m hazard inputs
    .e1m_valid_i  (e1m_valid_haz),
    .e1m_vd_i     (e1m_vd_haz),
    .e2_valid_i   (e2_valid),
    .e2_vd_i      (e2_vd),
    .r2a_valid_i  (r2a_valid),
    .r2a_vd_i     (r2a_vd),
    .r2b_valid_i  (r2b_valid),
    .r2b_vd_i     (r2b_vd),
    .e3_valid_i   (e3_valid),
    .e3_vd_i      (e3_vd),
    // Memory (unused)
    .m2_valid_i   (1'b0),
    .m2_vd_i      (5'd0),
    // Writeback
    .w_valid_i    (wb_valid),
    .w_vd_i       (wb_vd),
    // Control
    .sram_stall_i (1'b0),
    .multicycle_busy_i (multicycle_busy),  // v0.13: Stall on reduction pipeline
    .kill_i       (1'b0),
    // Outputs
    .stall_iq_o   (stall_iq),
    .stall_dec_o  (stall_dec),
    .stall_exec_o (stall_exec),
    .flush_o      (flush)
  );

  //==========================================================================
  // Result Interface
  // v1.2a: Only signal completion on LAST micro-op for LMUL>1 instructions
  //==========================================================================
  logic [CVXIF_ID_W-1:0] result_id_q;
  logic                  result_valid_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      result_valid_q <= 1'b0;
      result_id_q    <= '0;
    end else begin
      // v1.2a: Only signal completion on last micro-op
      if (e3_valid && e3_is_last_uop) begin
        result_valid_q <= 1'b1;
        result_id_q    <= e3_id;
      end else if (x_result_ready_i) begin
        result_valid_q <= 1'b0;
      end
    end
  end

  // Mux between vsetvl* fast-path and normal execution results
  // vsetvl* has priority since it completes faster
  assign x_result_valid_o = cfg_result_valid | result_valid_q;
  assign x_result_id_o    = cfg_result_valid ? cfg_result_id : result_id_q;
  assign x_result_data_o  = cfg_result_valid ? cfg_result_vl : e3_result[31:0];
  assign x_result_we_o    = cfg_result_valid;  // Write rd only for vsetvl*

  //==========================================================================
  // Status - Track in-flight instructions
  //==========================================================================
  logic [3:0] inflight_cnt;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      inflight_cnt <= '0;
    else begin
      case ({iq_push, wb_we})
        2'b10: inflight_cnt <= inflight_cnt + 1;  // New instruction
        2'b01: inflight_cnt <= inflight_cnt - 1;  // Completed
        default: inflight_cnt <= inflight_cnt;    // Both or neither
      endcase
    end
  end

  assign busy_o = (inflight_cnt != 0) || !iq_empty || d2_valid || of_valid || e3_valid || wb_valid;

  logic [31:0] perf_cnt_q;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      perf_cnt_q <= '0;
    else if (wb_valid)
      perf_cnt_q <= perf_cnt_q + 1;
  end
  assign perf_cnt_o = perf_cnt_q;

  //==========================================================================
  // v0.5: CV-X-IF Commit Handler (Minimal)
  // In-order commit assumed. Kill should never fire for vector instructions
  // in CV32E40X (no speculative vector issue). Flag as error if it does.
  //==========================================================================
  logic commit_kill_error_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      commit_kill_error_q <= 1'b0;
    end else if (x_commit_valid_i && x_commit_kill_i) begin
      commit_kill_error_q <= 1'b1;
      `ifdef SIMULATION
      $display("[%0t] VPU ERROR: Commit kill received for id=%0d — not supported",
               $time, x_commit_id_i);
      `endif
    end
  end

endmodule
