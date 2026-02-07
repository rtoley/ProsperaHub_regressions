//==============================================================================
// FPGA VPU Test Top - Netlist Simulation Testbench
// Verifies post-synthesis netlist behaves same as RTL
//
// Usage:
//   1. Run Vivado synthesis to generate netlist:
//      results/fpga_synth/fpga_test_funcsim.v
//   2. Compile with netlist:
//      iverilog -g2012 -o sim/fpga_netlist.vvp \
//        results/fpga_synth/fpga_test_funcsim.v \
//        tb/fpga_vpu_netlist_tb.sv \
//        -y $XILINX_VIVADO/data/verilog/src/unisims
//   3. Run: vvp sim/fpga_netlist.vvp
//==============================================================================

`timescale 1ns/1ps

module fpga_vpu_netlist_tb;

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
  // DUT - Post-synthesis netlist
  // The netlist module name should be fpga_vpu_test_top (same as RTL)
  //==========================================================================
  fpga_vpu_test_top u_dut (
    .clk_100mhz (clk_100mhz),
    .btn0       (btn0),
    .led        (led)
  );

  //==========================================================================
  // Test Sequence
  //==========================================================================
  initial begin
    $display("========================================");
    $display("  FPGA VPU Netlist Simulation");
    $display("  Post-synthesis verification");
    $display("========================================");
    $display("");

    // Start in reset
    btn0 = 1'b1;  // Active high reset
    repeat (10) @(posedge clk_100mhz);

    // Release reset
    btn0 = 1'b0;
    $display("[%0t] Reset released", $time);

    // Wait for test to complete (PASS or FAIL)
    // Netlist is slower, give more time - 500K cycles (5ms at 100MHz)
    fork
      begin
        wait (led[0] || led[1]);
        $display("[%0t] Test sequence completed", $time);
      end
      begin
        repeat (500000) @(posedge clk_100mhz);
        $display("[%0t] TIMEOUT - test did not complete", $time);
      end
    join_any
    disable fork;

    // Report result
    repeat (10) @(posedge clk_100mhz);

    $display("");
    $display("========================================");
    if (led[0] && !led[1]) begin
      $display("  NETLIST PASS - All tests passed!");
      $display("========================================");
    end else if (led[1]) begin
      $display("  NETLIST FAIL - Test failed");
      $display("========================================");
    end else begin
      $display("  ERROR - Unknown state (timeout?)");
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

endmodule
