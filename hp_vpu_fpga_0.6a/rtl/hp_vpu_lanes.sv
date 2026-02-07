//==============================================================================
// Hyperplane VPU - Vector Lanes (v1.6)
// 3-stage pipelined execution (E1, E2, E3) for 100 MHz FPGA / 2 GHz ASIC target
// Supports SEW=8, SEW=16, SEW=32
// v0.13: Multicycle execute for reductions to break timing paths
// v0.17: Widening pipeline (W1→W2) for vwmul/vwadd/vwsub
// v0.19: Fully parameterized by DLEN from config
// v1.4:  Pre-computed MAC results (mul+add in E1, registered in E2) to break
//        critical timing path. Same pipeline depth, zero added latency.
// v1.6:  Fixed MAC pipeline: e2m_* results now use e2m_op mux and dedicated
//        path to E3 (e2_op changes to new instruction when stall ends!)
//==============================================================================

module hp_vpu_lanes
  import hp_vpu_pkg::*;
#(
  parameter int unsigned NLANES = hp_vpu_pkg::NLANES,
  parameter int unsigned ELEN   = hp_vpu_pkg::ELEN,
  parameter bit ENABLE_VMADD    = hp_vpu_pkg::ENABLE_VMADD
)(
  input  logic                      clk,
  input  logic                      rst_n,
  input  logic                      stall_i,

  input  logic                      valid_i,
  input  vpu_op_e                   op_i,
  input  logic [NLANES*64-1:0]      vs1_i,
  input  logic [NLANES*64-1:0]      vs2_i,
  input  logic [NLANES*64-1:0]      vs3_i,      // old_vd for masking/vmacc
  input  logic [NLANES*64-1:0]      vmask_i,    // v0 mask register
  input  logic                      vm_i,       // vm=1 unmasked, vm=0 masked
  input  logic [31:0]               scalar_i,
  input  logic                      is_vx_i,    // True for .vx/.vi operations
  input  sew_e                      sew_i,
  input  logic [4:0]                vd_i,
  input  logic [CVXIF_ID_W-1:0]     id_i,

  // Multicycle control (v0.13+)
  input  logic                      is_multicycle_i,
  input  logic [2:0]                multicycle_count_i,

  // v1.2a: LMUL micro-op tracking
  input  logic                      is_last_uop_i,

  output logic                      valid_o,
  output logic [NLANES*64-1:0]      result_o,
  output logic [31:0]               mask_o,     // For comparison results
  output logic                      mask_valid_o,
  output logic [4:0]                vd_o,
  output logic [CVXIF_ID_W-1:0]     id_o,

  // v1.2a: LMUL micro-op tracking output
  output logic                      is_last_uop_o,

  // Multicycle busy output (v0.13+)
  output logic                      multicycle_busy_o,
  output logic                      mac_stall_o,       // v1.6b: Exposed for OF clearing logic
  output logic                      mul_stall_o,       // v1.7: Exposed for OF clearing logic
  output logic                      e1_handoff_capture_o, // v1.9: E1 captured from OF during multiply handoff
  output logic                      drain_stall_o,     // v1.7: Waiting for pipeline drain before multicycle op

  // Hazard detection outputs (E1/E2 stage info)
  output logic                      e1_valid_o,
  output logic [4:0]                e1_vd_o,
  // v0.5b: Separate E1m hazard port so both E1 and E1m destinations are visible
  output logic                      e1m_valid_o,
  output logic [4:0]                e1m_vd_o,
  output logic                      e2_valid_o,
  output logic [4:0]                e2_vd_o,

  // New hazard outputs for R2A/R2B stages
  output logic                      r2a_valid_o,
  output logic [4:0]                r2a_vd_o,
  output logic                      r2b_valid_o,
  output logic [4:0]                r2b_vd_o
);

  localparam int unsigned DLEN = NLANES * 64;  // 256 bits

  //============================================================================
  // Pipelined Reduction Tree (v0.13.2)
  // Splits tree reduction across R1→R2→R3 stages with registers between
  // Each stage: ~2 tree levels = ~6 LUTs deep → meets 100 MHz
  //============================================================================

  localparam int NUM_ELEM_8  = DLEN / 8;   // 8 for DLEN=64, 32 for DLEN=256
  localparam int NUM_ELEM_16 = DLEN / 16;  // 4 for DLEN=64, 16 for DLEN=256
  localparam int NUM_ELEM_32 = DLEN / 32;  // 2 for DLEN=64, 8 for DLEN=256

  // v0.3e: R1 output element counts
  localparam int R1_N8  = NUM_ELEM_8  / 4;  // 2 for DLEN=64, 8 for DLEN=256
  localparam int R1_N16 = NUM_ELEM_16 / 4;  // 1 for DLEN=64, 4 for DLEN=256
  localparam int R1_N32 = NUM_ELEM_32 / 2;  // 1 for DLEN=64, 4 for DLEN=256

  // v0.3e: R2A output element counts
  // When R1 has >2 elements, R2A reduces by half (1 comb level)
  // When R1 has <=2 elements, R2A passes through (no reduction needed)
  localparam int R2A_N8  = (R1_N8  > 2) ? R1_N8  / 2 : R1_N8;   // 2 for DLEN=64, 4 for DLEN=256
  localparam int R2A_N16 = (R1_N16 > 2) ? R1_N16 / 2 : R1_N16;  // 1 for DLEN=64, 2 for DLEN=256
  localparam int R2A_N32 = (R1_N32 > 2) ? R1_N32 / 2 : R1_N32;  // 1 for DLEN=64, 2 for DLEN=256

  // State machine
  // v0.4: Extended for 300MHz timing closure (split R2 -> R2A + R2B)
  // v0.3f: Split is now permanent. Guard ensures package matches.
`ifdef SIMULATION
  initial begin
    if (SPLIT_REDUCTION_PIPELINE != 1) begin
      $display("ERROR: SPLIT_REDUCTION_PIPELINE must be 1 (v0.3f+). Regenerate pkg with split_reduction_pipeline: true");
      $finish;
    end
  end
`endif
  logic [2:0] red_state;
  localparam logic [2:0] RED_IDLE = 3'd0;
  localparam logic [2:0] RED_R1   = 3'd1;
  localparam logic [2:0] RED_R2A  = 3'd2; // Was RED_R2
  localparam logic [2:0] RED_R2B  = 3'd3; // New split stage
  localparam logic [2:0] RED_R3   = 3'd4;

  // Detect reduction at input
  wire is_reduction_op = (op_i == OP_VREDSUM)  || (op_i == OP_VREDMAX)  ||
                         (op_i == OP_VREDMIN)  || (op_i == OP_VREDMAXU) ||
                         (op_i == OP_VREDMINU) || (op_i == OP_VREDAND)  ||
                         (op_i == OP_VREDOR)   || (op_i == OP_VREDXOR);

  // R1 stage registers (capture inputs + first tree level results)
  logic [DLEN-1:0] r1_vs2;           // Vector to reduce
  logic [DLEN-1:0] r1_vs1;           // Initial value
  logic [DLEN-1:0] r1_old_vd;        // For result packing
  vpu_op_e         r1_op;
  sew_e            r1_sew;
  logic [4:0]      r1_vd;
  logic [CVXIF_ID_W-1:0] r1_id;
  // R1 partial results after first 2 tree levels (8→4→2 for SEW=8/DLEN=64)
  logic [7:0]  r1_part8  [0:NUM_ELEM_8/4-1];   // 2 for DLEN=64, 8 for DLEN=256
  logic [15:0] r1_part16 [0:NUM_ELEM_16/4-1];  // 1 for DLEN=64, 4 for DLEN=256
  logic [31:0] r1_part32 [0:NUM_ELEM_32/2-1];  // 1 for DLEN=64, 4 for DLEN=256

  // R2a stage registers (Split R2 for 300MHz)
  logic [DLEN-1:0] r2a_vs1;
  logic [DLEN-1:0] r2a_old_vd;
  vpu_op_e         r2a_op;
  sew_e            r2a_sew;
  logic [4:0]      r2a_vd;
  logic [CVXIF_ID_W-1:0] r2a_id;
  // R2a partial results - sized by R2A_N* (v0.3e fix for small DLEN)
  logic [7:0]  r2a_part8  [0:R2A_N8-1];
  logic [15:0] r2a_part16 [0:R2A_N16-1];
  logic [31:0] r2a_part32 [0:R2A_N32-1];

  // R2b stage registers (Split R2 for 300MHz)
  logic [DLEN-1:0] r2b_vs1;
  logic [DLEN-1:0] r2b_old_vd;
  vpu_op_e         r2b_op;
  sew_e            r2b_sew;
  logic [4:0]      r2b_vd;
  logic [CVXIF_ID_W-1:0] r2b_id;
  // R2b partial results (down to 2 elements each)
  logic [7:0]  r2b_part8  [0:1];
  logic [15:0] r2b_part16 [0:1];
  logic [31:0] r2b_part32 [0:1];

  // R3 stage registers (final result)
  logic [DLEN-1:0] r3_vs1;
  logic [DLEN-1:0] r3_old_vd;
  vpu_op_e         r3_op;
  sew_e            r3_sew;
  logic [4:0]      r3_vd;
  logic [CVXIF_ID_W-1:0] r3_id;
  logic            r3_valid;
  logic [31:0]     r3_result;  // Final scalar result

  // v1.6c: MAC stall logic - always present (vmacc/vnmsac always work)
  // ENABLE_VMADD only gates vmadd/vnmsub multiplier, not the stall FSM

  // v1.5: MAC operation detection for dedicated MAC stage
  wire is_mac_op_e2 = e2_valid && (e2_op == OP_VMACC || e2_op == OP_VNMSAC ||
                                    e2_op == OP_VMADD || e2_op == OP_VNMSUB);

  // v0.5e: mac_stall REMOVED - MAC add is purely combinational,
  // results feed directly through final_result -> masked_result -> E3.
  // No staging registers or extra cycle needed.
  wire mac_stall = 1'b0;  // Kept as wire for minimal port/signal changes
  assign mac_stall_o = mac_stall;  // v1.6b: Expose to top level
  assign mul_stall_o = mul_stall;  // v1.7: Expose to top level

  // v1.9 FIX: Signal when E1 captures during multiply handoff
  // This happens when E1 hands off a multiply to E1m AND captures a new non-mul from OF
  wire e1_branch2_fires = !stall_i && !mac_stall && is_mul_op_e1 && !e1m_valid;
  wire e1_handoff_capture = e1_branch2_fires && valid_i && !is_reduction_op && !is_widening_op && !is_mul_op;
  assign e1_handoff_capture_o = e1_handoff_capture;

  // v1.7 FIX: Pipeline drain for multicycle operations
  // Before starting reduction/widening, E1/E1m/E2 must be empty to avoid VRF write contention
  wire pipeline_drained = !e1_valid && !e1m_valid && !e2_valid;

  // Detect when we want to start a multicycle op but can't yet (pipeline not drained)
  wire pending_reduction = valid_i && is_reduction_op && (red_state == RED_IDLE);
  wire pending_widening  = valid_i && is_widening_op && (wide_state == WIDE_IDLE);
  wire waiting_for_drain = (pending_reduction || pending_widening) && !pipeline_drained;

  // Register drain_stall for synthesis (but output must be combinational for
  // correctness — see v0.3f fix for of_valid race in hp_vpu_top.sv)
  logic drain_stall_r;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      drain_stall_r <= 1'b0;
    else
      drain_stall_r <= waiting_for_drain;
  end
  // v0.3f FIX: Use combinational waiting_for_drain, not registered drain_stall_r.
  // The 1-cycle delay of drain_stall_r allowed hp_vpu_top to clear of_valid
  // on the same cycle a multicycle op entered OF, losing the instruction.
  assign drain_stall_o = waiting_for_drain;

  // Can only start multicycle op when pipeline is drained
  wire can_start_reduction = pending_reduction && pipeline_drained;
  wire can_start_widening  = pending_widening && pipeline_drained;

  // Stall upstream when reduction, widening, MAC, E1m pipeline is active, OR waiting for drain
  assign multicycle_busy_o = (red_state != RED_IDLE) || (valid_i && is_reduction_op) ||
                             widening_busy || mac_stall || mul_stall || waiting_for_drain;

  // DEBUG: Trace specific IDs at lane input
  `ifdef SIMULATION
  always @(posedge clk) begin
    if (valid_i && (id_i == 32 || id_i == 92)) begin
      $display("[%0t] LANE_INPUT: vd=%0d id=%0d op=%0d", $time, vd_i, id_i, op_i);
      $display("         stall_i=%b mac_stall=%b mul_stall=%b multicycle_busy=%b",
               stall_i, mac_stall, mul_stall, multicycle_busy_o);
      $display("         is_reduction=%b is_widening=%b e1m_valid=%b e1_valid=%b",
               is_reduction_op, is_widening_op, e1m_valid, e1_valid);
    end
  end
  `endif

  // State machine
  // v1.7 FIX: Only start reduction when pipeline is drained to avoid VRF write contention
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      red_state <= RED_IDLE;
    end else if (!stall_i) begin
      case (red_state)
        RED_IDLE: if (can_start_reduction) red_state <= RED_R1;
        RED_R1:   red_state <= RED_R2A;
        RED_R2A:  red_state <= RED_R2B;
        RED_R2B:  red_state <= RED_R3;
        RED_R3:   red_state <= RED_IDLE;
      endcase
    end
  end

  //--------------------------------------------------------------------------
  // R1 Stage: Capture inputs + compute tree levels 0→1→2
  // SEW=8:  32→16→8 (or 8→4→2 for DLEN=64)
  // SEW=16: 16→8→4  (or 4→2→1 for DLEN=64)
  // SEW=32: 8→4→2   (or 2→1 for DLEN=64)
  //--------------------------------------------------------------------------

  // R1 combinational tree (2 levels)
  logic [7:0]  r1_tree8_l1  [0:NUM_ELEM_8/2-1];
  logic [7:0]  r1_tree8_l2  [0:NUM_ELEM_8/4-1];
  logic [15:0] r1_tree16_l1 [0:NUM_ELEM_16/2-1];
  logic [15:0] r1_tree16_l2 [0:NUM_ELEM_16/4-1];
  logic [31:0] r1_tree32_l1 [0:NUM_ELEM_32/2-1];

  // SEW=8 tree levels 0→1→2
  generate
    for (genvar i = 0; i < NUM_ELEM_8/2; i++) begin : gen_r1_tree8_l1
      wire [7:0] a = vs2_i[i*16 +: 8];
      wire [7:0] b = vs2_i[i*16+8 +: 8];
      always_comb begin
        case (op_i)
          OP_VREDSUM:  r1_tree8_l1[i] = a + b;
          OP_VREDMAX:  r1_tree8_l1[i] = ($signed(a) > $signed(b)) ? a : b;
          OP_VREDMIN:  r1_tree8_l1[i] = ($signed(a) < $signed(b)) ? a : b;
          OP_VREDMAXU: r1_tree8_l1[i] = (a > b) ? a : b;
          OP_VREDMINU: r1_tree8_l1[i] = (a < b) ? a : b;
          OP_VREDAND:  r1_tree8_l1[i] = a & b;
          OP_VREDOR:   r1_tree8_l1[i] = a | b;
          OP_VREDXOR:  r1_tree8_l1[i] = a ^ b;
          default:     r1_tree8_l1[i] = '0;
        endcase
      end
    end
    for (genvar i = 0; i < NUM_ELEM_8/4; i++) begin : gen_r1_tree8_l2
      always_comb begin
        case (op_i)
          OP_VREDSUM:  r1_tree8_l2[i] = r1_tree8_l1[i*2] + r1_tree8_l1[i*2+1];
          OP_VREDMAX:  r1_tree8_l2[i] = ($signed(r1_tree8_l1[i*2]) > $signed(r1_tree8_l1[i*2+1])) ?
                                         r1_tree8_l1[i*2] : r1_tree8_l1[i*2+1];
          OP_VREDMIN:  r1_tree8_l2[i] = ($signed(r1_tree8_l1[i*2]) < $signed(r1_tree8_l1[i*2+1])) ?
                                         r1_tree8_l1[i*2] : r1_tree8_l1[i*2+1];
          OP_VREDMAXU: r1_tree8_l2[i] = (r1_tree8_l1[i*2] > r1_tree8_l1[i*2+1]) ?
                                         r1_tree8_l1[i*2] : r1_tree8_l1[i*2+1];
          OP_VREDMINU: r1_tree8_l2[i] = (r1_tree8_l1[i*2] < r1_tree8_l1[i*2+1]) ?
                                         r1_tree8_l1[i*2] : r1_tree8_l1[i*2+1];
          OP_VREDAND:  r1_tree8_l2[i] = r1_tree8_l1[i*2] & r1_tree8_l1[i*2+1];
          OP_VREDOR:   r1_tree8_l2[i] = r1_tree8_l1[i*2] | r1_tree8_l1[i*2+1];
          OP_VREDXOR:  r1_tree8_l2[i] = r1_tree8_l1[i*2] ^ r1_tree8_l1[i*2+1];
          default:     r1_tree8_l2[i] = '0;
        endcase
      end
    end
  endgenerate

  // SEW=16 tree levels 0→1→2
  generate
    for (genvar i = 0; i < NUM_ELEM_16/2; i++) begin : gen_r1_tree16_l1
      wire [15:0] a = vs2_i[i*32 +: 16];
      wire [15:0] b = vs2_i[i*32+16 +: 16];
      always_comb begin
        case (op_i)
          OP_VREDSUM:  r1_tree16_l1[i] = a + b;
          OP_VREDMAX:  r1_tree16_l1[i] = ($signed(a) > $signed(b)) ? a : b;
          OP_VREDMIN:  r1_tree16_l1[i] = ($signed(a) < $signed(b)) ? a : b;
          OP_VREDMAXU: r1_tree16_l1[i] = (a > b) ? a : b;
          OP_VREDMINU: r1_tree16_l1[i] = (a < b) ? a : b;
          OP_VREDAND:  r1_tree16_l1[i] = a & b;
          OP_VREDOR:   r1_tree16_l1[i] = a | b;
          OP_VREDXOR:  r1_tree16_l1[i] = a ^ b;
          default:     r1_tree16_l1[i] = '0;
        endcase
      end
    end
    for (genvar i = 0; i < NUM_ELEM_16/4; i++) begin : gen_r1_tree16_l2
      always_comb begin
        case (op_i)
          OP_VREDSUM:  r1_tree16_l2[i] = r1_tree16_l1[i*2] + r1_tree16_l1[i*2+1];
          OP_VREDMAX:  r1_tree16_l2[i] = ($signed(r1_tree16_l1[i*2]) > $signed(r1_tree16_l1[i*2+1])) ?
                                          r1_tree16_l1[i*2] : r1_tree16_l1[i*2+1];
          OP_VREDMIN:  r1_tree16_l2[i] = ($signed(r1_tree16_l1[i*2]) < $signed(r1_tree16_l1[i*2+1])) ?
                                          r1_tree16_l1[i*2] : r1_tree16_l1[i*2+1];
          OP_VREDMAXU: r1_tree16_l2[i] = (r1_tree16_l1[i*2] > r1_tree16_l1[i*2+1]) ?
                                          r1_tree16_l1[i*2] : r1_tree16_l1[i*2+1];
          OP_VREDMINU: r1_tree16_l2[i] = (r1_tree16_l1[i*2] < r1_tree16_l1[i*2+1]) ?
                                          r1_tree16_l1[i*2] : r1_tree16_l1[i*2+1];
          OP_VREDAND:  r1_tree16_l2[i] = r1_tree16_l1[i*2] & r1_tree16_l1[i*2+1];
          OP_VREDOR:   r1_tree16_l2[i] = r1_tree16_l1[i*2] | r1_tree16_l1[i*2+1];
          OP_VREDXOR:  r1_tree16_l2[i] = r1_tree16_l1[i*2] ^ r1_tree16_l1[i*2+1];
          default:     r1_tree16_l2[i] = '0;
        endcase
      end
    end
  endgenerate

  // SEW=32 tree level 0→1
  generate
    for (genvar i = 0; i < NUM_ELEM_32/2; i++) begin : gen_r1_tree32_l1
      wire [31:0] a = vs2_i[i*64 +: 32];
      wire [31:0] b = vs2_i[i*64+32 +: 32];
      always_comb begin
        case (op_i)
          OP_VREDSUM:  r1_tree32_l1[i] = a + b;
          OP_VREDMAX:  r1_tree32_l1[i] = ($signed(a) > $signed(b)) ? a : b;
          OP_VREDMIN:  r1_tree32_l1[i] = ($signed(a) < $signed(b)) ? a : b;
          OP_VREDMAXU: r1_tree32_l1[i] = (a > b) ? a : b;
          OP_VREDMINU: r1_tree32_l1[i] = (a < b) ? a : b;
          OP_VREDAND:  r1_tree32_l1[i] = a & b;
          OP_VREDOR:   r1_tree32_l1[i] = a | b;
          OP_VREDXOR:  r1_tree32_l1[i] = a ^ b;
          default:     r1_tree32_l1[i] = '0;
        endcase
      end
    end
  endgenerate

  // R1 register capture
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r1_vs1    <= '0;
      r1_old_vd <= '0;
      r1_op     <= OP_NOP;
      r1_sew    <= SEW_8;
      r1_vd     <= '0;
      r1_id     <= '0;
      for (int i = 0; i < NUM_ELEM_8/4; i++)  r1_part8[i]  <= '0;
      for (int i = 0; i < NUM_ELEM_16/4; i++) r1_part16[i] <= '0;
      for (int i = 0; i < NUM_ELEM_32/2; i++) r1_part32[i] <= '0;
    end else if (!stall_i && red_state == RED_IDLE && valid_i && is_reduction_op) begin
      r1_vs1    <= vs1_i;
      r1_old_vd <= vs3_i;
      r1_op     <= op_i;
      r1_sew    <= sew_i;
      r1_vd     <= vd_i;
      r1_id     <= id_i;
      // Capture tree L2 results
      for (int i = 0; i < NUM_ELEM_8/4; i++)  r1_part8[i]  <= r1_tree8_l2[i];
      for (int i = 0; i < NUM_ELEM_16/4; i++) r1_part16[i] <= r1_tree16_l2[i];
      for (int i = 0; i < NUM_ELEM_32/2; i++) r1_part32[i] <= r1_tree32_l1[i];
    end
  end

  //--------------------------------------------------------------------------
  // R2A Stage: First half of R2 split (v0.3e: fixed array sizing for all DLEN)
  //--------------------------------------------------------------------------

  // R2A combinational - sized by R2A_N* localparams
  logic [7:0]  r2a_comb8  [0:R2A_N8-1];
  logic [15:0] r2a_comb16 [0:R2A_N16-1];
  logic [31:0] r2a_comb32 [0:R2A_N32-1];

  always_comb begin
    // SEW=8: If R1 has >2 elements, reduce by half. Else passthrough.
    if (R1_N8 > 2) begin
      for (int i = 0; i < R2A_N8; i++) begin
        case (r1_op)
          OP_VREDSUM:  r2a_comb8[i] = r1_part8[i*2] + r1_part8[i*2+1];
          OP_VREDMAX:  r2a_comb8[i] = ($signed(r1_part8[i*2]) > $signed(r1_part8[i*2+1])) ? r1_part8[i*2] : r1_part8[i*2+1];
          OP_VREDMIN:  r2a_comb8[i] = ($signed(r1_part8[i*2]) < $signed(r1_part8[i*2+1])) ? r1_part8[i*2] : r1_part8[i*2+1];
          OP_VREDMAXU: r2a_comb8[i] = (r1_part8[i*2] > r1_part8[i*2+1]) ? r1_part8[i*2] : r1_part8[i*2+1];
          OP_VREDMINU: r2a_comb8[i] = (r1_part8[i*2] < r1_part8[i*2+1]) ? r1_part8[i*2] : r1_part8[i*2+1];
          OP_VREDAND:  r2a_comb8[i] = r1_part8[i*2] & r1_part8[i*2+1];
          OP_VREDOR:   r2a_comb8[i] = r1_part8[i*2] | r1_part8[i*2+1];
          OP_VREDXOR:  r2a_comb8[i] = r1_part8[i*2] ^ r1_part8[i*2+1];
          default:     r2a_comb8[i] = '0;
        endcase
      end
    end else begin
      // R1 has <=2 elements (small DLEN): passthrough all
      for (int i = 0; i < R2A_N8; i++) r2a_comb8[i] = r1_part8[i];
    end

    // SEW=16: Same logic
    if (R1_N16 > 2) begin
      for (int i = 0; i < R2A_N16; i++) begin
        case (r1_op)
          OP_VREDSUM:  r2a_comb16[i] = r1_part16[i*2] + r1_part16[i*2+1];
          OP_VREDMAX:  r2a_comb16[i] = ($signed(r1_part16[i*2]) > $signed(r1_part16[i*2+1])) ? r1_part16[i*2] : r1_part16[i*2+1];
          OP_VREDMIN:  r2a_comb16[i] = ($signed(r1_part16[i*2]) < $signed(r1_part16[i*2+1])) ? r1_part16[i*2] : r1_part16[i*2+1];
          OP_VREDMAXU: r2a_comb16[i] = (r1_part16[i*2] > r1_part16[i*2+1]) ? r1_part16[i*2] : r1_part16[i*2+1];
          OP_VREDMINU: r2a_comb16[i] = (r1_part16[i*2] < r1_part16[i*2+1]) ? r1_part16[i*2] : r1_part16[i*2+1];
          OP_VREDAND:  r2a_comb16[i] = r1_part16[i*2] & r1_part16[i*2+1];
          OP_VREDOR:   r2a_comb16[i] = r1_part16[i*2] | r1_part16[i*2+1];
          OP_VREDXOR:  r2a_comb16[i] = r1_part16[i*2] ^ r1_part16[i*2+1];
          default:     r2a_comb16[i] = '0;
        endcase
      end
    end else begin
      for (int i = 0; i < R2A_N16; i++) r2a_comb16[i] = r1_part16[i];
    end

    // SEW=32: Same logic
    if (R1_N32 > 2) begin
      for (int i = 0; i < R2A_N32; i++) begin
        case (r1_op)
          OP_VREDSUM:  r2a_comb32[i] = r1_part32[i*2] + r1_part32[i*2+1];
          OP_VREDMAX:  r2a_comb32[i] = ($signed(r1_part32[i*2]) > $signed(r1_part32[i*2+1])) ? r1_part32[i*2] : r1_part32[i*2+1];
          OP_VREDMIN:  r2a_comb32[i] = ($signed(r1_part32[i*2]) < $signed(r1_part32[i*2+1])) ? r1_part32[i*2] : r1_part32[i*2+1];
          OP_VREDMAXU: r2a_comb32[i] = (r1_part32[i*2] > r1_part32[i*2+1]) ? r1_part32[i*2] : r1_part32[i*2+1];
          OP_VREDMINU: r2a_comb32[i] = (r1_part32[i*2] < r1_part32[i*2+1]) ? r1_part32[i*2] : r1_part32[i*2+1];
          OP_VREDAND:  r2a_comb32[i] = r1_part32[i*2] & r1_part32[i*2+1];
          OP_VREDOR:   r2a_comb32[i] = r1_part32[i*2] | r1_part32[i*2+1];
          OP_VREDXOR:  r2a_comb32[i] = r1_part32[i*2] ^ r1_part32[i*2+1];
          default:     r2a_comb32[i] = '0;
        endcase
      end
    end else begin
      for (int i = 0; i < R2A_N32; i++) r2a_comb32[i] = r1_part32[i];
    end
  end

  // R2A Register Capture
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r2a_vs1    <= '0;
      r2a_old_vd <= '0;
      r2a_op     <= OP_NOP;
      r2a_sew    <= SEW_8;
      r2a_vd     <= '0;
      r2a_id     <= '0;
      for (int i=0; i<R2A_N8; i++) r2a_part8[i] <= '0;
      for (int i=0; i<R2A_N16; i++) r2a_part16[i] <= '0;
      for (int i=0; i<R2A_N32; i++) r2a_part32[i] <= '0;
    end else if (!stall_i && red_state == RED_R1) begin
      r2a_vs1    <= r1_vs1;
      r2a_old_vd <= r1_old_vd;
      r2a_op     <= r1_op;
      r2a_sew    <= r1_sew;
      r2a_vd     <= r1_vd;
      r2a_id     <= r1_id;
      for (int i=0; i<R2A_N8; i++) r2a_part8[i] <= r2a_comb8[i];
      for (int i=0; i<R2A_N16; i++) r2a_part16[i] <= r2a_comb16[i];
      for (int i=0; i<R2A_N32; i++) r2a_part32[i] <= r2a_comb32[i];
    end
  end

  //--------------------------------------------------------------------------
  // R2B Stage: Second half of R2 split — reduce to final 2 elements (v0.3e fix)
  //--------------------------------------------------------------------------

  // R2B combinational — always outputs exactly 2 elements
  logic [7:0]  r2b_comb8  [0:1];
  logic [15:0] r2b_comb16 [0:1];
  logic [31:0] r2b_comb32 [0:1];

  always_comb begin
    // SEW=8: Reduce R2A output to 2 elements
    if (R2A_N8 >= 4) begin
       // R2A has 4+ elements: reduce pairs to 2
       for (int i=0; i<2; i++) begin
         case (r2a_op)
           OP_VREDSUM:  r2b_comb8[i] = r2a_part8[i*2] + r2a_part8[i*2+1];
           OP_VREDMAX:  r2b_comb8[i] = ($signed(r2a_part8[i*2]) > $signed(r2a_part8[i*2+1])) ? r2a_part8[i*2] : r2a_part8[i*2+1];
           OP_VREDMIN:  r2b_comb8[i] = ($signed(r2a_part8[i*2]) < $signed(r2a_part8[i*2+1])) ? r2a_part8[i*2] : r2a_part8[i*2+1];
           OP_VREDMAXU: r2b_comb8[i] = (r2a_part8[i*2] > r2a_part8[i*2+1]) ? r2a_part8[i*2] : r2a_part8[i*2+1];
           OP_VREDMINU: r2b_comb8[i] = (r2a_part8[i*2] < r2a_part8[i*2+1]) ? r2a_part8[i*2] : r2a_part8[i*2+1];
           OP_VREDAND:  r2b_comb8[i] = r2a_part8[i*2] & r2a_part8[i*2+1];
           OP_VREDOR:   r2b_comb8[i] = r2a_part8[i*2] | r2a_part8[i*2+1];
           OP_VREDXOR:  r2b_comb8[i] = r2a_part8[i*2] ^ r2a_part8[i*2+1];
           default:     r2b_comb8[i] = '0;
         endcase
       end
    end else if (R2A_N8 >= 2) begin
       // R2A has exactly 2 elements: passthrough
       r2b_comb8[0] = r2a_part8[0];
       r2b_comb8[1] = r2a_part8[1];
    end else begin
       // R2A has 1 element: fill identity for second
       r2b_comb8[0] = r2a_part8[0];
       case (r2a_op)
          OP_VREDMIN:  r2b_comb8[1] = 8'h7F;
          OP_VREDMAX:  r2b_comb8[1] = 8'h80;
          OP_VREDMINU: r2b_comb8[1] = 8'hFF;
          OP_VREDMAXU: r2b_comb8[1] = 8'h00;
          OP_VREDAND:  r2b_comb8[1] = 8'hFF;
          OP_VREDOR:   r2b_comb8[1] = 8'h00;
          OP_VREDXOR:  r2b_comb8[1] = 8'h00;
          default:     r2b_comb8[1] = 8'h00;
       endcase
    end

    // SEW=16: Reduce R2A output to 2 elements
    if (R2A_N16 >= 4) begin
       for (int i=0; i<2; i++) begin
         case (r2a_op)
           OP_VREDSUM:  r2b_comb16[i] = r2a_part16[i*2] + r2a_part16[i*2+1];
           OP_VREDMAX:  r2b_comb16[i] = ($signed(r2a_part16[i*2]) > $signed(r2a_part16[i*2+1])) ? r2a_part16[i*2] : r2a_part16[i*2+1];
           OP_VREDMIN:  r2b_comb16[i] = ($signed(r2a_part16[i*2]) < $signed(r2a_part16[i*2+1])) ? r2a_part16[i*2] : r2a_part16[i*2+1];
           OP_VREDMAXU: r2b_comb16[i] = (r2a_part16[i*2] > r2a_part16[i*2+1]) ? r2a_part16[i*2] : r2a_part16[i*2+1];
           OP_VREDMINU: r2b_comb16[i] = (r2a_part16[i*2] < r2a_part16[i*2+1]) ? r2a_part16[i*2] : r2a_part16[i*2+1];
           OP_VREDAND:  r2b_comb16[i] = r2a_part16[i*2] & r2a_part16[i*2+1];
           OP_VREDOR:   r2b_comb16[i] = r2a_part16[i*2] | r2a_part16[i*2+1];
           OP_VREDXOR:  r2b_comb16[i] = r2a_part16[i*2] ^ r2a_part16[i*2+1];
           default:     r2b_comb16[i] = '0;
         endcase
       end
    end else if (R2A_N16 >= 2) begin
       r2b_comb16[0] = r2a_part16[0];
       r2b_comb16[1] = r2a_part16[1];
    end else begin
       r2b_comb16[0] = r2a_part16[0];
       case (r2a_op)
          OP_VREDMIN:  r2b_comb16[1] = 16'h7FFF;
          OP_VREDMAX:  r2b_comb16[1] = 16'h8000;
          OP_VREDMINU: r2b_comb16[1] = 16'hFFFF;
          OP_VREDMAXU: r2b_comb16[1] = 16'h0000;
          OP_VREDAND:  r2b_comb16[1] = 16'hFFFF;
          OP_VREDOR:   r2b_comb16[1] = 16'h0000;
          OP_VREDXOR:  r2b_comb16[1] = 16'h0000;
          default:     r2b_comb16[1] = 16'h0000;
       endcase
    end

    // SEW=32: Reduce R2A output to 2 elements
    if (R2A_N32 >= 4) begin
       for (int i=0; i<2; i++) begin
         case (r2a_op)
           OP_VREDSUM:  r2b_comb32[i] = r2a_part32[i*2] + r2a_part32[i*2+1];
           OP_VREDMAX:  r2b_comb32[i] = ($signed(r2a_part32[i*2]) > $signed(r2a_part32[i*2+1])) ? r2a_part32[i*2] : r2a_part32[i*2+1];
           OP_VREDMIN:  r2b_comb32[i] = ($signed(r2a_part32[i*2]) < $signed(r2a_part32[i*2+1])) ? r2a_part32[i*2] : r2a_part32[i*2+1];
           OP_VREDMAXU: r2b_comb32[i] = (r2a_part32[i*2] > r2a_part32[i*2+1]) ? r2a_part32[i*2] : r2a_part32[i*2+1];
           OP_VREDMINU: r2b_comb32[i] = (r2a_part32[i*2] < r2a_part32[i*2+1]) ? r2a_part32[i*2] : r2a_part32[i*2+1];
           OP_VREDAND:  r2b_comb32[i] = r2a_part32[i*2] & r2a_part32[i*2+1];
           OP_VREDOR:   r2b_comb32[i] = r2a_part32[i*2] | r2a_part32[i*2+1];
           OP_VREDXOR:  r2b_comb32[i] = r2a_part32[i*2] ^ r2a_part32[i*2+1];
           default:     r2b_comb32[i] = '0;
         endcase
       end
    end else if (R2A_N32 >= 2) begin
       r2b_comb32[0] = r2a_part32[0];
       r2b_comb32[1] = r2a_part32[1];
    end else begin
       r2b_comb32[0] = r2a_part32[0];
       case (r2a_op)
          OP_VREDMIN:  r2b_comb32[1] = 32'h7FFFFFFF;
          OP_VREDMAX:  r2b_comb32[1] = 32'h80000000;
          OP_VREDMINU: r2b_comb32[1] = 32'hFFFFFFFF;
          OP_VREDMAXU: r2b_comb32[1] = 32'h00000000;
          OP_VREDAND:  r2b_comb32[1] = 32'hFFFFFFFF;
          OP_VREDOR:   r2b_comb32[1] = 32'h00000000;
          OP_VREDXOR:  r2b_comb32[1] = 32'h00000000;
          default:     r2b_comb32[1] = 32'h00000000;
       endcase
    end
  end

  // R2B Register Capture
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r2b_vs1    <= '0;
      r2b_old_vd <= '0;
      r2b_op     <= OP_NOP;
      r2b_sew    <= SEW_8;
      r2b_vd     <= '0;
      r2b_id     <= '0;
      r2b_part8[0]  <= '0; r2b_part8[1]  <= '0;
      r2b_part16[0] <= '0; r2b_part16[1] <= '0;
      r2b_part32[0] <= '0; r2b_part32[1] <= '0;
    end else if (!stall_i && red_state == RED_R2A) begin
      r2b_vs1    <= r2a_vs1;
      r2b_old_vd <= r2a_old_vd;
      r2b_op     <= r2a_op;
      r2b_sew    <= r2a_sew;
      r2b_vd     <= r2a_vd;
      r2b_id     <= r2a_id;
      r2b_part8[0]  <= r2b_comb8[0];  r2b_part8[1]  <= r2b_comb8[1];
      r2b_part16[0] <= r2b_comb16[0]; r2b_part16[1] <= r2b_comb16[1];
      r2b_part32[0] <= r2b_comb32[0]; r2b_part32[1] <= r2b_comb32[1];
    end
  end

  //--------------------------------------------------------------------------
  // R3 Stage: Final reduction (2→1) + add initial value
  //--------------------------------------------------------------------------

  logic [7:0]  r3_final8;
  logic [15:0] r3_final16;
  logic [31:0] r3_final32;

  // Temp variables for 2-stage comparisons (declared outside always_comb for iverilog)
  logic [7:0]  r3_tmp8;
  logic [15:0] r3_tmp16;
  logic [31:0] r3_tmp32;

  always_comb begin
    // SEW=8: 2→1 + initial
    r3_tmp8 = ($signed(r2b_part8[0]) > $signed(r2b_part8[1])) ? r2b_part8[0] : r2b_part8[1];
    case (r2b_op)
      OP_VREDSUM:  r3_final8 = r2b_part8[0] + r2b_part8[1] + r2b_vs1[7:0];
      OP_VREDMAX:  r3_final8 = ($signed(r3_tmp8) > $signed(r2b_vs1[7:0])) ? r3_tmp8 : r2b_vs1[7:0];
      OP_VREDMIN: begin
        r3_tmp8 = ($signed(r2b_part8[0]) < $signed(r2b_part8[1])) ? r2b_part8[0] : r2b_part8[1];
        r3_final8 = ($signed(r3_tmp8) < $signed(r2b_vs1[7:0])) ? r3_tmp8 : r2b_vs1[7:0];
      end
      OP_VREDMAXU: begin
        r3_tmp8 = (r2b_part8[0] > r2b_part8[1]) ? r2b_part8[0] : r2b_part8[1];
        r3_final8 = (r3_tmp8 > r2b_vs1[7:0]) ? r3_tmp8 : r2b_vs1[7:0];
      end
      OP_VREDMINU: begin
        r3_tmp8 = (r2b_part8[0] < r2b_part8[1]) ? r2b_part8[0] : r2b_part8[1];
        r3_final8 = (r3_tmp8 < r2b_vs1[7:0]) ? r3_tmp8 : r2b_vs1[7:0];
      end
      OP_VREDAND:  r3_final8 = r2b_part8[0] & r2b_part8[1] & r2b_vs1[7:0];
      OP_VREDOR:   r3_final8 = r2b_part8[0] | r2b_part8[1] | r2b_vs1[7:0];
      OP_VREDXOR:  r3_final8 = r2b_part8[0] ^ r2b_part8[1] ^ r2b_vs1[7:0];
      default:     r3_final8 = '0;
    endcase

    // SEW=16: 2→1 + initial
    r3_tmp16 = ($signed(r2b_part16[0]) > $signed(r2b_part16[1])) ? r2b_part16[0] : r2b_part16[1];
    case (r2b_op)
      OP_VREDSUM:  r3_final16 = r2b_part16[0] + r2b_part16[1] + r2b_vs1[15:0];
      OP_VREDMAX:  r3_final16 = ($signed(r3_tmp16) > $signed(r2b_vs1[15:0])) ? r3_tmp16 : r2b_vs1[15:0];
      OP_VREDMIN: begin
        r3_tmp16 = ($signed(r2b_part16[0]) < $signed(r2b_part16[1])) ? r2b_part16[0] : r2b_part16[1];
        r3_final16 = ($signed(r3_tmp16) < $signed(r2b_vs1[15:0])) ? r3_tmp16 : r2b_vs1[15:0];
      end
      OP_VREDMAXU: begin
        r3_tmp16 = (r2b_part16[0] > r2b_part16[1]) ? r2b_part16[0] : r2b_part16[1];
        r3_final16 = (r3_tmp16 > r2b_vs1[15:0]) ? r3_tmp16 : r2b_vs1[15:0];
      end
      OP_VREDMINU: begin
        r3_tmp16 = (r2b_part16[0] < r2b_part16[1]) ? r2b_part16[0] : r2b_part16[1];
        r3_final16 = (r3_tmp16 < r2b_vs1[15:0]) ? r3_tmp16 : r2b_vs1[15:0];
      end
      OP_VREDAND:  r3_final16 = r2b_part16[0] & r2b_part16[1] & r2b_vs1[15:0];
      OP_VREDOR:   r3_final16 = r2b_part16[0] | r2b_part16[1] | r2b_vs1[15:0];
      OP_VREDXOR:  r3_final16 = r2b_part16[0] ^ r2b_part16[1] ^ r2b_vs1[15:0];
      default:     r3_final16 = '0;
    endcase

    // SEW=32: 2→1 + initial
    r3_tmp32 = ($signed(r2b_part32[0]) > $signed(r2b_part32[1])) ? r2b_part32[0] : r2b_part32[1];
    case (r2b_op)
      OP_VREDSUM:  r3_final32 = r2b_part32[0] + r2b_part32[1] + r2b_vs1[31:0];
      OP_VREDMAX:  r3_final32 = ($signed(r3_tmp32) > $signed(r2b_vs1[31:0])) ? r3_tmp32 : r2b_vs1[31:0];
      OP_VREDMIN: begin
        r3_tmp32 = ($signed(r2b_part32[0]) < $signed(r2b_part32[1])) ? r2b_part32[0] : r2b_part32[1];
        r3_final32 = ($signed(r3_tmp32) < $signed(r2b_vs1[31:0])) ? r3_tmp32 : r2b_vs1[31:0];
      end
      OP_VREDMAXU: begin
        r3_tmp32 = (r2b_part32[0] > r2b_part32[1]) ? r2b_part32[0] : r2b_part32[1];
        r3_final32 = (r3_tmp32 > r2b_vs1[31:0]) ? r3_tmp32 : r2b_vs1[31:0];
      end
      OP_VREDMINU: begin
        r3_tmp32 = (r2b_part32[0] < r2b_part32[1]) ? r2b_part32[0] : r2b_part32[1];
        r3_final32 = (r3_tmp32 < r2b_vs1[31:0]) ? r3_tmp32 : r2b_vs1[31:0];
      end
      OP_VREDAND:  r3_final32 = r2b_part32[0] & r2b_part32[1] & r2b_vs1[31:0];
      OP_VREDOR:   r3_final32 = r2b_part32[0] | r2b_part32[1] | r2b_vs1[31:0];
      OP_VREDXOR:  r3_final32 = r2b_part32[0] ^ r2b_part32[1] ^ r2b_vs1[31:0];
      default:     r3_final32 = '0;
    endcase
  end

  // R3 register capture
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r3_vs1    <= '0;
      r3_old_vd <= '0;
      r3_op     <= OP_NOP;
      r3_sew    <= SEW_8;
      r3_vd     <= '0;
      r3_id     <= '0;
      r3_valid  <= 1'b0;
      r3_result <= '0;
    end else if (!stall_i) begin
      if (red_state == RED_R2B) begin
        r3_vs1    <= r2b_vs1;
        r3_old_vd <= r2b_old_vd;
        r3_op     <= r2b_op;
        r3_sew    <= r2b_sew;
        r3_vd     <= r2b_vd;
        r3_id     <= r2b_id;
        r3_valid  <= 1'b1;
        case (r2b_sew)
          SEW_8:   r3_result <= {24'b0, r3_final8};
          SEW_16:  r3_result <= {16'b0, r3_final16};
          default: r3_result <= r3_final32;
        endcase
      end else begin
        r3_valid <= 1'b0;
      end
    end
  end

  // Pack reduction result
  wire [DLEN-1:0] red_result_packed = (r3_sew == SEW_8)  ? {r3_old_vd[DLEN-1:8],  r3_result[7:0]} :
                                      (r3_sew == SEW_16) ? {r3_old_vd[DLEN-1:16], r3_result[15:0]} :
                                                           {r3_old_vd[DLEN-1:32], r3_result[31:0]};

  //============================================================================
  // Widening Pipeline (v0.17)
  // W1→W2 two-stage pipeline for widening multiply and add/sub
  // Parameterized by DLEN - works for DLEN=64, 128, 256, etc.
  // Output: 2*SEW width results packed into DLEN
  //============================================================================

  // Widening element counts (derived from DLEN)
  // SEW=8→16: Process DLEN/16 elements (input 8-bit, output 16-bit)
  // SEW=16→32: Process DLEN/32 elements (input 16-bit, output 32-bit)
  localparam int NUM_WIDE8  = DLEN / 16;  // 4 for DLEN=64, 16 for DLEN=256
  localparam int NUM_WIDE16 = DLEN / 32;  // 2 for DLEN=64, 8 for DLEN=256

  // Widening state machine
  logic [1:0] wide_state;
  localparam logic [1:0] WIDE_IDLE = 2'd0;
  localparam logic [1:0] WIDE_W1   = 2'd1;
  localparam logic [1:0] WIDE_W2   = 2'd2;

  // Detect widening op at input (v0.18: added widening MAC)
  wire is_widening_op = (op_i == OP_VWMULU)  || (op_i == OP_VWMULSU) ||
                        (op_i == OP_VWMUL)   || (op_i == OP_VWADDU)  ||
                        (op_i == OP_VWADD)   || (op_i == OP_VWSUBU)  ||
                        (op_i == OP_VWSUB)   || (op_i == OP_VWMACCU) ||
                        (op_i == OP_VWMACC)  || (op_i == OP_VWMACCSU);

  // W1 stage registers
  logic [DLEN-1:0] w1_vs2, w1_vs1;
  logic [DLEN-1:0] w1_old_vd;
  logic [NUM_ELEM_8-1:0] w1_vmask;  // Mask bits (1 per element at SEW=8)
  logic            w1_vm;
  vpu_op_e         w1_op;
  sew_e            w1_sew;
  logic [4:0]      w1_vd;
  logic [CVXIF_ID_W-1:0] w1_id;
  logic [31:0]     w1_scalar;
  logic            w1_is_vx;

  // W1 partial results (parameterized by DLEN)
  logic [15:0] w1_prod16 [0:NUM_WIDE8-1];   // SEW=8 widening multiply results
  logic [31:0] w1_prod32 [0:NUM_WIDE16-1];  // SEW=16 widening multiply results
  logic [15:0] w1_sum16  [0:NUM_WIDE8-1];   // SEW=8 widening add/sub results
  logic [31:0] w1_sum32  [0:NUM_WIDE16-1];  // SEW=16 widening add/sub results

  // W2 stage registers
  logic [DLEN-1:0] w2_result;
  logic [DLEN-1:0] w2_old_vd;
  logic [NUM_ELEM_8-1:0] w2_vmask;  // Mask bits (1 per element at SEW=8)
  logic            w2_vm;
  vpu_op_e         w2_op;
  sew_e            w2_sew;
  logic [4:0]      w2_vd;
  logic [CVXIF_ID_W-1:0] w2_id;
  logic            w2_valid;

  // Widening state machine
  // v1.7 FIX: Only start widening when pipeline is drained to avoid VRF write contention
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wide_state <= WIDE_IDLE;
    end else if (!stall_i) begin
      case (wide_state)
        WIDE_IDLE: if (can_start_widening) wide_state <= WIDE_W1;
        WIDE_W1:   wide_state <= WIDE_W2;
        WIDE_W2:   wide_state <= WIDE_IDLE;
        default:   wide_state <= WIDE_IDLE;
      endcase
    end
  end

  // Widening computations (combinational)
  // These compute widening products and sums in W1 stage

  // SEW=8 widening multiply: 8×8 → 16-bit (NUM_WIDE8 elements)
  // v0.18: Added widening MAC (product + accumulator)
  logic [15:0] wmul8_res [0:NUM_WIDE8-1];
  generate
    for (genvar i = 0; i < NUM_WIDE8; i++) begin : gen_wmul8
      wire [7:0] a8 = vs2_i[i*8 +: 8];
      wire [7:0] b8 = is_vx_i ? scalar_i[7:0] : vs1_i[i*8 +: 8];
      wire signed [7:0] a8_s = a8;
      wire signed [7:0] b8_s = b8;
      wire signed [15:0] prod_ss = a8_s * b8_s;       // signed × signed
      wire [15:0] prod_uu = a8 * b8;                   // unsigned × unsigned
      wire signed [15:0] prod_su = a8_s * $signed({1'b0, b8}); // signed × unsigned
      // Accumulator from old_vd (already widened to 16-bit)
      wire [15:0] acc16 = vs3_i[i*16 +: 16];

      always_comb begin
        case (op_i)
          OP_VWMUL:    wmul8_res[i] = prod_ss;
          OP_VWMULU:   wmul8_res[i] = prod_uu;
          OP_VWMULSU:  wmul8_res[i] = prod_su;
          // Widening MAC: product + accumulator
          OP_VWMACC:   wmul8_res[i] = prod_ss + acc16;
          OP_VWMACCU:  wmul8_res[i] = prod_uu + acc16;
          OP_VWMACCSU: wmul8_res[i] = prod_su + acc16;
          default:     wmul8_res[i] = '0;
        endcase
      end
    end
  endgenerate

  // SEW=16 widening multiply: 16×16 → 32-bit (NUM_WIDE16 elements)
  // v0.18: Added widening MAC (product + accumulator)
  logic [31:0] wmul16_res [0:NUM_WIDE16-1];
  generate
    for (genvar i = 0; i < NUM_WIDE16; i++) begin : gen_wmul16
      wire [15:0] a16 = vs2_i[i*16 +: 16];
      wire [15:0] b16 = is_vx_i ? scalar_i[15:0] : vs1_i[i*16 +: 16];
      wire signed [15:0] a16_s = a16;
      wire signed [15:0] b16_s = b16;
      wire signed [31:0] prod_ss = a16_s * b16_s;
      wire [31:0] prod_uu = a16 * b16;
      wire signed [31:0] prod_su = a16_s * $signed({1'b0, b16});
      // Accumulator from old_vd (already widened to 32-bit)
      wire [31:0] acc32 = vs3_i[i*32 +: 32];

      always_comb begin
        case (op_i)
          OP_VWMUL:    wmul16_res[i] = prod_ss;
          OP_VWMULU:   wmul16_res[i] = prod_uu;
          OP_VWMULSU:  wmul16_res[i] = prod_su;
          // Widening MAC: product + accumulator
          OP_VWMACC:   wmul16_res[i] = prod_ss + acc32;
          OP_VWMACCU:  wmul16_res[i] = prod_uu + acc32;
          OP_VWMACCSU: wmul16_res[i] = prod_su + acc32;
          default:     wmul16_res[i] = '0;
        endcase
      end
    end
  endgenerate

  // SEW=8 widening add/sub: 8+8 → 16-bit (sign/zero extended)
  // P3 FIX: Use explicit sign extension for consistent behavior across simulators
  logic [15:0] wadd8_res [0:NUM_WIDE8-1];
  generate
    for (genvar i = 0; i < NUM_WIDE8; i++) begin : gen_wadd8
      wire [7:0] a8 = vs2_i[i*8 +: 8];
      wire [7:0] b8 = is_vx_i ? scalar_i[7:0] : vs1_i[i*8 +: 8];
      // Explicit sign extension: replicate MSB to fill upper 8 bits
      wire signed [15:0] a8_se = {{8{a8[7]}}, a8};
      wire signed [15:0] b8_se = {{8{b8[7]}}, b8};
      wire [15:0] a8_ze = {8'b0, a8};          // zero-extend
      wire [15:0] b8_ze = {8'b0, b8};

      always_comb begin
        case (op_i)
          OP_VWADD:  wadd8_res[i] = a8_se + b8_se;
          OP_VWADDU: wadd8_res[i] = a8_ze + b8_ze;
          OP_VWSUB:  wadd8_res[i] = a8_se - b8_se;
          OP_VWSUBU: wadd8_res[i] = a8_ze - b8_ze;
          default:   wadd8_res[i] = '0;
        endcase
      end
    end
  endgenerate

  // SEW=16 widening add/sub: 16+16 → 32-bit
  // P3 FIX: Use explicit sign extension instead of $signed() for reliable behavior
  logic [31:0] wadd16_res [0:NUM_WIDE16-1];
  generate
    for (genvar i = 0; i < NUM_WIDE16; i++) begin : gen_wadd16
      wire [15:0] a16 = vs2_i[i*16 +: 16];
      wire [15:0] b16 = is_vx_i ? scalar_i[15:0] : vs1_i[i*16 +: 16];
      // Explicit sign extension: replicate MSB to fill upper 16 bits
      wire signed [31:0] a16_se = {{16{a16[15]}}, a16};
      wire signed [31:0] b16_se = {{16{b16[15]}}, b16};
      wire [31:0] a16_ze = {16'b0, a16};
      wire [31:0] b16_ze = {16'b0, b16};

      always_comb begin
        case (op_i)
          OP_VWADD:  wadd16_res[i] = a16_se + b16_se;
          OP_VWADDU: wadd16_res[i] = a16_ze + b16_ze;
          OP_VWSUB:  wadd16_res[i] = a16_se - b16_se;
          OP_VWSUBU: wadd16_res[i] = a16_ze - b16_ze;
          default:   wadd16_res[i] = '0;
        endcase
      end
    end
  endgenerate

  // W1 register capture
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      w1_vs2    <= '0;
      w1_vs1    <= '0;
      w1_old_vd <= '0;
      w1_vmask  <= '0;
      w1_vm     <= 1'b1;
      w1_op     <= OP_NOP;
      w1_sew    <= SEW_8;
      w1_vd     <= '0;
      w1_id     <= '0;
      w1_scalar <= '0;
      w1_is_vx  <= 1'b0;
      for (int i = 0; i < NUM_WIDE8; i++)  w1_prod16[i] <= '0;
      for (int i = 0; i < NUM_WIDE16; i++) w1_prod32[i] <= '0;
      for (int i = 0; i < NUM_WIDE8; i++)  w1_sum16[i]  <= '0;
      for (int i = 0; i < NUM_WIDE16; i++) w1_sum32[i]  <= '0;
    end else if (!stall_i && wide_state == WIDE_IDLE && valid_i && is_widening_op) begin
      w1_vs2    <= vs2_i;
      w1_vs1    <= vs1_i;
      w1_old_vd <= vs3_i;
      w1_vmask  <= vmask_i[NUM_ELEM_8-1:0];
      w1_vm     <= vm_i;
      w1_op     <= op_i;
      w1_sew    <= sew_i;
      w1_vd     <= vd_i;
      w1_id     <= id_i;
      w1_scalar <= scalar_i;
      w1_is_vx  <= is_vx_i;
      // Capture multiply results (for vwmul*)
      for (int i = 0; i < NUM_WIDE8; i++)  w1_prod16[i] <= wmul8_res[i];
      for (int i = 0; i < NUM_WIDE16; i++) w1_prod32[i] <= wmul16_res[i];
      // Capture add/sub results (for vwadd*/vwsub*)
      for (int i = 0; i < NUM_WIDE8; i++)  w1_sum16[i]  <= wadd8_res[i];
      for (int i = 0; i < NUM_WIDE16; i++) w1_sum32[i]  <= wadd16_res[i];
    end
  end

  // W2 stage: Pack results into DLEN-wide output
  logic [DLEN-1:0] wide_result_packed;

  always_comb begin
    wide_result_packed = '0;

    // Select multiply or add/sub results based on operation
    // v0.18: Added widening MAC operations
    case (w1_op)
      OP_VWMUL, OP_VWMULU, OP_VWMULSU,
      OP_VWMACC, OP_VWMACCU, OP_VWMACCSU: begin
        if (w1_sew == SEW_8) begin
          // NUM_WIDE8 × 16-bit products packed into DLEN bits
          for (int i = 0; i < NUM_WIDE8; i++) begin
            wide_result_packed[i*16 +: 16] = w1_prod16[i];
          end
        end else begin  // SEW_16
          // NUM_WIDE16 × 32-bit products packed into DLEN bits
          for (int i = 0; i < NUM_WIDE16; i++) begin
            wide_result_packed[i*32 +: 32] = w1_prod32[i];
          end
        end
      end
      OP_VWADD, OP_VWADDU, OP_VWSUB, OP_VWSUBU: begin
        if (w1_sew == SEW_8) begin
          // NUM_WIDE8 × 16-bit sums packed into DLEN bits
          for (int i = 0; i < NUM_WIDE8; i++) begin
            wide_result_packed[i*16 +: 16] = w1_sum16[i];
          end
        end else begin  // SEW_16
          // NUM_WIDE16 × 32-bit sums packed into DLEN bits
          for (int i = 0; i < NUM_WIDE16; i++) begin
            wide_result_packed[i*32 +: 32] = w1_sum32[i];
          end
        end
      end
      default: wide_result_packed = '0;
    endcase
  end

  // W2 register capture
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      w2_result <= '0;
      w2_old_vd <= '0;
      w2_vmask  <= '0;
      w2_vm     <= 1'b1;
      w2_op     <= OP_NOP;
      w2_sew    <= SEW_8;
      w2_vd     <= '0;
      w2_id     <= '0;
      w2_valid  <= 1'b0;
    end else if (!stall_i) begin
      if (wide_state == WIDE_W1) begin
        w2_result <= wide_result_packed;
        w2_old_vd <= w1_old_vd;
        w2_vmask  <= w1_vmask;
        w2_vm     <= w1_vm;
        w2_op     <= w1_op;
        w2_sew    <= w1_sew;
        w2_vd     <= w1_vd;
        w2_id     <= w1_id;
        w2_valid  <= 1'b1;
      end else begin
        w2_valid <= 1'b0;
      end
    end
  end

  // Widening busy signal - stall upstream when widening pipeline active
  wire widening_busy = (wide_state != WIDE_IDLE) || (valid_i && is_widening_op);

  //============================================================================
  // Scalar Replication (SEW-aware, parameterized by DLEN)
  //============================================================================
  wire [DLEN-1:0] scalar_rep_sew8;
  wire [DLEN-1:0] scalar_rep_sew16;
  wire [DLEN-1:0] scalar_rep_sew32;

  generate
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_rep8
      assign scalar_rep_sew8[i*8 +: 8] = scalar_i[7:0];
    end
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_rep16
      assign scalar_rep_sew16[i*16 +: 16] = scalar_i[15:0];
    end
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_rep32
      assign scalar_rep_sew32[i*32 +: 32] = scalar_i[31:0];
    end
  endgenerate

  wire [DLEN-1:0] scalar_rep = (sew_i == SEW_8)  ? scalar_rep_sew8 :
                               (sew_i == SEW_16) ? scalar_rep_sew16 :
                                                   scalar_rep_sew32;

  //============================================================================
  // Operand Selection
  //============================================================================
  // For .vv: a=vs1, b=vs2
  // Operand selection
  // For .vv: a=vs2, b=vs1 (RVV spec: vd = vs2 op vs1)
  // For .vx: a=vs2, b=scalar (RVV spec: vd = vs2 op rs1)
  wire [DLEN-1:0] vec_a, vec_b;

  generate
    for (genvar l = 0; l < NLANES; l++) begin : gen_operand_sel
      assign vec_a[l*64 +: 64] = vs2_i[l*64 +: 64];  // Always vs2
      assign vec_b[l*64 +: 64] = is_vx_i ? scalar_rep[l*64 +: 64] : vs1_i[l*64 +: 64];
    end
  endgenerate

  //============================================================================
  // LUT-based Operations for LLM Inference (v0.19)
  // Single-cycle lookup: vexp, vrecip, vrsqrt, vgelu
  // Input: 8-bit index from vs2 (lower bits of each element)
  // Output: 16-bit result, zero-extended or truncated based on SEW
  //============================================================================

  // Detect LUT operations
  wire is_lut_op = (op_i == OP_VEXP)   || (op_i == OP_VRECIP) ||
                   (op_i == OP_VRSQRT) || (op_i == OP_VGELU);

  // LUT function select encoding
  localparam logic [1:0] LUT_EXP   = 2'd0;
  localparam logic [1:0] LUT_RECIP = 2'd1;
  localparam logic [1:0] LUT_RSQRT = 2'd2;
  localparam logic [1:0] LUT_GELU  = 2'd3;

  // Function select based on op
  logic [1:0] lut_func_sel;
  always_comb begin
    case (op_i)
      OP_VEXP:   lut_func_sel = LUT_EXP;
      OP_VRECIP: lut_func_sel = LUT_RECIP;
      OP_VRSQRT: lut_func_sel = LUT_RSQRT;
      OP_VGELU:  lut_func_sel = LUT_GELU;
      default:   lut_func_sel = LUT_EXP;  // Don't care
    endcase
  end

  // LUT ROM instances - one per 8-bit element (DLEN/8 elements for SEW=8)
  // For larger SEW, we use fewer LUTs but still index by lower 8 bits
  logic [15:0] lut_result_raw [0:DLEN/8-1];

  generate
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_lut_rom
      hp_vpu_lut_rom u_lut_rom (
        .clk        (clk),
        .index_i    (vs2_i[i*8 +: 8]),
        .func_sel_i (lut_func_sel),
        .result_o   (lut_result_raw[i])
      );
    end
  endgenerate

  // Pack LUT results based on SEW
  // SEW=8:  Use low 8 bits of LUT output (truncate)
  // SEW=16: Use full 16 bits of LUT output
  // SEW=32: Zero-extend 16-bit LUT output to 32 bits
  logic [DLEN-1:0] lut_result_8, lut_result_16, lut_result_32;

  generate
    // SEW=8: DLEN/8 elements, take lower 8 bits of each 16-bit LUT result
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_lut_pack8
      assign lut_result_8[i*8 +: 8] = lut_result_raw[i][7:0];
    end

    // SEW=16: DLEN/16 elements, use full 16-bit LUT result
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_lut_pack16
      assign lut_result_16[i*16 +: 16] = lut_result_raw[i*2][15:0];
    end

    // SEW=32: DLEN/32 elements, zero-extend 16-bit result
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_lut_pack32
      assign lut_result_32[i*32 +: 32] = {16'b0, lut_result_raw[i*4][15:0]};
    end
  endgenerate

  wire [DLEN-1:0] lut_result = (sew_i == SEW_8)  ? lut_result_8 :
                               (sew_i == SEW_16) ? lut_result_16 :
                                                   lut_result_32;

  //============================================================================
  // v1.1: INT4 Pack/Unpack Operations for Lower Quantization
  // vunpack4.v: Unpack INT4 pairs to INT8 (sign-extended)
  //   Input:  vs2 = [b1:a1, b0:a0, ...] (packed INT4, 2 per byte)
  //   Output: vd  = [a0, b0, a1, b1, ...] (INT8, sign-extended from 4-bit)
  //
  // vpack4.v: Pack INT8 to INT4 with saturation
  //   Input:  vs2 = [a, b, c, d, ...] (INT8 values)
  //   Output: vd  = [b:a, d:c, ...] (packed INT4, saturated to [-8,7])
  //============================================================================

  wire is_pack_op = (op_i == OP_VPACK4) || (op_i == OP_VUNPACK4);

  // vunpack4: Unpack INT4 pairs to INT8
  // Input bytes: vs2[i] = {hi_nibble[3:0], lo_nibble[3:0]}
  // Output: vd[2*i] = sext(lo_nibble), vd[2*i+1] = sext(hi_nibble)
  wire [DLEN-1:0] unpack4_result;
  generate
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_unpack4
      // Each input byte produces 2 output bytes
      // Sign-extend 4-bit nibbles to 8-bit
      wire [3:0] lo_nib = vs2_i[i*8 +: 4];
      wire [3:0] hi_nib = vs2_i[i*8+4 +: 4];
      assign unpack4_result[i*16 +: 8]   = {{4{lo_nib[3]}}, lo_nib};
      assign unpack4_result[i*16+8 +: 8] = {{4{hi_nib[3]}}, hi_nib};
    end
  endgenerate

  // vpack4: Pack INT8 pairs to INT4 with signed saturation
  // Saturate INT8 [-128,127] to INT4 [-8,7]
  function automatic [3:0] saturate_to_int4(input [7:0] val);
    logic signed [7:0] sval;
    sval = val;
    if (sval > 7)
      saturate_to_int4 = 4'd7;       // Clamp positive overflow
    else if (sval < -8)
      saturate_to_int4 = 4'b1000;    // Clamp negative overflow (-8)
    else
      saturate_to_int4 = val[3:0];   // In range, take lower 4 bits
  endfunction

  wire [DLEN-1:0] pack4_result;
  generate
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_pack4
      // Each pair of input bytes produces 1 output byte
      wire [7:0] byte_lo = vs2_i[i*16 +: 8];
      wire [7:0] byte_hi = vs2_i[i*16+8 +: 8];
      wire [3:0] nib_lo = saturate_to_int4(byte_lo);
      wire [3:0] nib_hi = saturate_to_int4(byte_hi);
      assign pack4_result[i*8 +: 8] = {nib_hi, nib_lo};
    end
    // Zero upper half (pack produces half the bytes)
    if (DLEN > 16) begin : gen_pack4_zero
      assign pack4_result[DLEN-1:DLEN/2] = '0;
    end
  endgenerate

  wire [DLEN-1:0] int4_result = (op_i == OP_VUNPACK4) ? unpack4_result : pack4_result;

  //============================================================================
  // E1 Stage: Logic, Shifts, Min/Max, Comparisons
  //============================================================================
  logic        e1_valid;
  vpu_op_e     e1_op;
  logic [DLEN-1:0] e1_a, e1_b, e1_c;
  logic [DLEN-1:0] e1_old_vd;      // Old destination for masking
  logic [NUM_ELEM_8-1:0] e1_vmask; // Mask bits from v0 (1 per element at SEW=8)
  logic            e1_vm;          // vm=1 unmasked, vm=0 masked
  logic [DLEN-1:0] e1_logic_res;
  logic [DLEN-1:0] e1_shift_res;
  logic [DLEN-1:0] e1_minmax_res;
  logic [DLEN-1:0] e1_gather_res;  // Gather result
  logic [DLEN-1:0] e1_slideup_res; // Slide up result
  logic [DLEN-1:0] e1_slidedn_res; // Slide down result
  logic [DLEN-1:0] e1_slide1up_res; // v0.15: vslide1up result
  logic [DLEN-1:0] e1_slide1dn_res; // v0.15: vslide1down result
  logic [DLEN-1:0] e1_merge_res;    // v0.15: vmerge result
  logic [31:0]     e1_redsum;      // Reduction sum (accumulates to ELEN)
  logic [31:0]     e1_redmax;      // Reduction max (signed)
  logic [31:0]     e1_redmin;      // Reduction min (signed)
  logic [31:0]     e1_redmaxu;     // Reduction max (unsigned)
  logic [31:0]     e1_redminu;     // Reduction min (unsigned)
  logic [31:0]     e1_redand;      // Reduction AND
  logic [31:0]     e1_redor;       // Reduction OR
  logic [31:0]     e1_redxor;      // Reduction XOR
  logic [DLEN-1:0] e1_mask_res;    // Mask-register logical result
  logic [DLEN-1:0] e1_sat_res;     // Saturating add/sub result
  logic [DLEN-1:0] e1_sshift_res;  // Scaling shift result
  logic [DLEN-1:0] e1_nclip_res;   // Narrowing clip result
  logic [DLEN-1:0] e1_nshift_res;  // Narrowing shift result (v0.18)
  logic [DLEN-1:0] e1_lut_res;     // LUT result (v0.19)
  logic [DLEN-1:0] e1_int4_res;    // INT4 pack/unpack result (v1.1)
  // v0.5a: Pipeline-register combinational results that depend on OF-stage inputs
  logic [DLEN-1:0] e1_viota_res;   // viota.m result
  logic [DLEN-1:0] e1_compress_res; // vcompress.vm result
  logic [DLEN-1:0] e1_vcpop_res;   // vcpop result
  logic [DLEN-1:0] e1_vfirst_res;  // vfirst result
  logic [DLEN-1:0] e1_vmsbf_res;   // vmsbf result
  logic [DLEN-1:0] e1_vmsif_res;   // vmsif result
  logic [DLEN-1:0] e1_vmsof_res;   // vmsof result
  logic [DLEN-1:0] e1_gatherei16_res; // vrgatherei16 result
  logic [NUM_ELEM_8-1:0] e1_cmp_mask;  // Comparison result mask
  sew_e        e1_sew;
  logic [4:0]  e1_vd;
  logic [CVXIF_ID_W-1:0] e1_id;
  logic        e1_is_last_uop;   // v1.2a: LMUL micro-op tracking

  //============================================================================
  // E1m Stage: Intermediate stage for multiply operations (v1.7)
  // Splits 32×32 multiply timing path: E1→E1m (partials) → E2 (combine)
  // Only multiply ops flow through E1m; other ops bypass directly to E2
  //============================================================================
  logic        e1m_valid;
  vpu_op_e     e1m_op;
  sew_e        e1m_sew;
  logic [4:0]  e1m_vd;
  logic [CVXIF_ID_W-1:0] e1m_id;
  logic        e1m_is_last_uop;

  // Operands needed for E2 (MAC add stage uses these)
  logic [DLEN-1:0] e1m_a;         // vs2 (for vmadd/vnmsub addend)
  logic [DLEN-1:0] e1m_b;         // vs1
  logic [DLEN-1:0] e1m_c;         // old_vd (accumulator for vmacc/vnmsac)
  logic [DLEN-1:0] e1m_old_vd;    // For masking
  logic [NUM_ELEM_8-1:0] e1m_vmask;
  logic        e1m_vm;

  // Partial products for SEW=32 (split 32×32 into four 16×16)
  // Each 32×32 multiply needs: pp_ll, pp_lh, pp_hl, pp_hh
  logic [31:0] e1m_pp_ll_32 [NUM_ELEM_32];  // low × low (unsigned)
  logic [31:0] e1m_pp_lh_32 [NUM_ELEM_32];  // low × high (mixed)
  logic [31:0] e1m_pp_hl_32 [NUM_ELEM_32];  // high × low (mixed)
  logic [31:0] e1m_pp_hh_32 [NUM_ELEM_32];  // high × high (signed)

  // Unsigned partials for vmulhu
  logic [31:0] e1m_ppu_ll_32 [NUM_ELEM_32];
  logic [31:0] e1m_ppu_lh_32 [NUM_ELEM_32];
  logic [31:0] e1m_ppu_hl_32 [NUM_ELEM_32];
  logic [31:0] e1m_ppu_hh_32 [NUM_ELEM_32];

  // Signed×Unsigned partials for vmulhsu
  logic [31:0] e1m_ppsu_ll_32 [NUM_ELEM_32];
  logic [31:0] e1m_ppsu_lh_32 [NUM_ELEM_32];
  logic [31:0] e1m_ppsu_hl_32 [NUM_ELEM_32];
  logic [31:0] e1m_ppsu_hh_32 [NUM_ELEM_32];

  // VMADD partials (vs1 × old_vd)
  logic [31:0] e1m_ppmadd_ll_32 [NUM_ELEM_32];
  logic [31:0] e1m_ppmadd_lh_32 [NUM_ELEM_32];
  logic [31:0] e1m_ppmadd_hl_32 [NUM_ELEM_32];
  logic [31:0] e1m_ppmadd_hh_32 [NUM_ELEM_32];

  // For SEW=8 and SEW=16, full products fit in one DSP, so just register them
  logic [15:0] e1m_mul_8 [NUM_ELEM_8];
  logic [15:0] e1m_mulu_8 [NUM_ELEM_8];
  logic signed [15:0] e1m_mulsu_8 [NUM_ELEM_8];
  logic [15:0] e1m_madd_8 [NUM_ELEM_8];

  logic [31:0] e1m_mul_16 [NUM_ELEM_16];
  logic [31:0] e1m_mulu_16 [NUM_ELEM_16];
  logic signed [31:0] e1m_mulsu_16 [NUM_ELEM_16];
  logic [31:0] e1m_madd_16 [NUM_ELEM_16];

  // Detect multiply operations (these go through E1m)
  wire is_mul_op = (op_i == OP_VMUL)   || (op_i == OP_VMULH)  ||
                   (op_i == OP_VMULHU) || (op_i == OP_VMULHSU) ||
                   (op_i == OP_VMACC)  || (op_i == OP_VNMSAC) ||
                   (op_i == OP_VMADD)  || (op_i == OP_VNMSUB);

  wire is_mul_op_e1 = e1_valid && ((e1_op == OP_VMUL)   || (e1_op == OP_VMULH)  ||
                                   (e1_op == OP_VMULHU) || (e1_op == OP_VMULHSU) ||
                                   (e1_op == OP_VMACC)  || (e1_op == OP_VNMSAC) ||
                                   (e1_op == OP_VMADD)  || (e1_op == OP_VNMSUB));

  // E1 stall logic (v1.7, v1.9 FIX):
  // E1 can capture new instruction when its current content can advance:
  // - E1 empty: always can capture
  // - E1 has multiply, E1m empty: multiply hands off to E1m, E1 can capture non-mul
  // - E1 has multiply, E1m full: blocked (can't hand off)
  // - E1 has non-multiply, E1m empty: goes to E2, can capture
  // - E1 has non-multiply, E1m full: blocked (E2 takes from E1m first)
  //
  // So E1 is blocked (mul_stall) when:
  // 1. E1 has NON-multiply content AND E1m is full (E2 must drain E1m first)
  // v0.5e: Multiplies in E1 no longer stall - E1m does simultaneous drain+capture
  wire mul_stall = e1_valid && e1m_valid && !is_mul_op_e1;

  //--------------------------------------------------------------------------
  // Logic Operations (SEW-independent - bitwise)
  //--------------------------------------------------------------------------
  wire [DLEN-1:0] logic_and = vec_a & vec_b;
  wire [DLEN-1:0] logic_or  = vec_a | vec_b;
  wire [DLEN-1:0] logic_xor = vec_a ^ vec_b;

  //--------------------------------------------------------------------------
  // Shift Operations (Multi-SEW)
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] shift_sll_8, shift_srl_8, shift_sra_8;
  logic [DLEN-1:0] shift_sll_16, shift_srl_16, shift_sra_16;
  logic [DLEN-1:0] shift_sll_32, shift_srl_32, shift_sra_32;

  generate
    // SEW=8: 32 elements
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_shift8
      wire [7:0] data8 = vec_a[i*8 +: 8];
      wire [2:0] shamt8 = vec_b[i*8 +: 3];
      wire signed [7:0] data8_s = data8;
      assign shift_sll_8[i*8 +: 8] = data8 << shamt8;
      assign shift_srl_8[i*8 +: 8] = data8 >> shamt8;
      assign shift_sra_8[i*8 +: 8] = data8_s >>> shamt8;
    end

    // SEW=16: 16 elements
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_shift16
      wire [15:0] data16 = vec_a[i*16 +: 16];
      wire [3:0] shamt16 = vec_b[i*16 +: 4];
      wire signed [15:0] data16_s = data16;
      assign shift_sll_16[i*16 +: 16] = data16 << shamt16;
      assign shift_srl_16[i*16 +: 16] = data16 >> shamt16;
      assign shift_sra_16[i*16 +: 16] = data16_s >>> shamt16;
    end

    // SEW=32: 8 elements
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_shift32
      wire [31:0] data32 = vec_a[i*32 +: 32];
      wire [4:0] shamt32 = vec_b[i*32 +: 5];
      wire signed [31:0] data32_s = data32;
      assign shift_sll_32[i*32 +: 32] = data32 << shamt32;
      assign shift_srl_32[i*32 +: 32] = data32 >> shamt32;
      assign shift_sra_32[i*32 +: 32] = data32_s >>> shamt32;
    end
  endgenerate

  wire [DLEN-1:0] shift_sll = (sew_i == SEW_8) ? shift_sll_8 :
                              (sew_i == SEW_16) ? shift_sll_16 : shift_sll_32;
  wire [DLEN-1:0] shift_srl = (sew_i == SEW_8) ? shift_srl_8 :
                              (sew_i == SEW_16) ? shift_srl_16 : shift_srl_32;
  wire [DLEN-1:0] shift_sra = (sew_i == SEW_8) ? shift_sra_8 :
                              (sew_i == SEW_16) ? shift_sra_16 : shift_sra_32;

  //--------------------------------------------------------------------------
  // Min/Max Operations (Multi-SEW, Signed & Unsigned)
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] minmax_min_8, minmax_minu_8, minmax_max_8, minmax_maxu_8;
  logic [DLEN-1:0] minmax_min_16, minmax_minu_16, minmax_max_16, minmax_maxu_16;
  logic [DLEN-1:0] minmax_min_32, minmax_minu_32, minmax_max_32, minmax_maxu_32;

  generate
    // SEW=8
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_minmax8
      wire [7:0] a8 = vec_a[i*8 +: 8];
      wire [7:0] b8 = vec_b[i*8 +: 8];
      wire signed [7:0] a8_s = a8, b8_s = b8;
      assign minmax_minu_8[i*8 +: 8] = (a8 < b8) ? a8 : b8;
      assign minmax_maxu_8[i*8 +: 8] = (a8 > b8) ? a8 : b8;
      assign minmax_min_8[i*8 +: 8] = (a8_s < b8_s) ? a8 : b8;
      assign minmax_max_8[i*8 +: 8] = (a8_s > b8_s) ? a8 : b8;
    end

    // SEW=16
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_minmax16
      wire [15:0] a16 = vec_a[i*16 +: 16];
      wire [15:0] b16 = vec_b[i*16 +: 16];
      wire signed [15:0] a16_s = a16, b16_s = b16;
      assign minmax_minu_16[i*16 +: 16] = (a16 < b16) ? a16 : b16;
      assign minmax_maxu_16[i*16 +: 16] = (a16 > b16) ? a16 : b16;
      assign minmax_min_16[i*16 +: 16] = (a16_s < b16_s) ? a16 : b16;
      assign minmax_max_16[i*16 +: 16] = (a16_s > b16_s) ? a16 : b16;
    end

    // SEW=32
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_minmax32
      wire [31:0] a32 = vec_a[i*32 +: 32];
      wire [31:0] b32 = vec_b[i*32 +: 32];
      wire signed [31:0] a32_s = a32, b32_s = b32;
      assign minmax_minu_32[i*32 +: 32] = (a32 < b32) ? a32 : b32;
      assign minmax_maxu_32[i*32 +: 32] = (a32 > b32) ? a32 : b32;
      assign minmax_min_32[i*32 +: 32] = (a32_s < b32_s) ? a32 : b32;
      assign minmax_max_32[i*32 +: 32] = (a32_s > b32_s) ? a32 : b32;
    end
  endgenerate

  wire [DLEN-1:0] minmax_min = (sew_i == SEW_8) ? minmax_min_8 :
                               (sew_i == SEW_16) ? minmax_min_16 : minmax_min_32;
  wire [DLEN-1:0] minmax_minu = (sew_i == SEW_8) ? minmax_minu_8 :
                                (sew_i == SEW_16) ? minmax_minu_16 : minmax_minu_32;
  wire [DLEN-1:0] minmax_max = (sew_i == SEW_8) ? minmax_max_8 :
                               (sew_i == SEW_16) ? minmax_max_16 : minmax_max_32;
  wire [DLEN-1:0] minmax_maxu = (sew_i == SEW_8) ? minmax_maxu_8 :
                                (sew_i == SEW_16) ? minmax_maxu_16 : minmax_maxu_32;

  //--------------------------------------------------------------------------
  // Comparison Operations (Multi-SEW) - Output mask bits
  // Array sizes match DLEN - parameterized to avoid undriven bits
  //--------------------------------------------------------------------------
  logic [DLEN/8-1:0]  cmp_eq_8, cmp_ne_8, cmp_lt_8, cmp_ltu_8, cmp_le_8, cmp_leu_8;
  logic [DLEN/16-1:0] cmp_eq_16, cmp_ne_16, cmp_lt_16, cmp_ltu_16, cmp_le_16, cmp_leu_16;
  logic [DLEN/32-1:0] cmp_eq_32, cmp_ne_32, cmp_lt_32, cmp_ltu_32, cmp_le_32, cmp_leu_32;

  generate
    // SEW=8: 32 comparison results
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_cmp8
      wire [7:0] a8 = vec_a[i*8 +: 8];
      wire [7:0] b8 = vec_b[i*8 +: 8];
      wire signed [7:0] a8_s = a8, b8_s = b8;
      assign cmp_eq_8[i]  = (a8 == b8);
      assign cmp_ne_8[i]  = (a8 != b8);
      assign cmp_ltu_8[i] = (a8 < b8);
      assign cmp_lt_8[i]  = (a8_s < b8_s);
      assign cmp_leu_8[i] = (a8 <= b8);
      assign cmp_le_8[i]  = (a8_s <= b8_s);
    end

    // SEW=16: 16 comparison results
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_cmp16
      wire [15:0] a16 = vec_a[i*16 +: 16];
      wire [15:0] b16 = vec_b[i*16 +: 16];
      wire signed [15:0] a16_s = a16, b16_s = b16;
      assign cmp_eq_16[i]  = (a16 == b16);
      assign cmp_ne_16[i]  = (a16 != b16);
      assign cmp_ltu_16[i] = (a16 < b16);
      assign cmp_lt_16[i]  = (a16_s < b16_s);
      assign cmp_leu_16[i] = (a16 <= b16);
      assign cmp_le_16[i]  = (a16_s <= b16_s);
    end

    // SEW=32: 8 comparison results
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_cmp32
      wire [31:0] a32 = vec_a[i*32 +: 32];
      wire [31:0] b32 = vec_b[i*32 +: 32];
      wire signed [31:0] a32_s = a32, b32_s = b32;
      assign cmp_eq_32[i]  = (a32 == b32);
      assign cmp_ne_32[i]  = (a32 != b32);
      assign cmp_ltu_32[i] = (a32 < b32);
      assign cmp_lt_32[i]  = (a32_s < b32_s);
      assign cmp_leu_32[i] = (a32 <= b32);
      assign cmp_le_32[i]  = (a32_s <= b32_s);
    end
  endgenerate

  // Comparison result mux (extend smaller masks with zeros to DLEN/8 bits)
  // At DLEN=64: SEW=8 has 8 bits, SEW=16 has 4 bits, SEW=32 has 2 bits
  wire [DLEN/8-1:0] cmp_eq  = (sew_i == SEW_8) ? cmp_eq_8 :
                              (sew_i == SEW_16) ? {{(DLEN/8-DLEN/16){1'b0}}, cmp_eq_16} :
                                                  {{(DLEN/8-DLEN/32){1'b0}}, cmp_eq_32};
  wire [DLEN/8-1:0] cmp_ne  = (sew_i == SEW_8) ? cmp_ne_8 :
                              (sew_i == SEW_16) ? {{(DLEN/8-DLEN/16){1'b0}}, cmp_ne_16} :
                                                  {{(DLEN/8-DLEN/32){1'b0}}, cmp_ne_32};
  wire [DLEN/8-1:0] cmp_lt  = (sew_i == SEW_8) ? cmp_lt_8 :
                              (sew_i == SEW_16) ? {{(DLEN/8-DLEN/16){1'b0}}, cmp_lt_16} :
                                                  {{(DLEN/8-DLEN/32){1'b0}}, cmp_lt_32};
  wire [DLEN/8-1:0] cmp_ltu = (sew_i == SEW_8) ? cmp_ltu_8 :
                              (sew_i == SEW_16) ? {{(DLEN/8-DLEN/16){1'b0}}, cmp_ltu_16} :
                                                  {{(DLEN/8-DLEN/32){1'b0}}, cmp_ltu_32};
  wire [DLEN/8-1:0] cmp_le  = (sew_i == SEW_8) ? cmp_le_8 :
                              (sew_i == SEW_16) ? {{(DLEN/8-DLEN/16){1'b0}}, cmp_le_16} :
                                                  {{(DLEN/8-DLEN/32){1'b0}}, cmp_le_32};
  wire [DLEN/8-1:0] cmp_leu = (sew_i == SEW_8) ? cmp_leu_8 :
                              (sew_i == SEW_16) ? {{(DLEN/8-DLEN/16){1'b0}}, cmp_leu_16} :
                                                  {{(DLEN/8-DLEN/32){1'b0}}, cmp_leu_32};

  // Greater-than derived from less-than-or-equal: a > b iff !(a <= b)
  // Must only invert valid bits based on SEW, not the zero-padding
  wire [DLEN/8-1:0] valid_mask_8  = {(DLEN/8){1'b1}};   // All bits valid for SEW=8
  wire [DLEN/8-1:0] valid_mask_16 = {{(DLEN/8-DLEN/16){1'b0}}, {(DLEN/16){1'b1}}};
  wire [DLEN/8-1:0] valid_mask_32 = {{(DLEN/8-DLEN/32){1'b0}}, {(DLEN/32){1'b1}}};
  wire [DLEN/8-1:0] valid_mask = (sew_i == SEW_8) ? valid_mask_8 :
                                 (sew_i == SEW_16) ? valid_mask_16 : valid_mask_32;
  wire [DLEN/8-1:0] cmp_gt  = (~cmp_le) & valid_mask;   // Signed greater-than
  wire [DLEN/8-1:0] cmp_gtu = (~cmp_leu) & valid_mask;  // Unsigned greater-than

  //--------------------------------------------------------------------------
  // Gather Operations (vrgather) - vd[i] = vs2[vs1[i]]
  // vec_a = vs2 (source data), vec_b = vs1 (indices)
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] gather_res_8, gather_res_16, gather_res_32;

  generate
    // SEW=8: 32 elements, index in lower 5 bits (0-31)
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_gather8
      wire [4:0] idx8 = vec_b[i*8 +: 5];  // Index from vec_b (vs1)
      // 32-to-1 mux selecting 8-bit element from vec_a (vs2)
      assign gather_res_8[i*8 +: 8] = vec_a[idx8*8 +: 8];
    end

    // SEW=16: 16 elements, index in lower 4 bits (0-15)
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_gather16
      wire [3:0] idx16 = vec_b[i*16 +: 4];  // Index from vec_b (vs1)
      // 16-to-1 mux selecting 16-bit element from vec_a (vs2)
      assign gather_res_16[i*16 +: 16] = vec_a[idx16*16 +: 16];
    end

    // SEW=32: 8 elements, index in lower 3 bits (0-7)
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_gather32
      wire [2:0] idx32 = vec_b[i*32 +: 3];  // Index from vec_b (vs1)
      // 8-to-1 mux selecting 32-bit element from vec_a (vs2)
      assign gather_res_32[i*32 +: 32] = vec_a[idx32*32 +: 32];
    end
  endgenerate

  wire [DLEN-1:0] gather_res = (sew_i == SEW_8)  ? gather_res_8 :
                               (sew_i == SEW_16) ? gather_res_16 : gather_res_32;

  //--------------------------------------------------------------------------
  // Slide Operations - vslideup/vslidedown
  // scalar_i contains the offset
  // For .vx operations: vec_a = vs2 (source), scalar_i = offset
  // For vslideup:   vd[i] = (i >= offset) ? vs2[i-offset] : old_vd[i]
  // For vslidedown: vd[i] = (i+offset < VLMAX) ? vs2[i+offset] : 0
  //--------------------------------------------------------------------------
  wire [4:0] slide_offset = scalar_i[4:0];  // Limit to 31 for SEW=8

  logic [DLEN-1:0] slideup_res_8, slidedn_res_8;
  logic [DLEN-1:0] slideup_res_16, slidedn_res_16;
  logic [DLEN-1:0] slideup_res_32, slidedn_res_32;

  generate
    // SEW=8: DLEN/8 elements - use vec_a which is vs2 for .vx operations
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_slide8
      // Slideup: element i gets vs2[i-offset] if i >= offset
      wire [5:0] src_up = i - slide_offset;  // May underflow, checked below
      wire up_valid = (i >= slide_offset);
      assign slideup_res_8[i*8 +: 8] = up_valid ? vec_a[src_up[4:0]*8 +: 8] : vs3_i[i*8 +: 8];

      // Slidedown: element i gets vs2[i+offset] if (i+offset) < NUM_ELEM_8
      wire [5:0] src_dn = i + slide_offset;
      wire dn_valid = (src_dn < NUM_ELEM_8);
      assign slidedn_res_8[i*8 +: 8] = dn_valid ? vec_a[src_dn[4:0]*8 +: 8] : 8'b0;
    end

    // SEW=16: DLEN/16 elements
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_slide16
      wire [4:0] src_up16 = i - slide_offset[3:0];
      wire up_valid16 = (i >= slide_offset[3:0]);
      assign slideup_res_16[i*16 +: 16] = up_valid16 ? vec_a[src_up16[3:0]*16 +: 16] : vs3_i[i*16 +: 16];

      wire [4:0] src_dn16 = i + slide_offset[3:0];
      wire dn_valid16 = (src_dn16 < NUM_ELEM_16);
      assign slidedn_res_16[i*16 +: 16] = dn_valid16 ? vec_a[src_dn16[3:0]*16 +: 16] : 16'b0;
    end

    // SEW=32: DLEN/32 elements
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_slide32
      wire [3:0] src_up32 = i - slide_offset[2:0];
      wire up_valid32 = (i >= slide_offset[2:0]);
      assign slideup_res_32[i*32 +: 32] = up_valid32 ? vec_a[src_up32[2:0]*32 +: 32] : vs3_i[i*32 +: 32];

      wire [3:0] src_dn32 = i + slide_offset[2:0];
      wire dn_valid32 = (src_dn32 < NUM_ELEM_32);
      assign slidedn_res_32[i*32 +: 32] = dn_valid32 ? vec_a[src_dn32[2:0]*32 +: 32] : 32'b0;
    end
  endgenerate

  wire [DLEN-1:0] slideup_res = (sew_i == SEW_8)  ? slideup_res_8 :
                                (sew_i == SEW_16) ? slideup_res_16 : slideup_res_32;
  wire [DLEN-1:0] slidedn_res = (sew_i == SEW_8)  ? slidedn_res_8 :
                                (sew_i == SEW_16) ? slidedn_res_16 : slidedn_res_32;

  //--------------------------------------------------------------------------
  // v0.15: Slide1 Operations - vslide1up/vslide1down
  // vslide1up.vx:   vd[0] = rs1, vd[i] = vs2[i-1] for i > 0
  // vslide1down.vx: vd[VLMAX-1] = rs1, vd[i] = vs2[i+1] for i < VLMAX-1
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] slide1up_res_8, slide1dn_res_8;
  logic [DLEN-1:0] slide1up_res_16, slide1dn_res_16;
  logic [DLEN-1:0] slide1up_res_32, slide1dn_res_32;

  generate
    // SEW=8
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_slide1_8
      // Slide1up: element 0 = scalar, others shift up from vs2
      assign slide1up_res_8[i*8 +: 8] = (i == 0) ? scalar_i[7:0] : vec_a[(i-1)*8 +: 8];
      // Slide1down: last element = scalar, others shift down from vs2
      assign slide1dn_res_8[i*8 +: 8] = (i == DLEN/8-1) ? scalar_i[7:0] : vec_a[(i+1)*8 +: 8];
    end

    // SEW=16
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_slide1_16
      assign slide1up_res_16[i*16 +: 16] = (i == 0) ? scalar_i[15:0] : vec_a[(i-1)*16 +: 16];
      assign slide1dn_res_16[i*16 +: 16] = (i == DLEN/16-1) ? scalar_i[15:0] : vec_a[(i+1)*16 +: 16];
    end

    // SEW=32
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_slide1_32
      assign slide1up_res_32[i*32 +: 32] = (i == 0) ? scalar_i[31:0] : vec_a[(i-1)*32 +: 32];
      assign slide1dn_res_32[i*32 +: 32] = (i == DLEN/32-1) ? scalar_i[31:0] : vec_a[(i+1)*32 +: 32];
    end
  endgenerate

  wire [DLEN-1:0] slide1up_res = (sew_i == SEW_8)  ? slide1up_res_8 :
                                 (sew_i == SEW_16) ? slide1up_res_16 : slide1up_res_32;
  wire [DLEN-1:0] slide1dn_res = (sew_i == SEW_8)  ? slide1dn_res_8 :
                                 (sew_i == SEW_16) ? slide1dn_res_16 : slide1dn_res_32;

  //--------------------------------------------------------------------------
  // v0.15: vmerge - select vs2 or vs1/scalar based on mask
  // vmerge.vvm: vd[i] = v0[i] ? vs1[i] : vs2[i]
  // vmerge.vxm: vd[i] = v0[i] ? scalar : vs2[i]
  // vmerge.vim: vd[i] = v0[i] ? imm : vs2[i]
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] merge_res_8, merge_res_16, merge_res_32;

  generate
    // SEW=8
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_merge8
      assign merge_res_8[i*8 +: 8] = vmask_i[i] ? vec_b[i*8 +: 8] : vec_a[i*8 +: 8];
    end
    // SEW=16
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_merge16
      assign merge_res_16[i*16 +: 16] = vmask_i[i] ? vec_b[i*16 +: 16] : vec_a[i*16 +: 16];
    end
    // SEW=32
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_merge32
      assign merge_res_32[i*32 +: 32] = vmask_i[i] ? vec_b[i*32 +: 32] : vec_a[i*32 +: 32];
    end
  endgenerate

  wire [DLEN-1:0] merge_res = (sew_i == SEW_8)  ? merge_res_8 :
                              (sew_i == SEW_16) ? merge_res_16 : merge_res_32;

  //--------------------------------------------------------------------------
  // v0.15: vcpop.m - population count of mask bits
  // Result is scalar in rd (written to vd[0])
  //--------------------------------------------------------------------------
  logic [5:0] vcpop_count;
  always_comb begin
    vcpop_count = '0;
    for (int i = 0; i < DLEN; i++) begin
      vcpop_count = vcpop_count + {5'b0, vs2_i[i]};
    end
  end
  wire [DLEN-1:0] vcpop_res = {{(DLEN-32){1'b0}}, {26'b0, vcpop_count}};

  //--------------------------------------------------------------------------
  // v0.15: vfirst.m - find first set bit in mask
  // Result is index of first set bit, or -1 if none set
  //--------------------------------------------------------------------------
  logic signed [31:0] vfirst_idx;
  always_comb begin
    vfirst_idx = -1;  // Default: no bit set
    for (int i = DLEN-1; i >= 0; i--) begin
      if (vs2_i[i]) vfirst_idx = i;
    end
  end
  wire [DLEN-1:0] vfirst_res = {{(DLEN-32){vfirst_idx[31]}}, vfirst_idx};

  //--------------------------------------------------------------------------
  // v0.15: vmsbf.m - set-before-first mask
  // vd[i] = 1 for all i before the first set bit in vs2, 0 otherwise
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] vmsbf_res;
  always_comb begin
    vmsbf_res = '0;
    for (int i = 0; i < DLEN; i++) begin
      if (i == 0) begin
        vmsbf_res[0] = ~vs2_i[0];
      end else begin
        // Set bit i if all previous bits in vs2 were 0
        vmsbf_res[i] = vmsbf_res[i-1] & ~vs2_i[i];
      end
    end
  end

  //--------------------------------------------------------------------------
  // v0.15: vmsif.m - set-including-first mask
  // vd[i] = 1 for all i before AND including the first set bit in vs2
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] vmsif_res;
  always_comb begin
    vmsif_res = '0;
    for (int i = 0; i < DLEN; i++) begin
      if (i == 0) begin
        vmsif_res[0] = 1'b1;
      end else begin
        // Set bit i if no previous bits in vs2 were set, OR if bit i-1 was first
        vmsif_res[i] = vmsif_res[i-1] & ~vs2_i[i-1];
      end
    end
  end

  //--------------------------------------------------------------------------
  // v0.15: vmsof.m - set-only-first mask
  // vd[i] = 1 only for the first set bit in vs2, 0 otherwise
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] vmsof_res;
  always_comb begin
    vmsof_res = '0;
    for (int i = 0; i < DLEN; i++) begin
      if (i == 0) begin
        vmsof_res[0] = vs2_i[0];
      end else begin
        // Set bit i if it's set in vs2 and all previous bits (0..i-1) were 0
        // vmsbf_res[i-1] = 1 means bits 0..i-1 are all 0 in vs2
        vmsof_res[i] = vs2_i[i] & vmsbf_res[i-1];
      end
    end
  end

  //--------------------------------------------------------------------------
  // v0.5a: viota.m - inclusive prefix sum of mask bits
  // vd[i] = popcount(vs2[i-1:0]) — element i holds number of 1s before it
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] viota_res_8, viota_res_16, viota_res_32;
  always_comb begin
    viota_res_8  = '0;
    viota_res_16 = '0;
    viota_res_32 = '0;
    begin : viota_block
      // Prefix counts (one more than max elements needed)
      logic [7:0] psum8  [NUM_ELEM_8+1];
      logic [15:0] psum16 [NUM_ELEM_16+1];
      logic [31:0] psum32 [NUM_ELEM_32+1];
      psum8[0]  = 8'd0;
      psum16[0] = 16'd0;
      psum32[0] = 32'd0;
      for (int i = 0; i < NUM_ELEM_8; i++) begin
        viota_res_8[i*8 +: 8] = psum8[i];
        psum8[i+1] = psum8[i] + {7'b0, vs2_i[i]};
      end
      for (int i = 0; i < NUM_ELEM_16; i++) begin
        viota_res_16[i*16 +: 16] = psum16[i];
        psum16[i+1] = psum16[i] + {15'b0, vs2_i[i]};
      end
      for (int i = 0; i < NUM_ELEM_32; i++) begin
        viota_res_32[i*32 +: 32] = psum32[i];
        psum32[i+1] = psum32[i] + {31'b0, vs2_i[i]};
      end
    end
  end
  wire [DLEN-1:0] viota_res = (sew_i == SEW_8)  ? viota_res_8 :
                               (sew_i == SEW_16) ? viota_res_16 : viota_res_32;

  //--------------------------------------------------------------------------
  // v0.5a: vcompress.vm - compress active elements
  // Active elements from vs2 (where vs1 mask bit is 1) packed into vd[0..n-1]
  // Remaining elements retain old_vd (vs3_i)
  // Uses viota prefix sums to determine output position for each source element
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] compress_res_8, compress_res_16, compress_res_32;
  always_comb begin
    // Start with old_vd for tail elements
    compress_res_8  = vs3_i;
    compress_res_16 = vs3_i;
    compress_res_32 = vs3_i;
    begin : compress_block
      // Use viota prefix sums: psum[i] = output position for source element i
      logic [7:0] cpsum8  [NUM_ELEM_8+1];
      logic [15:0] cpsum16 [NUM_ELEM_16+1];
      logic [31:0] cpsum32 [NUM_ELEM_32+1];
      cpsum8[0]  = 8'd0;
      cpsum16[0] = 16'd0;
      cpsum32[0] = 32'd0;
      for (int i = 0; i < NUM_ELEM_8; i++)
        cpsum8[i+1] = cpsum8[i] + {7'b0, vs1_i[i]};
      for (int i = 0; i < NUM_ELEM_16; i++)
        cpsum16[i+1] = cpsum16[i] + {15'b0, vs1_i[i]};
      for (int i = 0; i < NUM_ELEM_32; i++)
        cpsum32[i+1] = cpsum32[i] + {31'b0, vs1_i[i]};
      // For each output position j, find the source element that maps to it
      // SEW=8
      for (int j = 0; j < NUM_ELEM_8; j++) begin
        for (int i = 0; i < NUM_ELEM_8; i++) begin
          if (vs1_i[i] && (cpsum8[i] == j[7:0]))
            compress_res_8[j*8 +: 8] = vec_a[i*8 +: 8];
        end
      end
      // SEW=16
      for (int j = 0; j < NUM_ELEM_16; j++) begin
        for (int i = 0; i < NUM_ELEM_16; i++) begin
          if (vs1_i[i] && (cpsum16[i] == j[15:0]))
            compress_res_16[j*16 +: 16] = vec_a[i*16 +: 16];
        end
      end
      // SEW=32
      for (int j = 0; j < NUM_ELEM_32; j++) begin
        for (int i = 0; i < NUM_ELEM_32; i++) begin
          if (vs1_i[i] && (cpsum32[i] == j[31:0]))
            compress_res_32[j*32 +: 32] = vec_a[i*32 +: 32];
        end
      end
    end
  end
  wire [DLEN-1:0] compress_res = (sew_i == SEW_8)  ? compress_res_8 :
                                  (sew_i == SEW_16) ? compress_res_16 : compress_res_32;

  //--------------------------------------------------------------------------
  // v0.15: vrgatherei16.vv - gather with 16-bit indices
  // vd[i] = vs2[vs1[i]], where vs1 contains 16-bit indices regardless of SEW
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] gatherei16_res_8, gatherei16_res_16, gatherei16_res_32;

  generate
    // SEW=8: each 8-bit result indexed by corresponding 16-bit index
    // For DLEN=64: 8 elements, but only 4 16-bit indices
    // This is a simplified implementation that uses lower indices
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_gatherei16_8
      wire [15:0] idx16 = vec_b[i*16 +: 16];  // 16-bit index from vs1
      wire [4:0] idx8 = idx16[4:0];  // Clamp to element range
      wire idx_valid = (idx16 < DLEN/8);
      // Each 16-bit index provides two 8-bit elements (at 2*i and 2*i+1)
      assign gatherei16_res_8[i*16 +: 8] = idx_valid ? vec_a[idx8*8 +: 8] : 8'b0;
      assign gatherei16_res_8[i*16+8 +: 8] = idx_valid ? vec_a[idx8*8 +: 8] : 8'b0;
    end

    // SEW=16: direct mapping - 16-bit index per 16-bit element
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_gatherei16_16
      wire [15:0] idx16 = vec_b[i*16 +: 16];
      wire [3:0] idx = idx16[3:0];
      wire idx_valid = (idx16 < DLEN/16);
      assign gatherei16_res_16[i*16 +: 16] = idx_valid ? vec_a[idx*16 +: 16] : 16'b0;
    end

    // SEW=32: two 16-bit indices per 32-bit element
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_gatherei16_32
      wire [15:0] idx16 = vec_b[i*16 +: 16];  // Use 16-bit index
      wire [2:0] idx = idx16[2:0];
      wire idx_valid = (idx16 < DLEN/32);
      assign gatherei16_res_32[i*32 +: 32] = idx_valid ? vec_a[idx*32 +: 32] : 32'b0;
    end
  endgenerate

  wire [DLEN-1:0] gatherei16_res = (sew_i == SEW_8)  ? gatherei16_res_8 :
                                   (sew_i == SEW_16) ? gatherei16_res_16 : gatherei16_res_32;

  //--------------------------------------------------------------------------

  //--------------------------------------------------------------------------
  // Mask-Register Logical Operations
  // These operate on the full vector as masks (bit-by-bit on vs2 and vs1)
  // v0.3c: Mask valid bits based on SEW (VLEN/SEW elements = VLEN/SEW mask bits)
  // For VLEN=64: SEW8=8 bits, SEW16=4 bits, SEW32=2 bits
  //--------------------------------------------------------------------------
  // v0.5c: Mask valid bits based on SEW - parameterized for any DLEN
  wire [DLEN-1:0] mask_valid = (sew_i == SEW_8)  ? {{(DLEN-NUM_ELEM_8){1'b0}},  {NUM_ELEM_8{1'b1}}} :
                               (sew_i == SEW_16) ? {{(DLEN-NUM_ELEM_16){1'b0}}, {NUM_ELEM_16{1'b1}}} :
                                                   {{(DLEN-NUM_ELEM_32){1'b0}}, {NUM_ELEM_32{1'b1}}};

  wire [DLEN-1:0] mask_and   = vs2_i & vs1_i;
  wire [DLEN-1:0] mask_nand  = (~(vs2_i & vs1_i)) & mask_valid;  // Mask upper bits
  wire [DLEN-1:0] mask_andn  = vs2_i & ~vs1_i;
  wire [DLEN-1:0] mask_or    = vs2_i | vs1_i;
  wire [DLEN-1:0] mask_nor   = (~(vs2_i | vs1_i)) & mask_valid;  // Mask upper bits
  wire [DLEN-1:0] mask_orn   = (vs2_i | ~vs1_i) & mask_valid;    // Mask upper bits
  wire [DLEN-1:0] mask_xor   = vs2_i ^ vs1_i;
  wire [DLEN-1:0] mask_xnor  = (~(vs2_i ^ vs1_i)) & mask_valid;  // Mask upper bits

  //--------------------------------------------------------------------------
  // Fixed-Point Saturating Add/Sub Operations
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] sat_addu_8, sat_add_8, sat_subu_8, sat_sub_8;
  logic [DLEN-1:0] sat_addu_16, sat_add_16, sat_subu_16, sat_sub_16;
  logic [DLEN-1:0] sat_addu_32, sat_add_32, sat_subu_32, sat_sub_32;

  // SEW=8 saturating operations
  generate
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_sat8
      wire [7:0] a8 = vec_a[i*8 +: 8];
      wire [7:0] b8 = vec_b[i*8 +: 8];
      wire signed [7:0] a8_s = a8;
      wire signed [7:0] b8_s = b8;
      wire [8:0] sum_u8 = {1'b0, a8} + {1'b0, b8};
      wire signed [8:0] sum_s8 = {a8_s[7], a8_s} + {b8_s[7], b8_s};
      wire [8:0] diff_u8 = {1'b0, a8} - {1'b0, b8};
      wire signed [8:0] diff_s8 = {a8_s[7], a8_s} - {b8_s[7], b8_s};

      // Unsigned saturating add: clamp to 255
      assign sat_addu_8[i*8 +: 8] = sum_u8[8] ? 8'hFF : sum_u8[7:0];
      // Signed saturating add: clamp to [-128, 127]
      assign sat_add_8[i*8 +: 8] = (sum_s8[8] != sum_s8[7]) ?
                                    (sum_s8[8] ? 8'h80 : 8'h7F) : sum_s8[7:0];
      // Unsigned saturating sub: clamp to 0
      assign sat_subu_8[i*8 +: 8] = diff_u8[8] ? 8'h00 : diff_u8[7:0];
      // Signed saturating sub: clamp to [-128, 127]
      assign sat_sub_8[i*8 +: 8] = (diff_s8[8] != diff_s8[7]) ?
                                    (diff_s8[8] ? 8'h80 : 8'h7F) : diff_s8[7:0];
    end
  endgenerate

  // SEW=16 saturating operations
  generate
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_sat16
      wire [15:0] a16 = vec_a[i*16 +: 16];
      wire [15:0] b16 = vec_b[i*16 +: 16];
      wire signed [15:0] a16_s = a16;
      wire signed [15:0] b16_s = b16;
      wire [16:0] sum_u16 = {1'b0, a16} + {1'b0, b16};
      wire signed [16:0] sum_s16 = {a16_s[15], a16_s} + {b16_s[15], b16_s};
      wire [16:0] diff_u16 = {1'b0, a16} - {1'b0, b16};
      wire signed [16:0] diff_s16 = {a16_s[15], a16_s} - {b16_s[15], b16_s};

      assign sat_addu_16[i*16 +: 16] = sum_u16[16] ? 16'hFFFF : sum_u16[15:0];
      assign sat_add_16[i*16 +: 16] = (sum_s16[16] != sum_s16[15]) ?
                                       (sum_s16[16] ? 16'h8000 : 16'h7FFF) : sum_s16[15:0];
      assign sat_subu_16[i*16 +: 16] = diff_u16[16] ? 16'h0000 : diff_u16[15:0];
      assign sat_sub_16[i*16 +: 16] = (diff_s16[16] != diff_s16[15]) ?
                                       (diff_s16[16] ? 16'h8000 : 16'h7FFF) : diff_s16[15:0];
    end
  endgenerate

  // SEW=32 saturating operations
  generate
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_sat32
      wire [31:0] a32 = vec_a[i*32 +: 32];
      wire [31:0] b32 = vec_b[i*32 +: 32];
      wire signed [31:0] a32_s = a32;
      wire signed [31:0] b32_s = b32;
      wire [32:0] sum_u32 = {1'b0, a32} + {1'b0, b32};
      wire signed [32:0] sum_s32 = {a32_s[31], a32_s} + {b32_s[31], b32_s};
      wire [32:0] diff_u32 = {1'b0, a32} - {1'b0, b32};
      wire signed [32:0] diff_s32 = {a32_s[31], a32_s} - {b32_s[31], b32_s};

      assign sat_addu_32[i*32 +: 32] = sum_u32[32] ? 32'hFFFFFFFF : sum_u32[31:0];
      assign sat_add_32[i*32 +: 32] = (sum_s32[32] != sum_s32[31]) ?
                                       (sum_s32[32] ? 32'h80000000 : 32'h7FFFFFFF) : sum_s32[31:0];
      assign sat_subu_32[i*32 +: 32] = diff_u32[32] ? 32'h00000000 : diff_u32[31:0];
      assign sat_sub_32[i*32 +: 32] = (diff_s32[32] != diff_s32[31]) ?
                                       (diff_s32[32] ? 32'h80000000 : 32'h7FFFFFFF) : diff_s32[31:0];
    end
  endgenerate

  wire [DLEN-1:0] sat_addu = (sew_i == SEW_8) ? sat_addu_8 : (sew_i == SEW_16) ? sat_addu_16 : sat_addu_32;
  wire [DLEN-1:0] sat_add  = (sew_i == SEW_8) ? sat_add_8  : (sew_i == SEW_16) ? sat_add_16  : sat_add_32;
  wire [DLEN-1:0] sat_subu = (sew_i == SEW_8) ? sat_subu_8 : (sew_i == SEW_16) ? sat_subu_16 : sat_subu_32;
  wire [DLEN-1:0] sat_sub  = (sew_i == SEW_8) ? sat_sub_8  : (sew_i == SEW_16) ? sat_sub_16  : sat_sub_32;

  //--------------------------------------------------------------------------
  // Fixed-Point Scaling Shift Operations (with rounding)
  // vssrl: (a + round) >> b, round = 1 << (b-1) if b > 0
  // vssra: same but arithmetic (preserves sign)
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] sshift_srl_8, sshift_sra_8;
  logic [DLEN-1:0] sshift_srl_16, sshift_sra_16;
  logic [DLEN-1:0] sshift_srl_32, sshift_sra_32;

  // SEW=8 scaling shifts
  generate
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_sshift8
      wire [7:0] data8 = vec_a[i*8 +: 8];
      wire [2:0] shamt8 = vec_b[i*8 +: 3];
      wire signed [7:0] data8_s = data8;
      // Rounding: add 1 << (shamt-1) before shifting, but only if shamt > 0
      wire [7:0] round8 = (shamt8 > 0) ? (8'b1 << (shamt8 - 1)) : 8'b0;
      wire [8:0] rounded8 = {1'b0, data8} + {1'b0, round8};
      wire signed [8:0] rounded8_s = {data8_s[7], data8_s} + {1'b0, round8};
      // v0.3c: Shift full 9-bit value, then take lower 8 bits
      assign sshift_srl_8[i*8 +: 8] = (rounded8 >> shamt8);
      // For arithmetic shift, use $signed to preserve sign bit during shift
      assign sshift_sra_8[i*8 +: 8] = ($signed(rounded8_s) >>> shamt8);
    end
  endgenerate

  // SEW=16 scaling shifts
  generate
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_sshift16
      wire [15:0] data16 = vec_a[i*16 +: 16];
      wire [3:0] shamt16 = vec_b[i*16 +: 4];
      wire signed [15:0] data16_s = data16;
      wire [15:0] round16 = (shamt16 > 0) ? (16'b1 << (shamt16 - 1)) : 16'b0;
      wire [16:0] rounded16 = {1'b0, data16} + {1'b0, round16};
      wire signed [16:0] rounded16_s = {data16_s[15], data16_s} + {1'b0, round16};
      // v0.3c: Shift full 17-bit value, then take lower 16 bits
      assign sshift_srl_16[i*16 +: 16] = (rounded16 >> shamt16);
      assign sshift_sra_16[i*16 +: 16] = ($signed(rounded16_s) >>> shamt16);
    end
  endgenerate

  // SEW=32 scaling shifts
  generate
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_sshift32
      wire [31:0] data32 = vec_a[i*32 +: 32];
      wire [4:0] shamt32 = vec_b[i*32 +: 5];
      wire signed [31:0] data32_s = data32;
      wire [31:0] round32 = (shamt32 > 0) ? (32'b1 << (shamt32 - 1)) : 32'b0;
      wire [32:0] rounded32 = {1'b0, data32} + {1'b0, round32};
      wire signed [32:0] rounded32_s = {data32_s[31], data32_s} + {1'b0, round32};
      // v0.3c: Shift full 33-bit value, then take lower 32 bits
      assign sshift_srl_32[i*32 +: 32] = (rounded32 >> shamt32);
      assign sshift_sra_32[i*32 +: 32] = ($signed(rounded32_s) >>> shamt32);
    end
  endgenerate

  wire [DLEN-1:0] sshift_srl = (sew_i == SEW_8) ? sshift_srl_8 : (sew_i == SEW_16) ? sshift_srl_16 : sshift_srl_32;
  wire [DLEN-1:0] sshift_sra = (sew_i == SEW_8) ? sshift_sra_8 : (sew_i == SEW_16) ? sshift_sra_16 : sshift_sra_32;

  //--------------------------------------------------------------------------
  // Narrowing Clip Operations (2*SEW -> SEW with saturation)
  // vnclipu: clip to [0, MAX_UNSIGNED]
  // vnclip: clip to [MIN_SIGNED, MAX_SIGNED]
  // Source is interpreted as 2*SEW elements, result is SEW elements
  //--------------------------------------------------------------------------
  // For SEW=8: source is 16-bit (16 elements), result is 8-bit (32 elements in lower half)
  // For SEW=16: source is 32-bit (8 elements), result is 16-bit (16 elements in lower half)
  // For SEW=32: source is 64-bit (4 elements), result is 32-bit (8 elements in lower half)
  // Parameterized for any DLEN

  logic [DLEN-1:0] nclip_u8, nclip_s8;   // Result for SEW=8 target (from 16-bit source)
  logic [DLEN-1:0] nclip_u16, nclip_s16; // Result for SEW=16 target (from 32-bit source)
  logic [DLEN-1:0] nclip_u32, nclip_s32; // Result for SEW=32 target (from 64-bit source)

  // Number of elements based on DLEN and SOURCE element width
  // Narrowing reads from 2*SEW source, writes to SEW result
  localparam NCLIP8_ELEMS  = DLEN / 16;  // 8-bit results from 16-bit source
  localparam NCLIP16_ELEMS = DLEN / 32;  // 16-bit results from 32-bit source
  localparam NCLIP32_ELEMS = DLEN / 64;  // 32-bit results from 64-bit source

  // Narrowing to SEW=8 from 16-bit source (shift amount from vec_b)
  generate
    for (genvar i = 0; i < NCLIP8_ELEMS; i++) begin : gen_nclip8
      wire [15:0] src16 = vec_a[i*16 +: 16];
      wire signed [15:0] src16_s = src16;
      wire [3:0] shamt = vec_b[i*16 +: 4];
      wire [15:0] shifted_u = src16 >> shamt;
      wire signed [15:0] shifted_s = src16_s >>> shamt;
      assign nclip_u8[i*8 +: 8] = (shifted_u > 16'd255) ? 8'hFF : shifted_u[7:0];
      assign nclip_s8[i*8 +: 8] = (shifted_s > 16'sd127) ? 8'h7F :
                                   (shifted_s < -16'sd128) ? 8'h80 : shifted_s[7:0];
    end
    // Upper half zeroing only needed when DLEN > result width
    if (DLEN > NCLIP8_ELEMS * 8) begin : gen_nclip8_upper
      assign nclip_u8[DLEN-1:NCLIP8_ELEMS*8] = '0;
      assign nclip_s8[DLEN-1:NCLIP8_ELEMS*8] = '0;
    end
  endgenerate

  // Narrowing to SEW=16 from 32-bit source
  generate
    for (genvar i = 0; i < NCLIP16_ELEMS; i++) begin : gen_nclip16
      wire [31:0] src32 = vec_a[i*32 +: 32];
      wire signed [31:0] src32_s = src32;
      wire [4:0] shamt = vec_b[i*32 +: 5];
      wire [31:0] shifted_u = src32 >> shamt;
      wire signed [31:0] shifted_s = src32_s >>> shamt;
      assign nclip_u16[i*16 +: 16] = (shifted_u > 32'd65535) ? 16'hFFFF : shifted_u[15:0];
      assign nclip_s16[i*16 +: 16] = (shifted_s > 32'sd32767) ? 16'h7FFF :
                                      (shifted_s < -32'sd32768) ? 16'h8000 : shifted_s[15:0];
    end
    if (DLEN > NCLIP16_ELEMS * 16) begin : gen_nclip16_upper
      assign nclip_u16[DLEN-1:NCLIP16_ELEMS*16] = '0;
      assign nclip_s16[DLEN-1:NCLIP16_ELEMS*16] = '0;
    end
  endgenerate

  // Narrowing to SEW=32 from 64-bit source
  generate
    for (genvar i = 0; i < NCLIP32_ELEMS; i++) begin : gen_nclip32
      wire [63:0] src64 = vec_a[i*64 +: 64];
      wire signed [63:0] src64_s = src64;
      wire [5:0] shamt = vec_b[i*64 +: 6];
      wire [63:0] shifted_u = src64 >> shamt;
      wire signed [63:0] shifted_s = src64_s >>> shamt;
      assign nclip_u32[i*32 +: 32] = (shifted_u > 64'd4294967295) ? 32'hFFFFFFFF : shifted_u[31:0];
      assign nclip_s32[i*32 +: 32] = (shifted_s > 64'sd2147483647) ? 32'h7FFFFFFF :
                                      (shifted_s < -64'sd2147483648) ? 32'h80000000 : shifted_s[31:0];
    end
    if (DLEN > NCLIP32_ELEMS * 32) begin : gen_nclip32_upper
      assign nclip_u32[DLEN-1:NCLIP32_ELEMS*32] = '0;
      assign nclip_s32[DLEN-1:NCLIP32_ELEMS*32] = '0;
    end
  endgenerate

  wire [DLEN-1:0] nclip_u = (sew_i == SEW_8) ? nclip_u8 : (sew_i == SEW_16) ? nclip_u16 : nclip_u32;
  wire [DLEN-1:0] nclip_s = (sew_i == SEW_8) ? nclip_s8 : (sew_i == SEW_16) ? nclip_s16 : nclip_s32;

  //--------------------------------------------------------------------------
  // Narrowing Shift Operations (2*SEW -> SEW without saturation) - v0.18
  // vnsrl: shift right logical, then truncate
  // vnsra: shift right arithmetic, then truncate
  // Source (vs2) is interpreted as 2*SEW elements, shift amount (vs1) is SEW elements
  // Result is SEW elements
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] nshift_srl8, nshift_sra8;   // SEW=8 target from 16-bit source
  logic [DLEN-1:0] nshift_srl16, nshift_sra16; // SEW=16 target from 32-bit source

  // Number of elements (same as nclip)
  localparam NSHIFT8_ELEMS  = DLEN / 16;  // 8-bit results from 16-bit source
  localparam NSHIFT16_ELEMS = DLEN / 32;  // 16-bit results from 32-bit source

  // Narrowing shift to SEW=8 from 16-bit source
  // vs1 has 8-bit shift amount elements (SEW width)
  generate
    for (genvar i = 0; i < NSHIFT8_ELEMS; i++) begin : gen_nshift8
      wire [15:0] src16 = vec_a[i*16 +: 16];
      wire signed [15:0] src16_s = src16;
      // Read full 8-bit shift amount, use lower 4 bits (max shift = 15 for 16-bit)
      wire [7:0] shamt_byte = vec_b[i*8 +: 8];
      wire [3:0] shamt = shamt_byte[3:0];
      wire [15:0] shifted_u = src16 >> shamt;
      wire signed [15:0] shifted_s = src16_s >>> shamt;
      assign nshift_srl8[i*8 +: 8] = shifted_u[7:0];  // Just truncate, no saturation
      assign nshift_sra8[i*8 +: 8] = shifted_s[7:0];
    end
    if (DLEN > NSHIFT8_ELEMS * 8) begin : gen_nshift8_upper
      assign nshift_srl8[DLEN-1:NSHIFT8_ELEMS*8] = '0;
      assign nshift_sra8[DLEN-1:NSHIFT8_ELEMS*8] = '0;
    end
  endgenerate

  // Narrowing shift to SEW=16 from 32-bit source
  // vs1 has 16-bit shift amount elements (SEW width)
  generate
    for (genvar i = 0; i < NSHIFT16_ELEMS; i++) begin : gen_nshift16
      wire [31:0] src32 = vec_a[i*32 +: 32];
      wire signed [31:0] src32_s = src32;
      // Read full 16-bit shift amount, use lower 5 bits (max shift = 31 for 32-bit)
      wire [15:0] shamt_word = vec_b[i*16 +: 16];
      wire [4:0] shamt = shamt_word[4:0];
      wire [31:0] shifted_u = src32 >> shamt;
      wire signed [31:0] shifted_s = src32_s >>> shamt;
      assign nshift_srl16[i*16 +: 16] = shifted_u[15:0];  // Just truncate
      assign nshift_sra16[i*16 +: 16] = shifted_s[15:0];
    end
    if (DLEN > NSHIFT16_ELEMS * 16) begin : gen_nshift16_upper
      assign nshift_srl16[DLEN-1:NSHIFT16_ELEMS*16] = '0;
      assign nshift_sra16[DLEN-1:NSHIFT16_ELEMS*16] = '0;
    end
  endgenerate

  wire [DLEN-1:0] nshift_srl = (sew_i == SEW_8) ? nshift_srl8 : nshift_srl16;
  wire [DLEN-1:0] nshift_sra = (sew_i == SEW_8) ? nshift_sra8 : nshift_sra16;

  //--------------------------------------------------------------------------
  // E1 Stage Registers
  //--------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      e1_valid     <= 1'b0;
      e1_op        <= OP_NOP;
      e1_a         <= '0;
      e1_b         <= '0;
      e1_c         <= '0;
      e1_old_vd    <= '0;
      e1_vmask     <= '0;
      e1_vm        <= 1'b1;
      e1_logic_res <= '0;
      e1_shift_res <= '0;
      e1_minmax_res <= '0;
      e1_cmp_mask  <= '0;
      e1_sew       <= SEW_8;
      e1_vd        <= '0;
      e1_id        <= '0;
      e1_is_last_uop <= 1'b1;  // v1.2a: Default to last (single µop)
      e1_gather_res <= '0;
      e1_slideup_res <= '0;
      e1_slidedn_res <= '0;
      e1_slide1up_res <= '0;
      e1_slide1dn_res <= '0;
      e1_merge_res <= '0;
      e1_redsum    <= '0;
      e1_redmax    <= '0;
      e1_redmin    <= '0;
      e1_redmaxu   <= '0;
      e1_redminu   <= '0;
      e1_redand    <= '0;
      e1_redor     <= '0;
      e1_redxor    <= '0;
      e1_mask_res  <= '0;
      e1_sat_res   <= '0;
      e1_sshift_res <= '0;
      e1_nclip_res <= '0;
      e1_nshift_res <= '0;
      e1_lut_res   <= '0;
      e1_int4_res  <= '0;
      e1_viota_res <= '0;
      e1_compress_res <= '0;
      e1_vcpop_res <= '0;
      e1_vfirst_res <= '0;
      e1_vmsbf_res <= '0;
      e1_vmsif_res <= '0;
      e1_vmsof_res <= '0;
      e1_gatherei16_res <= '0;
    end else if (!stall_i && !mac_stall && !mul_stall) begin
      // Non-reduction and non-widening instructions go through normal E1→E1m→E2→E3 path
      // Reductions go through separate R1→R2→R3 pipelined tree
      // Widening goes through separate W1→W2 pipeline (v0.17)
      // v1.5: Also stall when MAC op in E2 needs extra cycle for add
      // v1.7: Also stall when E1m is occupied (mul_stall)
      e1_valid  <= valid_i && !is_reduction_op && !is_widening_op;
      e1_op     <= op_i;
      e1_a      <= vec_a;
      e1_b      <= vec_b;
      e1_c      <= vs3_i;
      e1_old_vd <= vs3_i;  // vs3 contains old_vd for masking
      e1_vmask  <= vmask_i[31:0];  // Lower 32 bits of v0 for SEW=8
      e1_vm     <= vm_i;
      e1_sew    <= sew_i;
      e1_vd     <= vd_i;
      e1_id     <= id_i;
      e1_is_last_uop <= is_last_uop_i;  // v1.2a: Track through pipeline

      // DEBUG: trace vd==7 or vd==8 with source operands
      `ifdef SIMULATION
      if (valid_i && !is_reduction_op && !is_widening_op && (vd_i == 7 || vd_i == 8)) begin
        $display("[%0t] E1_CAPTURE: vd=%0d id=%0d op=%0d is_mul=%b",
                 $time, vd_i, id_i, op_i, is_mul_op);
        $display("         vs2(a)[31:0]=%08h vs1(b)[31:0]=%08h vs3(c)[31:0]=%08h",
                 vec_a[31:0], vec_b[31:0], vs3_i[31:0]);
        $display("         e1m_valid=%b mul_stall=%b mac_stall=%b",
                 e1m_valid, mul_stall, mac_stall);
      end
      // DEBUG: Trace specific IDs we're looking for (32 and 92)
      if (valid_i && !is_reduction_op && !is_widening_op && (id_i == 32 || id_i == 92)) begin
        $display("[%0t] E1_CAPTURE_ID_TRACE: vd=%0d id=%0d op=%0d is_mul=%b",
                 $time, vd_i, id_i, op_i, is_mul_op);
      end
      `endif

      // Logic operations
      case (op_i)
        OP_VAND: e1_logic_res <= logic_and;
        OP_VOR:  e1_logic_res <= logic_or;
        OP_VXOR: e1_logic_res <= logic_xor;
        default: e1_logic_res <= '0;
      endcase

      // Shift operations
      case (op_i)
        OP_VSLL: e1_shift_res <= shift_sll;
        OP_VSRL: e1_shift_res <= shift_srl;
        OP_VSRA: e1_shift_res <= shift_sra;
        default: e1_shift_res <= '0;
      endcase

      // Min/Max operations
      case (op_i)
        OP_VMIN:  e1_minmax_res <= minmax_min;
        OP_VMINU: e1_minmax_res <= minmax_minu;
        OP_VMAX:  e1_minmax_res <= minmax_max;
        OP_VMAXU: e1_minmax_res <= minmax_maxu;
        default:  e1_minmax_res <= '0;
      endcase

      // Gather operation
      e1_gather_res <= gather_res;

      // Slide operations
      e1_slideup_res <= slideup_res;
      e1_slidedn_res <= slidedn_res;

      // v0.15: Slide1 operations (also captured at OF->E1 with correct scalar)
      e1_slide1up_res <= slide1up_res;
      e1_slide1dn_res <= slide1dn_res;

      // v0.15: Merge operation (captured at OF->E1 with correct operands)
      e1_merge_res <= merge_res;

      // Reduction operations now use separate R1/R2/R3 pipeline (v0.13.2)
      // These E1 registers are unused but kept for interface compatibility
      e1_redsum  <= '0;
      e1_redmax  <= '0;
      e1_redmin  <= '0;
      e1_redmaxu <= '0;
      e1_redminu <= '0;
      e1_redand  <= '0;
      e1_redor   <= '0;
      e1_redxor  <= '0;

      // Mask-register logical operations
      case (op_i)
        OP_VMAND_MM:  e1_mask_res <= mask_and;
        OP_VMNAND_MM: e1_mask_res <= mask_nand;
        OP_VMANDN_MM: e1_mask_res <= mask_andn;
        OP_VMOR_MM:   e1_mask_res <= mask_or;
        OP_VMNOR_MM:  e1_mask_res <= mask_nor;
        OP_VMORN_MM:  e1_mask_res <= mask_orn;
        OP_VMXOR_MM:  e1_mask_res <= mask_xor;
        OP_VMXNOR_MM: e1_mask_res <= mask_xnor;
        default:      e1_mask_res <= '0;
      endcase

      // Comparison operations (store mask result)
      case (op_i)
        OP_VMSEQ:  e1_cmp_mask <= cmp_eq;
        OP_VMSNE:  e1_cmp_mask <= cmp_ne;
        OP_VMSLT:  e1_cmp_mask <= cmp_lt;
        OP_VMSLTU: e1_cmp_mask <= cmp_ltu;
        OP_VMSLE:  e1_cmp_mask <= cmp_le;
        OP_VMSLEU: e1_cmp_mask <= cmp_leu;
        OP_VMSGT:  e1_cmp_mask <= cmp_gt;
        OP_VMSGTU: e1_cmp_mask <= cmp_gtu;
        default:   e1_cmp_mask <= '0;
      endcase

      // Fixed-point saturating operations
      case (op_i)
        OP_VSADDU: e1_sat_res <= sat_addu;
        OP_VSADD:  e1_sat_res <= sat_add;
        OP_VSSUBU: e1_sat_res <= sat_subu;
        OP_VSSUB:  e1_sat_res <= sat_sub;
        default:   e1_sat_res <= '0;
      endcase

      // Fixed-point scaling shift operations
      case (op_i)
        OP_VSSRL: e1_sshift_res <= sshift_srl;
        OP_VSSRA: e1_sshift_res <= sshift_sra;
        default:  e1_sshift_res <= '0;
      endcase

      // Narrowing clip operations
      case (op_i)
        OP_VNCLIPU: e1_nclip_res <= nclip_u;
        OP_VNCLIP:  e1_nclip_res <= nclip_s;
        default:    e1_nclip_res <= '0;
      endcase

      // Narrowing shift operations (v0.18)
      case (op_i)
        OP_VNSRL: e1_nshift_res <= nshift_srl;
        OP_VNSRA: e1_nshift_res <= nshift_sra;
        default:  e1_nshift_res <= '0;
      endcase

      // LUT operations (v0.19)
      if (is_lut_op)
        e1_lut_res <= lut_result;
      else
        e1_lut_res <= '0;

      // INT4 pack/unpack operations (v1.1)
      if (is_pack_op)
        e1_int4_res <= int4_result;
      else
        e1_int4_res <= '0;

      // v0.5a: Pipeline-register combinational results that depend on OF-stage inputs
      e1_viota_res <= viota_res;
      e1_compress_res <= compress_res;
      e1_vcpop_res <= vcpop_res;
      e1_vfirst_res <= vfirst_res;
      e1_vmsbf_res <= vmsbf_res;
      e1_vmsif_res <= vmsif_res;
      e1_vmsof_res <= vmsof_res;
      e1_gatherei16_res <= gatherei16_res;
    end else if (!stall_i && !mac_stall && is_mul_op_e1 && !e1m_valid) begin
      // v1.7: E1's multiply is being captured by E1m
      // E1 can accept the new instruction if it's NOT a multiply
      // (If it's a multiply, it would need E1m which is about to be occupied)
      if (valid_i && !is_reduction_op && !is_widening_op && !is_mul_op) begin
        // New non-multiply instruction - capture it while clearing old multiply
        e1_valid  <= 1'b1;
        e1_op     <= op_i;
        e1_a      <= vec_a;
        e1_b      <= vec_b;
        e1_c      <= vs3_i;
        e1_old_vd <= vs3_i;
        e1_vmask  <= vmask_i[31:0];
        e1_vm     <= vm_i;
        e1_sew    <= sew_i;
        e1_vd     <= vd_i;
        e1_id     <= id_i;
        e1_is_last_uop <= is_last_uop_i;

        // DEBUG
        `ifdef SIMULATION
        if (vd_i == 7 || vd_i == 8)
          $display("[%0t] E1_CAPTURE_WHILE_HANDOFF: vd=%0d id=%0d op=%0d", $time, vd_i, id_i, op_i);
        if (id_i == 32 || id_i == 92)
          $display("[%0t] E1_CAPTURE_WHILE_HANDOFF_ID: vd=%0d id=%0d op=%0d", $time, vd_i, id_i, op_i);
        `endif

        // Compute logic/shift/etc results for the new instruction
        case (op_i)
          OP_VAND: e1_logic_res <= logic_and;
          OP_VOR:  e1_logic_res <= logic_or;
          OP_VXOR: e1_logic_res <= logic_xor;
          default: e1_logic_res <= '0;
        endcase
        // v0.5a: Capture OF-stage combinational results
        e1_viota_res <= viota_res;
        e1_compress_res <= compress_res;
        e1_vcpop_res <= vcpop_res;
        e1_vfirst_res <= vfirst_res;
        e1_vmsbf_res <= vmsbf_res;
        e1_vmsif_res <= vmsif_res;
        e1_vmsof_res <= vmsof_res;
        e1_gatherei16_res <= gatherei16_res;
      end else begin
        // No new instruction, or new instruction is multiply/reduction/widening - just clear E1
        e1_valid <= 1'b0;

        // DEBUG: trace E1 clearing
        `ifdef SIMULATION
        if (e1_vd == 7 || e1_vd == 8)
          $display("[%0t] E1_CLEAR: vd=%0d op=%0d handed to E1m", $time, e1_vd, e1_op);
        `endif
      end
    end
  end

  //============================================================================
  // E2 Stage: Add/Sub & Multiply (Multi-SEW)
  //============================================================================
  logic        e2_valid;
  vpu_op_e     e2_op;
  logic [DLEN-1:0] e2_logic_res;
  logic [DLEN-1:0] e2_shift_res;
  logic [DLEN-1:0] e2_minmax_res;
  logic [DLEN-1:0] e2_gather_res;  // Gather result
  logic [DLEN-1:0] e2_slideup_res; // Slide up result
  logic [DLEN-1:0] e2_slidedn_res; // Slide down result
  logic [31:0]     e2_redsum;      // Reduction sum
  logic [31:0]     e2_redmax;      // Reduction max
  logic [31:0]     e2_redmin;      // Reduction min
  logic [31:0]     e2_redmaxu;     // Reduction max (unsigned)
  logic [31:0]     e2_redminu;     // Reduction min (unsigned)
  logic [31:0]     e2_redand;      // Reduction AND
  logic [31:0]     e2_redor;       // Reduction OR
  logic [31:0]     e2_redxor;      // Reduction XOR
  logic [DLEN-1:0] e2_mask_res;    // Mask-register logical result
  logic [DLEN-1:0] e2_sat_res;     // Saturating add/sub result
  logic [DLEN-1:0] e2_sshift_res;  // Scaling shift result
  logic [DLEN-1:0] e2_nclip_res;   // Narrowing clip result
  logic [DLEN-1:0] e2_nshift_res;  // Narrowing shift result (v0.18)
  logic [DLEN-1:0] e2_lut_res;     // LUT result (v0.19)
  logic [DLEN-1:0] e2_int4_res;    // INT4 pack/unpack result (v1.1)
  logic [DLEN-1:0] e2_add_res;
  logic [DLEN-1:0] e2_c;
  logic [DLEN-1:0] e2_b;           // vs2 for vmadd/vnmsub addend
  logic [DLEN-1:0] e2_vs1;         // vs1 pass-through for vmv.v.v
  logic [DLEN-1:0] e2_vid_res;     // vid.v result
  // v0.15: New operation results
  logic [DLEN-1:0] e2_slide1up_res;  // vslide1up result
  logic [DLEN-1:0] e2_slide1dn_res;  // vslide1down result
  logic [DLEN-1:0] e2_merge_res;     // vmerge result
  logic [DLEN-1:0] e2_vcpop_res;     // vcpop.m result
  logic [DLEN-1:0] e2_vfirst_res;    // vfirst.m result
  logic [DLEN-1:0] e2_vmsbf_res;     // vmsbf.m result
  logic [DLEN-1:0] e2_vmsif_res;     // vmsif.m result
  logic [DLEN-1:0] e2_vmsof_res;     // vmsof.m result
  logic [DLEN-1:0] e2_viota_res;     // viota.m result
  logic [DLEN-1:0] e2_compress_res;  // vcompress.vm result
  logic [DLEN-1:0] e2_gatherei16_res; // vrgatherei16 result
  logic [DLEN-1:0] e2_old_vd;      // Old destination for masking
  logic [NUM_ELEM_8-1:0] e2_vmask; // Mask bits (1 per element at SEW=8)
  logic            e2_vm;          // vm=1 unmasked, vm=0 masked
  logic [DLEN*2-1:0] e2_mul_partial;   // Signed multiply partials (vs1*vs2)
  logic [DLEN*2-1:0] e2_mulu_partial;  // Unsigned multiply partials
  logic [DLEN*2-1:0] e2_mulsu_partial; // Signed*Unsigned multiply partials (for vmulhsu)
  logic [DLEN*2-1:0] e2_madd_partial;  // Signed multiply partials for vmadd (vs1*old_vd)
  // v1.4: Pre-computed MAC results (registered to break timing path)
  // v1.5: e2m_* are MAC stage registers (add computed in E2, registered for E3)
  logic [DLEN-1:0] e2m_mac_res;      // vmacc result (mul_lo + acc)
  logic [DLEN-1:0] e2m_nmsac_res;    // vnmsac result (acc - mul_lo)
  logic [DLEN-1:0] e2m_madd_res;     // vmadd result (madd_lo + vs2)
  logic [DLEN-1:0] e2m_nmsub_res;    // vnmsub result (vs2 - madd_lo)
  logic            e2m_valid;        // MAC result valid
  vpu_op_e         e2m_op;           // Operation (for result mux)
  sew_e            e2m_sew;
  logic [4:0]      e2m_vd;
  logic [CVXIF_ID_W-1:0] e2m_id;
  logic            e2m_is_last_uop;
  logic [DLEN-1:0] e2m_old_vd;
  logic [NUM_ELEM_8-1:0] e2m_vmask;
  logic            e2m_vm;
  logic [NUM_ELEM_8-1:0] e2m_cmp_mask;
  logic [NUM_ELEM_8-1:0] e2_cmp_mask;  // Comparison result mask
  sew_e        e2_sew;
  logic [4:0]  e2_vd;
  logic [CVXIF_ID_W-1:0] e2_id;
  logic        e2_is_last_uop;   // v1.2a: LMUL micro-op tracking

  //--------------------------------------------------------------------------
  // SIMD Adders (Multi-SEW)
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] add_res_8, sub_res_8;
  logic [DLEN-1:0] add_res_16, sub_res_16;
  logic [DLEN-1:0] add_res_32, sub_res_32;

  generate
    // SEW=8
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_add8
      wire [7:0] a8 = e1_a[i*8 +: 8];
      wire [7:0] b8 = e1_b[i*8 +: 8];
      assign add_res_8[i*8 +: 8] = a8 + b8;
      assign sub_res_8[i*8 +: 8] = a8 - b8;
    end

    // SEW=16
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_add16
      wire [15:0] a16 = e1_a[i*16 +: 16];
      wire [15:0] b16 = e1_b[i*16 +: 16];
      assign add_res_16[i*16 +: 16] = a16 + b16;
      assign sub_res_16[i*16 +: 16] = a16 - b16;
    end

    // SEW=32
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_add32
      wire [31:0] a32 = e1_a[i*32 +: 32];
      wire [31:0] b32 = e1_b[i*32 +: 32];
      assign add_res_32[i*32 +: 32] = a32 + b32;
      assign sub_res_32[i*32 +: 32] = a32 - b32;
    end
  endgenerate

  wire [DLEN-1:0] add_res = (e1_sew == SEW_8) ? add_res_8 :
                            (e1_sew == SEW_16) ? add_res_16 : add_res_32;
  wire [DLEN-1:0] sub_res = (e1_sew == SEW_8) ? sub_res_8 :
                            (e1_sew == SEW_16) ? sub_res_16 : sub_res_32;

  // Reverse subtract: b - a (for vrsub: scalar - vs2)
  logic [DLEN-1:0] rsub_res_8, rsub_res_16, rsub_res_32;
  generate
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_rsub8
      assign rsub_res_8[i*8 +: 8] = e1_b[i*8 +: 8] - e1_a[i*8 +: 8];
    end
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_rsub16
      assign rsub_res_16[i*16 +: 16] = e1_b[i*16 +: 16] - e1_a[i*16 +: 16];
    end
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_rsub32
      assign rsub_res_32[i*32 +: 32] = e1_b[i*32 +: 32] - e1_a[i*32 +: 32];
    end
  endgenerate
  wire [DLEN-1:0] rsub_res = (e1_sew == SEW_8) ? rsub_res_8 :
                             (e1_sew == SEW_16) ? rsub_res_16 : rsub_res_32;

  //--------------------------------------------------------------------------
  // Vector Index Generation (vid.v)
  // Generates vd[i] = i for each element position
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] vid_8, vid_16, vid_32;

  generate
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_vid8
      assign vid_8[i*8 +: 8] = i[7:0];
    end
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_vid16
      assign vid_16[i*16 +: 16] = i[15:0];
    end
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_vid32
      assign vid_32[i*32 +: 32] = i[31:0];
    end
  endgenerate

  wire [DLEN-1:0] vid_res = (e1_sew == SEW_8) ? vid_8 :
                            (e1_sew == SEW_16) ? vid_16 : vid_32;

  //--------------------------------------------------------------------------
  // SIMD Multipliers (Multi-SEW) - Parameterized by DLEN
  //--------------------------------------------------------------------------
  // Signed multiply (for vmulh)
  logic [15:0] mul_part_8 [NUM_ELEM_8];   // 8x8 -> 16 bit products (signed)
  logic [31:0] mul_part_16 [NUM_ELEM_16]; // 16x16 -> 32 bit products (signed)
  logic [63:0] mul_part_32 [NUM_ELEM_32]; // 32x32 -> 64 bit products (signed)

  // Unsigned multiply (for vmulhu)
  logic [15:0] mulu_part_8 [NUM_ELEM_8];   // 8x8 -> 16 bit products (unsigned)
  logic [31:0] mulu_part_16 [NUM_ELEM_16]; // 16x16 -> 32 bit products (unsigned)
  logic [63:0] mulu_part_32 [NUM_ELEM_32]; // 32x32 -> 64 bit products (unsigned)

  // Signed*Unsigned multiply (for vmulhsu) - vs2=signed, vs1=unsigned
  logic signed [15:0] mulsu_part_8 [NUM_ELEM_8];
  logic signed [31:0] mulsu_part_16 [NUM_ELEM_16];
  logic signed [63:0] mulsu_part_32 [NUM_ELEM_32];

  // VMADD multiply (vs1 * old_vd for vmadd/vnmsub) - gated by ENABLE_VMADD
  // When ENABLE_VMADD=0, these are optimized away by synthesis for 2 GHz timing
  logic [15:0] madd_part_8 [NUM_ELEM_8];
  logic [31:0] madd_part_16 [NUM_ELEM_16];
  logic [63:0] madd_part_32 [NUM_ELEM_32];

  // v1.5: MAC results computed in E2m stage (after multiply registered in E2)
  // This breaks the critical path: E1→E2 is multiply only, E2→E2m is add only
  // vmacc:  vd = mul_lo + old_vd
  // vnmsac: vd = old_vd - mul_lo
  // vmadd:  vd = madd_lo + vs2
  // vnmsub: vd = vs2 - madd_lo

  // v1.7: Partial product wires for SEW=32 (declared before generate)
  logic [31:0] pp_ll_32 [NUM_ELEM_32];
  logic signed [31:0] pp_lh_32 [NUM_ELEM_32];
  logic signed [31:0] pp_hl_32 [NUM_ELEM_32];
  logic signed [31:0] pp_hh_32 [NUM_ELEM_32];
  logic [31:0] ppu_ll_32 [NUM_ELEM_32];
  logic [31:0] ppu_lh_32 [NUM_ELEM_32];
  logic [31:0] ppu_hl_32 [NUM_ELEM_32];
  logic [31:0] ppu_hh_32 [NUM_ELEM_32];
  logic [31:0] ppsu_ll_32 [NUM_ELEM_32];
  logic signed [31:0] ppsu_lh_32 [NUM_ELEM_32];
  logic signed [31:0] ppsu_hl_32 [NUM_ELEM_32];
  logic signed [31:0] ppsu_hh_32 [NUM_ELEM_32];
  logic [31:0] ppmadd_ll_32 [NUM_ELEM_32];
  logic signed [31:0] ppmadd_lh_32 [NUM_ELEM_32];
  logic signed [31:0] ppmadd_hl_32 [NUM_ELEM_32];
  logic signed [31:0] ppmadd_hh_32 [NUM_ELEM_32];

  generate
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_mul8
      wire signed [7:0] a8_s = e1_a[i*8 +: 8];
      wire signed [7:0] b8_s = e1_b[i*8 +: 8];
      wire [7:0] a8_u = e1_a[i*8 +: 8];
      wire [7:0] b8_u = e1_b[i*8 +: 8];
      wire [7:0] c8   = e1_c[i*8 +: 8];
      assign mul_part_8[i] = a8_s * b8_s;    // Signed
      assign mulu_part_8[i] = a8_u * b8_u;   // Unsigned
      // Signed*Unsigned for vmulhsu (vs2=signed, vs1=unsigned)
      assign mulsu_part_8[i] = a8_s * $signed({1'b0, b8_u});
      // v1.5: MAC add moved to E2m stage (see below)
      // VMADD: vs1 * old_vd (e1_b * e1_c) - e1_b=vs1, e1_c=old_vd
      if (ENABLE_VMADD) begin : gen_madd8
        wire signed [7:0] c8_s = e1_c[i*8 +: 8];
        assign madd_part_8[i] = b8_s * c8_s;
        // v1.5: madd add moved to E2m stage
      end else begin : gen_madd8_stub
        assign madd_part_8[i] = '0;
        // v1.5: madd disabled
      end
    end

    for (genvar i = 0; i < DLEN/16; i++) begin : gen_mul16
      wire signed [15:0] a16_s = e1_a[i*16 +: 16];
      wire signed [15:0] b16_s = e1_b[i*16 +: 16];
      wire [15:0] a16_u = e1_a[i*16 +: 16];
      wire [15:0] b16_u = e1_b[i*16 +: 16];
      wire [15:0] c16   = e1_c[i*16 +: 16];
      assign mul_part_16[i] = a16_s * b16_s;   // Signed
      assign mulu_part_16[i] = a16_u * b16_u;  // Unsigned
      // Signed*Unsigned for vmulhsu
      assign mulsu_part_16[i] = a16_s * $signed({1'b0, b16_u});
      // v1.5: MAC add moved to E2m stage
      // VMADD: vs1 * old_vd (e1_b * e1_c)
      if (ENABLE_VMADD) begin : gen_madd16
        wire signed [15:0] c16_s = e1_c[i*16 +: 16];
        assign madd_part_16[i] = b16_s * c16_s;
        // v1.5: madd add moved to E2m stage
      end else begin : gen_madd16_stub
        assign madd_part_16[i] = '0;
        // v1.5: madd disabled
      end
    end

    // v1.7: SEW=32 uses partial products (split 32×32 into four 16×16)
    // This breaks the critical timing path: E1→E1m (partials) + E1m→E2 (combine)
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_mul32
      // Signed multiply partials (for vmul/vmulh)
      wire signed [15:0] a32_hi_s = e1_a[i*32+16 +: 16];  // High 16 bits (signed)
      wire [15:0] a32_lo = e1_a[i*32 +: 16];              // Low 16 bits (unsigned)
      wire signed [15:0] b32_hi_s = e1_b[i*32+16 +: 16];
      wire [15:0] b32_lo = e1_b[i*32 +: 16];

      // Partial products for signed multiply
      assign pp_ll_32[i] = a32_lo * b32_lo;                                    // u × u
      assign pp_lh_32[i] = $signed({1'b0, a32_lo}) * b32_hi_s;                  // u × s
      assign pp_hl_32[i] = a32_hi_s * $signed({1'b0, b32_lo});                  // s × u
      assign pp_hh_32[i] = a32_hi_s * b32_hi_s;                                 // s × s

      // Unsigned multiply partials (for vmulhu)
      wire [15:0] a32_hi_u = e1_a[i*32+16 +: 16];
      wire [15:0] b32_hi_u = e1_b[i*32+16 +: 16];
      assign ppu_ll_32[i] = a32_lo * b32_lo;
      assign ppu_lh_32[i] = a32_lo * b32_hi_u;
      assign ppu_hl_32[i] = a32_hi_u * b32_lo;
      assign ppu_hh_32[i] = a32_hi_u * b32_hi_u;

      // Signed×Unsigned partials (for vmulhsu: vs2=signed, vs1=unsigned)
      assign ppsu_ll_32[i] = a32_lo * b32_lo;                                   // u × u
      assign ppsu_lh_32[i] = $signed({1'b0, a32_lo}) * $signed({1'b0, b32_hi_u}); // u × u (treat as signed for extension)
      assign ppsu_hl_32[i] = a32_hi_s * $signed({1'b0, b32_lo});                 // s × u
      assign ppsu_hh_32[i] = a32_hi_s * $signed({1'b0, b32_hi_u});               // s × u

      // VMADD partials (vs1 × old_vd = e1_b × e1_c)
      if (ENABLE_VMADD) begin : gen_madd32
        wire signed [15:0] b32_hi_s_madd = e1_b[i*32+16 +: 16];
        wire [15:0] b32_lo_madd = e1_b[i*32 +: 16];
        wire signed [15:0] c32_hi_s = e1_c[i*32+16 +: 16];
        wire [15:0] c32_lo = e1_c[i*32 +: 16];
        assign ppmadd_ll_32[i] = b32_lo_madd * c32_lo;
        assign ppmadd_lh_32[i] = $signed({1'b0, b32_lo_madd}) * c32_hi_s;
        assign ppmadd_hl_32[i] = b32_hi_s_madd * $signed({1'b0, c32_lo});
        assign ppmadd_hh_32[i] = b32_hi_s_madd * c32_hi_s;
      end else begin : gen_madd32_stub
        assign ppmadd_ll_32[i] = '0;
        assign ppmadd_lh_32[i] = '0;
        assign ppmadd_hl_32[i] = '0;
        assign ppmadd_hh_32[i] = '0;
      end

      // Legacy full multiply (for non-E1m path fallback - will be removed)
      wire signed [31:0] a32_s = e1_a[i*32 +: 32];
      wire signed [31:0] b32_s = e1_b[i*32 +: 32];
      wire [31:0] a32_u = e1_a[i*32 +: 32];
      wire [31:0] b32_u = e1_b[i*32 +: 32];
      assign mul_part_32[i] = a32_s * b32_s;
      assign mulu_part_32[i] = a32_u * b32_u;
      assign mulsu_part_32[i] = a32_s * $signed({1'b0, b32_u});
      if (ENABLE_VMADD) begin : gen_madd32_legacy
        wire signed [31:0] c32_s = e1_c[i*32 +: 32];
        assign madd_part_32[i] = b32_s * c32_s;
      end else begin : gen_madd32_legacy_stub
        assign madd_part_32[i] = '0;
      end
    end
  endgenerate

  //--------------------------------------------------------------------------
  // E1m Stage Registers - Capture partial products for multiply ops (v1.7)
  //--------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      e1m_valid       <= 1'b0;
      e1m_op          <= OP_NOP;
      e1m_sew         <= SEW_8;
      e1m_vd          <= '0;
      e1m_id          <= '0;
      e1m_is_last_uop <= 1'b1;
      e1m_a           <= '0;
      e1m_b           <= '0;
      e1m_c           <= '0;
      e1m_old_vd      <= '0;
      e1m_vmask       <= '0;
      e1m_vm          <= 1'b1;
      for (int i = 0; i < NUM_ELEM_32; i++) begin
        e1m_pp_ll_32[i] <= '0;
        e1m_pp_lh_32[i] <= '0;
        e1m_pp_hl_32[i] <= '0;
        e1m_pp_hh_32[i] <= '0;
        e1m_ppu_ll_32[i] <= '0;
        e1m_ppu_lh_32[i] <= '0;
        e1m_ppu_hl_32[i] <= '0;
        e1m_ppu_hh_32[i] <= '0;
        e1m_ppsu_ll_32[i] <= '0;
        e1m_ppsu_lh_32[i] <= '0;
        e1m_ppsu_hl_32[i] <= '0;
        e1m_ppsu_hh_32[i] <= '0;
        e1m_ppmadd_ll_32[i] <= '0;
        e1m_ppmadd_lh_32[i] <= '0;
        e1m_ppmadd_hl_32[i] <= '0;
        e1m_ppmadd_hh_32[i] <= '0;
      end
      for (int i = 0; i < NUM_ELEM_8; i++) begin
        e1m_mul_8[i] <= '0;
        e1m_mulu_8[i] <= '0;
        e1m_mulsu_8[i] <= '0;
        e1m_madd_8[i] <= '0;
      end
      for (int i = 0; i < NUM_ELEM_16; i++) begin
        e1m_mul_16[i] <= '0;
        e1m_mulu_16[i] <= '0;
        e1m_mulsu_16[i] <= '0;
        e1m_madd_16[i] <= '0;
      end
    end else if (!stall_i && !mac_stall) begin
      // v0.5e: Restructured for simultaneous drain+capture
      // When E1 has a multiply AND E1m is valid: drain E1m to E2 AND capture E1 into E1m
      // on the same clock edge. E2 reads old e1m_* (non-blocking assignment semantics).
      if (is_mul_op_e1 && e1m_valid) begin
        // SIMULTANEOUS drain+capture: E1m content goes to E2, E1 multiply replaces E1m
        e1m_valid       <= e1_valid;
        e1m_op          <= e1_op;
        e1m_sew         <= e1_sew;
        e1m_vd          <= e1_vd;
        e1m_id          <= e1_id;
        e1m_is_last_uop <= e1_is_last_uop;
        e1m_a           <= e1_a;
        e1m_b           <= e1_b;
        e1m_c           <= e1_c;
        e1m_old_vd      <= e1_old_vd;
        e1m_vmask       <= e1_vmask;
        e1m_vm          <= e1_vm;

        // DEBUG: trace simultaneous drain+capture
        `ifdef SIMULATION
        if (e1_vd == 7 || e1_vd == 8 || e1m_vd == 7 || e1m_vd == 8)
          $display("[%0t] E1M_SIMUL_DRAIN_CAPTURE: draining vd=%0d, capturing vd=%0d op=%0d",
                   $time, e1m_vd, e1_vd, e1_op);
        `endif

        // Capture partial products for SEW=32
        for (int i = 0; i < NUM_ELEM_32; i++) begin
          e1m_pp_ll_32[i] <= pp_ll_32[i];
          e1m_pp_lh_32[i] <= pp_lh_32[i];
          e1m_pp_hl_32[i] <= pp_hl_32[i];
          e1m_pp_hh_32[i] <= pp_hh_32[i];
          e1m_ppu_ll_32[i] <= ppu_ll_32[i];
          e1m_ppu_lh_32[i] <= ppu_lh_32[i];
          e1m_ppu_hl_32[i] <= ppu_hl_32[i];
          e1m_ppu_hh_32[i] <= ppu_hh_32[i];
          e1m_ppsu_ll_32[i] <= ppsu_ll_32[i];
          e1m_ppsu_lh_32[i] <= ppsu_lh_32[i];
          e1m_ppsu_hl_32[i] <= ppsu_hl_32[i];
          e1m_ppsu_hh_32[i] <= ppsu_hh_32[i];
          e1m_ppmadd_ll_32[i] <= ppmadd_ll_32[i];
          e1m_ppmadd_lh_32[i] <= ppmadd_lh_32[i];
          e1m_ppmadd_hl_32[i] <= ppmadd_hl_32[i];
          e1m_ppmadd_hh_32[i] <= ppmadd_hh_32[i];
        end

        // Capture full products for SEW=8 and SEW=16
        for (int i = 0; i < NUM_ELEM_8; i++) begin
          e1m_mul_8[i] <= mul_part_8[i];
          e1m_mulu_8[i] <= mulu_part_8[i];
          e1m_mulsu_8[i] <= mulsu_part_8[i];
          e1m_madd_8[i] <= madd_part_8[i];
        end
        for (int i = 0; i < NUM_ELEM_16; i++) begin
          e1m_mul_16[i] <= mul_part_16[i];
          e1m_mulu_16[i] <= mulu_part_16[i];
          e1m_mulsu_16[i] <= mulsu_part_16[i];
          e1m_madd_16[i] <= madd_part_16[i];
        end
      end else if (is_mul_op_e1 && !e1m_valid) begin
        // E1 has multiply and E1m is free - capture the multiply
        // Multiply op advances from E1 to E1m
        e1m_valid       <= e1_valid;
        e1m_op          <= e1_op;
        e1m_sew         <= e1_sew;
        e1m_vd          <= e1_vd;
        e1m_id          <= e1_id;
        e1m_is_last_uop <= e1_is_last_uop;
        e1m_a           <= e1_a;
        e1m_b           <= e1_b;
        e1m_c           <= e1_c;
        e1m_old_vd      <= e1_old_vd;
        e1m_vmask       <= e1_vmask;
        e1m_vm          <= e1_vm;

        // DEBUG: trace vd==7 or vd==8
        `ifdef SIMULATION
        if (e1_vd == 7 || e1_vd == 8)
          $display("[%0t] E1M_CAPTURE: vd=%0d op=%0d from E1", $time, e1_vd, e1_op);
        `endif

        // Capture partial products for SEW=32
        for (int i = 0; i < NUM_ELEM_32; i++) begin
          e1m_pp_ll_32[i] <= pp_ll_32[i];
          e1m_pp_lh_32[i] <= pp_lh_32[i];
          e1m_pp_hl_32[i] <= pp_hl_32[i];
          e1m_pp_hh_32[i] <= pp_hh_32[i];
          e1m_ppu_ll_32[i] <= ppu_ll_32[i];
          e1m_ppu_lh_32[i] <= ppu_lh_32[i];
          e1m_ppu_hl_32[i] <= ppu_hl_32[i];
          e1m_ppu_hh_32[i] <= ppu_hh_32[i];
          e1m_ppsu_ll_32[i] <= ppsu_ll_32[i];
          e1m_ppsu_lh_32[i] <= ppsu_lh_32[i];
          e1m_ppsu_hl_32[i] <= ppsu_hl_32[i];
          e1m_ppsu_hh_32[i] <= ppsu_hh_32[i];
          e1m_ppmadd_ll_32[i] <= ppmadd_ll_32[i];
          e1m_ppmadd_lh_32[i] <= ppmadd_lh_32[i];
          e1m_ppmadd_hl_32[i] <= ppmadd_hl_32[i];
          e1m_ppmadd_hh_32[i] <= ppmadd_hh_32[i];
        end

        // Capture full products for SEW=8 and SEW=16 (no split needed)
        for (int i = 0; i < NUM_ELEM_8; i++) begin
          e1m_mul_8[i] <= mul_part_8[i];
          e1m_mulu_8[i] <= mulu_part_8[i];
          e1m_mulsu_8[i] <= mulsu_part_8[i];
          e1m_madd_8[i] <= madd_part_8[i];
        end
        for (int i = 0; i < NUM_ELEM_16; i++) begin
          e1m_mul_16[i] <= mul_part_16[i];
          e1m_mulu_16[i] <= mulu_part_16[i];
          e1m_mulsu_16[i] <= mulsu_part_16[i];
          e1m_madd_16[i] <= madd_part_16[i];
        end
      end else if (e1m_valid) begin
        // E1m advances to E2, clear E1m
        e1m_valid <= 1'b0;

        // DEBUG: trace E1m clearing
        `ifdef SIMULATION
        if (e1m_vd == 7 || e1m_vd == 8)
          $display("[%0t] E1M_CLEAR: vd=%0d op=%0d advancing to E2", $time, e1m_vd, e1m_op);
        `endif
      end
      // else: E1m stays empty (non-multiply op in E1, or E1 empty)
    end
  end

  //--------------------------------------------------------------------------
  // E1m→E2: Combine partial products for SEW=32 (combinational)
  //--------------------------------------------------------------------------
  logic [63:0] e1m_mul_combined_32 [NUM_ELEM_32];
  logic [63:0] e1m_mulu_combined_32 [NUM_ELEM_32];
  logic [63:0] e1m_mulsu_combined_32 [NUM_ELEM_32];
  logic [63:0] e1m_madd_combined_32 [NUM_ELEM_32];

  generate
    for (genvar i = 0; i < NUM_ELEM_32; i++) begin : gen_combine32
      // Combine partial products: result = pp_hh<<32 + pp_hl<<16 + pp_lh<<16 + pp_ll
      // Sign extension for cross products
      wire signed [63:0] pp_hh_ext = {{32{e1m_pp_hh_32[i][31]}}, e1m_pp_hh_32[i]};
      wire signed [63:0] pp_hl_ext = {{32{e1m_pp_hl_32[i][31]}}, e1m_pp_hl_32[i]};
      wire signed [63:0] pp_lh_ext = {{32{e1m_pp_lh_32[i][31]}}, e1m_pp_lh_32[i]};

      assign e1m_mul_combined_32[i] = (pp_hh_ext << 32) + (pp_hl_ext << 16) + (pp_lh_ext << 16) + {32'b0, e1m_pp_ll_32[i]};

      // Unsigned combination (no sign extension needed)
      assign e1m_mulu_combined_32[i] = ({32'b0, e1m_ppu_hh_32[i]} << 32) +
                                        ({32'b0, e1m_ppu_hl_32[i]} << 16) +
                                        ({32'b0, e1m_ppu_lh_32[i]} << 16) +
                                        {32'b0, e1m_ppu_ll_32[i]};

      // Signed×Unsigned combination
      wire signed [63:0] ppsu_hh_ext = {{32{e1m_ppsu_hh_32[i][31]}}, e1m_ppsu_hh_32[i]};
      wire signed [63:0] ppsu_hl_ext = {{32{e1m_ppsu_hl_32[i][31]}}, e1m_ppsu_hl_32[i]};
      wire signed [63:0] ppsu_lh_ext = {{32{e1m_ppsu_lh_32[i][31]}}, e1m_ppsu_lh_32[i]};
      assign e1m_mulsu_combined_32[i] = (ppsu_hh_ext << 32) + (ppsu_hl_ext << 16) + (ppsu_lh_ext << 16) + {32'b0, e1m_ppsu_ll_32[i]};

      // VMADD combination
      wire signed [63:0] ppmadd_hh_ext = {{32{e1m_ppmadd_hh_32[i][31]}}, e1m_ppmadd_hh_32[i]};
      wire signed [63:0] ppmadd_hl_ext = {{32{e1m_ppmadd_hl_32[i][31]}}, e1m_ppmadd_hl_32[i]};
      wire signed [63:0] ppmadd_lh_ext = {{32{e1m_ppmadd_lh_32[i][31]}}, e1m_ppmadd_lh_32[i]};
      assign e1m_madd_combined_32[i] = (ppmadd_hh_ext << 32) + (ppmadd_hl_ext << 16) + (ppmadd_lh_ext << 16) + {32'b0, e1m_ppmadd_ll_32[i]};
    end
  endgenerate

  //--------------------------------------------------------------------------
  // E2 Stage Registers
  //--------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      e2_valid       <= 1'b0;
      e2_op          <= OP_NOP;
      e2_logic_res   <= '0;
      e2_shift_res   <= '0;
      e2_minmax_res  <= '0;
      e2_gather_res  <= '0;
      e2_slideup_res <= '0;
      e2_slidedn_res <= '0;
      e2_redsum      <= '0;
      e2_redmax      <= '0;
      e2_redmin      <= '0;
      e2_redmaxu     <= '0;
      e2_redminu     <= '0;
      e2_redand      <= '0;
      e2_redor       <= '0;
      e2_redxor      <= '0;
      e2_mask_res    <= '0;
      e2_sat_res     <= '0;
      e2_sshift_res  <= '0;
      e2_nclip_res   <= '0;
      e2_nshift_res  <= '0;
      e2_lut_res     <= '0;
      e2_int4_res    <= '0;
      e2_add_res     <= '0;
      e2_c           <= '0;
      e2_b           <= '0;
      e2_vs1         <= '0;
      e2_vid_res     <= '0;
      // v0.15: New operation result resets
      e2_slide1up_res  <= '0;
      e2_slide1dn_res  <= '0;
      e2_merge_res     <= '0;
      e2_vcpop_res     <= '0;
      e2_vfirst_res    <= '0;
      e2_vmsbf_res     <= '0;
      e2_vmsif_res     <= '0;
      e2_vmsof_res     <= '0;
      e2_viota_res     <= '0;
      e2_compress_res  <= '0;
      e2_gatherei16_res <= '0;
      e2_old_vd      <= '0;
      e2_vmask       <= '0;
      e2_vm          <= 1'b1;
      e2_mul_partial <= '0;
      e2_mulu_partial <= '0;
      e2_mulsu_partial <= '0;
      e2_madd_partial <= '0;
      // v1.5: e2m_* registers reset handled separately
      e2_cmp_mask    <= '0;
      e2_sew         <= SEW_8;
      e2_vd          <= '0;
      e2_id          <= '0;
      e2_is_last_uop <= 1'b1;  // v1.2a: Default to last (single µop)
    end else if (!stall_i && !mac_stall) begin
      // v1.7: E2 accepts from E1m (multiply ops) or E1 (non-multiply ops)
      // Also stall when MAC op in E2 needs extra cycle for add (mac_stall)
      // When E1m is valid, it advances to E2 (multiply result ready)
      // When E1m is empty and E1 has non-multiply, E1 advances directly to E2
      if (e1m_valid) begin
        // Multiply op from E1m - use combined partial products
        e2_valid       <= 1'b1;
        e2_op          <= e1m_op;
        e2_sew         <= e1m_sew;
        e2_vd          <= e1m_vd;
        e2_id          <= e1m_id;
        e2_is_last_uop <= e1m_is_last_uop;
        e2_c           <= e1m_c;
        e2_b           <= e1m_a;  // vs2 for vmadd/vnmsub
        e2_vs1         <= e1m_b;  // vs1 pass-through
        e2_old_vd      <= e1m_old_vd;
        e2_vmask       <= e1m_vmask;
        e2_vm          <= e1m_vm;
        e2_cmp_mask    <= '0;  // Multiply ops don't produce comparison masks

        // DEBUG: trace vd==7 or vd==8
        `ifdef SIMULATION
        if (e1m_vd == 7 || e1m_vd == 8)
          $display("[%0t] E2_CAPTURE_FROM_E1M: vd=%0d op=%0d", $time, e1m_vd, e1m_op);
        `endif

        // Pass through non-multiply results as zeros (not used for multiply ops)
        e2_logic_res   <= '0;
        e2_shift_res   <= '0;
        e2_minmax_res  <= '0;
        e2_gather_res  <= '0;
        e2_slideup_res <= '0;
        e2_slidedn_res <= '0;
        e2_redsum      <= '0;
        e2_redmax      <= '0;
        e2_redmin      <= '0;
        e2_redmaxu     <= '0;
        e2_redminu     <= '0;
        e2_redand      <= '0;
        e2_redor       <= '0;
        e2_redxor      <= '0;
        e2_mask_res    <= '0;
        e2_sat_res     <= '0;
        e2_sshift_res  <= '0;
        e2_nclip_res   <= '0;
        e2_nshift_res  <= '0;
        e2_lut_res     <= '0;
        e2_int4_res    <= '0;
        e2_add_res     <= '0;
        e2_vid_res     <= '0;
        e2_slide1up_res  <= '0;
        e2_slide1dn_res  <= '0;
        e2_merge_res     <= '0;
        e2_vcpop_res     <= '0;
        e2_vfirst_res    <= '0;
        e2_vmsbf_res     <= '0;
        e2_vmsif_res     <= '0;
        e2_vmsof_res     <= '0;
        e2_viota_res     <= '0;
        e2_compress_res  <= '0;
        e2_gatherei16_res <= '0;

        // Multiply results from E1m (combined partials for SEW=32, direct for SEW=8/16)
        case (e1m_sew)
          SEW_8: begin
            for (int i = 0; i < DLEN/8; i++) begin
              e2_mul_partial[i*16 +: 16] <= e1m_mul_8[i];
              e2_mulu_partial[i*16 +: 16] <= e1m_mulu_8[i];
              e2_mulsu_partial[i*16 +: 16] <= e1m_mulsu_8[i];
              e2_madd_partial[i*16 +: 16] <= e1m_madd_8[i];
            end
          end
          SEW_16: begin
            for (int i = 0; i < DLEN/16; i++) begin
              e2_mul_partial[i*32 +: 32] <= e1m_mul_16[i];
              e2_mulu_partial[i*32 +: 32] <= e1m_mulu_16[i];
              e2_mulsu_partial[i*32 +: 32] <= e1m_mulsu_16[i];
              e2_madd_partial[i*32 +: 32] <= e1m_madd_16[i];
            end
          end
          default: begin // SEW_32 - use combined partials
            for (int i = 0; i < DLEN/32; i++) begin
              e2_mul_partial[i*64 +: 64] <= e1m_mul_combined_32[i];
              e2_mulu_partial[i*64 +: 64] <= e1m_mulu_combined_32[i];
              e2_mulsu_partial[i*64 +: 64] <= e1m_mulsu_combined_32[i];
              e2_madd_partial[i*64 +: 64] <= e1m_madd_combined_32[i];
            end
          end
        endcase

      end else if (e1_valid && !is_mul_op_e1) begin
        // Non-multiply op from E1 - bypass E1m
        e2_valid       <= e1_valid;
        e2_op          <= e1_op;

        // DEBUG: trace vd==7 or vd==8
        `ifdef SIMULATION
        if (e1_vd == 7 || e1_vd == 8)
          $display("[%0t] E2_CAPTURE_FROM_E1: vd=%0d op=%0d (non-mul)", $time, e1_vd, e1_op);
        `endif

        e2_logic_res   <= e1_logic_res;
        e2_shift_res   <= e1_shift_res;
        e2_minmax_res  <= e1_minmax_res;
        e2_gather_res  <= e1_gather_res;
        e2_slideup_res <= e1_slideup_res;
        e2_slidedn_res <= e1_slidedn_res;
        e2_redsum      <= e1_redsum;
        e2_redmax      <= e1_redmax;
        e2_redmin      <= e1_redmin;
        e2_redmaxu     <= e1_redmaxu;
        e2_redminu     <= e1_redminu;
        e2_redand      <= e1_redand;
        e2_redor       <= e1_redor;
        e2_redxor      <= e1_redxor;
        e2_mask_res    <= e1_mask_res;
        e2_sat_res     <= e1_sat_res;
        e2_sshift_res  <= e1_sshift_res;
        e2_nclip_res   <= e1_nclip_res;
        e2_nshift_res  <= e1_nshift_res;
        e2_lut_res     <= e1_lut_res;
        e2_int4_res    <= e1_int4_res;
        e2_c           <= e1_c;
        e2_b           <= e1_a;  // For vmadd/vnmsub addend (vs2)
        e2_vs1         <= e1_b;  // For vmv.v.v pass-through (vs1)
        e2_vid_res     <= vid_res;  // For vid.v
        e2_slide1up_res  <= e1_slide1up_res;
        e2_slide1dn_res  <= e1_slide1dn_res;
        e2_merge_res     <= e1_merge_res;
        e2_vcpop_res     <= e1_vcpop_res;
        e2_vfirst_res    <= e1_vfirst_res;
        e2_vmsbf_res     <= e1_vmsbf_res;
        e2_vmsif_res     <= e1_vmsif_res;
        e2_vmsof_res     <= e1_vmsof_res;
        e2_viota_res     <= e1_viota_res;
        e2_compress_res  <= e1_compress_res;
        e2_gatherei16_res <= e1_gatherei16_res;
        e2_old_vd      <= e1_old_vd;
        e2_vmask       <= e1_vmask;
        e2_vm          <= e1_vm;
        e2_cmp_mask    <= e1_cmp_mask;
        e2_sew         <= e1_sew;
        e2_vd          <= e1_vd;
        e2_id          <= e1_id;
        e2_is_last_uop <= e1_is_last_uop;

        // Add/Sub result
        e2_add_res <= (e1_op == OP_VSUB) ? sub_res :
                      (e1_op == OP_VRSUB) ? rsub_res : add_res;

        // Non-multiply ops don't use multiply partials, but clear them
        e2_mul_partial <= '0;
        e2_mulu_partial <= '0;
        e2_mulsu_partial <= '0;
        e2_madd_partial <= '0;

      end else begin
        // Either: no valid input, OR E1 has multiply going to E1m (not to E2)
        // In both cases, E2 gets a bubble
        e2_valid <= 1'b0;
      end
    end
  end

  //============================================================================
  // E3 Stage: Final Result MUX & MAC
  //============================================================================
  logic        e3_valid;
  logic [DLEN-1:0] e3_result;
  logic [NUM_ELEM_8-1:0] e3_cmp_mask;  // Comparison result mask
  logic            e3_is_cmp;
  logic [DLEN-1:0] e3_old_vd;      // Old destination for masking
  logic [NUM_ELEM_8-1:0] e3_vmask; // Mask bits (1 per element at SEW=8)
  logic            e3_vm;          // vm=1 unmasked, vm=0 masked
  sew_e        e3_sew;
  logic [4:0]  e3_vd;
  logic [CVXIF_ID_W-1:0] e3_id;
  logic        e3_is_last_uop;   // v1.2a: LMUL micro-op tracking

  //--------------------------------------------------------------------------
  // Extract low/high bits from signed multiply
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] mul_lo_8, mul_lo_16, mul_lo_32;
  logic [DLEN-1:0] mul_hi_8, mul_hi_16, mul_hi_32;

  generate
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_mul_extract8
      assign mul_lo_8[i*8 +: 8] = e2_mul_partial[i*16 +: 8];
      assign mul_hi_8[i*8 +: 8] = e2_mul_partial[i*16+8 +: 8];
    end
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_mul_extract16
      assign mul_lo_16[i*16 +: 16] = e2_mul_partial[i*32 +: 16];
      assign mul_hi_16[i*16 +: 16] = e2_mul_partial[i*32+16 +: 16];
    end
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_mul_extract32
      assign mul_lo_32[i*32 +: 32] = e2_mul_partial[i*64 +: 32];
      assign mul_hi_32[i*32 +: 32] = e2_mul_partial[i*64+32 +: 32];
    end
  endgenerate

  wire [DLEN-1:0] mul_lo = (e2_sew == SEW_8) ? mul_lo_8 :
                           (e2_sew == SEW_16) ? mul_lo_16 : mul_lo_32;
  wire [DLEN-1:0] mul_hi = (e2_sew == SEW_8) ? mul_hi_8 :
                           (e2_sew == SEW_16) ? mul_hi_16 : mul_hi_32;

  //--------------------------------------------------------------------------
  // Extract high bits from unsigned multiply (for vmulhu)
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] mulu_hi_8, mulu_hi_16, mulu_hi_32;

  generate
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_mulu_extract8
      assign mulu_hi_8[i*8 +: 8] = e2_mulu_partial[i*16+8 +: 8];
    end
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_mulu_extract16
      assign mulu_hi_16[i*16 +: 16] = e2_mulu_partial[i*32+16 +: 16];
    end
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_mulu_extract32
      assign mulu_hi_32[i*32 +: 32] = e2_mulu_partial[i*64+32 +: 32];
    end
  endgenerate

  wire [DLEN-1:0] mulu_hi = (e2_sew == SEW_8) ? mulu_hi_8 :
                            (e2_sew == SEW_16) ? mulu_hi_16 : mulu_hi_32;

  //--------------------------------------------------------------------------
  // Extract high bits from signed*unsigned multiply (for vmulhsu)
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] mulsu_hi_8, mulsu_hi_16, mulsu_hi_32;

  generate
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_mulsu_extract8
      assign mulsu_hi_8[i*8 +: 8] = e2_mulsu_partial[i*16+8 +: 8];
    end
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_mulsu_extract16
      assign mulsu_hi_16[i*16 +: 16] = e2_mulsu_partial[i*32+16 +: 16];
    end
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_mulsu_extract32
      assign mulsu_hi_32[i*32 +: 32] = e2_mulsu_partial[i*64+32 +: 32];
    end
  endgenerate

  wire [DLEN-1:0] mulsu_hi = (e2_sew == SEW_8) ? mulsu_hi_8 :
                             (e2_sew == SEW_16) ? mulsu_hi_16 : mulsu_hi_32;

  // v1.5: MAC results computed in dedicated E2m stage with 1-cycle stall.
  // E1→E2: multiply only. E2→E2m: add only (stall 1 cycle). E2m→E3: mux only.
  // This cleanly breaks timing: each stage fits in target clock period.

  //--------------------------------------------------------------------------
  // E2m Stage: MAC Add Computation (combinational from registered mul_lo)
  //--------------------------------------------------------------------------
  // Extract low bits from madd_partial (vs1 * old_vd for vmadd/vnmsub)
  logic [DLEN-1:0] madd_lo_8, madd_lo_16, madd_lo_32;
  generate
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_madd_extract8
      assign madd_lo_8[i*8 +: 8] = e2_madd_partial[i*16 +: 8];
    end
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_madd_extract16
      assign madd_lo_16[i*16 +: 16] = e2_madd_partial[i*32 +: 16];
    end
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_madd_extract32
      assign madd_lo_32[i*32 +: 32] = e2_madd_partial[i*64 +: 32];
    end
  endgenerate
  wire [DLEN-1:0] madd_lo = (e2_sew == SEW_8) ? madd_lo_8 :
                            (e2_sew == SEW_16) ? madd_lo_16 : madd_lo_32;

  // MAC add computation (combinational - uses registered mul_lo and e2_c)
  // vmacc:  vd = mul_lo + e2_c (accumulator)
  // vnmsac: vd = e2_c - mul_lo
  // vmadd:  vd = madd_lo + e2_b (vs2)
  // vnmsub: vd = e2_b - madd_lo
  logic [DLEN-1:0] mac_add_8, mac_add_16, mac_add_32;
  logic [DLEN-1:0] nmsac_add_8, nmsac_add_16, nmsac_add_32;
  logic [DLEN-1:0] madd_add_8, madd_add_16, madd_add_32;
  logic [DLEN-1:0] nmsub_add_8, nmsub_add_16, nmsub_add_32;

  generate
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_mac_add8
      assign mac_add_8[i*8 +: 8]   = mul_lo_8[i*8 +: 8] + e2_c[i*8 +: 8];
      assign nmsac_add_8[i*8 +: 8] = e2_c[i*8 +: 8] - mul_lo_8[i*8 +: 8];
      assign madd_add_8[i*8 +: 8]  = madd_lo_8[i*8 +: 8] + e2_b[i*8 +: 8];
      assign nmsub_add_8[i*8 +: 8] = e2_b[i*8 +: 8] - madd_lo_8[i*8 +: 8];
    end
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_mac_add16
      assign mac_add_16[i*16 +: 16]   = mul_lo_16[i*16 +: 16] + e2_c[i*16 +: 16];
      assign nmsac_add_16[i*16 +: 16] = e2_c[i*16 +: 16] - mul_lo_16[i*16 +: 16];
      assign madd_add_16[i*16 +: 16]  = madd_lo_16[i*16 +: 16] + e2_b[i*16 +: 16];
      assign nmsub_add_16[i*16 +: 16] = e2_b[i*16 +: 16] - madd_lo_16[i*16 +: 16];
    end
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_mac_add32
      assign mac_add_32[i*32 +: 32]   = mul_lo_32[i*32 +: 32] + e2_c[i*32 +: 32];
      assign nmsac_add_32[i*32 +: 32] = e2_c[i*32 +: 32] - mul_lo_32[i*32 +: 32];
      assign madd_add_32[i*32 +: 32]  = madd_lo_32[i*32 +: 32] + e2_b[i*32 +: 32];
      assign nmsub_add_32[i*32 +: 32] = e2_b[i*32 +: 32] - madd_lo_32[i*32 +: 32];
    end
  endgenerate

  wire [DLEN-1:0] mac_add_res   = (e2_sew == SEW_8) ? mac_add_8   : (e2_sew == SEW_16) ? mac_add_16   : mac_add_32;
  wire [DLEN-1:0] nmsac_add_res = (e2_sew == SEW_8) ? nmsac_add_8 : (e2_sew == SEW_16) ? nmsac_add_16 : nmsac_add_32;
  wire [DLEN-1:0] madd_add_res  = (e2_sew == SEW_8) ? madd_add_8  : (e2_sew == SEW_16) ? madd_add_16  : madd_add_32;
  wire [DLEN-1:0] nmsub_add_res = (e2_sew == SEW_8) ? nmsub_add_8 : (e2_sew == SEW_16) ? nmsub_add_16 : nmsub_add_32;

  // v1.6: MAC result selection using e2m_op (not e2_op!) for correct muxing
  logic [DLEN-1:0] mac_final_result;
  always_comb begin
    case (e2m_op)
      OP_VMACC:  mac_final_result = e2m_mac_res;
      OP_VNMSAC: mac_final_result = e2m_nmsac_res;
      OP_VMADD:  mac_final_result = e2m_madd_res;
      OP_VNMSUB: mac_final_result = e2m_nmsub_res;
      default:   mac_final_result = e2m_mac_res;
    endcase
  end

  // v0.5e: e2m registers REMOVED - mac_stall is always 0, so these never capture.
  // MAC results now flow through final_result -> masked_result -> E3 on the normal path.
  // Keep e2m_valid as constant 0 to avoid dangling references in E3 capture.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      e2m_mac_res     <= '0;
      e2m_nmsac_res   <= '0;
      e2m_madd_res    <= '0;
      e2m_nmsub_res   <= '0;
      e2m_valid       <= 1'b0;
      e2m_op          <= OP_NOP;
      e2m_sew         <= SEW_8;
      e2m_vd          <= '0;
      e2m_id          <= '0;
      e2m_is_last_uop <= 1'b1;
      e2m_old_vd      <= '0;
      e2m_vmask       <= '0;
      e2m_vm          <= 1'b1;
      e2m_cmp_mask    <= '0;
    end
    // v0.5e: No capture logic - e2m stays at reset values
  end

  //--------------------------------------------------------------------------
  // Reduction result packing (result in element 0, rest from vs1 which is e2_old_vd)
  //--------------------------------------------------------------------------
  wire [DLEN-1:0] redsum_full = (e2_sew == SEW_8)  ? {e2_old_vd[DLEN-1:8], e2_redsum[7:0]} :
                                (e2_sew == SEW_16) ? {e2_old_vd[DLEN-1:16], e2_redsum[15:0]} :
                                                     {e2_old_vd[DLEN-1:32], e2_redsum[31:0]};
  wire [DLEN-1:0] redmax_full = (e2_sew == SEW_8)  ? {e2_old_vd[DLEN-1:8], e2_redmax[7:0]} :
                                (e2_sew == SEW_16) ? {e2_old_vd[DLEN-1:16], e2_redmax[15:0]} :
                                                     {e2_old_vd[DLEN-1:32], e2_redmax[31:0]};
  wire [DLEN-1:0] redmin_full = (e2_sew == SEW_8)  ? {e2_old_vd[DLEN-1:8], e2_redmin[7:0]} :
                                (e2_sew == SEW_16) ? {e2_old_vd[DLEN-1:16], e2_redmin[15:0]} :
                                                     {e2_old_vd[DLEN-1:32], e2_redmin[31:0]};
  wire [DLEN-1:0] redmaxu_full = (e2_sew == SEW_8)  ? {e2_old_vd[DLEN-1:8], e2_redmaxu[7:0]} :
                                 (e2_sew == SEW_16) ? {e2_old_vd[DLEN-1:16], e2_redmaxu[15:0]} :
                                                      {e2_old_vd[DLEN-1:32], e2_redmaxu[31:0]};
  wire [DLEN-1:0] redminu_full = (e2_sew == SEW_8)  ? {e2_old_vd[DLEN-1:8], e2_redminu[7:0]} :
                                 (e2_sew == SEW_16) ? {e2_old_vd[DLEN-1:16], e2_redminu[15:0]} :
                                                      {e2_old_vd[DLEN-1:32], e2_redminu[31:0]};
  wire [DLEN-1:0] redand_full = (e2_sew == SEW_8)  ? {e2_old_vd[DLEN-1:8], e2_redand[7:0]} :
                                (e2_sew == SEW_16) ? {e2_old_vd[DLEN-1:16], e2_redand[15:0]} :
                                                     {e2_old_vd[DLEN-1:32], e2_redand[31:0]};
  wire [DLEN-1:0] redor_full = (e2_sew == SEW_8)  ? {e2_old_vd[DLEN-1:8], e2_redor[7:0]} :
                               (e2_sew == SEW_16) ? {e2_old_vd[DLEN-1:16], e2_redor[15:0]} :
                                                    {e2_old_vd[DLEN-1:32], e2_redor[31:0]};
  wire [DLEN-1:0] redxor_full = (e2_sew == SEW_8)  ? {e2_old_vd[DLEN-1:8], e2_redxor[7:0]} :
                                (e2_sew == SEW_16) ? {e2_old_vd[DLEN-1:16], e2_redxor[15:0]} :
                                                     {e2_old_vd[DLEN-1:32], e2_redxor[31:0]};

  //--------------------------------------------------------------------------
  // Final Result MUX
  //--------------------------------------------------------------------------
  // v0.5c: Mask valid bits for mask operations based on e2_sew - parameterized for any DLEN
  wire [DLEN-1:0] mask_valid_e2 = (e2_sew == SEW_8)  ? {{(DLEN-NUM_ELEM_8){1'b0}},  {NUM_ELEM_8{1'b1}}} :
                                  (e2_sew == SEW_16) ? {{(DLEN-NUM_ELEM_16){1'b0}}, {NUM_ELEM_16{1'b1}}} :
                                                       {{(DLEN-NUM_ELEM_32){1'b0}}, {NUM_ELEM_32{1'b1}}};

  logic [DLEN-1:0] final_result;
  logic final_is_cmp;
  logic final_is_mask_op;

  always_comb begin
    final_is_cmp = 1'b0;
    final_is_mask_op = 1'b0;
    case (e2_op)
      OP_VADD, OP_VSUB, OP_VRSUB: final_result = e2_add_res;
      OP_VMUL:          final_result = mul_lo;
      OP_VMULH:         final_result = mul_hi;
      OP_VMULHU:        final_result = mulu_hi;
      OP_VMULHSU:       final_result = mulsu_hi;
      OP_VMV:           final_result = e2_vs1;  // vmv.v.v pass-through
      OP_VID:           final_result = e2_vid_res;  // vid.v - vector index
      // v0.5e: MAC results directly from combinational add (no e2m staging)
      OP_VMACC:         final_result = mac_add_res;
      OP_VNMSAC:        final_result = nmsac_add_res;
      OP_VMADD:         final_result = madd_add_res;
      OP_VNMSUB:        final_result = nmsub_add_res;
      OP_VAND, OP_VOR, OP_VXOR: final_result = e2_logic_res;
      OP_VSLL, OP_VSRL, OP_VSRA: final_result = e2_shift_res;
      OP_VMIN, OP_VMINU, OP_VMAX, OP_VMAXU: final_result = e2_minmax_res;
      OP_VRGATHER: final_result = e2_gather_res;
      OP_VSLIDEUP: final_result = e2_slideup_res;
      OP_VSLIDEDN: final_result = e2_slidedn_res;
      // Reductions
      OP_VREDSUM:  final_result = redsum_full;
      OP_VREDMAX:  final_result = redmax_full;
      OP_VREDMIN:  final_result = redmin_full;
      OP_VREDMAXU: final_result = redmaxu_full;
      OP_VREDMINU: final_result = redminu_full;
      OP_VREDAND:  final_result = redand_full;
      OP_VREDOR:   final_result = redor_full;
      OP_VREDXOR:  final_result = redxor_full;
      // Mask-register logical operations (result goes to vd, no masking)
      OP_VMAND_MM, OP_VMNAND_MM, OP_VMANDN_MM, OP_VMXOR_MM,
      OP_VMOR_MM, OP_VMNOR_MM, OP_VMORN_MM, OP_VMXNOR_MM: begin
        final_result = e2_mask_res;
        final_is_mask_op = 1'b1;
      end
      // Fixed-point operations
      OP_VSADDU, OP_VSADD, OP_VSSUBU, OP_VSSUB: final_result = e2_sat_res;
      OP_VSSRL, OP_VSSRA: final_result = e2_sshift_res;
      OP_VNCLIPU, OP_VNCLIP: final_result = e2_nclip_res;
      // v0.18: Narrowing shift operations
      OP_VNSRL, OP_VNSRA: final_result = e2_nshift_res;
      // v0.19: LUT-based operations for LLM inference
      OP_VEXP, OP_VRECIP, OP_VRSQRT, OP_VGELU: final_result = e2_lut_res;
      // v1.1: INT4 pack/unpack for lower quantization
      OP_VPACK4, OP_VUNPACK4: final_result = e2_int4_res;
      // Comparisons
      OP_VMSEQ, OP_VMSNE, OP_VMSLT, OP_VMSLTU, OP_VMSLE, OP_VMSLEU, OP_VMSGT, OP_VMSGTU: begin
        final_result = '0;
        final_is_cmp = 1'b1;
      end
      // v0.15: New operations
      OP_VSLIDE1UP: final_result = e2_slide1up_res;
      OP_VSLIDE1DN: final_result = e2_slide1dn_res;
      OP_VMERGE: begin
        final_result = e2_merge_res;
        final_is_mask_op = 1'b1;  // vmerge uses mask internally, bypass element masking
      end
      OP_VRGATHEREI16: final_result = e2_gatherei16_res;
      // v0.15: Mask operations (result goes to vd as mask)
      OP_VCPOP: begin
        final_result = e2_vcpop_res;  // Scalar result in element 0
        final_is_mask_op = 1'b1;      // No element masking
      end
      OP_VFIRST: begin
        final_result = e2_vfirst_res;  // Scalar result in element 0
        final_is_mask_op = 1'b1;       // No element masking
      end
      OP_VMSBF: begin
        final_result = e2_vmsbf_res & mask_valid_e2;  // v0.3c: Mask to valid bits
        final_is_mask_op = 1'b1;
      end
      OP_VMSIF: begin
        final_result = e2_vmsif_res & mask_valid_e2;  // v0.3c: Mask to valid bits
        final_is_mask_op = 1'b1;
      end
      OP_VMSOF: begin
        final_result = e2_vmsof_res;
        final_is_mask_op = 1'b1;
      end
      OP_VIOTA: begin
        final_result = e2_viota_res;
        // Normal vector result — goes through element masking
      end
      OP_VCOMPRESS: begin
        final_result = e2_compress_res;
        final_is_mask_op = 1'b1;  // Bypass element masking (compress handles its own selection)
      end
      default: final_result = '0;
    endcase
  end

  //--------------------------------------------------------------------------
  // Masked Result: Merge computed result with old_vd based on mask
  // vm=1: unmasked, use computed result for all elements
  // vm=0: masked, use computed result only where mask bit is 1
  //--------------------------------------------------------------------------
  logic [DLEN-1:0] masked_result_8, masked_result_16, masked_result_32;

  generate
    // SEW=8: 32 elements, 32 mask bits
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_mask8
      assign masked_result_8[i*8 +: 8] = (e2_vm || e2_vmask[i]) ?
                                          final_result[i*8 +: 8] :
                                          e2_old_vd[i*8 +: 8];
    end

    // SEW=16: 16 elements, 16 mask bits (lower 16 of vmask)
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_mask16
      assign masked_result_16[i*16 +: 16] = (e2_vm || e2_vmask[i]) ?
                                             final_result[i*16 +: 16] :
                                             e2_old_vd[i*16 +: 16];
    end

    // SEW=32: 8 elements, 8 mask bits (lower 8 of vmask)
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_mask32
      assign masked_result_32[i*32 +: 32] = (e2_vm || e2_vmask[i]) ?
                                             final_result[i*32 +: 32] :
                                             e2_old_vd[i*32 +: 32];
    end
  endgenerate

  wire [DLEN-1:0] masked_result = final_is_mask_op ? final_result :  // Mask ops bypass element masking
                                  (e2_sew == SEW_8)  ? masked_result_8 :
                                  (e2_sew == SEW_16) ? masked_result_16 :
                                                       masked_result_32;

  // v1.6: MAC-specific masking using e2m_* signals (not e2_* which has new instruction!)
  logic [DLEN-1:0] mac_masked_result_8, mac_masked_result_16, mac_masked_result_32;

  generate
    // MAC masking SEW=8: uses e2m_vmask and e2m_old_vd
    for (genvar i = 0; i < DLEN/8; i++) begin : gen_mac_mask8
      assign mac_masked_result_8[i*8 +: 8] = (e2m_vm || e2m_vmask[i]) ?
                                              mac_final_result[i*8 +: 8] :
                                              e2m_old_vd[i*8 +: 8];
    end

    // MAC masking SEW=16
    for (genvar i = 0; i < DLEN/16; i++) begin : gen_mac_mask16
      assign mac_masked_result_16[i*16 +: 16] = (e2m_vm || e2m_vmask[i]) ?
                                                 mac_final_result[i*16 +: 16] :
                                                 e2m_old_vd[i*16 +: 16];
    end

    // MAC masking SEW=32
    for (genvar i = 0; i < DLEN/32; i++) begin : gen_mac_mask32
      assign mac_masked_result_32[i*32 +: 32] = (e2m_vm || e2m_vmask[i]) ?
                                                 mac_final_result[i*32 +: 32] :
                                                 e2m_old_vd[i*32 +: 32];
    end
  endgenerate

  wire [DLEN-1:0] mac_masked_result = (e2m_sew == SEW_8)  ? mac_masked_result_8 :
                                      (e2m_sew == SEW_16) ? mac_masked_result_16 :
                                                            mac_masked_result_32;

  //--------------------------------------------------------------------------
  // E3 Stage Registers
  // v0.5e: Single path to E3 - MAC results flow through final_result/masked_result
  //   like all other ops. No more e2m staging or mac_stall bubbles.
  //--------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      e3_valid    <= 1'b0;
      e3_result   <= '0;
      e3_cmp_mask <= '0;
      e3_is_cmp   <= 1'b0;
      e3_old_vd   <= '0;
      e3_vmask    <= '0;
      e3_vm       <= 1'b1;
      e3_sew      <= SEW_8;
      e3_vd       <= '0;
      e3_id       <= '0;
      e3_is_last_uop <= 1'b1;  // v1.2a: Default to last (single µop)
    end else if (!stall_i) begin
      // v0.5e: Unified path - all ops (including MAC) go through masked_result
      e3_valid    <= e2_valid;
      e3_result   <= masked_result;
      e3_cmp_mask <= e2_cmp_mask;
      e3_is_cmp   <= final_is_cmp;
      e3_old_vd   <= e2_old_vd;
      e3_vmask    <= e2_vmask;
      e3_vm       <= e2_vm;
      e3_sew      <= e2_sew;
      e3_vd       <= e2_vd;
      e3_id       <= e2_id;
      e3_is_last_uop <= e2_is_last_uop;

      // DEBUG: trace vd==7 or vd==8
      `ifdef SIMULATION
      if (e2_valid && (e2_vd == 7 || e2_vd == 8))
        $display("[%0t] E3_CAPTURE: vd=%0d op=%0d result[7:0]=%02h",
                 $time, e2_vd, e2_op, masked_result[7:0]);
      `endif
    end
  end

  //============================================================================
  // Outputs - Mux between normal E3 path, R3 reduction, and W2 widening pipeline
  //============================================================================
  // Result valid from normal path, reduction pipeline, or widening pipeline
  assign valid_o      = e3_valid || r3_valid || w2_valid;

  // DEBUG: Detect multiple valid outputs at same time
  `ifdef SIMULATION
  always @(posedge clk) begin
    if ((e3_valid && r3_valid) || (e3_valid && w2_valid) || (r3_valid && w2_valid)) begin
      $display("[%0t] ERROR: Multiple valid outputs! e3_valid=%b r3_valid=%b w2_valid=%b",
               $time, e3_valid, r3_valid, w2_valid);
      $display("       e3_vd=%0d r3_vd=%0d w2_vd=%0d", e3_vd, r3_vd, w2_vd);
    end
    // Trace ALL VRF writes
    if (valid_o && (vd_o == 7 || vd_o == 8)) begin
      $display("[%0t] VRF_WRITE: vd=%0d result[31:0]=%08h e3=%b r3=%b w2=%b",
               $time, vd_o, result_o[31:0], e3_valid, r3_valid, w2_valid);
    end
  end
  `endif

  // Mux result based on which path produced it
  // Priority: widening > reduction > normal (only one should be valid at a time)
  assign result_o     = w2_valid ? w2_result :
                        r3_valid ? red_result_packed : e3_result;
  assign vd_o         = w2_valid ? w2_vd :
                        r3_valid ? r3_vd : e3_vd;
  assign id_o         = w2_valid ? w2_id :
                        r3_valid ? r3_id : e3_id;

  // v1.2a: LMUL micro-op tracking - reductions and widening ops complete in one µop
  // For these paths, is_last_uop is always true (they don't span multiple register groups)
  assign is_last_uop_o = w2_valid ? 1'b1 :
                         r3_valid ? 1'b1 : e3_is_last_uop;

  // Mask outputs (comparisons only, not reductions or widening)
  assign mask_o       = e3_cmp_mask;
  assign mask_valid_o = e3_valid && e3_is_cmp;

  // Hazard detection - v0.5b: E1 and E1m reported separately so both destinations
  // are visible to the hazard unit during simultaneous E1/E1m occupancy
  assign e1_valid_o   = e1_valid || (red_state == RED_R1) || (wide_state == WIDE_W1);
  assign e1_vd_o      = (red_state == RED_R1) ? r1_vd :
                        (wide_state == WIDE_W1) ? w1_vd : e1_vd;
  // v0.5b: Separate E1m hazard port
  assign e1m_valid_o  = e1m_valid;
  assign e1m_vd_o     = e1m_vd;

  // v0.3e: R2A now tracked via dedicated r2a_valid_o port, not e2
  assign e2_valid_o   = e2_valid || (wide_state == WIDE_W2);
  assign e2_vd_o      = (wide_state == WIDE_W2) ? w2_vd : e2_vd;

  // New hazard outputs for R2A/R2B
  assign r2a_valid_o = (red_state == RED_R2A);
  assign r2a_vd_o    = r2a_vd;
  assign r2b_valid_o = (red_state == RED_R2B);
  assign r2b_vd_o    = r2b_vd;

  // DEBUG: Monitor ALL pipeline outputs when v7 or v8 is being written to VRF
  `ifdef SIMULATION
  always @(posedge clk) begin
    // When valid_o fires with vd==7 or vd==8, show ALL pipeline states
    if (valid_o && (vd_o == 5'd7 || vd_o == 5'd8)) begin
      $display("[%0t] VRF_WRITE: vd=%0d", $time, vd_o);
      $display("         result=%h", result_o);
      $display("         e3_valid=%b e3_vd=%0d | r3_valid=%b r3_vd=%0d | w2_valid=%b w2_vd=%0d",
               e3_valid, e3_vd, r3_valid, r3_vd, w2_valid, w2_vd);
      // Check for conflicts
      if (e3_valid && r3_valid)
        $display("         WARNING: BOTH e3 and r3 valid!");
      if (e3_valid && w2_valid)
        $display("         WARNING: BOTH e3 and w2 valid!");
      if (r3_valid && w2_valid)
        $display("         WARNING: BOTH r3 and w2 valid!");
    end
  end
  `endif

  //============================================================================
  // STRESS TEST INSTRUMENTATION (v1.7)
  // Counters and detection for VRF write contentions and deadlocks
  //============================================================================
  `ifdef SIMULATION
  // Contention counters
  integer stress_vrf_contentions;
  integer stress_e3_r3_contentions;
  integer stress_e3_w2_contentions;
  integer stress_r3_w2_contentions;

  // Stall cycle counters
  integer stress_mul_stall_cycles;
  integer stress_mac_stall_cycles;
  integer stress_red_busy_cycles;
  integer stress_wide_busy_cycles;
  integer stress_total_stall_cycles;

  // Deadlock detection
  integer stress_stall_streak;
  integer stress_max_stall_streak;
  localparam DEADLOCK_THRESHOLD = 100;  // cycles

  // Pipeline utilization
  integer stress_e3_valid_cycles;
  integer stress_r3_valid_cycles;
  integer stress_w2_valid_cycles;
  integer stress_total_cycles;

  // Initialize counters
  initial begin
    stress_vrf_contentions = 0;
    stress_e3_r3_contentions = 0;
    stress_e3_w2_contentions = 0;
    stress_r3_w2_contentions = 0;
    stress_mul_stall_cycles = 0;
    stress_mac_stall_cycles = 0;
    stress_red_busy_cycles = 0;
    stress_wide_busy_cycles = 0;
    stress_total_stall_cycles = 0;
    stress_stall_streak = 0;
    stress_max_stall_streak = 0;
    stress_e3_valid_cycles = 0;
    stress_r3_valid_cycles = 0;
    stress_w2_valid_cycles = 0;
    stress_total_cycles = 0;
  end

  // VRF Write Contention Detection - FATAL ERROR
  always @(posedge clk) begin
    if (rst_n) begin
      stress_total_cycles <= stress_total_cycles + 1;

      // Count valid outputs from each pipeline
      if (e3_valid) stress_e3_valid_cycles <= stress_e3_valid_cycles + 1;
      if (r3_valid) stress_r3_valid_cycles <= stress_r3_valid_cycles + 1;
      if (w2_valid) stress_w2_valid_cycles <= stress_w2_valid_cycles + 1;

      // Count stall cycles
      if (mul_stall) stress_mul_stall_cycles <= stress_mul_stall_cycles + 1;
      if (mac_stall) stress_mac_stall_cycles <= stress_mac_stall_cycles + 1;
      if (red_state != RED_IDLE) stress_red_busy_cycles <= stress_red_busy_cycles + 1;
      if (wide_state != WIDE_IDLE) stress_wide_busy_cycles <= stress_wide_busy_cycles + 1;

      // Track stall streaks for deadlock detection
      if (multicycle_busy_o || stall_i) begin
        stress_stall_streak <= stress_stall_streak + 1;
        stress_total_stall_cycles <= stress_total_stall_cycles + 1;
        if (stress_stall_streak + 1 > stress_max_stall_streak)
          stress_max_stall_streak <= stress_stall_streak + 1;
        // Deadlock warning
        if (stress_stall_streak == DEADLOCK_THRESHOLD) begin
          $display("[%0t] WARNING: Possible deadlock detected! Stall streak = %0d cycles",
                   $time, stress_stall_streak);
          $display("         mul_stall=%b mac_stall=%b red_state=%0d wide_state=%0d",
                   mul_stall, mac_stall, red_state, wide_state);
          $display("         e1_valid=%b e1m_valid=%b e2_valid=%b e3_valid=%b",
                   e1_valid, e1m_valid, e2_valid, e3_valid);
        end
      end else begin
        stress_stall_streak <= 0;
      end

      // VRF WRITE CONTENTION DETECTION
      if (e3_valid && r3_valid) begin
        stress_vrf_contentions <= stress_vrf_contentions + 1;
        stress_e3_r3_contentions <= stress_e3_r3_contentions + 1;
        $display("[%0t] FATAL: VRF WRITE CONTENTION! e3_valid && r3_valid", $time);
        $display("         e3_vd=%0d e3_result[31:0]=%08h", e3_vd, e3_result[31:0]);
        $display("         r3_vd=%0d r3_result[31:0]=%08h", r3_vd, red_result_packed[31:0]);
        $display("         Pipeline state: e1=%b e1m=%b e2=%b red_state=%0d wide_state=%0d",
                 e1_valid, e1m_valid, e2_valid, red_state, wide_state);
      end

      if (e3_valid && w2_valid) begin
        stress_vrf_contentions <= stress_vrf_contentions + 1;
        stress_e3_w2_contentions <= stress_e3_w2_contentions + 1;
        $display("[%0t] FATAL: VRF WRITE CONTENTION! e3_valid && w2_valid", $time);
        $display("         e3_vd=%0d e3_result[31:0]=%08h", e3_vd, e3_result[31:0]);
        $display("         w2_vd=%0d w2_result[31:0]=%08h", w2_vd, w2_result[31:0]);
        $display("         Pipeline state: e1=%b e1m=%b e2=%b red_state=%0d wide_state=%0d",
                 e1_valid, e1m_valid, e2_valid, red_state, wide_state);
      end

      if (r3_valid && w2_valid) begin
        stress_vrf_contentions <= stress_vrf_contentions + 1;
        stress_r3_w2_contentions <= stress_r3_w2_contentions + 1;
        $display("[%0t] FATAL: VRF WRITE CONTENTION! r3_valid && w2_valid", $time);
        $display("         r3_vd=%0d r3_result[31:0]=%08h", r3_vd, red_result_packed[31:0]);
        $display("         w2_vd=%0d w2_result[31:0]=%08h", w2_vd, w2_result[31:0]);
        $display("         Pipeline state: e1=%b e1m=%b e2=%b red_state=%0d wide_state=%0d",
                 e1_valid, e1m_valid, e2_valid, red_state, wide_state);
      end
    end
  end

  // Final statistics report
  final begin
    $display("\n==================================================");
    $display("STRESS TEST INSTRUMENTATION - FINAL REPORT");
    $display("==================================================");
    $display("Total cycles:              %0d", stress_total_cycles);
    $display("");
    $display("VRF Write Contentions:     %0d", stress_vrf_contentions);
    $display("  - e3 && r3 contentions:  %0d", stress_e3_r3_contentions);
    $display("  - e3 && w2 contentions:  %0d", stress_e3_w2_contentions);
    $display("  - r3 && w2 contentions:  %0d", stress_r3_w2_contentions);
    $display("");
    $display("Pipeline Valid Cycles:");
    $display("  - e3_valid cycles:       %0d", stress_e3_valid_cycles);
    $display("  - r3_valid cycles:       %0d", stress_r3_valid_cycles);
    $display("  - w2_valid cycles:       %0d", stress_w2_valid_cycles);
    $display("");
    $display("Stall Statistics:");
    $display("  - mul_stall cycles:      %0d", stress_mul_stall_cycles);
    $display("  - mac_stall cycles:      %0d", stress_mac_stall_cycles);
    $display("  - red_busy cycles:       %0d", stress_red_busy_cycles);
    $display("  - wide_busy cycles:      %0d", stress_wide_busy_cycles);
    $display("  - total stall cycles:    %0d", stress_total_stall_cycles);
    $display("  - max stall streak:      %0d", stress_max_stall_streak);
    $display("==================================================\n");
  end
  `endif

endmodule
