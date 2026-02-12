// VPU v0.3e - R2A/R2B Pipeline Split Stress Tests
// Tests the split reduction pipeline (R2A + R2B) for:
//   1. RAW hazard detection at every R-pipeline stage
//   2. WAW hazard between E and R pipelines
//   3. Back-to-back reductions with data dependency
//   4. Mixed ALU/reduction interleave with shared registers
//   5. All SEW variants through split pipeline
//   6. Pipeline depth verification

  // Helper: wait until pipeline is idle (busy deasserts)
  task automatic wait_idle(input int timeout = 500);
    int cnt;
    cnt = 0;
    while (busy && cnt < timeout) begin
      @(posedge clk);
      cnt++;
    end
    if (cnt >= timeout)
      $display("  WARNING: wait_idle timed out after %0d cycles", timeout);
    // Extra cycle for WB to commit
    repeat(2) @(posedge clk);
  endtask

  //==========================================================================
  // Test 1: RAW hazard - ALU reads result of in-flight reduction
  //==========================================================================
  task automatic test_raw_hazard_red_then_alu();
    logic [31:0] instr;
    logic [DLEN-1:0] actual;
    int errors;
    $display("\n==================================================");
    $display("=== STRESS: RAW Hazard - Reduction then ALU read ===");
    $display("==================================================");
    errors = 0;
    set_vtype(3'b000, 3'b000, VLMAX_8);
    vrf_write(5'd1,  {(DLEN/8){8'h01}});
    vrf_write(5'd2,  {(DLEN/8){8'h00}});
    vrf_write(5'd10, {DLEN{1'b0}});
    vrf_write(5'd3,  {(DLEN/8){8'h05}});
    instr = encode_vredsum_vs(5'd10, 5'd1, 5'd2);
    issue(instr);
    instr = encode_vadd_vv(5'd20, 5'd3, 5'd10);
    issue(instr);
    wait_idle();
    begin
      automatic logic [7:0] expected_sum = VLMAX_8[7:0];
      vrf_read(5'd10, actual);
      if (actual[7:0] !== expected_sum) begin
        errors++;
        $display("  ERROR: v10[0] = 0x%02h, expected 0x%02h", actual[7:0], expected_sum);
      end
    end
    begin
      automatic logic [7:0] expected_elem0 = 8'h05 + VLMAX_8[7:0];
      vrf_read(5'd20, actual);
      if (actual[7:0] !== expected_elem0) begin
        errors++;
        $display("  ERROR: v20[0] = 0x%02h, expected 0x%02h (0x05 + 0x%02h)",
                 actual[7:0], expected_elem0, VLMAX_8[7:0]);
      end
    end
    tests_run++;
    if (errors == 0) begin tests_passed++; $display("[%0t] PASS: RAW hazard reduction then ALU", $time);
    end else begin tests_failed++; $display("[%0t] FAIL: RAW hazard reduction then ALU - %0d errors", $time, errors); end
  endtask

  //==========================================================================
  // Test 2: RAW hazard - Reduction reads result of prior ALU
  //==========================================================================
  task automatic test_raw_hazard_alu_then_red();
    logic [31:0] instr;
    logic [DLEN-1:0] actual;
    int errors;
    $display("\n==================================================");
    $display("=== STRESS: RAW Hazard - ALU then Reduction read ===");
    $display("==================================================");
    errors = 0;
    set_vtype(3'b000, 3'b000, VLMAX_8);
    vrf_write(5'd1, {(DLEN/8){8'h03}});
    vrf_write(5'd2, {(DLEN/8){8'h02}});
    vrf_write(5'd5, {DLEN{1'b0}});
    vrf_write(5'd8, {(DLEN/8){8'h00}});
    vrf_write(5'd9, {DLEN{1'b0}});
    instr = encode_vadd_vv(5'd5, 5'd1, 5'd2);
    issue(instr);
    instr = encode_vredsum_vs(5'd9, 5'd5, 5'd8);
    issue(instr);
    wait_idle();
    begin
      automatic logic [7:0] expected_sum = (VLMAX_8 * 8'h05) & 8'hFF;
      vrf_read(5'd9, actual);
      if (actual[7:0] !== expected_sum) begin
        errors++;
        $display("  ERROR: v9[0] = 0x%02h, expected 0x%02h", actual[7:0], expected_sum);
      end
    end
    tests_run++;
    if (errors == 0) begin tests_passed++; $display("[%0t] PASS: RAW hazard ALU then reduction", $time);
    end else begin tests_failed++; $display("[%0t] FAIL: RAW hazard ALU then reduction - %0d errors", $time, errors); end
  endtask

  //==========================================================================
  // Test 3: Back-to-back reductions with data dependency on accumulator
  //==========================================================================
  task automatic test_back_to_back_reductions();
    logic [31:0] instr;
    logic [DLEN-1:0] actual;
    int errors;
    $display("\n==================================================");
    $display("=== STRESS: Back-to-back Reductions (RAW) ===");
    $display("==================================================");
    errors = 0;
    set_vtype(3'b000, 3'b000, VLMAX_8);
    vrf_write(5'd1, {(DLEN/8){8'h01}});
    vrf_write(5'd2, {(DLEN/8){8'h02}});
    vrf_write(5'd10, {(DLEN/8){8'h00}});
    instr = encode_vredsum_vs(5'd10, 5'd1, 5'd10);
    issue(instr); wait_idle();
    instr = encode_vredsum_vs(5'd10, 5'd2, 5'd10);
    issue(instr); wait_idle();
    begin
      automatic logic [7:0] expected = ((VLMAX_8 * 3)) & 8'hFF;
      vrf_read(5'd10, actual);
      if (actual[7:0] !== expected) begin
        errors++;
        $display("  ERROR: v10[0] = 0x%02h, expected 0x%02h (VLMAX*3=%0d)", actual[7:0], expected, VLMAX_8*3);
      end
    end
    tests_run++;
    if (errors == 0) begin tests_passed++; $display("[%0t] PASS: Back-to-back reductions", $time);
    end else begin tests_failed++; $display("[%0t] FAIL: Back-to-back reductions - %0d errors", $time, errors); end
  endtask

  //==========================================================================
  // Test 4: Triple back-to-back reductions (accumulating)
  //==========================================================================
  task automatic test_triple_reduction_chain();
    logic [31:0] instr;
    logic [DLEN-1:0] actual;
    int errors;
    $display("\n==================================================");
    $display("=== STRESS: Triple Reduction Chain ===");
    $display("==================================================");
    errors = 0;
    set_vtype(3'b000, 3'b000, VLMAX_8);
    vrf_write(5'd1, {(DLEN/8){8'h01}});
    vrf_write(5'd2, {(DLEN/8){8'h02}});
    vrf_write(5'd3, {(DLEN/8){8'h03}});
    vrf_write(5'd10, {(DLEN/8){8'h00}});
    instr = encode_vredsum_vs(5'd10, 5'd1, 5'd10);
    issue(instr); wait_idle();
    instr = encode_vredsum_vs(5'd10, 5'd2, 5'd10);
    issue(instr); wait_idle();
    instr = encode_vredsum_vs(5'd10, 5'd3, 5'd10);
    issue(instr); wait_idle();
    begin
      automatic logic [7:0] expected = ((VLMAX_8 * 6)) & 8'hFF;
      vrf_read(5'd10, actual);
      if (actual[7:0] !== expected) begin
        errors++;
        $display("  ERROR: v10[0] = 0x%02h, expected 0x%02h", actual[7:0], expected);
      end
    end
    tests_run++;
    if (errors == 0) begin tests_passed++; $display("[%0t] PASS: Triple reduction chain", $time);
    end else begin tests_failed++; $display("[%0t] FAIL: Triple reduction chain - %0d errors", $time, errors); end
  endtask

  //==========================================================================
  // Test 5: WAW - ALU then reduction targeting same register
  //==========================================================================
  task automatic test_waw_alu_reduction_same_dest();
    logic [31:0] instr;
    logic [DLEN-1:0] actual;
    int errors;
    $display("\n==================================================");
    $display("=== STRESS: WAW - ALU + Reduction same dest ===");
    $display("==================================================");
    errors = 0;
    set_vtype(3'b000, 3'b000, VLMAX_8);
    vrf_write(5'd1, {(DLEN/8){8'h07}});
    vrf_write(5'd2, {(DLEN/8){8'h03}});
    vrf_write(5'd3, {(DLEN/8){8'h01}});
    vrf_write(5'd4, {(DLEN/8){8'h00}});
    vrf_write(5'd10, {DLEN{1'b0}});
    instr = encode_vadd_vv(5'd10, 5'd1, 5'd2);
    issue(instr);
    instr = encode_vredsum_vs(5'd10, 5'd3, 5'd4);
    issue(instr);
    wait_idle();
    begin
      automatic logic [7:0] expected = VLMAX_8[7:0];
      vrf_read(5'd10, actual);
      if (actual[7:0] !== expected) begin
        errors++;
        $display("  ERROR: v10[0] = 0x%02h, expected 0x%02h (reduction should win)", actual[7:0], expected);
      end
    end
    tests_run++;
    if (errors == 0) begin tests_passed++; $display("[%0t] PASS: WAW ALU+reduction same dest", $time);
    end else begin tests_failed++; $display("[%0t] FAIL: WAW ALU+reduction same dest - %0d errors", $time, errors); end
  endtask

  //==========================================================================
  // Test 6: Multiply then reduction (E1m path then R path)
  //==========================================================================
  task automatic test_mul_then_reduction_hazard();
    logic [31:0] instr;
    logic [DLEN-1:0] actual;
    int errors;
    $display("\n==================================================");
    $display("=== STRESS: Multiply then Reduction (drain) ===");
    $display("==================================================");
    errors = 0;
    set_vtype(3'b000, 3'b000, VLMAX_8);
    vrf_write(5'd1, {(DLEN/8){8'h02}});
    vrf_write(5'd2, {(DLEN/8){8'h03}});
    vrf_write(5'd5, {DLEN{1'b0}});
    vrf_write(5'd8, {(DLEN/8){8'h00}});
    vrf_write(5'd9, {DLEN{1'b0}});
    instr = encode_vmul_vv(5'd5, 5'd1, 5'd2);
    issue(instr);
    instr = encode_vredsum_vs(5'd9, 5'd5, 5'd8);
    issue(instr);
    wait_idle();
    begin
      automatic logic [7:0] expected = (VLMAX_8 * 6) & 8'hFF;
      vrf_read(5'd9, actual);
      if (actual[7:0] !== expected) begin
        errors++;
        $display("  ERROR: v9[0] = 0x%02h, expected 0x%02h (sum of %0d * 6)", actual[7:0], expected, VLMAX_8);
      end
    end
    tests_run++;
    if (errors == 0) begin tests_passed++; $display("[%0t] PASS: Multiply then reduction", $time);
    end else begin tests_failed++; $display("[%0t] FAIL: Multiply then reduction - %0d errors", $time, errors); end
  endtask

  //==========================================================================
  // Test 7: All SEW variants through R2A/R2B
  //==========================================================================
  task automatic test_r2ab_all_sew();
    logic [31:0] instr;
    logic [DLEN-1:0] actual;
    int errors;
    $display("\n==================================================");
    $display("=== STRESS: R2A/R2B All SEW Variants ===");
    $display("==================================================");
    errors = 0;
    // SEW=8
    set_vtype(3'b000, 3'b000, VLMAX_8);
    vrf_write(5'd1, {(DLEN/8){8'h03}});
    vrf_write(5'd2, {(DLEN/8){8'h0A}});
    vrf_write(5'd10, {DLEN{1'b0}});
    instr = encode_vredsum_vs(5'd10, 5'd1, 5'd2);
    issue(instr); wait_idle();
    begin
      automatic logic [7:0] exp8 = (VLMAX_8 * 8'h03 + 8'h0A) & 8'hFF;
      vrf_read(5'd10, actual);
      if (actual[7:0] !== exp8) begin errors++; $display("  ERROR SEW=8: v10[0] = 0x%02h, expected 0x%02h", actual[7:0], exp8);
      end else $display("  SEW=8:  v10[0] = 0x%02h OK", actual[7:0]);
    end
    // SEW=16
    set_vtype(3'b001, 3'b000, VLMAX_16);
    vrf_write(5'd1, {(DLEN/16){16'h0005}});
    vrf_write(5'd2, {(DLEN/16){16'h0064}});
    vrf_write(5'd10, {DLEN{1'b0}});
    instr = encode_vredsum_vs(5'd10, 5'd1, 5'd2);
    issue(instr); wait_idle();
    begin
      automatic logic [15:0] exp16 = (VLMAX_16 * 16'h0005 + 16'h0064) & 16'hFFFF;
      vrf_read(5'd10, actual);
      if (actual[15:0] !== exp16) begin errors++; $display("  ERROR SEW=16: v10[0] = 0x%04h, expected 0x%04h", actual[15:0], exp16);
      end else $display("  SEW=16: v10[0] = 0x%04h OK", actual[15:0]);
    end
    // SEW=32
    set_vtype(3'b010, 3'b000, VLMAX_32);
    vrf_write(5'd1, {(DLEN/32){32'h0000000A}});
    vrf_write(5'd2, {(DLEN/32){32'h000003E8}});
    vrf_write(5'd10, {DLEN{1'b0}});
    instr = encode_vredsum_vs(5'd10, 5'd1, 5'd2);
    issue(instr); wait_idle();
    begin
      automatic logic [31:0] exp32 = VLMAX_32 * 32'h0000000A + 32'h000003E8;
      vrf_read(5'd10, actual);
      if (actual[31:0] !== exp32) begin errors++; $display("  ERROR SEW=32: v10[0] = 0x%08h, expected 0x%08h", actual[31:0], exp32);
      end else $display("  SEW=32: v10[0] = 0x%08h OK", actual[31:0]);
    end
    tests_run++;
    if (errors == 0) begin tests_passed++; $display("[%0t] PASS: R2A/R2B all SEW variants", $time);
    end else begin tests_failed++; $display("[%0t] FAIL: R2A/R2B SEW variants - %0d errors", $time, errors); end
  endtask

  //==========================================================================
  // Test 8: Rapid alternating ALU + Reduction (20 rounds)
  //==========================================================================
  task automatic test_rapid_alu_red_interleave();
    logic [31:0] instr;
    logic [DLEN-1:0] actual;
    int errors, round;
    $display("\n==================================================");
    $display("=== STRESS: Rapid ALU/Reduction Interleave ===");
    $display("==================================================");
    errors = 0;
    set_vtype(3'b000, 3'b000, VLMAX_8);
    vrf_write(5'd1, {(DLEN/8){8'h01}});
    vrf_write(5'd2, {(DLEN/8){8'h02}});
    vrf_write(5'd3, {(DLEN/8){8'h00}});
    vrf_write(5'd10, {(DLEN/8){8'h00}});
    vrf_write(5'd11, {DLEN{1'b0}});
    for (round = 0; round < 20; round++) begin
      instr = encode_vadd_vv(5'd11, 5'd1, 5'd2);
      issue(instr);
      instr = encode_vredsum_vs(5'd10, 5'd11, 5'd3);
      issue(instr);
      wait_idle();
    end
    begin
      automatic logic [7:0] expected_v10 = (VLMAX_8 * 3) & 8'hFF;
      vrf_read(5'd10, actual);
      if (actual[7:0] !== expected_v10) begin
        errors++;
        $display("  ERROR: v10[0] = 0x%02h, expected 0x%02h after 20 rounds", actual[7:0], expected_v10);
      end
    end
    tests_run++;
    if (errors == 0) begin tests_passed++; $display("[%0t] PASS: Rapid ALU/reduction interleave (20 rounds)", $time);
    end else begin tests_failed++; $display("[%0t] FAIL: Rapid ALU/reduction interleave - %0d errors", $time, errors); end
  endtask

  //==========================================================================
  // Test 9: All reduction ops through R2A/R2B
  //==========================================================================
  task automatic test_r2ab_all_red_ops();
    logic [31:0] instr;
    logic [DLEN-1:0] actual;
    int errors;
    $display("\n==================================================");
    $display("=== STRESS: All Reduction Ops Through R2A/R2B ===");
    $display("==================================================");
    errors = 0;
    set_vtype(3'b000, 3'b000, VLMAX_8);
    // vredsum
    vrf_write(5'd1, {(DLEN/8){8'h02}}); vrf_write(5'd2, {(DLEN/8){8'h00}}); vrf_write(5'd10, {DLEN{1'b0}});
    instr = encode_vredsum_vs(5'd10, 5'd1, 5'd2); issue(instr); wait_idle();
    begin automatic logic [7:0] exp = (VLMAX_8 * 2) & 8'hFF; vrf_read(5'd10, actual);
      if (actual[7:0] !== exp) begin errors++; $display("  ERROR vredsum: got 0x%02h exp 0x%02h", actual[7:0], exp);
      end else $display("  vredsum:  0x%02h OK", actual[7:0]); end
    // vredmax (signed) - pattern {0x7F, 0x80, 0x7F, 0x80, ...}
    begin automatic logic [DLEN-1:0] pattern;
      for (int i = 0; i < DLEN/8; i++) pattern[i*8 +: 8] = (i % 2 == 0) ? 8'h7F : 8'h80;
      vrf_write(5'd1, pattern); end
    vrf_write(5'd2, {(DLEN/8){8'h00}}); vrf_write(5'd10, {DLEN{1'b0}});
    instr = encode_vredmax_vs(5'd10, 5'd1, 5'd2); issue(instr); wait_idle();
    vrf_read(5'd10, actual);
    if (actual[7:0] !== 8'h7F) begin errors++; $display("  ERROR vredmax: got 0x%02h exp 0x7F", actual[7:0]);
    end else $display("  vredmax:  0x%02h OK", actual[7:0]);
    // vredmin (signed)
    vrf_write(5'd10, {DLEN{1'b0}});
    instr = encode_vredmin_vs(5'd10, 5'd1, 5'd2); issue(instr); wait_idle();
    vrf_read(5'd10, actual);
    if (actual[7:0] !== 8'h80) begin errors++; $display("  ERROR vredmin: got 0x%02h exp 0x80", actual[7:0]);
    end else $display("  vredmin:  0x%02h OK", actual[7:0]);
    // vredor
    vrf_write(5'd1, {(DLEN/8){8'hA5}}); vrf_write(5'd2, {(DLEN/8){8'h00}}); vrf_write(5'd10, {DLEN{1'b0}});
    instr = encode_vredor_vs(5'd10, 5'd1, 5'd2); issue(instr); wait_idle();
    vrf_read(5'd10, actual);
    if (actual[7:0] !== 8'hA5) begin errors++; $display("  ERROR vredor: got 0x%02h exp 0xA5", actual[7:0]);
    end else $display("  vredor:   0x%02h OK", actual[7:0]);
    // vredand
    vrf_write(5'd1, {(DLEN/8){8'hFF}}); vrf_write(5'd2, {(DLEN/8){8'hFF}}); vrf_write(5'd10, {DLEN{1'b0}});
    instr = encode_vredand_vs(5'd10, 5'd1, 5'd2); issue(instr); wait_idle();
    vrf_read(5'd10, actual);
    if (actual[7:0] !== 8'hFF) begin errors++; $display("  ERROR vredand: got 0x%02h exp 0xFF", actual[7:0]);
    end else $display("  vredand:  0x%02h OK", actual[7:0]);
    // vredxor
    vrf_write(5'd1, {(DLEN/8){8'hAA}}); vrf_write(5'd2, {(DLEN/8){8'h00}}); vrf_write(5'd10, {DLEN{1'b0}});
    instr = encode_vredxor_vs(5'd10, 5'd1, 5'd2); issue(instr); wait_idle();
    vrf_read(5'd10, actual);
    begin automatic logic [7:0] exp_xor = (VLMAX_8 % 2 == 1) ? 8'hAA : 8'h00;
      if (actual[7:0] !== exp_xor) begin errors++; $display("  ERROR vredxor: got 0x%02h exp 0x%02h (VLMAX=%0d)", actual[7:0], exp_xor, VLMAX_8);
      end else $display("  vredxor:  0x%02h OK", actual[7:0]); end
    tests_run++;
    if (errors == 0) begin tests_passed++; $display("[%0t] PASS: All reduction ops through R2A/R2B", $time);
    end else begin tests_failed++; $display("[%0t] FAIL: All reduction ops - %0d errors", $time, errors); end
  endtask

  //==========================================================================
  // Test 10: Pipeline depth verification
  //==========================================================================
  task automatic test_r2ab_pipeline_depth();
    logic [31:0] instr;
    logic [DLEN-1:0] actual;
    int start_time, end_time, latency_cycles, errors;
    $display("\n==================================================");
    $display("=== STRESS: R2A/R2B Pipeline Depth Check ===");
    $display("==================================================");
    errors = 0;
    set_vtype(3'b000, 3'b000, VLMAX_8);
    vrf_write(5'd1, {(DLEN/8){8'h01}});
    vrf_write(5'd2, {(DLEN/8){8'h00}});
    vrf_write(5'd10, {DLEN{1'b0}});
    repeat(5) @(posedge clk);
    start_time = $time;
    instr = encode_vredsum_vs(5'd10, 5'd1, 5'd2);
    issue(instr);
    while (busy) @(posedge clk);
    repeat(2) @(posedge clk);
    end_time = $time;
    latency_cycles = (end_time - start_time) / 2;
    $display("  Reduction latency: %0d cycles (from issue to idle)", latency_cycles);
    if (latency_cycles < 6) begin errors++;
      $display("  ERROR: Latency too short (%0d < 6), pipeline may skip stages", latency_cycles);
    end else $display("  Pipeline depth looks reasonable");
    begin automatic logic [7:0] exp = VLMAX_8[7:0]; vrf_read(5'd10, actual);
      if (actual[7:0] !== exp) begin errors++;
        $display("  ERROR: v10[0] = 0x%02h, expected 0x%02h", actual[7:0], exp); end end
    tests_run++;
    if (errors == 0) begin tests_passed++; $display("[%0t] PASS: R2A/R2B pipeline depth", $time);
    end else begin tests_failed++; $display("[%0t] FAIL: R2A/R2B pipeline depth - %0d errors", $time, errors); end
  endtask

  //==========================================================================
  // Test 11: No false hazard when registers don't conflict
  //==========================================================================
  task automatic test_no_false_hazard();
    logic [31:0] instr;
    logic [DLEN-1:0] actual;
    int errors;
    $display("\n==================================================");
    $display("=== STRESS: No-conflict (false hazard check) ===");
    $display("==================================================");
    errors = 0;
    set_vtype(3'b000, 3'b000, VLMAX_8);
    vrf_write(5'd1, {(DLEN/8){8'h01}});
    vrf_write(5'd2, {(DLEN/8){8'h02}});
    vrf_write(5'd3, {(DLEN/8){8'h03}});
    vrf_write(5'd4, {(DLEN/8){8'h04}});
    vrf_write(5'd10, {DLEN{1'b0}});
    vrf_write(5'd20, {DLEN{1'b0}});
    instr = encode_vredsum_vs(5'd10, 5'd1, 5'd2);
    issue(instr);
    instr = encode_vadd_vv(5'd20, 5'd3, 5'd4);
    issue(instr);
    wait_idle();
    begin automatic logic [7:0] exp_red = VLMAX_8[7:0]; vrf_read(5'd10, actual);
      if (actual[7:0] !== exp_red) begin errors++;
        $display("  ERROR: v10[0] = 0x%02h, expected 0x%02h", actual[7:0], exp_red); end end
    vrf_read(5'd20, actual);
    if (actual[7:0] !== 8'h07) begin errors++;
      $display("  ERROR: v20[0] = 0x%02h, expected 0x07", actual[7:0]); end
    tests_run++;
    if (errors == 0) begin tests_passed++; $display("[%0t] PASS: No false hazard", $time);
    end else begin tests_failed++; $display("[%0t] FAIL: No false hazard - %0d errors", $time, errors); end
  endtask

  //==========================================================================
  // Runner
  //==========================================================================
  task automatic run_stress_r2ab_tests;
    $display("\n##################################################");
    $display("### v0.3e R2A/R2B Pipeline Split Stress Tests ###");
    $display("##################################################");
    test_raw_hazard_red_then_alu();
    test_raw_hazard_alu_then_red();
    test_back_to_back_reductions();
    test_triple_reduction_chain();
    test_waw_alu_reduction_same_dest();
    test_mul_then_reduction_hazard();
    test_r2ab_all_sew();
    test_rapid_alu_red_interleave();
    test_r2ab_all_red_ops();
    test_r2ab_pipeline_depth();
    test_no_false_hazard();
    $display("##################################################\n");
  endtask
