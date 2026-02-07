//==============================================================================
// Hyperplane VPU - Hazard Pattern Test (v0.4b - iverilog 12 compatible)
// Tests MAC/MUL vs non-MAC pipeline hazards at distances 1-6
//==============================================================================

`timescale 1ns/1ps

module hp_vpu_hazard_test;
  import hp_vpu_pkg::*;

  localparam int unsigned VLEN   = hp_vpu_pkg::VLEN;
  localparam int unsigned NLANES = hp_vpu_pkg::NLANES;
  localparam int unsigned ELEN   = hp_vpu_pkg::ELEN;
  localparam int unsigned DLEN   = NLANES * 64;
  localparam int unsigned VLMAX_8 = VLEN / 8;
  localparam CLK_PERIOD = 2.0;

  logic                      clk;
  logic                      rst_n;
  logic                      x_issue_valid;
  wire                       x_issue_ready;
  logic [31:0]               x_issue_instr;
  logic [CVXIF_ID_W-1:0]    x_issue_id;
  logic [31:0]               x_issue_rs1;
  logic [31:0]               x_issue_rs2;
  wire                       x_result_valid;
  logic                      x_result_ready;
  wire  [CVXIF_ID_W-1:0]    x_result_id;
  wire  [31:0]               x_result_data;
  wire                       x_result_we;
  logic [31:0]               csr_vtype;
  logic [31:0]               csr_vl;
  wire  [31:0]               csr_vtype_out;
  wire  [31:0]               csr_vl_out;
  wire                       csr_vl_valid;
  logic                      dma_valid;
  wire                       dma_ready;
  logic                      dma_we;
  logic [4:0]                dma_addr;
  logic [DLEN-1:0]           dma_wdata;
  logic [DLEN/8-1:0]         dma_be;
  wire                       dma_rvalid;
  wire  [DLEN-1:0]           dma_rdata;
  wire                       busy;
  wire  [31:0]               perf_cnt;

  reg [DLEN-1:0] actual;
  reg [DLEN-1:0] expected_val;
  integer total_tests, total_errors;
  integer d, fi;

  initial clk = 0;
  always #(CLK_PERIOD/2) clk = ~clk;

  hp_vpu_top #(.VLEN(VLEN), .NLANES(NLANES), .ELEN(ELEN)) u_dut (
    .clk(clk), .rst_n(rst_n),
    .x_issue_valid_i(x_issue_valid), .x_issue_ready_o(x_issue_ready),
    .x_issue_instr_i(x_issue_instr), .x_issue_id_i(x_issue_id),
    .x_issue_rs1_i(x_issue_rs1), .x_issue_rs2_i(x_issue_rs2),
    .x_result_valid_o(x_result_valid), .x_result_ready_i(x_result_ready),
    .x_result_id_o(x_result_id), .x_result_data_o(x_result_data),
    .x_result_we_o(x_result_we),
    .csr_vtype_i(csr_vtype), .csr_vl_i(csr_vl),
    .csr_vtype_o(csr_vtype_out), .csr_vl_o(csr_vl_out),
    .csr_vl_valid_o(csr_vl_valid),
    .csr_req_i(1'b0), .csr_we_i(1'b0), .csr_addr_i(12'h0), .csr_wdata_i(32'h0),
    .csr_gnt_o(), .csr_rdata_o(), .csr_rvalid_o(), .csr_error_o(),
    .exc_valid_o(), .exc_cause_o(), .exc_ack_i(1'b0),
    .dma_valid_i(dma_valid), .dma_ready_o(dma_ready), .dma_we_i(dma_we),
    .dma_addr_i(dma_addr), .dma_wdata_i(dma_wdata), .dma_be_i(dma_be),
    .dma_rvalid_o(dma_rvalid), .dma_rdata_o(dma_rdata),
    // v0.5e: Weight double-buffer (disabled)
    .dma_dbuf_en_i    (1'b0),
    .dma_dbuf_swap_i  (1'b0),
    .x_commit_valid_i(1'b0), .x_commit_id_i({CVXIF_ID_W{1'b0}}), .x_commit_kill_i(1'b0),
    .busy_o(busy), .perf_cnt_o(perf_cnt)
  );

  // Instruction encoders (Verilog-2001 style)
  function [31:0] enc_vadd;  input [4:0] vd, vs2, vs1;
    enc_vadd = {6'b000000, 1'b1, vs2, vs1, 3'b000, vd, 7'b1010111};
  endfunction
  function [31:0] enc_vand;  input [4:0] vd, vs2, vs1;
    enc_vand = {6'b001001, 1'b1, vs2, vs1, 3'b000, vd, 7'b1010111};
  endfunction
  function [31:0] enc_vmul;  input [4:0] vd, vs2, vs1;
    enc_vmul = {6'b100101, 1'b1, vs2, vs1, 3'b010, vd, 7'b1010111};
  endfunction
  function [31:0] enc_vmacc; input [4:0] vd, vs1, vs2;
    enc_vmacc = {6'b101101, 1'b1, vs2, vs1, 3'b010, vd, 7'b1010111};
  endfunction

  // Fill register with repeated byte
  task vrf_fill;
    input [4:0] addr;
    input [7:0] val;
    integer b;
    reg [DLEN-1:0] tmp;
    begin
      tmp = {DLEN{1'b0}};
      for (b = 0; b < DLEN/8; b = b + 1)
        tmp[b*8 +: 8] = val;
      @(posedge clk);
      dma_valid <= 1; dma_we <= 1; dma_addr <= addr; dma_wdata <= tmp; dma_be <= {(DLEN/8){1'b1}};
      @(posedge clk);
      dma_valid <= 0; dma_we <= 0;
    end
  endtask

  task vrf_read_reg;
    input [4:0] addr;
    begin
      @(posedge clk); dma_valid <= 1; dma_we <= 0; dma_addr <= addr;
      @(posedge clk); dma_valid <= 0;  // Request accepted this cycle (NBA from prev)
      @(posedge clk);                  // VRF BRAM output register
      @(posedge clk); actual = dma_rdata;  // rvalid + rdata available
    end
  endtask

  task issue_one;
    input [31:0] instr;
    input [7:0] id;
    begin
      @(posedge clk);
      x_issue_valid <= 1; x_issue_instr <= instr; x_issue_id <= id;
      @(posedge clk);
      while (!x_issue_ready) @(posedge clk);
      x_issue_valid <= 0;
    end
  endtask

  // Build expected_val with repeated byte
  task build_expected;
    input [7:0] val;
    integer b;
    begin
      expected_val = {DLEN{1'b0}};
      for (b = 0; b < DLEN/8; b = b + 1)
        expected_val[b*8 +: 8] = val;
    end
  endtask

  task check_result;
    input [4:0] vreg;
    input [7:0] exp_byte;
    input [199:0] label;
    begin
      vrf_read_reg(vreg);
      build_expected(exp_byte);
      total_tests = total_tests + 1;
      if (actual !== expected_val) begin
        $display("  FAIL: v%0d exp=0x%02h act=0x%02h (%0s)", vreg, exp_byte, actual[7:0], label);
        total_errors = total_errors + 1;
      end else
        $display("  PASS: v%0d = 0x%02h", vreg, actual[7:0]);
    end
  endtask

  initial begin
    $display("\n##################################################");
    $display("### HAZARD PATTERN TEST (v0.4b)");
    $display("### VLEN=%0d, DLEN=%0d, NLANES=%0d", VLEN, DLEN, NLANES);
    $display("##################################################\n");

    total_tests = 0; total_errors = 0;

    // Reset
    rst_n <= 0; x_issue_valid <= 0; x_issue_instr <= 0;
    x_issue_id <= 0; x_issue_rs1 <= 0; x_issue_rs2 <= 0;
    x_result_ready <= 1; dma_valid <= 0; dma_we <= 0;
    dma_addr <= 0; dma_wdata <= 0; dma_be <= 0;
    csr_vtype <= 0; csr_vl <= VLMAX_8;
    repeat (10) @(posedge clk);
    rst_n <= 1;
    repeat (5) @(posedge clk);
    csr_vtype <= {25'b0, 3'b000, 3'b000};
    csr_vl <= VLMAX_8;
    @(posedge clk);

    //========================================================================
    // GROUP 1: MAC -> non-MAC (RAW)
    // vmacc v4,v2,v3 => v4=0+2*3=6; [fillers]; vadd v5,v4,v1 => v5=6+16=22
    //========================================================================
    $display("=== GROUP 1: MAC -> non-MAC (RAW hazard) ===");
    for (d = 1; d <= 6; d = d + 1) begin
      $display("\n--- Distance %0d ---", d);
      vrf_fill(5'd1, 8'h10); vrf_fill(5'd2, 8'h02);
      vrf_fill(5'd3, 8'h03); vrf_fill(5'd4, 8'h00);
      vrf_fill(5'd5, 8'h00);
      repeat(5) @(posedge clk);
      issue_one(enc_vmacc(5'd4, 5'd2, 5'd3), 8'd1);
      for (fi = 0; fi < d - 1; fi = fi + 1)
        issue_one(enc_vand(5'd20, 5'd1, 5'd1), 8'd10);
      issue_one(enc_vadd(5'd5, 5'd4, 5'd1), 8'd2);
      repeat(30) @(posedge clk);
      check_result(5'd5, 8'h16, "RAW mac->add");
    end

    //========================================================================
    // GROUP 2: non-MAC -> MAC (RAW on accumulator)
    // vadd v6,v3,v4 => v6=0x10+0x05=0x15; [fillers]; vmacc v6,v1,v2 => v6=0x15+6=0x1B
    //========================================================================
    $display("\n=== GROUP 2: non-MAC -> MAC (RAW on accum) ===");
    for (d = 1; d <= 6; d = d + 1) begin
      $display("\n--- Distance %0d ---", d);
      vrf_fill(5'd1, 8'h02); vrf_fill(5'd2, 8'h03);
      vrf_fill(5'd3, 8'h10); vrf_fill(5'd4, 8'h05);
      vrf_fill(5'd6, 8'hFF);
      repeat(5) @(posedge clk);
      issue_one(enc_vadd(5'd6, 5'd3, 5'd4), 8'd20);
      for (fi = 0; fi < d - 1; fi = fi + 1)
        issue_one(enc_vand(5'd20, 5'd1, 5'd1), 8'd30);
      issue_one(enc_vmacc(5'd6, 5'd1, 5'd2), 8'd21);
      repeat(30) @(posedge clk);
      check_result(5'd6, 8'h1B, "RAW add->mac");
    end

    //========================================================================
    // GROUP 3: MAC -> MAC same dest (WAW + RAW)
    // vmacc v7,v1,v2 => v7=0+6=6; [fillers]; vmacc v7,v1,v2 => v7=6+6=12
    //========================================================================
    $display("\n=== GROUP 3: MAC -> MAC same dest (WAW+RAW) ===");
    for (d = 1; d <= 6; d = d + 1) begin
      $display("\n--- Distance %0d ---", d);
      vrf_fill(5'd1, 8'h02); vrf_fill(5'd2, 8'h03);
      vrf_fill(5'd7, 8'h00);
      repeat(5) @(posedge clk);
      issue_one(enc_vmacc(5'd7, 5'd1, 5'd2), 8'd40);
      for (fi = 0; fi < d - 1; fi = fi + 1)
        issue_one(enc_vand(5'd20, 5'd1, 5'd1), 8'd50);
      issue_one(enc_vmacc(5'd7, 5'd1, 5'd2), 8'd41);
      repeat(30) @(posedge clk);
      check_result(5'd7, 8'h0C, "WAW mac->mac");
    end

    //========================================================================
    // GROUP 4: VMUL -> non-MAC (E1m RAW)
    // vmul v9,v2,v3 => v9=6; [fillers]; vadd v9,v9,v1 => v9=6+16=22
    //========================================================================
    $display("\n=== GROUP 4: VMUL -> non-MAC (E1m RAW) ===");
    for (d = 1; d <= 6; d = d + 1) begin
      $display("\n--- Distance %0d ---", d);
      vrf_fill(5'd1, 8'h10); vrf_fill(5'd2, 8'h02);
      vrf_fill(5'd3, 8'h03); vrf_fill(5'd9, 8'h00);
      repeat(5) @(posedge clk);
      issue_one(enc_vmul(5'd9, 5'd2, 5'd3), 8'd80);
      for (fi = 0; fi < d - 1; fi = fi + 1)
        issue_one(enc_vand(5'd20, 5'd1, 5'd1), 8'd90);
      issue_one(enc_vadd(5'd9, 5'd9, 5'd1), 8'd81);
      repeat(30) @(posedge clk);
      check_result(5'd9, 8'h16, "RAW mul->add");
    end

    //========================================================================
    $display("\n##################################################");
    $display("### HAZARD TEST SUMMARY");
    $display("##################################################");
    $display("  Total: %0d  Passed: %0d  Failed: %0d",
             total_tests, total_tests - total_errors, total_errors);
    if (total_errors == 0)
      $display("\n  HAZARD TEST PASS");
    else
      $display("\n  HAZARD TEST FAIL");
    $display("##################################################\n");
    #100; $finish;
  end

endmodule
