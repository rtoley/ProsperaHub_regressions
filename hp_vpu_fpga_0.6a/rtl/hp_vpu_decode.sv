//==============================================================================
// Hyperplane VPU - Instruction Decode Unit
// 2-stage pipeline (D1: pre-decode, D2: full decode)
// Optimized for 2 GHz with minimal combinational logic per stage
//==============================================================================

module hp_vpu_decode
  import hp_vpu_pkg::*;
#(
  parameter int unsigned VLEN = hp_vpu_pkg::VLEN
)(
  input  logic                      clk,
  input  logic                      rst_n,
  input  logic                      stall_i,
  input  logic                      flush_i,

  // From Instruction Queue
  input  logic                      valid_i,
  input  logic [31:0]               instr_i,
  input  logic [CVXIF_ID_W-1:0]     id_i,
  input  logic [31:0]               rs1_i,
  input  logic [31:0]               rs2_i,

  // CSRs
  input  logic [31:0]               vtype_i,
  input  logic [31:0]               vl_i,

  // Decoded outputs (D2 stage)
  output logic                      valid_o,
  output logic                      valid_op_o,   // v0.3c: Instruction is valid/supported (not OP_NOP)
  output vpu_op_e                   op_o,
  output logic [4:0]                vd_o,
  output logic [4:0]                vs1_o,
  output logic [4:0]                vs2_o,
  output logic [4:0]                vs3_o,
  output logic                      vm_o,
  output sew_e                      sew_o,
  output lmul_e                     lmul_o,
  output logic [31:0]               scalar_o,
  output logic [CVXIF_ID_W-1:0]     id_o,
  output logic                      is_load_o,
  output logic                      is_store_o,
  output logic                      is_vx_o,    // Vector-scalar operation
  output logic                      pop_iq_o,

  // Multicycle execute signals (v0.13+)
  output logic                      is_multicycle_o,  // Operation needs multiple execute cycles
  output logic [2:0]                multicycle_count_o, // Extra cycles needed (0=single cycle)

  // LMUL micro-op signals (v1.2)
  output logic                      is_last_uop_o,    // Last micro-op of LMUL group
  output logic [2:0]                uop_index_o,      // Current micro-op index (0 to 7)
  output logic                      uop_busy_o        // Busy with multi-µop sequence (stall issue)
);

  //==========================================================================
  // Instruction Fields (combinational)
  //==========================================================================
  wire [6:0] opcode = instr_i[6:0];
  wire [4:0] rd_vd  = instr_i[11:7];
  wire [2:0] funct3 = instr_i[14:12];
  wire [4:0] rs1_vs1= instr_i[19:15];
  wire [4:0] rs2_vs2= instr_i[24:20];
  wire       vm     = instr_i[25];
  wire [5:0] funct6 = instr_i[31:26];

  // Quick instruction type detection (D1)
  wire is_vec_load  = (opcode == OPC_LOAD_FP);
  wire is_vec_store = (opcode == OPC_STORE_FP);
  wire is_vec_arith = (opcode == OPC_VECTOR) && (funct3 != F3_OPCFG);
  wire is_vec_cfg   = (opcode == OPC_VECTOR) && (funct3 == F3_OPCFG);
  wire is_vec_op    = is_vec_load | is_vec_store | is_vec_arith | is_vec_cfg;

  //==========================================================================
  // D1 Stage Registers (Pre-decode)
  //==========================================================================
  logic        d1_valid_q;
  logic [31:0] d1_instr_q;
  logic [CVXIF_ID_W-1:0] d1_id_q;
  logic [31:0] d1_rs1_q, d1_rs2_q;
  logic        d1_is_load_q, d1_is_store_q, d1_is_arith_q;
  sew_e        d1_sew_q;
  lmul_e       d1_lmul_q;

  // v1.2: LMUL micro-op support signals
  logic        d1_multi_uop_q;  // Registered flag for LMUL > 1 (timing optimization)

  // Forward declaration of uop_active and uop_count for D1 logic
  logic uop_active;
  logic [2:0] uop_count;
  logic [2:0] uop_total;
  wire [3:0] uop_total_eff = (uop_total == 3'd0) ? 4'd8 : {1'b0, uop_total};

  // Compute last µop index correctly (handles LMUL=8 where uop_total_eff=8)
  wire [2:0] last_uop_idx = (uop_total == 3'd0) ? 3'd7 : (uop_total - 3'd1);

  // Detect when last µop is being issued
  wire is_last_uop_cycle = uop_active && (uop_count == last_uop_idx);

  // Hold D1 during multi-µop sequence
  wire starting_uops = d1_valid_q && !uop_active && d1_multi_uop_q;
  wire hold_d1 = uop_active && !is_last_uop_cycle;

  // Pre-compute if incoming LMUL needs multi-µop (LMUL > 1)
  // LMUL encoding: 000=1, 001=2, 010=4, 011=8, 1xx=fractional
  wire incoming_needs_multi_uop = !vtype_i[2] && (vtype_i[1] || vtype_i[0]);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      d1_valid_q    <= 1'b0;
      d1_instr_q    <= '0;
      d1_id_q       <= '0;
      d1_rs1_q      <= '0;
      d1_rs2_q      <= '0;
      d1_is_load_q  <= 1'b0;
      d1_is_store_q <= 1'b0;
      d1_is_arith_q <= 1'b0;
      d1_sew_q      <= SEW_8;
      d1_lmul_q     <= LMUL_1;
      d1_multi_uop_q <= 1'b0;
    end else if (flush_i) begin
      d1_valid_q <= 1'b0;
      d1_multi_uop_q <= 1'b0;
    end else if (!stall_i) begin
      // v1.2: Handle LMUL micro-op sequencing
      if (is_last_uop_cycle) begin
        // Last micro-op completing - clear D1
        d1_valid_q     <= 1'b0;
        d1_lmul_q      <= LMUL_1;  // Reset to avoid stale alignment
        d1_multi_uop_q <= 1'b0;
      end else if (!hold_d1 && !starting_uops) begin
        // Normal D1 update
        d1_valid_q    <= valid_i && is_vec_op;
        d1_instr_q    <= instr_i;
        d1_id_q       <= id_i;
        d1_rs1_q      <= rs1_i;
        d1_rs2_q      <= rs2_i;
        d1_is_load_q  <= is_vec_load;
        d1_is_store_q <= is_vec_store;
        d1_is_arith_q <= is_vec_arith;
        d1_sew_q      <= sew_e'(vtype_i[5:3]);
        d1_lmul_q     <= lmul_e'(vtype_i[2:0]);
        d1_multi_uop_q <= incoming_needs_multi_uop;
      end
      // else: hold_d1 or starting_uops - keep D1 state
    end
  end

  // Pop IQ when entering D1 (only when not busy with multi-µop sequence)
  assign pop_iq_o = valid_i && is_vec_op && !stall_i && !hold_d1 && !starting_uops;
  assign uop_busy_o = uop_active || starting_uops;

  //==========================================================================
  // D2 Stage: Full Decode
  //==========================================================================
  // Re-extract fields from D1 instruction
  wire [4:0] d1_vd     = d1_instr_q[11:7];
  wire [2:0] d1_funct3 = d1_instr_q[14:12];
  wire [4:0] d1_vs1    = d1_instr_q[19:15];
  wire [4:0] d1_vs2    = d1_instr_q[24:20];
  wire       d1_vm     = d1_instr_q[25];
  wire [5:0] d1_funct6 = d1_instr_q[31:26];

  // Decode operation (combinational, but on registered inputs)
  vpu_op_e decoded_op;

  always_comb begin
    decoded_op = OP_NOP;

    if (d1_is_load_q) begin
      decoded_op = OP_VLOAD;
    end else if (d1_is_store_q) begin
      decoded_op = OP_VSTORE;
    end else if (d1_is_arith_q) begin
      case (d1_funct3)
        F3_OPIVV, F3_OPIVX, F3_OPIVI: begin
          case (d1_funct6)
            F6_VADD:  decoded_op = OP_VADD;
            F6_VSUB:  decoded_op = OP_VSUB;
            F6_VRSUB: decoded_op = OP_VRSUB;  // Reverse subtract (vx/vi only)
            F6_VAND:  decoded_op = OP_VAND;
            F6_VOR:   decoded_op = OP_VOR;
            F6_VXOR:  decoded_op = OP_VXOR;
            F6_VMINU: decoded_op = OP_VMINU;
            F6_VMIN:  decoded_op = OP_VMIN;
            F6_VMAXU: decoded_op = OP_VMAXU;
            F6_VMAX:  decoded_op = OP_VMAX;
            F6_VSLL:  decoded_op = OP_VSLL;
            F6_VSRL:  decoded_op = OP_VSRL;
            F6_VSRA:  decoded_op = OP_VSRA;
            F6_VMUL:  decoded_op = OP_VMUL;
            F6_VMULH: decoded_op = OP_VMULH;
            // Note: F6_VMACC removed - only valid in OPMVV, not OPIVV
            // Comparison operations
            F6_VMSEQ:  decoded_op = OP_VMSEQ;
            F6_VMSNE:  decoded_op = OP_VMSNE;
            F6_VMSLT:  decoded_op = OP_VMSLT;
            F6_VMSLTU: decoded_op = OP_VMSLTU;
            F6_VMSLE:  decoded_op = OP_VMSLE;
            F6_VMSLEU: decoded_op = OP_VMSLEU;
            F6_VMSGT:  decoded_op = OP_VMSGT;
            F6_VMSGTU: decoded_op = OP_VMSGTU;
            F6_VRGATHER:  decoded_op = OP_VRGATHER;
            // vslideup/vrgatherei16 share funct6=001110 but differ by funct3
            // OPIVV: vrgatherei16.vv (v0.15)
            // OPIVX/OPIVI: vslideup.vx/vi
            F6_VSLIDEUP: begin
              if (d1_funct3 == F3_OPIVV)
                decoded_op = OP_VRGATHEREI16;
              else
                decoded_op = OP_VSLIDEUP;
            end
            F6_VSLIDEDN:  decoded_op = OP_VSLIDEDN;
            // Fixed-point operations (v0.6+)
            F6_VSADDU:  decoded_op = OP_VSADDU;
            F6_VSADD:   decoded_op = OP_VSADD;
            F6_VSSUBU:  decoded_op = OP_VSSUBU;
            F6_VSSUB:   decoded_op = OP_VSSUB;
            F6_VSSRL:   decoded_op = OP_VSSRL;
            F6_VSSRA:   decoded_op = OP_VSSRA;
            F6_VNCLIPU: decoded_op = OP_VNCLIPU;
            F6_VNCLIP:  decoded_op = OP_VNCLIP;
            // vmerge/vmv.v.v (v0.10+, v0.15: proper vmerge support)
            // vm=0: vmerge (select based on mask)
            // vm=1: vmv.v.v/x/i (copy all elements)
            F6_VMERGE: begin
              if (d1_vm)
                decoded_op = OP_VMV;
              else
                decoded_op = OP_VMERGE;
            end
            // v0.17: Widening add/sub (SEW->2*SEW)
            F6_VWADDU: decoded_op = OP_VWADDU;
            F6_VWADD:  decoded_op = OP_VWADD;
            F6_VWSUBU: decoded_op = OP_VWSUBU;
            F6_VWSUB:  decoded_op = OP_VWSUB;
            // v0.18: Narrowing shifts (2*SEW->SEW)
            F6_VNSRL:  decoded_op = OP_VNSRL;
            F6_VNSRA:  decoded_op = OP_VNSRA;
            default:  decoded_op = OP_NOP;
          endcase
        end
        F3_OPMVV: begin
          // Multiply and reduction operations
          case (d1_funct6)
            F6_VMUL:     decoded_op = OP_VMUL;
            F6_VMULH:    decoded_op = OP_VMULH;
            F6_VMULHU:   decoded_op = OP_VMULHU;
            F6_VMULHSU:  decoded_op = OP_VMULHSU;  // Multiply high signed*unsigned (v0.10+)
            // vcpop.m / vfirst.m (v0.15) - funct6=010000, vs1 selects operation
            F6_VCPOP_VFIRST: begin
              case (d1_vs1)
                5'b10000: decoded_op = OP_VCPOP;   // vcpop.m
                5'b10001: decoded_op = OP_VFIRST;  // vfirst.m
                default:  decoded_op = OP_NOP;
              endcase
            end
            // vmsbf/vmsif/vmsof/viota/vid.v - funct6=010100 (VMUNARY0)
            // vs1 field selects the operation per RVV spec
            F6_VID: begin
              case (d1_vs1)
                5'b10001: decoded_op = OP_VID;    // vid.v
                5'b10000: decoded_op = OP_VIOTA;  // viota.m
                5'b00001: decoded_op = OP_VMSBF;  // vmsbf.m
                5'b00010: decoded_op = OP_VMSOF;  // vmsof.m
                5'b00011: decoded_op = OP_VMSIF;  // vmsif.m
                default:  decoded_op = OP_NOP;
              endcase
            end
            // MAC family operations
            F6_VMACC:    decoded_op = OP_VMACC;
            F6_VNMSAC:   decoded_op = OP_VNMSAC;
            F6_VMADD:    decoded_op = OP_VMADD;
            F6_VNMSUB:   decoded_op = OP_VNMSUB;
            // Reduction operations
            F6_VREDSUM:  decoded_op = OP_VREDSUM;
            F6_VREDAND:  decoded_op = OP_VREDAND;
            F6_VREDOR:   decoded_op = OP_VREDOR;
            F6_VREDXOR:  decoded_op = OP_VREDXOR;
            F6_VREDMINU: decoded_op = OP_VREDMINU;
            F6_VREDMIN:  decoded_op = OP_VREDMIN;
            F6_VREDMAXU: decoded_op = OP_VREDMAXU;
            F6_VREDMAX:  decoded_op = OP_VREDMAX;
            // Mask-register logical operations
            F6_VMAND:    decoded_op = OP_VMAND_MM;
            F6_VMNAND:   decoded_op = OP_VMNAND_MM;
            F6_VMANDN:   decoded_op = OP_VMANDN_MM;
            F6_VMXOR:    decoded_op = OP_VMXOR_MM;
            F6_VMOR:     decoded_op = OP_VMOR_MM;
            F6_VMNOR:    decoded_op = OP_VMNOR_MM;
            F6_VMORN:    decoded_op = OP_VMORN_MM;
            F6_VMXNOR:   decoded_op = OP_VMXNOR_MM;
            // v0.17: Widening multiply (SEW->2*SEW)
            F6_VWMULU:   decoded_op = OP_VWMULU;
            F6_VWMULSU:  decoded_op = OP_VWMULSU;
            F6_VWMUL:    decoded_op = OP_VWMUL;
            // v0.18: Widening MAC (SEW->2*SEW with accumulate)
            F6_VWMACCU:  decoded_op = OP_VWMACCU;
            F6_VWMACC:   decoded_op = OP_VWMACC;
            F6_VWMACCSU: decoded_op = OP_VWMACCSU;
            // v0.19: LUT-based instructions for LLM inference
            // funct6=010010, vs1 field selects function
            F6_VLUT: begin
              case (d1_vs1)
                5'b00000: decoded_op = OP_VEXP;    // vexp.v
                5'b00001: decoded_op = OP_VRECIP;  // vrecip.v
                5'b00010: decoded_op = OP_VRSQRT;  // vrsqrt.v
                5'b00011: decoded_op = OP_VGELU;   // vgelu.v
                default:  decoded_op = OP_NOP;
              endcase
            end
            // v1.1: INT4 pack/unpack for lower quantization
            F6_VPACK4:   decoded_op = OP_VPACK4;    // vpack4.v (INT8 -> INT4)
            F6_VUNPACK4: decoded_op = OP_VUNPACK4;  // vunpack4.v (INT4 -> INT8)
            F6_VCOMPRESS: decoded_op = OP_VCOMPRESS; // vcompress.vm (compress active elements)
            default:     decoded_op = OP_NOP;
          endcase
        end
        F3_OPMVX: begin
          // v0.15: Vector-scalar operations including slide1
          case (d1_funct6)
            F6_VSLIDE1UP: decoded_op = OP_VSLIDE1UP;  // vslide1up.vx
            F6_VSLIDE1DN: decoded_op = OP_VSLIDE1DN;  // vslide1down.vx
            // MAC operations with scalar
            F6_VMUL:      decoded_op = OP_VMUL;
            F6_VMULH:     decoded_op = OP_VMULH;
            F6_VMULHU:    decoded_op = OP_VMULHU;
            F6_VMULHSU:   decoded_op = OP_VMULHSU;
            F6_VMACC:     decoded_op = OP_VMACC;
            F6_VNMSAC:    decoded_op = OP_VNMSAC;
            F6_VMADD:     decoded_op = OP_VMADD;
            F6_VNMSUB:    decoded_op = OP_VNMSUB;
            // v0.17: Widening multiply (SEW->2*SEW)
            F6_VWMULU:    decoded_op = OP_VWMULU;
            F6_VWMULSU:   decoded_op = OP_VWMULSU;
            F6_VWMUL:     decoded_op = OP_VWMUL;
            // v0.18: Widening MAC (SEW->2*SEW with accumulate)
            F6_VWMACCU:   decoded_op = OP_VWMACCU;
            F6_VWMACC:    decoded_op = OP_VWMACC;
            F6_VWMACCSU:  decoded_op = OP_VWMACCSU;
            default:      decoded_op = OP_NOP;
          endcase
        end
        default: decoded_op = OP_NOP;
      endcase
    end
  end

  // Scalar operand selection
  wire use_rs1 = (d1_funct3 == F3_OPIVX) || (d1_funct3 == F3_OPMVX);
  wire use_imm = (d1_funct3 == F3_OPIVI);
  wire [31:0] imm_sext = {{27{d1_vs1[4]}}, d1_vs1};  // Sign-extend 5-bit immediate

  //==========================================================================
  // Multicycle Operation Detection (v0.13+)
  // Reductions and other complex ops need multiple execute cycles
  //==========================================================================
  logic is_reduction_op;
  logic is_widening_op;  // v0.17: Widening operations
  logic is_multicycle;
  logic [2:0] multicycle_count;

  always_comb begin
    // Detect reduction operations
    is_reduction_op = (decoded_op == OP_VREDSUM)  || (decoded_op == OP_VREDMAX)  ||
                      (decoded_op == OP_VREDMIN)  || (decoded_op == OP_VREDMAXU) ||
                      (decoded_op == OP_VREDMINU) || (decoded_op == OP_VREDAND)  ||
                      (decoded_op == OP_VREDOR)   || (decoded_op == OP_VREDXOR);

    // v0.17: Detect widening operations (need separate pipeline for timing)
    // v0.18: Added widening MAC operations
    is_widening_op = (decoded_op == OP_VWMULU)  || (decoded_op == OP_VWMULSU) ||
                     (decoded_op == OP_VWMUL)   || (decoded_op == OP_VWADDU)  ||
                     (decoded_op == OP_VWADD)   || (decoded_op == OP_VWSUBU)  ||
                     (decoded_op == OP_VWSUB)   || (decoded_op == OP_VWMACCU) ||
                     (decoded_op == OP_VWMACC)  || (decoded_op == OP_VWMACCSU);

    // Multicycle operations and their extra cycle counts
    // Reductions: 2 extra cycles (3 total) for pipelined tree reduction
    // Widening: 1 extra cycle (2 total) for W1->W2 pipeline
    is_multicycle = is_reduction_op || is_widening_op;
    multicycle_count = is_reduction_op ? 3'd2 :
                       is_widening_op  ? 3'd1 : 3'd0;
  end

  //==========================================================================
  // v1.2: LMUL Micro-op Sequencer
  // Decompose LMUL>1 instructions into multiple micro-ops
  //==========================================================================

  // LMUL → µop count mapping
  always_comb begin
    case (d1_lmul_q)
      LMUL_1:   uop_total = 3'd1;
      LMUL_2:   uop_total = 3'd2;
      LMUL_4:   uop_total = 3'd4;
      LMUL_8:   uop_total = 3'd0;  // 0 encodes 8
      default:  uop_total = 3'd1;  // Fractional LMUL
    endcase
  end

  // Sequencer state machine
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      uop_count  <= 3'd0;
      uop_active <= 1'b0;
    end else if (flush_i) begin
      uop_count  <= 3'd0;
      uop_active <= 1'b0;
    end else if (!stall_i) begin
      if (d1_valid_q && !uop_active && uop_total_eff > 4'd1) begin
        // Start multi-µop sequence
        uop_active <= 1'b1;
        uop_count  <= 3'd1;
      end else if (uop_active) begin
        if (uop_count == last_uop_idx) begin
          // Last µop - return to idle
          uop_active <= 1'b0;
          uop_count  <= 3'd0;
        end else begin
          // Advance to next µop
          uop_count <= uop_count + 3'd1;
        end
      end
    end
  end

  // Register group alignment (RVV spec requirement)
  // LMUL=2: base must be even (v0,v2,v4...)
  // LMUL=4: base must be multiple of 4 (v0,v4,v8...)
  // LMUL=8: base must be multiple of 8 (v0,v8,v16,v24)
  wire [4:0] vd_base  = (uop_total_eff == 4'd8) ? {d1_vd[4:3], 3'b0} :
                        (uop_total_eff == 4'd4) ? {d1_vd[4:2], 2'b0} :
                        (uop_total_eff == 4'd2) ? {d1_vd[4:1], 1'b0} : d1_vd;
  wire [4:0] vs1_base = (uop_total_eff == 4'd8) ? {d1_vs1[4:3], 3'b0} :
                        (uop_total_eff == 4'd4) ? {d1_vs1[4:2], 2'b0} :
                        (uop_total_eff == 4'd2) ? {d1_vs1[4:1], 1'b0} : d1_vs1;
  wire [4:0] vs2_base = (uop_total_eff == 4'd8) ? {d1_vs2[4:3], 3'b0} :
                        (uop_total_eff == 4'd4) ? {d1_vs2[4:2], 2'b0} :
                        (uop_total_eff == 4'd2) ? {d1_vs2[4:1], 1'b0} : d1_vs2;

  // Adjusted addresses for current µop
  wire [4:0] vd_eff  = vd_base  + {2'b0, uop_count};
  wire [4:0] vs1_eff = vs1_base + {2'b0, uop_count};
  wire [4:0] vs2_eff = vs2_base + {2'b0, uop_count};

  // Last µop indicator
  // For single µop (LMUL≤1): always last
  // For multi µop (LMUL>1): only when uop_active and on last count
  wire is_last_uop = (uop_total_eff <= 4'd1) || (uop_active && (uop_count == last_uop_idx));

  // Output signals for LMUL micro-ops
  assign is_last_uop_o = is_last_uop;
  assign uop_index_o = uop_count;

  //==========================================================================
  // D2 Stage Registers (Output)
  // v1.2: Use effective register addresses for LMUL micro-ops
  //==========================================================================
  // v0.3c: Track if decoded operation is valid/supported
  wire d2_valid_op = (decoded_op != OP_NOP);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_o    <= 1'b0;
      valid_op_o <= 1'b0;
      op_o       <= OP_NOP;
      vd_o       <= '0;
      vs1_o      <= '0;
      vs2_o      <= '0;
      vs3_o      <= '0;
      vm_o       <= 1'b1;
      sew_o      <= SEW_8;
      lmul_o     <= LMUL_1;
      scalar_o   <= '0;
      id_o       <= '0;
      is_load_o  <= 1'b0;
      is_store_o <= 1'b0;
      is_vx_o    <= 1'b0;
      is_multicycle_o    <= 1'b0;
      multicycle_count_o <= 3'd0;
    end else if (flush_i) begin
      valid_o <= 1'b0;
      valid_op_o <= 1'b0;
      is_multicycle_o <= 1'b0;
    end else if (!stall_i) begin
      // v1.2: Valid on D1 valid OR when continuing multi-µop sequence
      valid_o    <= d1_valid_q || uop_active;
      valid_op_o <= d2_valid_op;
      op_o       <= decoded_op;
      // v1.2: Use effective addresses for LMUL micro-ops
      vd_o       <= vd_eff;
      // v0.5a: For VMUNARY0/VCPOP_VFIRST, vs1 is a function selector, not a register.
      // Zero it out to prevent false RAW hazards in the hazard unit.
      case (decoded_op)
        OP_VID, OP_VIOTA, OP_VMSBF, OP_VMSIF, OP_VMSOF,
        OP_VCPOP, OP_VFIRST:
          vs1_o <= 5'd0;
        default:
          vs1_o <= vs1_eff;
      endcase
      vs2_o      <= vs2_eff;
      vs3_o      <= vd_eff;  // For vmacc, vs3 = vd (also needs adjustment)
      vm_o       <= d1_vm;
      sew_o      <= d1_sew_q;
      lmul_o     <= d1_lmul_q;
      scalar_o   <= use_imm ? imm_sext : d1_rs1_q;
      id_o       <= d1_id_q;
      is_load_o  <= d1_is_load_q;
      is_store_o <= d1_is_store_q;
      is_vx_o    <= use_rs1 || use_imm;  // .vx and .vi operations use scalar
      is_multicycle_o    <= is_multicycle;
      multicycle_count_o <= multicycle_count;
    end
  end

endmodule
