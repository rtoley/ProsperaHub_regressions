//==============================================================================
// FPGA VPU Self-Checking Test Top
// Target: Arty A7-100T @ 100 MHz
//
// This is a fully synthesizable self-checking test that:
// 1. Loads test vectors into VRF via DMA interface
// 2. Issues vsetvli + compute instructions via CV-X-IF
// 3. Waits for completion
// 4. Reads back results via DMA interface
// 5. Compares against golden values
// 6. Outputs PASS/FAIL on LEDs
//
// Tests (10 total):
//   Test 0: vadd.vv  - vector add
//   Test 1: vmul.vv  - vector multiply
//   Test 2: vredsum  - reduction sum (dot product)
//   Test 3: vand.vv  - vector AND
//   Test 4: vsub.vv  - vector subtract
//   Test 5: vor.vv   - vector OR
//   Test 6: vxor.vv  - vector XOR
//   Test 7: vmin.vv  - vector signed minimum
//   Test 8: vmax.vv  - vector signed maximum
//   Test 9: vminu.vv - vector unsigned minimum
//==============================================================================

module fpga_vpu_test_top
  import hp_vpu_pkg::*;
(
  input  logic        clk_100mhz,   // 100 MHz from Arty oscillator
  input  logic        btn0,         // Reset (active high from BTN0)
  output logic [3:0]  led           // Status LEDs
);

  //==========================================================================
  // Parameters
  //==========================================================================
  localparam int unsigned VLEN   = hp_vpu_pkg::VLEN;    // 64 for Arty7
  localparam int unsigned NLANES = hp_vpu_pkg::NLANES;  // 1 for Arty7
  localparam int unsigned DLEN   = NLANES * 64;         // 64 bits

  localparam int unsigned NUM_TESTS = 10;  // Number of tests to run

  //==========================================================================
  // Clock and Reset
  //==========================================================================
  logic clk;
  logic rst_n;

  assign clk   = clk_100mhz;
  assign rst_n = ~btn0;  // btn0 active high -> active low reset

  //==========================================================================
  // VPU Interface Signals
  //==========================================================================
  // CV-X-IF Issue
  logic                      x_issue_valid;
  logic                      x_issue_ready;
  logic [31:0]               x_issue_instr;
  logic [CVXIF_ID_W-1:0]     x_issue_id;
  logic [31:0]               x_issue_rs1;
  logic [31:0]               x_issue_rs2;

  // CV-X-IF Result
  logic                      x_result_valid;
  logic                      x_result_ready;
  logic [CVXIF_ID_W-1:0]     x_result_id;
  logic [31:0]               x_result_data;
  logic                      x_result_we;

  // CSRs (used until first vsetvli)
  logic [31:0]               csr_vtype;
  logic [31:0]               csr_vl;
  logic [31:0]               csr_vtype_out;
  logic [31:0]               csr_vl_out;
  logic                      csr_vl_valid;

  // DMA data interface (v0.5)
  logic                      dma_valid;
  logic                      dma_ready;
  logic                      dma_we;
  logic [4:0]                dma_addr;
  logic [DLEN-1:0]           dma_wdata;
  logic [DLEN/8-1:0]         dma_be;
  logic                      dma_rvalid;
  logic [DLEN-1:0]           dma_rdata;

  // Status
  logic                      vpu_busy;
  logic [31:0]               perf_cnt;

  //==========================================================================
  // Test Sequencer FSM
  //==========================================================================
  typedef enum logic [4:0] {
    ST_RESET,
    ST_LOAD_V1,           // Load vector A into v1
    ST_LOAD_V2,           // Load vector B into v2
    ST_LOAD_V3,           // Load/clear v3 (for accumulator or result)
    ST_ISSUE_VSETVLI,     // Configure SEW=8, LMUL=1
    ST_WAIT_VSETVLI,      // Wait for vsetvli completion
    ST_ISSUE_OP,          // Issue test operation
    ST_WAIT_OP,           // Wait for operation completion
    ST_ISSUE_OP2,         // Issue second operation (for multi-op tests)
    ST_WAIT_OP2,          // Wait for second operation
    ST_WAIT_DONE,         // Wait for VPU not busy
    ST_READ_RESULT,       // Read result register (cycle 0: present address)
    ST_LATCH_RESULT,      // DMA read cycle 1 (BRAM output register)
    ST_WAIT_RDATA,        // DMA read cycle 2 (rvalid + rdata available)
    ST_CHECK_RESULT,      // Compare against golden
    ST_NEXT_TEST,         // Advance to next test
    ST_PASS,              // All tests passed
    ST_FAIL               // Test failed
  } state_e;

  state_e state, next_state;

  //==========================================================================
  // Test Vectors (hardcoded - minimal footprint)
  //==========================================================================
  // Vector A: [1, 2, 3, 4, 5, 6, 7, 8] (8 INT8 elements, little endian)
  localparam logic [63:0] VEC_A = 64'h0807060504030201;

  // Vector B: [1, 1, 1, 1, 1, 1, 1, 1]
  localparam logic [63:0] VEC_B = 64'h0101010101010101;

  // Vector C: [0xFF, 0x0F, 0xF0, 0xAA, 0x55, 0xCC, 0x33, 0x99]
  localparam logic [63:0] VEC_C = 64'h9933CC55AAF00FFF;

  //==========================================================================
  // Golden Results for Each Test
  //==========================================================================
  // Test 0: vadd.vv v3, v1, v2 -> [2,3,4,5,6,7,8,9]
  localparam logic [63:0] GOLDEN_VADD = 64'h0908070605040302;

  // Test 1: vmul.vv v4, v1, v2 -> [1,2,3,4,5,6,7,8] (same as A since B=1s)
  localparam logic [63:0] GOLDEN_VMUL = 64'h0807060504030201;

  // Test 2: vredsum.vs (dot product A·B) -> sum([1..8]) = 36 = 0x24
  localparam logic [7:0]  GOLDEN_REDSUM = 8'h24;

  // Test 3: vand.vv v3, v1, v2 -> A & B elementwise
  // 0x08 & 0x01 = 0x00, 0x07 & 0x01 = 0x01, etc.
  // Result: 0x0001000100010001 (every other byte has bit 0 set)
  localparam logic [63:0] GOLDEN_VAND = 64'h0001000100010001;

  // Test 4: vsub.vv v3, v1, v2 -> vs2 - vs1 = B - A
  // B=[1,1,1,1,1,1,1,1], A=[1,2,3,4,5,6,7,8]
  // Result: [0,-1,-2,-3,-4,-5,-6,-7] = [0x00,0xFF,0xFE,0xFD,0xFC,0xFB,0xFA,0xF9]
  localparam logic [63:0] GOLDEN_VSUB = 64'hF9FAFBFCFDFEFF00;

  // Test 5: vor.vv v3, v1, v2 -> A | B elementwise
  // [1|1, 2|1, 3|1, 4|1, 5|1, 6|1, 7|1, 8|1] = [1,3,3,5,5,7,7,9]
  localparam logic [63:0] GOLDEN_VOR = 64'h0907070505030301;

  // Test 6: vxor.vv v3, v1, v2 -> A ^ B elementwise
  // [1^1, 2^1, 3^1, 4^1, 5^1, 6^1, 7^1, 8^1] = [0,3,2,5,4,7,6,9]
  localparam logic [63:0] GOLDEN_VXOR = 64'h0906070405020300;

  // Test 7: vmin.vv v3, v1, v2 (signed) -> min(A, B) per element
  // min([1,2,3,4,5,6,7,8], [1,1,1,1,1,1,1,1]) = [1,1,1,1,1,1,1,1]
  localparam logic [63:0] GOLDEN_VMIN = 64'h0101010101010101;

  // Test 8: vmax.vv v3, v1, v2 (signed) -> max(A, B) per element
  // max([1,2,3,4,5,6,7,8], [1,1,1,1,1,1,1,1]) = [1,2,3,4,5,6,7,8]
  localparam logic [63:0] GOLDEN_VMAX = 64'h0807060504030201;

  // Test 9: vminu.vv v3, v1, v2 (unsigned) -> same as vmin for positive values
  localparam logic [63:0] GOLDEN_VMINU = 64'h0101010101010101;

  //==========================================================================
  // Instruction Encodings (RVV 1.0)
  //==========================================================================
  // vsetvli x0, x0, e8, m1, ta, ma
  localparam logic [31:0] INSTR_VSETVLI = 32'b0_00000000_000_00000_111_00000_1010111;

  // vadd.vv v3, v1, v2 : funct6=000000, vm=1, vs2=2, vs1=1, funct3=000, vd=3
  localparam logic [31:0] INSTR_VADD = {6'b000000, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111};

  // vmul.vv v4, v1, v2 : funct6=100101, vm=1, vs2=2, vs1=1, funct3=010, vd=4
  localparam logic [31:0] INSTR_VMUL = {6'b100101, 1'b1, 5'd2, 5'd1, 3'b010, 5'd4, 7'b1010111};

  // vredsum.vs v3, v4, v3 : funct6=000000, vm=1, vs2=4, vs1=3, funct3=010, vd=3
  localparam logic [31:0] INSTR_VREDSUM = {6'b000000, 1'b1, 5'd4, 5'd3, 3'b010, 5'd3, 7'b1010111};

  // vand.vv v3, v1, v2 : funct6=001001, vm=1, vs2=2, vs1=1, funct3=000, vd=3
  localparam logic [31:0] INSTR_VAND = {6'b001001, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111};

  // vsub.vv v3, v1, v2 : funct6=000010, vm=1, vs2=2, vs1=1, funct3=000, vd=3
  localparam logic [31:0] INSTR_VSUB = {6'b000010, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111};

  // vor.vv v3, v1, v2 : funct6=001010, vm=1, vs2=2, vs1=1, funct3=000, vd=3
  localparam logic [31:0] INSTR_VOR = {6'b001010, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111};

  // vxor.vv v3, v1, v2 : funct6=001011, vm=1, vs2=2, vs1=1, funct3=000, vd=3
  localparam logic [31:0] INSTR_VXOR = {6'b001011, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111};

  // vmin.vv v3, v1, v2 : funct6=000101, vm=1, vs2=2, vs1=1, funct3=000, vd=3
  localparam logic [31:0] INSTR_VMIN = {6'b000101, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111};

  // vmax.vv v3, v1, v2 : funct6=000111, vm=1, vs2=2, vs1=1, funct3=000, vd=3
  localparam logic [31:0] INSTR_VMAX = {6'b000111, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111};

  // vminu.vv v3, v1, v2 : funct6=000100, vm=1, vs2=2, vs1=1, funct3=000, vd=3
  localparam logic [31:0] INSTR_VMINU = {6'b000100, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111};

  //==========================================================================
  // Test Control Registers
  //==========================================================================
  logic [7:0]      instr_id;
  logic [DLEN-1:0] result_reg;
  logic [15:0]     timeout_cnt;
  logic [3:0]      test_num;        // Current test number (0-9)
  logic [3:0]      tests_passed;    // Count of passed tests

  // Current test parameters (selected by test_num)
  logic [31:0]     cur_instr;       // Current instruction to issue
  logic [31:0]     cur_instr2;      // Second instruction (for multi-op tests)
  logic            cur_needs_op2;   // Does this test need a second operation?
  logic [63:0]     cur_golden;      // Golden result for comparison
  logic            cur_is_reduction; // Is result a scalar reduction?
  logic [4:0]      cur_result_reg;  // Which register to read result from

  //==========================================================================
  // Test Configuration Mux
  //==========================================================================
  always_comb begin
    // Defaults
    cur_instr       = INSTR_VADD;
    cur_instr2      = 32'h0;
    cur_needs_op2   = 1'b0;
    cur_golden      = GOLDEN_VADD;
    cur_is_reduction = 1'b0;
    cur_result_reg  = 5'd3;

    case (test_num)
      4'd0: begin  // Test 0: vadd.vv
        cur_instr      = INSTR_VADD;
        cur_golden     = GOLDEN_VADD;
        cur_result_reg = 5'd3;
      end

      4'd1: begin  // Test 1: vmul.vv
        cur_instr      = INSTR_VMUL;
        cur_golden     = GOLDEN_VMUL;
        cur_result_reg = 5'd4;
      end

      4'd2: begin  // Test 2: vredsum (vmul then reduce)
        cur_instr      = INSTR_VMUL;
        cur_instr2     = INSTR_VREDSUM;
        cur_needs_op2  = 1'b1;
        cur_golden     = {56'h0, GOLDEN_REDSUM};
        cur_is_reduction = 1'b1;
        cur_result_reg = 5'd3;
      end

      4'd3: begin  // Test 3: vand.vv
        cur_instr      = INSTR_VAND;
        cur_golden     = GOLDEN_VAND;
        cur_result_reg = 5'd3;
      end

      4'd4: begin  // Test 4: vsub.vv
        cur_instr      = INSTR_VSUB;
        cur_golden     = GOLDEN_VSUB;
        cur_result_reg = 5'd3;
      end

      4'd5: begin  // Test 5: vor.vv
        cur_instr      = INSTR_VOR;
        cur_golden     = GOLDEN_VOR;
        cur_result_reg = 5'd3;
      end

      4'd6: begin  // Test 6: vxor.vv
        cur_instr      = INSTR_VXOR;
        cur_golden     = GOLDEN_VXOR;
        cur_result_reg = 5'd3;
      end

      4'd7: begin  // Test 7: vmin.vv
        cur_instr      = INSTR_VMIN;
        cur_golden     = GOLDEN_VMIN;
        cur_result_reg = 5'd3;
      end

      4'd8: begin  // Test 8: vmax.vv
        cur_instr      = INSTR_VMAX;
        cur_golden     = GOLDEN_VMAX;
        cur_result_reg = 5'd3;
      end

      4'd9: begin  // Test 9: vminu.vv
        cur_instr      = INSTR_VMINU;
        cur_golden     = GOLDEN_VMINU;
        cur_result_reg = 5'd3;
      end

      default: begin
        cur_instr  = INSTR_VADD;
        cur_golden = GOLDEN_VADD;
      end
    endcase
  end

  //==========================================================================
  // State Machine - Sequential
  //==========================================================================
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state        <= ST_RESET;
      instr_id     <= 8'd0;
      result_reg   <= '0;
      timeout_cnt  <= '0;
      test_num     <= 4'd0;
      tests_passed <= 4'd0;
    end else begin
      state <= next_state;

      // Capture result when DMA read completes
      if (dma_rvalid) begin
        result_reg <= dma_rdata;
      end

      // Increment instruction ID on issue
      if (x_issue_valid && x_issue_ready) begin
        instr_id <= instr_id + 1;
      end

      // Timeout counter for wait states
      if (state != next_state) begin
        timeout_cnt <= '0;
      end else begin
        timeout_cnt <= timeout_cnt + 1;
      end

      // Test progression
      if (state == ST_CHECK_RESULT && next_state == ST_NEXT_TEST) begin
        tests_passed <= tests_passed + 1;
      end
      if (state == ST_NEXT_TEST) begin
        test_num <= test_num + 1;
      end
    end
  end

  //==========================================================================
  // State Machine - Combinational
  //==========================================================================
  always_comb begin
    // Defaults
    next_state      = state;
    x_issue_valid   = 1'b0;
    x_issue_instr   = 32'h0;
    x_issue_rs1     = 32'h0;
    x_issue_rs2     = 32'h0;
    dma_valid       = 1'b0;
    dma_we          = 1'b0;
    dma_addr        = 5'd0;
    dma_wdata       = '0;
    dma_be          = '0;


    x_result_ready  = 1'b1;  // Always ready to accept results

    case (state)
      ST_RESET: begin
        next_state = ST_LOAD_V1;
      end

      //--- VRF Loading Phase ---
      ST_LOAD_V1: begin
        dma_valid = 1'b1; dma_we = 1'b1; dma_be = {(DLEN/8){1'b1}};
        dma_addr  = 5'd1;
        dma_wdata = VEC_A;
        next_state    = ST_LOAD_V2;
      end

      ST_LOAD_V2: begin
        dma_valid = 1'b1; dma_we = 1'b1; dma_be = {(DLEN/8){1'b1}};
        dma_addr  = 5'd2;
        dma_wdata = VEC_B;
        next_state    = ST_LOAD_V3;
      end

      ST_LOAD_V3: begin
        dma_valid = 1'b1; dma_we = 1'b1; dma_be = {(DLEN/8){1'b1}};
        dma_addr  = 5'd3;
        dma_wdata = '0;  // Clear accumulator
        next_state    = ST_ISSUE_VSETVLI;
      end

      //--- Configuration Phase ---
      ST_ISSUE_VSETVLI: begin
        x_issue_valid = 1'b1;
        x_issue_instr = INSTR_VSETVLI;
        x_issue_rs1   = 32'd0;  // AVL=0 -> VL=VLMAX
        if (x_issue_ready) begin
          next_state = ST_WAIT_VSETVLI;
        end
      end

      ST_WAIT_VSETVLI: begin
        if (x_result_valid) begin
          next_state = ST_ISSUE_OP;
        end
      end

      //--- Compute Phase ---
      ST_ISSUE_OP: begin
        x_issue_valid = 1'b1;
        x_issue_instr = cur_instr;
        if (x_issue_ready) begin
          next_state = ST_WAIT_OP;
        end
      end

      ST_WAIT_OP: begin
        if (x_result_valid) begin
          if (cur_needs_op2) begin
            next_state = ST_ISSUE_OP2;
          end else begin
            next_state = ST_WAIT_DONE;
          end
        end
      end

      ST_ISSUE_OP2: begin
        x_issue_valid = 1'b1;
        x_issue_instr = cur_instr2;
        if (x_issue_ready) begin
          next_state = ST_WAIT_OP2;
        end
      end

      ST_WAIT_OP2: begin
        if (x_result_valid) begin
          next_state = ST_WAIT_DONE;
        end
      end

      ST_WAIT_DONE: begin
        if (!vpu_busy) begin
          next_state = ST_READ_RESULT;
        end
        if (timeout_cnt == 16'hFFFF) begin
          next_state = ST_FAIL;
        end
      end

      //--- Result Check Phase ---
      ST_READ_RESULT: begin
        dma_valid = 1'b1; dma_we = 1'b0; dma_addr = cur_result_reg;
        next_state   = ST_LATCH_RESULT;
      end

      ST_LATCH_RESULT: begin
        // Cycle 1: VRF BRAM output register latching
        next_state   = ST_WAIT_RDATA;
      end

      ST_WAIT_RDATA: begin
        // Cycle 2: dma_rdata valid, result_reg captured by rvalid-gated flop
        next_state   = ST_CHECK_RESULT;
      end

      ST_CHECK_RESULT: begin
        if (cur_is_reduction) begin
          // Compare only lowest byte for reduction
          if (result_reg[7:0] == cur_golden[7:0]) begin
            next_state = ST_NEXT_TEST;
          end else begin
            next_state = ST_FAIL;
          end
        end else begin
          // Compare full vector
          if (result_reg == cur_golden) begin
            next_state = ST_NEXT_TEST;
          end else begin
            next_state = ST_FAIL;
          end
        end
      end

      ST_NEXT_TEST: begin
        if (test_num == NUM_TESTS - 1) begin
          next_state = ST_PASS;  // All tests done
        end else begin
          next_state = ST_LOAD_V3;  // Reset accumulator and run next test
        end
      end

      ST_PASS: begin
        next_state = ST_PASS;  // Stay here
      end

      ST_FAIL: begin
        next_state = ST_FAIL;  // Stay here
      end

      default: begin
        next_state = ST_RESET;
      end
    endcase
  end

  //==========================================================================
  // CSR Defaults (until vsetvli runs)
  //==========================================================================
  assign csr_vtype = 32'h0;  // SEW=8, LMUL=1
  assign csr_vl    = VLEN/8; // VLMAX for SEW=8

  //==========================================================================
  // Instruction ID
  //==========================================================================
  assign x_issue_id = instr_id;

  //==========================================================================
  // VPU Instance
  //==========================================================================
  // v0.3d: New ports - tie off unused CSR/exception signals
  wire        vpu_accept;      // Could use for debug
  wire [31:0] vpu_exc_cause;   // Could use for debug
  wire        vpu_exc_valid;   // Could use for debug

  hp_vpu_top #(
    .VLEN   (VLEN),
    .NLANES (NLANES)
  ) u_vpu (
    .clk              (clk),
    .rst_n            (rst_n),
    // CV-X-IF Issue
    .x_issue_valid_i  (x_issue_valid),
    .x_issue_ready_o  (x_issue_ready),
    .x_issue_accept_o (vpu_accept),      // v0.3d
    .x_issue_instr_i  (x_issue_instr),
    .x_issue_id_i     (x_issue_id),
    .x_issue_rs1_i    (x_issue_rs1),
    .x_issue_rs2_i    (x_issue_rs2),
    // CV-X-IF Result
    .x_result_valid_o (x_result_valid),
    .x_result_ready_i (x_result_ready),
    .x_result_id_o    (x_result_id),
    .x_result_data_o  (x_result_data),
    .x_result_we_o    (x_result_we),
    // Vector CSRs
    .csr_vtype_i      (csr_vtype),
    .csr_vl_i         (csr_vl),
    .csr_vtype_o      (csr_vtype_out),
    .csr_vl_o         (csr_vl_out),
    .csr_vl_valid_o   (csr_vl_valid),
    // v0.3d: VPU CSR Interface (tie off - not used in test)
    .csr_req_i        (1'b0),
    .csr_gnt_o        (),
    .csr_we_i         (1'b0),
    .csr_addr_i       (12'h0),
    .csr_wdata_i      (32'h0),
    .csr_rdata_o      (),
    .csr_rvalid_o     (),
    .csr_error_o      (),
    // v0.3d: Exception Interface (auto-ack)
    .exc_valid_o      (vpu_exc_valid),
    .exc_cause_o      (vpu_exc_cause),
    .exc_ack_i        (vpu_exc_valid),   // Auto-acknowledge
    // DMA data interface (v0.5)
    .dma_valid_i      (dma_valid),
    .dma_ready_o      (dma_ready),
    .dma_we_i         (dma_we),
    .dma_addr_i       (dma_addr),
    .dma_wdata_i      (dma_wdata),
    .dma_be_i         (dma_be),
    .dma_rvalid_o     (dma_rvalid),
    .dma_rdata_o      (dma_rdata),
    // v0.5e: Weight double-buffer (disabled)
    .dma_dbuf_en_i    (1'b0),
    .dma_dbuf_swap_i  (1'b0),
    // Commit interface (v0.5 - tied off)
    .x_commit_valid_i (1'b0),
    .x_commit_id_i    ('0),
    .x_commit_kill_i  (1'b0),
    // Status
    .busy_o           (vpu_busy),
    .perf_cnt_o       (perf_cnt)
  );

  //==========================================================================
  // LED Outputs
  //==========================================================================
  // led[0] = PASS (green)
  // led[1] = FAIL (red indicator)
  // led[2] = VPU busy
  // led[3] = Test running (not in PASS/FAIL)
  assign led[0] = (state == ST_PASS);
  assign led[1] = (state == ST_FAIL);
  assign led[2] = vpu_busy;
  assign led[3] = (state != ST_PASS) && (state != ST_FAIL);

endmodule
