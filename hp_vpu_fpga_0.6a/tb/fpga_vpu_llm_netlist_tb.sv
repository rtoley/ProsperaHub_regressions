//==============================================================================
// FPGA VPU LLM Test - Netlist Simulation Testbench
// Verifies post-synthesis netlist behaves same as RTL
//==============================================================================

`timescale 1ns/1ps

module fpga_vpu_llm_netlist_tb;

  logic        clk_100mhz;
  logic        btn0;
  logic [3:0]  led;

  // Clock Generation - 100 MHz
  initial clk_100mhz = 0;
  always #5 clk_100mhz = ~clk_100mhz;

  // DUT - Post-synthesis netlist
  fpga_vpu_llm_test_top u_dut (
    .clk_100mhz (clk_100mhz),
    .btn0       (btn0),
    .led        (led)
  );

  // Test Sequence
  initial begin
    $display("========================================");
    $display("  FPGA VPU LLM Netlist Simulation");
    $display("  Post-synthesis verification");
    $display("========================================");
    $display("");

    btn0 = 1'b1;
    repeat (10) @(posedge clk_100mhz);
    btn0 = 1'b0;
    $display("[%0t] Reset released", $time);

    // Wait for completion - netlist is slower
    fork
      begin
        wait (led[0] || led[1]);
        $display("[%0t] Test completed", $time);
      end
      begin
        repeat (1000000) @(posedge clk_100mhz);
        $display("[%0t] TIMEOUT", $time);
      end
    join_any
    disable fork;

    repeat (10) @(posedge clk_100mhz);

    $display("");
    $display("========================================");
    if (led[0] && !led[1]) begin
      $display("  NETLIST PASS - LLM test succeeded");
    end else begin
      $display("  NETLIST FAIL - LLM test failed");
    end
    $display("========================================");
    $display("");
    $display("LED status: [3:0] = %b", led);
    $display("");

    $finish;
  end

endmodule
