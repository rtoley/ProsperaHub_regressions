//==============================================================================
// FPGA VPU Test Top - Simulation Testbench
// Verifies the self-checking test works in RTL simulation before synthesis
//==============================================================================

`timescale 1ns/1ps

module fpga_vpu_test_tb;

  //==========================================================================
  // Signals
  //==========================================================================
  logic        clk_100mhz;
  logic        btn0;
  logic [3:0]  led;

  //==========================================================================
  // Clock Generation - 100 MHz (10ns period)
  //==========================================================================
  initial clk_100mhz = 0;
  always #5 clk_100mhz = ~clk_100mhz;

  //==========================================================================
  // DUT
  //==========================================================================
  fpga_vpu_test_top u_dut (
    .clk_100mhz (clk_100mhz),
    .btn0       (btn0),
    .led        (led)
  );

  // Test names for display - use function instead of array init
  function string get_test_name(input int idx);
    case (idx)
      0: return "vadd.vv";
      1: return "vmul.vv";
      2: return "vredsum";
      3: return "vand.vv";
      4: return "vsub.vv";
      5: return "vor.vv";
      6: return "vxor.vv";
      7: return "vmin.vv";
      8: return "vmax.vv";
      9: return "vminu.vv";
      default: return "unknown";
    endcase
  endfunction

  //==========================================================================
  // Test Sequence
  //==========================================================================
  initial begin
    $display("========================================");
    $display("  FPGA VPU Self-Checking Test");
    $display("  Running 10 tests:");
    $display("    0. vadd.vv  - vector add");
    $display("    1. vmul.vv  - vector multiply");
    $display("    2. vredsum  - reduction sum");
    $display("    3. vand.vv  - vector AND");
    $display("    4. vsub.vv  - vector subtract");
    $display("    5. vor.vv   - vector OR");
    $display("    6. vxor.vv  - vector XOR");
    $display("    7. vmin.vv  - vector min (signed)");
    $display("    8. vmax.vv  - vector max (signed)");
    $display("    9. vminu.vv - vector min (unsigned)");
    $display("========================================");
    $display("");

    // Start in reset
    btn0 = 1'b1;  // Active high reset
    repeat (10) @(posedge clk_100mhz);

    // Release reset
    btn0 = 1'b0;
    $display("[%0t] Reset released", $time);

    // Wait for test to complete (PASS or FAIL)
    // Timeout after 200,000 cycles (2ms at 100MHz) - more time for 5 tests
    fork
      begin
        wait (led[0] || led[1]);
        $display("[%0t] Test sequence completed", $time);
      end
      begin
        repeat (200000) @(posedge clk_100mhz);
        $display("[%0t] TIMEOUT - test did not complete", $time);
      end
    join_any
    disable fork;

    // Report result
    repeat (10) @(posedge clk_100mhz);

    $display("");
    $display("========================================");
    if (led[0] && !led[1]) begin
      $display("  PASS - All %0d tests passed!", u_dut.tests_passed);
      $display("========================================");
    end else if (led[1]) begin
      $display("  FAIL - Test %0d (%s) failed", u_dut.test_num, get_test_name(u_dut.test_num));
      $display("========================================");
      $display("  Result:   0x%h", u_dut.result_reg);
      $display("  Expected: 0x%h", u_dut.cur_golden);
      $display("  Tests passed before failure: %0d", u_dut.tests_passed);
    end else begin
      $display("  ERROR - Unknown state");
      $display("========================================");
    end

    $display("");
    $display("LED status: [3:0] = %b", led);
    $display("  led[0] PASS = %b", led[0]);
    $display("  led[1] FAIL = %b", led[1]);
    $display("  led[2] BUSY = %b", led[2]);
    $display("  led[3] RUN  = %b", led[3]);
    $display("");

    $finish;
  end

  //==========================================================================
  // State and Test monitoring (for debug)
  //==========================================================================
  logic [2:0] prev_test_num = 0;

  always @(posedge clk_100mhz) begin
    // Report state transitions
    if (u_dut.state != u_dut.next_state) begin
      $display("[%0t] State: %s -> %s", $time, u_dut.state.name(), u_dut.next_state.name());
    end

    // Report test progression
    if (u_dut.test_num != prev_test_num) begin
      $display("[%0t] === Starting Test %0d: %s ===", $time, u_dut.test_num, get_test_name(u_dut.test_num));
      prev_test_num <= u_dut.test_num;
    end

    // Report test pass
    if (u_dut.state == u_dut.ST_CHECK_RESULT && u_dut.next_state == u_dut.ST_NEXT_TEST) begin
      $display("[%0t] PASS: Test %0d (%s)", $time, u_dut.test_num, get_test_name(u_dut.test_num));
    end
  end

endmodule
