//============================================================================
// Hyperplane VPU - LUT ROM STUB for Synthesis
// Use this instead of hp_vpu_lut_rom.sv if Vivado runs out of memory
// Full LUT will be inferred as BRAM in final implementation
//============================================================================

`timescale 1ns/1ps

module hp_vpu_lut_rom (
  input  logic [7:0]  index_i,
  input  logic [1:0]  func_sel_i,
  output logic [15:0] result_o
);

  // Stub - synthesizes to small logic, full tables loaded at runtime
  // In real implementation, use BRAM with $readmemh
  always_comb begin
    result_o = {8'b0, index_i};  // Placeholder
  end

endmodule
