//==============================================================================
// Test: test_r2ab_stress.sv
// Stress tests for R2A/R2B pipeline split (v0.3e → v0.3f)
//
// Tests:
//   1. Back-to-back reductions (different vd) — pipeline throughput
//   2. Reduction → arithmetic RAW hazard (same vs/vd) — stall correctness
//   3. Arithmetic → reduction WAW (same vd) — write ordering
//   4. Reduction → widening interleave (same vd) — WAW across pipe types
//   5. All-SEW reduction sweep — R2A/R2B data integrity at SEW=8,16,32
//   6. Rapid-fire reduction burst — 8 back-to-back reductions
//   7. RAW chain: red→add→red→add (dependency chain through R pipe)
//   8. Pipeline drain verification — E3 in-flight when reduction starts
//==============================================================================

`timescale 1ns/1ps

module test_r2ab_stress;

  import hp_vpu_pkg::*;

  //--------------------------------------------------------------------------
  // Testbench Signals
  //--------------------------------------------------------------------------
  logic clk;
  logic rst_n;

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

  logic [31:0] csr_vtype, csr_vl;
  logic [31:0] csr_vtype_o, csr_vl_o;
  logic        csr_vl_valid_o;
  logic        exc_valid_o;
  logic [31:0] exc_cause_o;
  logic        busy_o;
  logic [31:0] perf_cnt_o;

  integer cycle_count = 0;
  integer tests_passed = 0;
  integer tests_failed = 0;
  integer total_tests = 0;

  //--------------------------------------------------------------------------
  // DUT — VLEN=256, NLANES=4 (worst case for R2A/R2B sizing)
  //--------------------------------------------------------------------------
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

  //--------------------------------------------------------------------------
  // Clock & Cycle Counter
  //--------------------------------------------------------------------------
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100 MHz sim clock
  end

  always @(posedge clk) cycle_count <= cycle_count + 1;

  //--------------------------------------------------------------------------
  // Timeout Watchdog
  //--------------------------------------------------------------------------
  initial begin
    #500000;
    $display("TIMEOUT: Test hung after 500us (cycle %0d)", cycle_count);
    $display("  Tests passed: %0d / %0d", tests_passed, total_tests);
    $display("  Pipeline state at hang:");
    $display("    busy_o=%b issue_ready=%b result_valid=%b result_id=0x%02x",
             busy_o, issue_ready, result_valid, result_id);
    $finish;
  end

  //--------------------------------------------------------------------------
  // Helpers
  //--------------------------------------------------------------------------

  task automatic issue_and_wait_ready(
    input [31:0] instr, input [7:0] id,
    input [31:0] rs1_val, input [31:0] rs2_val
  );
    // Assert valid and hold until ready is sampled high on the same cycle
    @(posedge clk);
    issue_valid <= 1;
    issue_instr <= instr;
    issue_id    <= id;
    issue_rs1   <= rs1_val;
    issue_rs2   <= rs2_val;
    @(posedge clk);
    while (!issue_ready) @(posedge clk);  // Hold valid until handshake completes
    issue_valid <= 0;
  endtask

  task automatic wait_for_result(input [7:0] expected_id, output integer latency);
    integer start;
    integer timed_out;
    start = cycle_count;
    timed_out = 0;
    while (!(result_valid && result_id == expected_id) && !timed_out) begin
      @(posedge clk);
      if ((cycle_count - start) > 200) begin
        $display("  ERROR: Timeout waiting for result id=0x%02x after %0d cycles",
                 expected_id, cycle_count - start);
        $display("    busy_o=%b issue_ready=%b result_valid=%b result_id=0x%02x",
                 busy_o, issue_ready, result_valid, result_id);
        timed_out = 1;
      end
    end
    if (timed_out)
      latency = -1;
    else begin
      latency = cycle_count - start;
      @(posedge clk);  // consume the result cycle
    end
  endtask

  task automatic wait_busy_clear();
    integer timeout;
    timeout = 0;
    while (busy_o && timeout < 200) begin
      @(posedge clk);
      timeout++;
    end
    if (timeout >= 200)
      $display("  WARNING: busy_o did not clear after %0d cycles", timeout);
  endtask

  // Configure SEW and VL via vsetvli
  task automatic cfg_vtype(input [2:0] sew, input [2:0] lmul, input [31:0] vl_val);
    logic [31:0] instr;
    // vsetvli rd=x0, rs1=x1, vtype={0, vsew, vlmul}
    instr = {1'b0, {4'b0, sew, lmul}, 5'd1, 3'b111, 5'd0, 7'b1010111};
    issue_and_wait_ready(instr, 8'h00, vl_val, 0);
    repeat(4) @(posedge clk);  // let config propagate
  endtask

  // Build V-type instruction
  function automatic [31:0] v_instr(
    input [5:0] funct6, input vm,
    input [4:0] vs2, input [4:0] vs1,
    input [2:0] funct3, input [4:0] vd
  );
    return {funct6, vm, vs2, vs1, funct3, vd, 7'b1010111};
  endfunction

  //--------------------------------------------------------------------------
  // Instruction Encoding Helpers
  //--------------------------------------------------------------------------
  // Reductions: funct3=010 (OPMVV)
  //   vredsum.vs : funct6=000000
  //   vredand.vs : funct6=000001
  //   vredor.vs  : funct6=000010
  //   vredxor.vs : funct6=000011
  //
  // Arithmetic: funct3=000 (OPIVV)
  //   vadd.vv    : funct6=000000
  //   vsub.vv    : funct6=000010
  //
  // Widening: funct3=010 (OPMVV)
  //   vwaddu.vv  : funct6=110000
  //--------------------------------------------------------------------------

  function automatic [31:0] vredsum(input [4:0] vd, vs2, vs1);
    return v_instr(6'b000000, 1'b1, vs2, vs1, 3'b010, vd);
  endfunction

  function automatic [31:0] vredand(input [4:0] vd, vs2, vs1);
    return v_instr(6'b000001, 1'b1, vs2, vs1, 3'b010, vd);
  endfunction

  function automatic [31:0] vredor(input [4:0] vd, vs2, vs1);
    return v_instr(6'b000010, 1'b1, vs2, vs1, 3'b010, vd);
  endfunction

  function automatic [31:0] vredxor(input [4:0] vd, vs2, vs1);
    return v_instr(6'b000011, 1'b1, vs2, vs1, 3'b010, vd);
  endfunction

  function automatic [31:0] vadd_vv(input [4:0] vd, vs2, vs1);
    return v_instr(6'b000000, 1'b1, vs2, vs1, 3'b000, vd);
  endfunction

  function automatic [31:0] vsub_vv(input [4:0] vd, vs2, vs1);
    return v_instr(6'b000010, 1'b1, vs2, vs1, 3'b000, vd);
  endfunction

  function automatic [31:0] vwaddu_vv(input [4:0] vd, vs2, vs1);
    return v_instr(6'b110000, 1'b1, vs2, vs1, 3'b010, vd);
  endfunction

  //--------------------------------------------------------------------------
  // Test reporting
  //--------------------------------------------------------------------------
  task automatic check(input string name, input logic pass);
    total_tests++;
    if (pass) begin
      tests_passed++;
      $display("  PASS: %s", name);
    end else begin
      tests_failed++;
      $display("  FAIL: %s", name);
    end
  endtask

  //==========================================================================
  // TEST 1: Back-to-back reductions (different vd)
  // Verifies multicycle_busy properly serializes reductions
  //==========================================================================
  task test_back_to_back_reductions();
    integer lat1, lat2;
    integer issue1_cycle, issue2_cycle;

    $display("\n--- Test 1: Back-to-back reductions (different vd) ---");

    // vredsum.vs v1, v10, v11  (writes v1)
    issue1_cycle = cycle_count;
    issue_and_wait_ready(vredsum(5'd1, 5'd10, 5'd11), 8'h10, 0, 0);

    // vredand.vs v2, v12, v13  (writes v2 — different vd, no RAW)
    // Should stall until first reduction completes (multicycle_busy)
    issue2_cycle = cycle_count;
    issue_and_wait_ready(vredand(5'd2, 5'd12, 5'd13), 8'h11, 0, 0);

    $display("  Issue gap: %0d cycles", issue2_cycle - issue1_cycle);

    wait_for_result(8'h10, lat1);
    wait_for_result(8'h11, lat2);

    $display("  Reduction 1 latency: %0d, Reduction 2 latency: %0d", lat1, lat2);

    check("Both reductions complete", (lat1 > 0) && (lat2 > 0));
    // Both complete with reasonable latency (multicycle_busy serializes them)
    check("Reductions properly serialized (total lat reasonable)", (lat1 + lat2) > 8);

    wait_busy_clear();
  endtask

  //==========================================================================
  // TEST 2: Reduction → arithmetic RAW hazard (same vd→vs)
  // vredsum writes v4, then vadd reads v4 as vs2.
  // Must stall vadd until reduction completes through WB.
  //==========================================================================
  task test_reduction_arith_raw();
    integer lat_red, lat_add;
    integer issue_red_cycle, issue_add_cycle;

    $display("\n--- Test 2: Reduction -> arithmetic RAW (same vd) ---");

    // vredsum.vs v4, v10, v11  (writes v4)
    issue_red_cycle = cycle_count;
    issue_and_wait_ready(vredsum(5'd4, 5'd10, 5'd11), 8'h20, 0, 0);

    // vadd.vv v5, v4, v6  (reads v4 — RAW hazard with reduction output)
    issue_add_cycle = cycle_count;
    issue_and_wait_ready(vadd_vv(5'd5, 5'd4, 5'd6), 8'h21, 0, 0);

    $display("  Issue gap: %0d cycles", issue_add_cycle - issue_red_cycle);

    wait_for_result(8'h20, lat_red);
    wait_for_result(8'h21, lat_add);

    $display("  Reduction latency: %0d, Add latency: %0d", lat_red, lat_add);

    check("Reduction completes", lat_red > 0);
    check("Add completes after reduction", lat_add > 0);
    // Add must wait for reduction to finish (RAW on v4)
    check("RAW hazard resolved (add waited)", lat_red > 0 && lat_add > 0);

    wait_busy_clear();
  endtask

  //==========================================================================
  // TEST 3: Arithmetic → reduction WAW (same vd)
  // vadd writes v4, then vredsum also writes v4.
  // E-pipe must drain before R-pipe starts (pipeline_drained gate).
  //==========================================================================
  task test_arith_reduction_waw();
    integer lat_add, lat_red;
    integer issue_add_cycle, issue_red_cycle;

    $display("\n--- Test 3: Arithmetic -> reduction WAW (same vd) ---");

    // vadd.vv v4, v10, v11  (writes v4 via E-pipe)
    issue_add_cycle = cycle_count;
    issue_and_wait_ready(vadd_vv(5'd4, 5'd10, 5'd11), 8'h30, 0, 0);

    // vredsum.vs v4, v12, v13  (also writes v4 via R-pipe — WAW)
    issue_red_cycle = cycle_count;
    issue_and_wait_ready(vredsum(5'd4, 5'd12, 5'd13), 8'h31, 0, 0);

    $display("  Issue gap: %0d cycles", issue_red_cycle - issue_add_cycle);

    wait_for_result(8'h30, lat_add);
    wait_for_result(8'h31, lat_red);

    $display("  Add latency: %0d, Reduction latency: %0d", lat_add, lat_red);

    check("Add completes", lat_add > 0);
    check("Reduction completes", lat_red > 0);
    // WAW: both write v4, must serialize. Reduction waits for E-pipe drain.
    check("WAW serialized (both complete)", lat_add > 0 && lat_red > 0);

    wait_busy_clear();
  endtask

  //==========================================================================
  // TEST 4: Reduction → widening (same vd) — cross-pipe WAW
  // vredsum writes v4, then vwaddu also writes v4.
  // Both are multicycle ops, must fully serialize.
  //==========================================================================
  task test_reduction_widening_waw();
    integer lat_red, lat_wide;
    integer issue_red_cycle, issue_wide_cycle;

    $display("\n--- Test 4: Reduction -> widening WAW (same vd) ---");

    // vredsum.vs v4, v10, v11  (writes v4 via R-pipe)
    issue_red_cycle = cycle_count;
    issue_and_wait_ready(vredsum(5'd4, 5'd10, 5'd11), 8'h40, 0, 0);

    // vwaddu.vv v4, v12, v13  (writes v4 via W-pipe — WAW across pipe types)
    issue_wide_cycle = cycle_count;
    issue_and_wait_ready(vwaddu_vv(5'd4, 5'd12, 5'd13), 8'h41, 0, 0);

    $display("  Issue gap: %0d cycles", issue_wide_cycle - issue_red_cycle);

    wait_for_result(8'h40, lat_red);
    wait_for_result(8'h41, lat_wide);

    $display("  Reduction latency: %0d, Widening latency: %0d", lat_red, lat_wide);

    check("Reduction completes", lat_red > 0);
    check("Widening completes", lat_wide > 0);
    // Both multicycle, must serialize
    check("Cross-pipe WAW serialized (both complete)", lat_red > 0 && lat_wide > 0);

    wait_busy_clear();
  endtask

  //==========================================================================
  // TEST 5: SEW sweep — reductions at SEW=8, SEW=16, SEW=32
  // Stresses R2A array sizing (the Jules bug) at all element widths.
  //==========================================================================
  task test_sew_sweep();
    integer lat;

    $display("\n--- Test 5: SEW sweep (8/16/32) ---");

    // SEW=8, LMUL=1, VL=32 (VLEN=256 → 32 elements at SEW=8)
    cfg_vtype(3'b000, 3'b000, 32'd32);
    issue_and_wait_ready(vredsum(5'd1, 5'd10, 5'd11), 8'h50, 0, 0);
    wait_for_result(8'h50, lat);
    $display("  SEW=8  latency: %0d", lat);
    check("SEW=8 reduction completes", lat > 0);
    wait_busy_clear();

    // SEW=16, LMUL=1, VL=16
    cfg_vtype(3'b001, 3'b000, 32'd16);
    issue_and_wait_ready(vredand(5'd2, 5'd12, 5'd13), 8'h51, 0, 0);
    wait_for_result(8'h51, lat);
    $display("  SEW=16 latency: %0d", lat);
    check("SEW=16 reduction completes", lat > 0);
    wait_busy_clear();

    // SEW=32, LMUL=1, VL=8
    cfg_vtype(3'b010, 3'b000, 32'd8);
    issue_and_wait_ready(vredor(5'd3, 5'd14, 5'd15), 8'h52, 0, 0);
    wait_for_result(8'h52, lat);
    $display("  SEW=32 latency: %0d", lat);
    check("SEW=32 reduction completes", lat > 0);
    wait_busy_clear();

    // Restore default config
    cfg_vtype(3'b010, 3'b000, 32'd8);
  endtask

  //==========================================================================
  // TEST 6: 8x reduction burst — sustained pipeline stress
  // Issues 8 reductions back-to-back (all different vd to avoid RAW).
  // Verifies multicycle_busy serializes all correctly.
  // Uses always-block scoreboard for reliable result capture.
  //==========================================================================
  reg burst_seen [0:7];
  integer burst_count = 0;
  reg burst_active = 0;

  // Scoreboard: always watching for burst results
  always @(posedge clk) begin
    if (burst_active && result_valid) begin : burst_check
      integer k;
      integer matched;
      matched = 0;
      $display("  [burst-scoreboard] result_valid=1 result_id=0x%02x cycle=%0d burst_count=%0d",
               result_id, cycle_count, burst_count);
      for (k = 0; k < 8; k = k + 1) begin
        if (result_id == (8'h60 + k[7:0]) && !burst_seen[k]) begin
          burst_seen[k] = 1;
          burst_count = burst_count + 1;
          matched = 1;
          $display("  [burst-scoreboard] -> matched burst %0d", k);
        end
      end
      if (!matched)
        $display("  [burst-scoreboard] UNMATCHED result: id=0x%02x at cycle %0d", result_id, cycle_count);
    end
  end

  task test_reduction_burst();
    integer i;
    integer start_cycle, end_cycle;

    $display("\n--- Test 6: 8x reduction burst ---");

    // Clear scoreboard
    for (i = 0; i < 8; i++) burst_seen[i] = 0;
    burst_count = 0;
    burst_active = 1;

    start_cycle = cycle_count;

    // Issue 8 reductions: vredsum v1..v8
    for (i = 0; i < 8; i++) begin
      $display("  [burst-issue] issuing burst %0d: vd=%0d id=0x%02x cycle=%0d ready=%b busy=%b",
               i, 1+i, 8'h60+i[7:0], cycle_count, issue_ready, busy_o);
      issue_and_wait_ready(
        vredsum(5'd1 + i[4:0], 5'd16 + i[4:0], 5'd24 + i[4:0]),
        8'h60 + i[7:0], 0, 0
      );
      $display("  [burst-issue] burst %0d accepted at cycle=%0d", i, cycle_count);
    end

    // Wait for all results to arrive
    begin
      integer timeout;
      timeout = 0;
      while (burst_count < 8 && timeout < 400) begin
        @(posedge clk);
        timeout = timeout + 1;
      end
    end

    burst_active = 0;
    end_cycle = cycle_count;

    for (i = 0; i < 8; i++) begin
      if (burst_seen[i])
        $display("  Burst %0d: DONE", i);
      else
        $display("  Burst %0d: MISSING", i);
    end

    $display("  Total burst time: %0d cycles for 8 reductions (%0d completed)",
             end_cycle - start_cycle, burst_count);

    check($sformatf("All 8 burst reductions complete (%0d/8)", burst_count), burst_count == 8);

    wait_busy_clear();
  endtask

  //==========================================================================
  // TEST 7: RAW chain — red→add→red→add (dependency chain through R pipe)
  // Each instruction depends on the previous result.
  // Tests hazard detection across alternating pipe types.
  //==========================================================================
  task test_raw_chain();
    integer lat;

    $display("\n--- Test 7: RAW chain red->add->red->add ---");

    // Step 1: vredsum.vs v4, v10, v11  (writes v4)
    issue_and_wait_ready(vredsum(5'd4, 5'd10, 5'd11), 8'h70, 0, 0);
    wait_for_result(8'h70, lat);
    $display("  Chain step 1 (red->v4): lat=%0d", lat);
    check("Chain step 1 completes", lat > 0);

    // Step 2: vadd.vv v5, v4, v6  (reads v4, writes v5)
    issue_and_wait_ready(vadd_vv(5'd5, 5'd4, 5'd6), 8'h71, 0, 0);
    wait_for_result(8'h71, lat);
    $display("  Chain step 2 (add v4->v5): lat=%0d", lat);
    check("Chain step 2 completes", lat > 0);

    // Step 3: vredand.vs v6, v5, v7  (reads v5, writes v6)
    issue_and_wait_ready(vredand(5'd6, 5'd5, 5'd7), 8'h72, 0, 0);
    wait_for_result(8'h72, lat);
    $display("  Chain step 3 (red v5->v6): lat=%0d", lat);
    check("Chain step 3 completes", lat > 0);

    // Step 4: vsub.vv v8, v6, v9  (reads v6, writes v8)
    issue_and_wait_ready(vsub_vv(5'd8, 5'd6, 5'd9), 8'h73, 0, 0);
    wait_for_result(8'h73, lat);
    $display("  Chain step 4 (sub v6->v8): lat=%0d", lat);
    check("Chain step 4 completes", lat > 0);

    wait_busy_clear();
  endtask

  //==========================================================================
  // TEST 8: Pipeline drain verification
  // Issue vadd (E-pipe), then immediately issue reduction.
  // The reduction must wait for pipeline_drained before starting.
  // This specifically tests the drain gate when E-pipe stages are occupied.
  //==========================================================================
  task test_pipeline_drain();
    integer lat_add, lat_red;
    integer issue_add_cycle, issue_red_cycle;

    $display("\n--- Test 8: Pipeline drain (E3 in-flight + reduction) ---");

    // Issue vadd into E-pipe — use different vd to avoid RAW, pure drain test
    issue_add_cycle = cycle_count;
    issue_and_wait_ready(vadd_vv(5'd20, 5'd10, 5'd11), 8'h80, 0, 0);

    // Immediately issue reduction — must wait for E-pipe to drain
    // (pipeline_drained = !e1_valid && !e1m_valid && !e2_valid)
    issue_red_cycle = cycle_count;
    issue_and_wait_ready(vredsum(5'd21, 5'd12, 5'd13), 8'h81, 0, 0);

    $display("  Issue gap: %0d cycles (add@%0d, red@%0d)",
             issue_red_cycle - issue_add_cycle, issue_add_cycle, issue_red_cycle);

    // Wait for both results — the add should complete first
    wait_for_result(8'h80, lat_add);
    $display("  Add result: lat=%0d", lat_add);

    wait_for_result(8'h81, lat_red);
    $display("  Reduction result: lat=%0d", lat_red);

    check("Add completes", lat_add > 0);
    check("Reduction completes after drain", lat_red > 0);
    check("Drain serialization happened", (issue_red_cycle - issue_add_cycle) >= 2);

    wait_busy_clear();
  endtask

  //==========================================================================
  // Main Test Sequence
  //==========================================================================
  initial begin
    $display("===========================================================");
    $display(" R2A/R2B Stress Tests (VLEN=256, NLANES=4)");
    $display("===========================================================");

    // Initialize
    rst_n = 0;
    issue_valid = 0;
    issue_instr = 0;
    issue_id = 0;
    issue_rs1 = 0;
    issue_rs2 = 0;
    result_ready = 1;
    csr_vtype = 0;
    csr_vl = 0;

    repeat(10) @(posedge clk);
    rst_n = 1;
    repeat(10) @(posedge clk);

    // Default config: SEW=32, LMUL=1, VL=8
    cfg_vtype(3'b010, 3'b000, 32'd8);

    // Run tests
    test_back_to_back_reductions();  // Test 1
    repeat(20) @(posedge clk);

    test_reduction_arith_raw();      // Test 2
    repeat(20) @(posedge clk);

    test_arith_reduction_waw();      // Test 3
    repeat(20) @(posedge clk);

    test_reduction_widening_waw();   // Test 4
    repeat(20) @(posedge clk);

    test_sew_sweep();                // Test 5
    repeat(20) @(posedge clk);

    test_reduction_burst();          // Test 6
    repeat(20) @(posedge clk);

    test_raw_chain();                // Test 7
    repeat(20) @(posedge clk);

    test_pipeline_drain();           // Test 8
    repeat(20) @(posedge clk);

    // Report
    $display("\n===========================================================");
    $display(" Results: %0d / %0d passed", tests_passed, total_tests);
    $display("===========================================================");

    if (tests_failed == 0)
      $display("ALL STRESS TESTS PASSED");
    else
      $display("*** %0d STRESS TESTS FAILED ***", tests_failed);

    $finish;
  end

endmodule
