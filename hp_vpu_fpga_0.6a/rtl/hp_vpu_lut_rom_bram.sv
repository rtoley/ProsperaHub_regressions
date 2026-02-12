//============================================================================
// Hyperplane VPU - LUT ROM for LLM Inference Functions (BRAM Version)
// Uses $readmemh for Vivado BRAM inference (avoids elaboration OOM)
//
// Tables loaded from generated/lut_tables.mem
// Run: python3 scripts/gen_lut_tables.py to regenerate
//============================================================================

`timescale 1ns/1ps

module hp_vpu_lut_rom (
  input  logic        clk,          // Added for v2.1c compatibility (unused in combinational read)
  input  logic [7:0]  index_i,
  input  logic [1:0]  func_sel_i,  // 0=exp, 1=recip, 2=rsqrt, 3=gelu
  output logic [15:0] result_o
);

  // Combined ROM: 4 tables x 256 entries = 1024 x 16-bit
  // Address = {func_sel, index} = 10 bits
  logic [15:0] rom [0:1023];

  // Load from hex file - Vivado infers BRAM
  initial begin
    $readmemh("generated/lut_tables.mem", rom);
  end

  // Combinational read
  wire [9:0] addr = {func_sel_i, index_i};
  assign result_o = rom[addr];

endmodule
