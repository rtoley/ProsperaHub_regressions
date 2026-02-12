//==============================================================================
// Test: test_reduction_timing.sv
// Verify 300 MHz timing changes (split reduction pipeline)
//==============================================================================

`timescale 1ns/1ps

module test_reduction_timing;

  import hp_vpu_pkg::*;

  //----------------------------------------------------------------------------
  // Testbench Signals
  //----------------------------------------------------------------------------
  logic clk;
  logic rst_n;

  // Pipeline interface
  logic                      issue_valid;
  logic                      issue_ready;
  logic [31:0]               issue_instr;
  logic [CVXIF_ID_W-1:0]     issue_id;
  logic [31:0]               issue_rs1;
  logic [31:0]               issue_rs2;

  logic                      result_valid;
  logic                      result_ready;
  logic [CVXIF_ID_W-1:0]     result_id;
  logic [31:0]               result_data;
  logic                      result_we;

  // Other top-level signals (dummy)
  logic [31:0] csr_vtype, csr_vl;
  logic [31:0] csr_vtype_o, csr_vl_o;
  logic        csr_vl_valid_o;
  logic        exc_valid_o;
  logic [31:0] exc_cause_o;
  logic        busy_o;
  logic [31:0] perf_cnt_o;

  // Simulation control
  integer cycle_count = 0;
  integer tests_passed = 0;
  integer tests_failed = 0;

  //----------------------------------------------------------------------------
  // DUT Instantiation
  //----------------------------------------------------------------------------
  hp_vpu_top #(
    .VLEN(256),
    .NLANES(4)
  ) dut (
    .clk              (clk),
    .rst_n            (rst_n),
    .x_issue_valid_i  (issue_valid),
    .x_issue_ready_o  (issue_ready),
    .x_issue_accept_o (),
    .x_issue_instr_i  (issue_instr),
    .x_issue_id_i     (issue_id),
    .x_issue_rs1_i    (issue_rs1),
    .x_issue_rs2_i    (issue_rs2),
    .x_result_valid_o (result_valid),
    .x_result_ready_i (result_ready),
    .x_result_id_o    (result_id),
    .x_result_data_o  (result_data),
    .x_result_we_o    (result_we),
    .csr_vtype_i      (csr_vtype),
    .csr_vl_i         (csr_vl),
    .csr_vtype_o      (csr_vtype_o),
    .csr_vl_o         (csr_vl_o),
    .csr_vl_valid_o   (csr_vl_valid_o),
    .csr_req_i        (1'b0),
    .csr_we_i         (1'b0),
    .csr_addr_i       ('0),
    .csr_wdata_i      ('0),
    .exc_ack_i        (1'b0),
    .dma_valid_i      (1'b0),
    .dma_we_i         (1'b0),
    .dma_addr_i       ('0),
    .dma_wdata_i      ('0),
    .dma_be_i         ('0),
    // v0.5e: Weight double-buffer (disabled)
    .dma_dbuf_en_i    (1'b0),
    .dma_dbuf_swap_i  (1'b0),
    .x_commit_valid_i (1'b0),
    .x_commit_id_i    ('0),
    .x_commit_kill_i  (1'b0),
    .busy_o           (busy_o),
    .perf_cnt_o       (perf_cnt_o)
  );

  //----------------------------------------------------------------------------
  // Clock Generation
  //----------------------------------------------------------------------------
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  always @(posedge clk) cycle_count <= cycle_count + 1;

  //----------------------------------------------------------------------------
  // Helper Tasks
  //----------------------------------------------------------------------------

  // Issue instruction
  task issue_instr_raw(input [31:0] instr, input [7:0] id, input [31:0] rs1, input [31:0] rs2);
    @(posedge clk);
    issue_valid <= 1;
    issue_instr <= instr;
    issue_id    <= id;
    issue_rs1   <= rs1;
    issue_rs2   <= rs2;
    @(posedge clk);
    while (!issue_ready) @(posedge clk);
    issue_valid <= 0;
  endtask

  // Configure VPU (set vtype and vl)
  task vsetvli(input [2:0] sew, input [2:0] lmul, input [31:0] vl);
    logic [31:0] instr;
    // vsetvli rd, rs1, vtype (rd=x0, rs1=vl)
    // vtype: 0 | vsew[2:0] | vlmul[2:0]
    // opcode=1010111, funct3=111
    instr = {1'b0, {4'b0, sew, lmul}, 5'd1, 3'b111, 5'd0, 7'b1010111};

    // We provide rs1 value directly (bypass regfile read in core)
    issue_instr_raw(instr, 8'h0, vl, 0);

    // Wait for config to apply
    repeat(2) @(posedge clk);
  endtask

  // Build Vector Instruction
  function [31:0] build_v_instr(
    input [5:0] funct6,
    input       vm,
    input [4:0] vs2,
    input [4:0] vs1,
    input [2:0] funct3,
    input [4:0] vd
  );
    return {funct6, vm, vs2, vs1, funct3, vd, 7'b1010111};
  endfunction

  //----------------------------------------------------------------------------
  // Test Cases
  //----------------------------------------------------------------------------

  // Test 1: Verify reduction latency
  // Old pipeline: R1 -> R2 -> R3 -> WB (4 cycles)
  // New pipeline: R1 -> R2a -> R2b -> R3 -> WB (5 cycles)
  // Total latency from issue should be ~6 cycles
  task test_reduction_latency();
    integer start_cycle;
    integer latency;
    logic [31:0] instr;

    $display("Test 1: Reduction Latency Check");

    // vredsum.vs vd=1, vs2=2, vs1=3
    // funct6=000000, vm=1, vs2=2, vs1=3, funct3=010 (OPIVV), vd=1
    instr = build_v_instr(6'b000000, 1'b1, 5'd2, 5'd3, 3'b010, 5'd1);

    start_cycle = cycle_count;
    issue_instr_raw(instr, 8'h10, 0, 0);

    // Wait for result
    while (!result_valid || result_id != 8'h10) @(posedge clk);

    latency = cycle_count - start_cycle;
    $display("  Latency: %0d cycles", latency);

    // Original was ~5 cycles from issue to result valid
    // New should be ~6 cycles
    if (latency == 6) begin
      $display("  PASS: Latency is 6 cycles as expected");
      tests_passed++;
    end else begin
      $display("  FAIL: Expected 6 cycles, got %0d", latency);
      tests_failed++;
    end
  endtask

  // Test 2: Back-to-back hazard
  // Issue vredsum (writes v1) followed immediately by instruction reading v1
  // Should stall correctly
  task test_reduction_hazard();
    logic [31:0] instr1, instr2;
    integer issue1_cycle, issue2_cycle;

    $display("Test 2: Back-to-back Hazard Check");

    // 1. vredsum.vs v1, v2, v3
    instr1 = build_v_instr(6'b000000, 1'b1, 5'd2, 5'd3, 3'b010, 5'd1);

    // 2. vadd.vv v4, v1, v2 (reads v1 produced by reduction)
    instr2 = build_v_instr(6'b000000, 1'b1, 5'd1, 5'd2, 3'b000, 5'd4);

    fork
      begin
        // Thread 1: Issue instructions
        wait(clk);
        issue_valid <= 1;
        issue_instr <= instr1;
        issue_id    <= 8'h20;
        @(posedge clk);
        issue1_cycle = cycle_count;

        // Try to issue next immediately
        while (!issue_ready) @(posedge clk);
        issue_instr <= instr2;
        issue_id    <= 8'h21;
        @(posedge clk);

        // If we stalled, this cycle count will be significantly later
        issue2_cycle = cycle_count;
        issue_valid <= 0;
      end

      begin
        // Thread 2: Monitor stalls
        // We expect issue_ready to go low for several cycles while reduction is in flight
      end
    join

    $display("  Issue 1 cycle: %0d", issue1_cycle);
    $display("  Issue 2 cycle: %0d", issue2_cycle);
    $display("  Stall cycles: %0d", issue2_cycle - issue1_cycle);

    // Reduction takes ~5 cycles in execution. Hazard unit should stall decode/issue
    // until reduction is complete or near complete.
    if ((issue2_cycle - issue1_cycle) >= 5) begin
      $display("  PASS: Stalled sufficiently for hazard resolution");
      tests_passed++;
    end else begin
      $display("  FAIL: Insufficient stall (%0d cycles)", issue2_cycle - issue1_cycle);
      tests_failed++;
    end

    // Clean up results
    wait(result_valid && result_id == 8'h21);
    @(posedge clk);
  endtask

  //----------------------------------------------------------------------------
  // Main Test Process
  //----------------------------------------------------------------------------
  initial begin
    // Initialize
    rst_n = 0;
    issue_valid = 0;
    issue_instr = 0;
    result_ready = 1; // Always accept results

    repeat(10) @(posedge clk);
    rst_n = 1;
    repeat(10) @(posedge clk);

    // Configure VPU
    vsetvli(3'b010, 3'b000, 32'd256); // SEW=32, LMUL=1, VL=256

    // Run tests
    test_reduction_latency();
    repeat(20) @(posedge clk);

    test_reduction_hazard();
    repeat(20) @(posedge clk);

    // Report
    $display("\n--------------------------------------------------");
    $display("Passed: %0d", tests_passed);
    $display("Failed: %0d", tests_failed);
    $display("--------------------------------------------------");

    if (tests_failed == 0)
      $display("ALL TESTS PASSED");
    else
      $display("SOME TESTS FAILED");

    $finish;
  end

endmodule
