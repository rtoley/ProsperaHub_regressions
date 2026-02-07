//============================================================================
// Hyperplane VPU Netlist Testbench - RANDOMIZED VALUE VERIFICATION
// Runs randomized instructions and verifies computed values
//============================================================================

`timescale 1ns/1ps

module hp_vpu_netlist_tb;
  import hp_vpu_pkg::*;

  localparam DLEN_TB = hp_vpu_pkg::DLEN;
  localparam VLEN_TB = hp_vpu_pkg::VLEN;
  localparam NLANES_TB = hp_vpu_pkg::NLANES;
  localparam VLMAX_8 = VLEN_TB / 8;
  localparam NUM_RANDOM_TESTS = 100;

  logic clk = 0;
  logic rst_n = 0;

  always #5 clk = ~clk;

  // DUT signals
  logic        x_issue_valid;
  logic        x_issue_ready;
  logic [31:0] x_issue_instr;
  logic [7:0]  x_issue_id;
  logic [31:0] x_issue_rs1;
  logic [31:0] x_issue_rs2;

  logic        x_result_valid;
  logic        x_result_ready;
  logic [7:0]  x_result_id;
  logic [31:0] x_result_data;
  logic        x_result_we;

  logic [31:0] csr_vtype;
  logic [31:0] csr_vl;
  logic [31:0] csr_vtype_out;
  logic [31:0] csr_vl_out;
  logic        csr_vl_valid;

  logic                   dma_valid;
  logic                   dma_ready;
  logic                   dma_we;
  logic [4:0]             dma_addr;
  logic [DLEN_TB-1:0]     dma_wdata;
  logic [DLEN_TB/8-1:0]   dma_be;
  logic                   dma_rvalid;
  logic [DLEN_TB-1:0]     dma_rdata;

  logic        busy;
  logic [31:0] perf_cnt;

  // Result capture
  logic        saw_result;
  logic [31:0] captured_result;

  always @(posedge clk) begin
    if (x_result_valid && x_result_ready) begin
      saw_result <= 1;
      captured_result <= x_result_data;
    end
  end

  hp_vpu_top dut (
    .clk              (clk),
    .rst_n            (rst_n),
    .x_issue_valid_i  (x_issue_valid),
    .x_issue_ready_o  (x_issue_ready),
    .x_issue_instr_i  (x_issue_instr),
    .x_issue_id_i     (x_issue_id),
    .x_issue_rs1_i    (x_issue_rs1),
    .x_issue_rs2_i    (x_issue_rs2),
    .x_result_valid_o (x_result_valid),
    .x_result_ready_i (x_result_ready),
    .x_result_id_o    (x_result_id),
    .x_result_data_o  (x_result_data),
    .x_result_we_o    (x_result_we),
    .csr_vtype_i      (csr_vtype),
    .csr_vl_i         (csr_vl),
    .csr_vtype_o      (csr_vtype_out),
    .csr_vl_o         (csr_vl_out),
    .csr_vl_valid_o   (csr_vl_valid),
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
    .x_commit_valid_i (1'b0),
    .x_commit_id_i    ('0),
    .x_commit_kill_i  (1'b0),
    .busy_o           (busy),
    .perf_cnt_o       (perf_cnt)
  );

  //--------------------------------------------------------------------------
  // Instruction encodings
  //--------------------------------------------------------------------------
  function automatic logic [31:0] encode_vsetvli(logic [4:0] rd, logic [4:0] rs1, logic [10:0] vtypei);
    return {1'b0, vtypei[9:0], rs1, 3'b111, rd, 7'b1010111};
  endfunction

  function automatic logic [31:0] encode_vadd_vv(logic [4:0] vd, logic [4:0] vs1, logic [4:0] vs2);
    return {6'b000000, 1'b1, vs2, vs1, 3'b000, vd, 7'b1010111};
  endfunction

  function automatic logic [31:0] encode_vsub_vv(logic [4:0] vd, logic [4:0] vs1, logic [4:0] vs2);
    return {6'b000010, 1'b1, vs2, vs1, 3'b000, vd, 7'b1010111};
  endfunction

  function automatic logic [31:0] encode_vand_vv(logic [4:0] vd, logic [4:0] vs1, logic [4:0] vs2);
    return {6'b001001, 1'b1, vs2, vs1, 3'b000, vd, 7'b1010111};
  endfunction

  function automatic logic [31:0] encode_vor_vv(logic [4:0] vd, logic [4:0] vs1, logic [4:0] vs2);
    return {6'b001010, 1'b1, vs2, vs1, 3'b000, vd, 7'b1010111};
  endfunction

  function automatic logic [31:0] encode_vxor_vv(logic [4:0] vd, logic [4:0] vs1, logic [4:0] vs2);
    return {6'b001011, 1'b1, vs2, vs1, 3'b000, vd, 7'b1010111};
  endfunction

  function automatic logic [31:0] encode_vmul_vv(logic [4:0] vd, logic [4:0] vs1, logic [4:0] vs2);
    return {6'b100101, 1'b1, vs2, vs1, 3'b010, vd, 7'b1010111};
  endfunction

  // LUT instruction encoders (v0.19)
  function automatic logic [31:0] encode_vexp_v(logic [4:0] vd, logic [4:0] vs2);
    return {6'b010010, 1'b1, vs2, 5'b00000, 3'b010, vd, 7'b1010111};  // vs1=0 for exp
  endfunction

  function automatic logic [31:0] encode_vrecip_v(logic [4:0] vd, logic [4:0] vs2);
    return {6'b010010, 1'b1, vs2, 5'b00001, 3'b010, vd, 7'b1010111};  // vs1=1 for recip
  endfunction

  function automatic logic [31:0] encode_vrsqrt_v(logic [4:0] vd, logic [4:0] vs2);
    return {6'b010010, 1'b1, vs2, 5'b00010, 3'b010, vd, 7'b1010111};  // vs1=2 for rsqrt
  endfunction

  function automatic logic [31:0] encode_vgelu_v(logic [4:0] vd, logic [4:0] vs2);
    return {6'b010010, 1'b1, vs2, 5'b00011, 3'b010, vd, 7'b1010111};  // vs1=3 for gelu
  endfunction

  //--------------------------------------------------------------------------
  // Golden model - compute expected result
  //--------------------------------------------------------------------------
  function automatic logic [DLEN_TB-1:0] golden_vadd(
    input logic [DLEN_TB-1:0] vs2,
    input logic [DLEN_TB-1:0] vs1
  );
    logic [DLEN_TB-1:0] result;
    for (int i = 0; i < DLEN_TB/8; i++) begin
      result[i*8 +: 8] = vs2[i*8 +: 8] + vs1[i*8 +: 8];
    end
    return result;
  endfunction

  function automatic logic [DLEN_TB-1:0] golden_vsub(
    input logic [DLEN_TB-1:0] vs2,
    input logic [DLEN_TB-1:0] vs1
  );
    logic [DLEN_TB-1:0] result;
    for (int i = 0; i < DLEN_TB/8; i++) begin
      result[i*8 +: 8] = vs2[i*8 +: 8] - vs1[i*8 +: 8];
    end
    return result;
  endfunction

  function automatic logic [DLEN_TB-1:0] golden_vand(
    input logic [DLEN_TB-1:0] vs2,
    input logic [DLEN_TB-1:0] vs1
  );
    return vs2 & vs1;
  endfunction

  function automatic logic [DLEN_TB-1:0] golden_vor(
    input logic [DLEN_TB-1:0] vs2,
    input logic [DLEN_TB-1:0] vs1
  );
    return vs2 | vs1;
  endfunction

  function automatic logic [DLEN_TB-1:0] golden_vxor(
    input logic [DLEN_TB-1:0] vs2,
    input logic [DLEN_TB-1:0] vs1
  );
    return vs2 ^ vs1;
  endfunction

  function automatic logic [DLEN_TB-1:0] golden_vmul(
    input logic [DLEN_TB-1:0] vs2,
    input logic [DLEN_TB-1:0] vs1
  );
    logic [DLEN_TB-1:0] result;
    for (int i = 0; i < DLEN_TB/8; i++) begin
      result[i*8 +: 8] = (vs2[i*8 +: 8] * vs1[i*8 +: 8]) & 8'hFF;
    end
    return result;
  endfunction

  //--------------------------------------------------------------------------
  // Helper tasks
  //--------------------------------------------------------------------------
  task automatic vrf_write(input logic [4:0] addr, input logic [DLEN_TB-1:0] data);
    @(posedge clk);
    dma_valid <= 1;
    dma_we <= 1;
    dma_addr <= addr;
    dma_wdata <= data;
    dma_be <= {(DLEN_TB/8){1'b1}};
    @(posedge clk);
    dma_valid <= 0;
    dma_we <= 0;
    repeat(2) @(posedge clk);
  endtask

  task automatic vrf_read(input logic [4:0] addr, output logic [DLEN_TB-1:0] data);
    dma_valid <= 1;
    dma_we <= 0;
    dma_addr <= addr;
    @(posedge clk);
    dma_valid <= 0;
    repeat(2) @(posedge clk);
    data = dma_rdata;
  endtask

  task automatic issue_instr(input logic [31:0] instr, input logic [31:0] rs1_val = 0);
    x_issue_valid <= 1;
    x_issue_instr <= instr;
    x_issue_rs1 <= rs1_val;
    x_issue_rs2 <= 0;
    @(posedge clk);
    while (!x_issue_ready) @(posedge clk);
    x_issue_valid <= 0;
  endtask

  task automatic wait_idle();
    int timeout = 100;
    repeat(2) @(posedge clk);
    while (busy && timeout > 0) begin
      @(posedge clk);
      timeout--;
    end
    repeat(3) @(posedge clk);
  endtask

  //--------------------------------------------------------------------------
  // Main test
  //--------------------------------------------------------------------------
  initial begin
    logic [DLEN_TB-1:0] vs1_data, vs2_data, vd_result, expected;
    logic [31:0] instr;
    int op_type;
    int errors;
    int total_tests;
    string op_name;
    int seed;

    // Initialize
    x_issue_valid = 0;
    x_issue_instr = 0;
    x_issue_id = 0;
    x_issue_rs1 = 0;
    x_issue_rs2 = 0;
    x_result_ready = 1;
    csr_vtype = 0;
    csr_vl = 0;
    dma_valid = 0;
    dma_we = 0;
    dma_addr = 0;
    dma_wdata = 0;
    dma_be = 0;
    saw_result = 0;
    errors = 0;
    total_tests = 0;
    seed = 12345;

    // Reset
    rst_n = 0;
    repeat(20) @(posedge clk);
    rst_n = 1;
    repeat(10) @(posedge clk);

    $display("");
    $display("================================================================");
    $display("  VPU Netlist - RANDOMIZED VALUE VERIFICATION");
    $display("  VLEN=%0d, DLEN=%0d, VLMAX=%0d", VLEN_TB, DLEN_TB, VLMAX_8);
    $display("  Running %0d randomized tests", NUM_RANDOM_TESTS);
    $display("================================================================");
    $display("");

    // Configure VPU: SEW=8
    saw_result = 0;
    issue_instr(encode_vsetvli(5'd1, 5'd0, 11'h000));
    repeat(10) @(posedge clk);

    if (saw_result && captured_result == VLMAX_8) begin
      $display("VPU configured: SEW=8, VL=%0d", captured_result);
    end else begin
      $display("ERROR: vsetvli failed, VL=%0d (expected %0d)", captured_result, VLMAX_8);
      $finish;
    end
    $display("");

    // Run randomized tests
    for (int test = 0; test < NUM_RANDOM_TESTS; test++) begin
      // Generate random operands
      vs1_data = {$random(seed), $random(seed)};
      vs2_data = {$random(seed), $random(seed)};

      // Pick random operation (0-5)
      op_type = ($random(seed) & 32'h7FFFFFFF) % 6;

      // Write operands
      vrf_write(5'd1, vs1_data);
      vrf_write(5'd2, vs2_data);

      // Select operation and compute expected
      case (op_type)
        0: begin
          instr = encode_vadd_vv(5'd3, 5'd1, 5'd2);
          expected = golden_vadd(vs2_data, vs1_data);
          op_name = "vadd";
        end
        1: begin
          instr = encode_vsub_vv(5'd3, 5'd1, 5'd2);
          expected = golden_vsub(vs2_data, vs1_data);
          op_name = "vsub";
        end
        2: begin
          instr = encode_vand_vv(5'd3, 5'd1, 5'd2);
          expected = golden_vand(vs2_data, vs1_data);
          op_name = "vand";
        end
        3: begin
          instr = encode_vor_vv(5'd3, 5'd1, 5'd2);
          expected = golden_vor(vs2_data, vs1_data);
          op_name = "vor";
        end
        4: begin
          instr = encode_vxor_vv(5'd3, 5'd1, 5'd2);
          expected = golden_vxor(vs2_data, vs1_data);
          op_name = "vxor";
        end
        5: begin
          instr = encode_vmul_vv(5'd3, 5'd1, 5'd2);
          expected = golden_vmul(vs2_data, vs1_data);
          op_name = "vmul";
        end
        default: begin
          instr = encode_vadd_vv(5'd3, 5'd1, 5'd2);
          expected = golden_vadd(vs2_data, vs1_data);
          op_name = "vadd";
        end
      endcase

      // Execute instruction
      issue_instr(instr);
      wait_idle();

      // Read result
      vrf_read(5'd3, vd_result);

      total_tests++;

      // Compare
      if (vd_result !== expected) begin
        errors++;
        $display("FAIL test %0d: %s", test, op_name);
        $display("  vs1 = 0x%h", vs1_data);
        $display("  vs2 = 0x%h", vs2_data);
        $display("  got = 0x%h", vd_result);
        $display("  exp = 0x%h", expected);

        // Stop after 5 errors to avoid flooding
        if (errors >= 5) begin
          $display("");
          $display("Stopping after 5 errors");
          break;
        end
      end else begin
        // Progress indicator every 10 tests
        if ((test + 1) % 10 == 0) begin
          $display("  ... %0d tests completed, %0d errors", test + 1, errors);
        end
      end
    end

    // Summary
    $display("");
    $display("================================================================");
    $display("  RANDOM TEST RESULTS: %0d/%0d tests passed", total_tests - errors, total_tests);
    $display("  Errors: %0d", errors);
    $display("================================================================");

    // LUT instruction tests (v0.19) - critical for LLM inference
    $display("");
    $display("================================================================");
    $display("  LUT INSTRUCTION TESTS (LLM Inference)");
    $display("================================================================");

    // Configure SEW=16 for LUT tests (16-bit results)
    saw_result = 0;
    issue_instr(encode_vsetvli(5'd1, 5'd0, 11'h005));  // SEW=16
    repeat(10) @(posedge clk);
    $display("  Configured SEW=16 for LUT tests");

    // Test vexp.v
    vs1_data = 64'h0030002000100000;  // indices 0, 16, 32, 48 as 16-bit
    vrf_write(5'd1, vs1_data);
    issue_instr(encode_vexp_v(5'd2, 5'd1));
    wait_idle();
    vrf_read(5'd2, vd_result);
    if (vd_result != 0) begin
      $display("  PASS: vexp.v output = 0x%h (non-zero)", vd_result);
    end else begin
      $display("  FAIL: vexp.v output = 0 (expected non-zero)");
      errors++;
    end
    total_tests++;

    // Test vrecip.v
    vs1_data = 64'h0008000400020001;  // 1, 2, 4, 8 as 16-bit
    vrf_write(5'd1, vs1_data);
    issue_instr(encode_vrecip_v(5'd2, 5'd1));
    wait_idle();
    vrf_read(5'd2, vd_result);
    if (vd_result != 0) begin
      $display("  PASS: vrecip.v output = 0x%h (non-zero)", vd_result);
    end else begin
      $display("  FAIL: vrecip.v output = 0 (expected non-zero)");
      errors++;
    end
    total_tests++;

    // Test vrsqrt.v
    vs1_data = 64'h0010000900040001;  // 1, 4, 9, 16 as 16-bit
    vrf_write(5'd1, vs1_data);
    issue_instr(encode_vrsqrt_v(5'd2, 5'd1));
    wait_idle();
    vrf_read(5'd2, vd_result);
    if (vd_result != 0) begin
      $display("  PASS: vrsqrt.v output = 0x%h (non-zero)", vd_result);
    end else begin
      $display("  FAIL: vrsqrt.v output = 0 (expected non-zero)");
      errors++;
    end
    total_tests++;

    // Test vgelu.v
    vs1_data = 64'h0060004000200000;  // 0, 32, 64, 96 as 16-bit
    vrf_write(5'd1, vs1_data);
    issue_instr(encode_vgelu_v(5'd2, 5'd1));
    wait_idle();
    vrf_read(5'd2, vd_result);
    if (vd_result != 0) begin
      $display("  PASS: vgelu.v output = 0x%h (non-zero)", vd_result);
    end else begin
      $display("  FAIL: vgelu.v output = 0 (expected non-zero)");
      errors++;
    end
    total_tests++;

    // Final Summary
    $display("");
    $display("================================================================");
    $display("  FINAL RESULTS: %0d/%0d tests passed", total_tests - errors, total_tests);
    $display("  Errors: %0d", errors);
    $display("================================================================");

    if (errors == 0) begin
      $display("*** ALL TESTS PASSED - NETLIST VERIFIED ***");
    end else begin
      $display("*** TESTS FAILED - NETLIST HAS ERRORS ***");
    end

    $finish;
  end

  initial begin
    #10000000;
    $display("ERROR: Global timeout!");
    $finish;
  end

endmodule
