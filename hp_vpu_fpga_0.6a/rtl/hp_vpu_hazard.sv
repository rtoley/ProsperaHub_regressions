//==============================================================================
// Hyperplane VPU - Hazard Detection Unit
// Detects RAW hazards and generates stalls
// v0.10: Extended to check OF, E1, E2 stages for complete hazard coverage
//        Added vs3 checking for MAC operations (vmacc, vnmsac, etc.)
// v0.13: Added multicycle execute support - stall on multicycle_busy
//==============================================================================


module hp_vpu_hazard
  import hp_vpu_pkg::*;
(
  input  logic        clk,
  input  logic        rst_n,

  // Decode stage (D2)
  input  logic        d_valid_i,
  input  logic [4:0]  d_vd_i,
  input  logic [4:0]  d_vs1_i,
  input  logic [4:0]  d_vs2_i,
  input  logic [4:0]  d_vs3_i,      // Accumulator source (vd for MAC ops)

  // Operand Fetch stage (OF)
  input  logic        of_valid_i,
  input  logic [4:0]  of_vd_i,

  // Execute stage 1 (E1)
  input  logic        e1_valid_i,
  input  logic [4:0]  e1_vd_i,

  // Execute stage 1m (E1m) - v0.5b: separate multiply holding register
  input  logic        e1m_valid_i,
  input  logic [4:0]  e1m_vd_i,

  // Execute stage 2 (E2)
  input  logic        e2_valid_i,
  input  logic [4:0]  e2_vd_i,

  // R2 reduction stages (v0.4: split into R2A and R2B)
  input  logic        r2a_valid_i,
  input  logic [4:0]  r2a_vd_i,
  input  logic        r2b_valid_i,
  input  logic [4:0]  r2b_vd_i,

  // Execute stage 3 (E3)
  input  logic        e3_valid_i,
  input  logic [4:0]  e3_vd_i,

  // Memory stage (not used in Phase 1)
  input  logic        m2_valid_i,
  input  logic [4:0]  m2_vd_i,

  // Writeback stage
  input  logic        w_valid_i,
  input  logic [4:0]  w_vd_i,

  // External stall (SRAM backpressure)
  input  logic        sram_stall_i,

  // Multicycle execute busy (v0.13+)
  input  logic        multicycle_busy_i,

  // Kill from scalar core
  input  logic        kill_i,

  // Output stalls
  output logic        stall_iq_o,
  output logic        stall_dec_o,
  output logic        stall_exec_o,
  output logic        flush_o
);

  //--------------------------------------------------------------------------
  // RAW Hazard Detection
  // Stall if decode reads a register that any in-flight instruction will write
  // Pipeline: D2 -> OF -> E1 -> E2 -> E3 -> WB
  // Check vs1, vs2, vs3 (accumulator for MAC ops)
  //--------------------------------------------------------------------------

  // OF stage hazards
  logic raw_vs1_of, raw_vs2_of, raw_vs3_of;
  assign raw_vs1_of = of_valid_i && (d_vs1_i == of_vd_i);
  assign raw_vs2_of = of_valid_i && (d_vs2_i == of_vd_i);
  assign raw_vs3_of = of_valid_i && (d_vs3_i == of_vd_i);

  // E1 stage hazards
  logic raw_vs1_e1, raw_vs2_e1, raw_vs3_e1;
  assign raw_vs1_e1 = e1_valid_i && (d_vs1_i == e1_vd_i);
  assign raw_vs2_e1 = e1_valid_i && (d_vs2_i == e1_vd_i);
  assign raw_vs3_e1 = e1_valid_i && (d_vs3_i == e1_vd_i);

  // E1m stage hazards (v0.5b: multiply holding register)
  logic raw_vs1_e1m, raw_vs2_e1m, raw_vs3_e1m;
  assign raw_vs1_e1m = e1m_valid_i && (d_vs1_i == e1m_vd_i);
  assign raw_vs2_e1m = e1m_valid_i && (d_vs2_i == e1m_vd_i);
  assign raw_vs3_e1m = e1m_valid_i && (d_vs3_i == e1m_vd_i);

  // E2 stage hazards
  logic raw_vs1_e2, raw_vs2_e2, raw_vs3_e2;
  assign raw_vs1_e2 = e2_valid_i && (d_vs1_i == e2_vd_i);
  assign raw_vs2_e2 = e2_valid_i && (d_vs2_i == e2_vd_i);
  assign raw_vs3_e2 = e2_valid_i && (d_vs3_i == e2_vd_i);

  // R2a stage hazards
  logic raw_vs1_r2a, raw_vs2_r2a, raw_vs3_r2a;
  assign raw_vs1_r2a = r2a_valid_i && (d_vs1_i == r2a_vd_i);
  assign raw_vs2_r2a = r2a_valid_i && (d_vs2_i == r2a_vd_i);
  assign raw_vs3_r2a = r2a_valid_i && (d_vs3_i == r2a_vd_i);

  // R2b stage hazards
  logic raw_vs1_r2b, raw_vs2_r2b, raw_vs3_r2b;
  assign raw_vs1_r2b = r2b_valid_i && (d_vs1_i == r2b_vd_i);
  assign raw_vs2_r2b = r2b_valid_i && (d_vs2_i == r2b_vd_i);
  assign raw_vs3_r2b = r2b_valid_i && (d_vs3_i == r2b_vd_i);

  // E3 stage hazards
  logic raw_vs1_e3, raw_vs2_e3, raw_vs3_e3;
  assign raw_vs1_e3 = e3_valid_i && (d_vs1_i == e3_vd_i);
  assign raw_vs2_e3 = e3_valid_i && (d_vs2_i == e3_vd_i);
  assign raw_vs3_e3 = e3_valid_i && (d_vs3_i == e3_vd_i);

  // Writeback stage hazards
  logic raw_vs1_w, raw_vs2_w, raw_vs3_w;
  assign raw_vs1_w = w_valid_i && (d_vs1_i == w_vd_i);
  assign raw_vs2_w = w_valid_i && (d_vs2_i == w_vd_i);
  assign raw_vs3_w = w_valid_i && (d_vs3_i == w_vd_i);

  // Combined RAW hazard
  logic raw_hazard;
  assign raw_hazard = d_valid_i && (
    raw_vs1_of || raw_vs2_of || raw_vs3_of ||
    raw_vs1_e1  || raw_vs2_e1  || raw_vs3_e1  ||
    raw_vs1_e1m || raw_vs2_e1m || raw_vs3_e1m ||  // v0.5b: E1m separate check
    raw_vs1_e2  || raw_vs2_e2  || raw_vs3_e2  ||
    raw_vs1_r2a || raw_vs2_r2a || raw_vs3_r2a ||
    raw_vs1_r2b || raw_vs2_r2b || raw_vs3_r2b ||
    raw_vs1_e3  || raw_vs2_e3  || raw_vs3_e3  ||
    raw_vs1_w   || raw_vs2_w   || raw_vs3_w
  );

  //--------------------------------------------------------------------------
  // Stall Generation
  // D2 and OF stall on hazard or multicycle busy
  // Execution must continue to clear pipeline (unless SRAM backpressure)
  //--------------------------------------------------------------------------
  assign stall_iq_o   = raw_hazard || sram_stall_i || multicycle_busy_i;
  assign stall_dec_o  = raw_hazard || sram_stall_i || multicycle_busy_i;
  assign stall_exec_o = sram_stall_i;  // Execution must continue to clear hazards

  //--------------------------------------------------------------------------
  // Flush on kill
  //--------------------------------------------------------------------------
  logic flush_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      flush_q <= 1'b0;
    else
      flush_q <= kill_i;
  end

  assign flush_o = flush_q;

endmodule
