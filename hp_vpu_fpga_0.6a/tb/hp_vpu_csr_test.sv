//==============================================================================
// HP-VPU v0.3d - Standalone Test for CSR Module and Issue Checker
//==============================================================================

module hp_vpu_csr_test;
  import hp_vpu_pkg::*;

  logic clk = 0;
  logic rst_n;

  always #5 clk = ~clk;  // 100MHz

  //==========================================================================
  // CSR Module Signals
  //==========================================================================
  logic        reg_req;
  logic        reg_gnt;
  logic        reg_we;
  logic [11:0] reg_addr;
  logic [31:0] reg_wdata;
  logic [3:0]  reg_be;
  logic [31:0] reg_rdata;
  logic        reg_rvalid;
  logic        reg_error;

  logic        illegal_instr;
  logic [31:0] illegal_instr_data;
  logic        vpu_busy;
  logic [31:0] instr_cnt;

  logic        sw_reset;
  logic        perf_cnt_en;
  logic [1:0]  exc_mode;

  logic        exc_valid;
  logic [31:0] exc_cause;
  logic        exc_ack;

  //==========================================================================
  // Issue Checker Signals
  //==========================================================================
  logic [31:0] instr;
  logic        is_vector;
  logic        is_supported;
  logic        is_config;

  //==========================================================================
  // DUT: CSR Module
  //==========================================================================
  hp_vpu_csr #(
    .VLEN   (64),
    .NLANES (1)
  ) u_csr (
    .clk                  (clk),
    .rst_n                (rst_n),
    .reg_req_i            (reg_req),
    .reg_gnt_o            (reg_gnt),
    .reg_we_i             (reg_we),
    .reg_addr_i           (reg_addr),
    .reg_wdata_i          (reg_wdata),
    .reg_be_i             (reg_be),
    .reg_rdata_o          (reg_rdata),
    .reg_rvalid_o         (reg_rvalid),
    .reg_error_o          (reg_error),
    .illegal_instr_i      (illegal_instr),
    .illegal_instr_data_i (illegal_instr_data),
    .vpu_busy_i           (vpu_busy),
    .instr_cnt_i          (instr_cnt),
    .stall_i              (1'b0),       // Tie low for standalone CSR test
    .sw_reset_o           (sw_reset),
    .perf_cnt_en_o        (perf_cnt_en),
    .exc_mode_o           (exc_mode),
    .exc_valid_o          (exc_valid),
    .exc_cause_o          (exc_cause),
    .exc_ack_i            (exc_ack)
  );

  //==========================================================================
  // DUT: Issue Checker
  //==========================================================================
  hp_vpu_issue_check u_issue_check (
    .instr_i        (instr),
    .is_vector_o    (is_vector),
    .is_supported_o (is_supported),
    .is_config_o    (is_config)
  );

  //==========================================================================
  // Test Tasks
  //==========================================================================
  task automatic csr_read(input logic [11:0] addr, output logic [31:0] data);
    // CSR has 1-cycle read latency: rvalid comes 1 cycle after req
    reg_req = 1;
    reg_we = 0;
    reg_addr = addr;
    @(posedge clk);  // Cycle 1: request seen, rvalid will be set next cycle
    @(posedge clk);  // Cycle 2: rvalid is now high, data is valid
    data = reg_rdata;
    reg_req = 0;
  endtask

  task automatic csr_write(input logic [11:0] addr, input logic [31:0] data);
    reg_req = 1;
    reg_we = 1;
    reg_addr = addr;
    reg_wdata = data;
    @(posedge clk);  // Write captured on this edge
    reg_req = 0;
    reg_we = 0;
  endtask

  //==========================================================================
  // Main Test
  //==========================================================================
  int tests_run = 0;
  int tests_passed = 0;
  logic [31:0] rdata;

  initial begin
    $display("\n==================================================");
    $display("HP-VPU v0.4a CSR and Issue Checker Test");
    $display("==================================================\n");

    // Initialize
    rst_n = 0;
    reg_req = 0;
    reg_we = 0;
    reg_addr = 0;
    reg_wdata = 0;
    reg_be = 4'hF;
    illegal_instr = 0;
    illegal_instr_data = 0;
    vpu_busy = 0;
    instr_cnt = 0;
    exc_ack = 0;
    instr = 0;

    repeat(10) @(posedge clk);
    rst_n = 1;
    repeat(5) @(posedge clk);

    //========================================================================
    // TEST 1: CSR Read - VPU_ID
    //========================================================================
    $display("TEST 1: Read VPU_ID (0x000)");
    csr_read(12'h000, rdata);
    tests_run++;
    if (rdata == 32'h4850_0006) begin
      tests_passed++;
      $display("  PASS: VPU_ID = 0x%h", rdata);
    end else begin
      $display("  FAIL: VPU_ID = 0x%h, expected 0x48500006", rdata);
    end

    //========================================================================
    // TEST 2: CSR Read - VPU_CONFIG
    //========================================================================
    $display("TEST 2: Read VPU_CONFIG (0x004)");
    csr_read(12'h004, rdata);
    tests_run++;
    // Expected: VLEN=64 (0x0040), NLANES=1 (0x01), features=0x01
    if (rdata == 32'h0040_0101) begin
      tests_passed++;
      $display("  PASS: VPU_CONFIG = 0x%h", rdata);
    end else begin
      $display("  FAIL: VPU_CONFIG = 0x%h, expected 0x00400101", rdata);
    end

    //========================================================================
    // TEST 3: CSR Read - CAP0 (ALU capabilities)
    //========================================================================
    $display("TEST 3: Read CAP0 (0x020)");
    csr_read(12'h020, rdata);
    tests_run++;
    if (rdata == 32'h0000_003F) begin
      tests_passed++;
      $display("  PASS: CAP0 = 0x%h", rdata);
    end else begin
      $display("  FAIL: CAP0 = 0x%h, expected 0x0000003F", rdata);
    end

    //========================================================================
    // TEST 4: CSR Read - CAP1 (Multiply/MAC, no divide)
    //========================================================================
    $display("TEST 4: Read CAP1 (0x024)");
    csr_read(12'h024, rdata);
    tests_run++;
    if (rdata == 32'h0000_0007) begin
      tests_passed++;
      $display("  PASS: CAP1 = 0x%h (no divide)", rdata);
    end else begin
      $display("  FAIL: CAP1 = 0x%h, expected 0x00000007", rdata);
    end

    //========================================================================
    // TEST 5: CSR Write/Read - CTRL register
    //========================================================================
    $display("TEST 5: Write/Read CTRL (0x080)");
    csr_write(12'h080, 32'h0000_0002);  // Enable perf counters
    csr_read(12'h080, rdata);
    tests_run++;
    if (rdata == 32'h0000_0002) begin
      tests_passed++;
      $display("  PASS: CTRL = 0x%h", rdata);
    end else begin
      $display("  FAIL: CTRL = 0x%h, expected 0x00000002", rdata);
    end

    //========================================================================
    // TEST 6: CSR Write/Read - EXC_CTRL register
    //========================================================================
    $display("TEST 6: Write/Read EXC_CTRL (0x084)");
    csr_write(12'h084, 32'h0000_0002);  // Set interrupt mode
    csr_read(12'h084, rdata);
    tests_run++;
    if (rdata == 32'h0000_0002) begin
      tests_passed++;
      $display("  PASS: EXC_CTRL = 0x%h (interrupt mode)", rdata);
    end else begin
      $display("  FAIL: EXC_CTRL = 0x%h, expected 0x00000002", rdata);
    end

    //========================================================================
    // TEST 7: Illegal instruction tracking
    //========================================================================
    $display("TEST 7: Illegal instruction tracking");
    illegal_instr_data = 32'hDEAD_BEEF;
    illegal_instr = 1;
    @(posedge clk);
    illegal_instr = 0;
    @(posedge clk);

    csr_read(12'h044, rdata);  // ERR_INSTR
    tests_run++;
    if (rdata == 32'hDEAD_BEEF) begin
      tests_passed++;
      $display("  PASS: ERR_INSTR = 0x%h", rdata);
    end else begin
      $display("  FAIL: ERR_INSTR = 0x%h, expected 0xDEADBEEF", rdata);
    end

    csr_read(12'h048, rdata);  // ERR_CNT
    tests_run++;
    if (rdata == 32'h0000_0001) begin
      tests_passed++;
      $display("  PASS: ERR_CNT = %0d", rdata);
    end else begin
      $display("  FAIL: ERR_CNT = %0d, expected 1", rdata);
    end

    //========================================================================
    // TEST 8: Exception pending (interrupt mode)
    //========================================================================
    $display("TEST 8: Exception interrupt output");
    tests_run++;
    if (exc_valid == 1'b1 && exc_cause == 32'hDEAD_BEEF) begin
      tests_passed++;
      $display("  PASS: exc_valid=1, exc_cause=0x%h", exc_cause);
    end else begin
      $display("  FAIL: exc_valid=%b, exc_cause=0x%h", exc_valid, exc_cause);
    end

    // Acknowledge exception
    exc_ack = 1;
    @(posedge clk);
    exc_ack = 0;
    @(posedge clk);

    tests_run++;
    if (exc_valid == 1'b0) begin
      tests_passed++;
      $display("  PASS: Exception cleared after ack");
    end else begin
      $display("  FAIL: exc_valid still 1 after ack");
    end

    //========================================================================
    // TEST 9: Issue Checker - vadd.vv (supported)
    //========================================================================
    $display("TEST 9: Issue check - vadd.vv");
    // vadd.vv: funct6=000000, vm=1, vs2=2, vs1=1, funct3=000, vd=3, opcode=1010111
    instr = {6'b000000, 1'b1, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111};
    #1;  // Combinational
    tests_run++;
    if (is_vector && is_supported && !is_config) begin
      tests_passed++;
      $display("  PASS: vadd.vv -> vector=1, supported=1, config=0");
    end else begin
      $display("  FAIL: vadd.vv -> vector=%b, supported=%b, config=%b",
               is_vector, is_supported, is_config);
    end

    //========================================================================
    // TEST 10: Issue Checker - vmul.vv (supported)
    //========================================================================
    $display("TEST 10: Issue check - vmul.vv");
    // vmul.vv: funct6=100101, vm=1, vs2=2, vs1=1, funct3=010, vd=3, opcode=1010111
    instr = {6'b100101, 1'b1, 5'd2, 5'd1, 3'b010, 5'd3, 7'b1010111};
    #1;
    tests_run++;
    if (is_vector && is_supported) begin
      tests_passed++;
      $display("  PASS: vmul.vv -> vector=1, supported=1");
    end else begin
      $display("  FAIL: vmul.vv -> vector=%b, supported=%b", is_vector, is_supported);
    end

    //========================================================================
    // TEST 11: Issue Checker - vdiv.vv (NOT supported)
    //========================================================================
    $display("TEST 11: Issue check - vdiv.vv (unsupported)");
    // vdiv.vv: funct6=100000, vm=1, vs2=2, vs1=1, funct3=010, vd=3, opcode=1010111
    instr = {6'b100000, 1'b1, 5'd2, 5'd1, 3'b010, 5'd3, 7'b1010111};
    #1;
    tests_run++;
    if (is_vector && !is_supported) begin
      tests_passed++;
      $display("  PASS: vdiv.vv -> vector=1, supported=0 (correctly rejected)");
    end else begin
      $display("  FAIL: vdiv.vv -> vector=%b, supported=%b", is_vector, is_supported);
    end

    //========================================================================
    // TEST 12: Issue Checker - vsetvli (config)
    //========================================================================
    $display("TEST 12: Issue check - vsetvli");
    // vsetvli: funct3=111, opcode=1010111
    instr = {11'b0, 5'd5, 3'b111, 5'd0, 7'b1010111};
    #1;
    tests_run++;
    if (is_vector && is_supported && is_config) begin
      tests_passed++;
      $display("  PASS: vsetvli -> vector=1, supported=1, config=1");
    end else begin
      $display("  FAIL: vsetvli -> vector=%b, supported=%b, config=%b",
               is_vector, is_supported, is_config);
    end

    //========================================================================
    // TEST 13: Issue Checker - non-vector instruction
    //========================================================================
    $display("TEST 13: Issue check - non-vector (ADD)");
    // ADD instruction: opcode=0110011
    instr = 32'h003100B3;  // add x1, x2, x3
    #1;
    tests_run++;
    if (!is_vector) begin
      tests_passed++;
      $display("  PASS: ADD -> vector=0");
    end else begin
      $display("  FAIL: ADD -> vector=%b (should be 0)", is_vector);
    end

    //========================================================================
    // TEST 14: Issue Checker - vmacc.vv (supported MAC)
    //========================================================================
    $display("TEST 14: Issue check - vmacc.vv");
    // vmacc.vv: funct6=101101, vm=1, vs2=2, vs1=1, funct3=010, vd=3, opcode=1010111
    instr = {6'b101101, 1'b1, 5'd2, 5'd1, 3'b010, 5'd3, 7'b1010111};
    #1;
    tests_run++;
    if (is_vector && is_supported) begin
      tests_passed++;
      $display("  PASS: vmacc.vv -> vector=1, supported=1");
    end else begin
      $display("  FAIL: vmacc.vv -> vector=%b, supported=%b", is_vector, is_supported);
    end

    //========================================================================
    // TEST 15: Issue Checker - vredsum.vs (reduction)
    //========================================================================
    $display("TEST 15: Issue check - vredsum.vs");
    // vredsum.vs: funct6=000000, vm=1, vs2=2, vs1=1, funct3=010 (OPMVV), vd=3
    instr = {6'b000000, 1'b1, 5'd2, 5'd1, 3'b010, 5'd3, 7'b1010111};
    #1;
    tests_run++;
    if (is_vector && is_supported) begin
      tests_passed++;
      $display("  PASS: vredsum.vs -> vector=1, supported=1");
    end else begin
      $display("  FAIL: vredsum.vs -> vector=%b, supported=%b", is_vector, is_supported);
    end

    //========================================================================
    // TEST 16: Write-to-clear ERR_CNT
    //========================================================================
    $display("TEST 16: W1C - ERR_CNT (0x048)");
    // ERR_CNT should be non-zero from TEST 7 illegal instruction
    csr_read(12'h048, rdata);
    if (rdata > 0) begin
      $display("  Pre-clear ERR_CNT = %0d (good, non-zero)", rdata);
    end else begin
      $display("  WARNING: ERR_CNT already 0 before W1C test");
    end
    // Write 0xFFFFFFFF to clear
    csr_write(12'h048, 32'hFFFF_FFFF);
    csr_read(12'h048, rdata);
    tests_run++;
    if (rdata == 32'h0) begin
      tests_passed++;
      $display("  PASS: ERR_CNT cleared to 0 after W1C");
    end else begin
      $display("  FAIL: ERR_CNT = %0d after W1C, expected 0", rdata);
    end

    //========================================================================
    // Summary
    //========================================================================
    $display("\n==================================================");
    $display("Test Results: %0d/%0d passed", tests_passed, tests_run);
    if (tests_passed == tests_run)
      $display("*** ALL TESTS PASSED ***");
    else
      $display("*** %0d TESTS FAILED ***", tests_run - tests_passed);
    $display("==================================================\n");

    $finish;
  end

endmodule
