//==============================================================================
// FPGA VPU LLM Test - Simulation Testbench
//==============================================================================

`timescale 1ns/1ps

module fpga_vpu_llm_test_tb;

  logic        clk_100mhz;
  logic        btn0;
  logic [3:0]  led;

  // Clock Generation - 100 MHz
  initial clk_100mhz = 0;
  always #5 clk_100mhz = ~clk_100mhz;

  // DUT
  fpga_vpu_llm_test_top u_dut (
    .clk_100mhz (clk_100mhz),
    .btn0       (btn0),
    .led        (led)
  );

  // Test Sequence
  initial begin
    $display("========================================");
    $display("  FPGA VPU LLM Inference Test");
    $display("========================================");
    $display("  Phase 1: GEMV (matrix-vector multiply)");
    $display("  Phase 2: Dot product (Q·K attention)");
    $display("  Phase 3: Back-to-back MAC stress");
    $display("========================================");
    $display("");

    btn0 = 1'b1;
    repeat (10) @(posedge clk_100mhz);
    btn0 = 1'b0;
    $display("[%0t] Reset released", $time);

    // Wait for completion
    fork
      begin
        wait (led[0] || led[1]);
        $display("[%0t] Test completed", $time);
      end
      begin
        repeat (500000) @(posedge clk_100mhz);
        $display("[%0t] TIMEOUT", $time);
      end
    join_any
    disable fork;

    repeat (10) @(posedge clk_100mhz);

    $display("");
    $display("========================================");
    if (led[0] && !led[1]) begin
      $display("  PASS - LLM inference test succeeded");
      $display("  Total operations: %0d", u_dut.total_ops);
    end else begin
      $display("  FAIL - LLM inference test failed");
      $display("  State: %s", u_dut.state.name());
      $display("  Result: 0x%h", u_dut.result_reg);
      $display("  Expected: 0x%h", u_dut.GOLDEN_STRESS);
    end
    $display("========================================");
    $display("");

    $finish;
  end

  // State monitoring
  always @(posedge clk_100mhz) begin
    if (u_dut.state != u_dut.next_state) begin
      $display("[%0t] State: %s -> %s", $time, u_dut.state.name(), u_dut.next_state.name());
    end
  end

endmodule
