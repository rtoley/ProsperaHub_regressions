//==============================================================================
// Hyperplane VPU - Issue Stage Instruction Checker
//
// Fast combinational decode to determine if an instruction is supported
// BEFORE accepting it into the pipeline. This enables proper CV-X-IF
// accept signaling so the CPU can trap on unsupported instructions.
//
// This is intentionally simple/fast - full decode happens later in pipeline.
//==============================================================================

module hp_vpu_issue_check
  import hp_vpu_pkg::*;
(
  input  logic [31:0] instr_i,          // Instruction to check

  output logic        is_vector_o,      // Is a vector instruction (opcode match)
  output logic        is_supported_o,   // Is a SUPPORTED vector instruction
  output logic        is_config_o       // Is vsetvl/vsetvli/vsetivli
);

  //==========================================================================
  // Instruction Field Extraction
  //==========================================================================
  wire [6:0] opcode = instr_i[6:0];
  wire [2:0] funct3 = instr_i[14:12];
  wire [5:0] funct6 = instr_i[31:26];
  wire [4:0] vs1    = instr_i[19:15];
  wire [4:0] vs2    = instr_i[24:20];

  // Vector opcode
  localparam OPCODE_V = 7'b1010111;

  // funct3 encodings
  localparam F3_OPIVV = 3'b000;
  localparam F3_OPFVV = 3'b001;
  localparam F3_OPMVV = 3'b010;
  localparam F3_OPIVI = 3'b011;
  localparam F3_OPIVX = 3'b100;
  localparam F3_OPFVF = 3'b101;
  localparam F3_OPMVX = 3'b110;
  localparam F3_OPCFG = 3'b111;

  //==========================================================================
  // Basic Classification
  //==========================================================================
  assign is_vector_o = (opcode == OPCODE_V);
  assign is_config_o = is_vector_o && (funct3 == F3_OPCFG);

  //==========================================================================
  // Supported Instruction Check
  //==========================================================================
  logic supported_opivv, supported_opivx, supported_opivi;
  logic supported_opmvv, supported_opmvx;

  // OPIVV supported funct6 values
  always_comb begin
    supported_opivv = 1'b0;
    case (funct6)
      6'b000000: supported_opivv = 1'b1;  // vadd
      6'b000010: supported_opivv = 1'b1;  // vsub
      6'b000011: supported_opivv = 1'b1;  // vrsub
      6'b000100: supported_opivv = 1'b1;  // vminu
      6'b000101: supported_opivv = 1'b1;  // vmin
      6'b000110: supported_opivv = 1'b1;  // vmaxu
      6'b000111: supported_opivv = 1'b1;  // vmax
      6'b001001: supported_opivv = 1'b1;  // vand
      6'b001010: supported_opivv = 1'b1;  // vor
      6'b001011: supported_opivv = 1'b1;  // vxor
      6'b001100: supported_opivv = 1'b1;  // vrgather
      6'b001110: supported_opivv = 1'b1;  // vrgatherei16
      6'b010111: supported_opivv = 1'b1;  // vmv/vmerge
      6'b011000: supported_opivv = 1'b1;  // vmseq
      6'b011001: supported_opivv = 1'b1;  // vmsne
      6'b011010: supported_opivv = 1'b1;  // vmsltu
      6'b011011: supported_opivv = 1'b1;  // vmslt
      6'b011100: supported_opivv = 1'b1;  // vmsleu
      6'b011101: supported_opivv = 1'b1;  // vmsle
      6'b100000: supported_opivv = 1'b1;  // vsaddu
      6'b100001: supported_opivv = 1'b1;  // vsadd
      6'b100010: supported_opivv = 1'b1;  // vssubu
      6'b100011: supported_opivv = 1'b1;  // vssub
      6'b100101: supported_opivv = 1'b1;  // vsll
      6'b101000: supported_opivv = 1'b1;  // vsrl
      6'b101001: supported_opivv = 1'b1;  // vsra
      6'b101010: supported_opivv = 1'b1;  // vssrl
      6'b101011: supported_opivv = 1'b1;  // vssra
      6'b101100: supported_opivv = 1'b1;  // vnsrl
      6'b101101: supported_opivv = 1'b1;  // vnsra
      6'b101110: supported_opivv = 1'b1;  // vnclipu
      6'b101111: supported_opivv = 1'b1;  // vnclip
      6'b110000: supported_opivv = 1'b1;  // vwaddu
      6'b110001: supported_opivv = 1'b1;  // vwadd
      6'b110010: supported_opivv = 1'b1;  // vwsubu
      6'b110011: supported_opivv = 1'b1;  // vwsub
      6'b110100: supported_opivv = 1'b1;  // vwaddu.w
      6'b110101: supported_opivv = 1'b1;  // vwadd.w
      6'b110110: supported_opivv = 1'b1;  // vwsubu.w
      6'b110111: supported_opivv = 1'b1;  // vwsub.w
      default:   supported_opivv = 1'b0;
    endcase
  end

  // OPIVX supported funct6 values (similar to OPIVV plus slideup/down)
  always_comb begin
    supported_opivx = 1'b0;
    case (funct6)
      6'b000000: supported_opivx = 1'b1;  // vadd
      6'b000010: supported_opivx = 1'b1;  // vsub
      6'b000011: supported_opivx = 1'b1;  // vrsub
      6'b000100: supported_opivx = 1'b1;  // vminu
      6'b000101: supported_opivx = 1'b1;  // vmin
      6'b000110: supported_opivx = 1'b1;  // vmaxu
      6'b000111: supported_opivx = 1'b1;  // vmax
      6'b001001: supported_opivx = 1'b1;  // vand
      6'b001010: supported_opivx = 1'b1;  // vor
      6'b001011: supported_opivx = 1'b1;  // vxor
      6'b001100: supported_opivx = 1'b1;  // vrgather
      6'b001110: supported_opivx = 1'b1;  // vslideup
      6'b001111: supported_opivx = 1'b1;  // vslidedown
      6'b010111: supported_opivx = 1'b1;  // vmv/vmerge
      6'b011000: supported_opivx = 1'b1;  // vmseq
      6'b011001: supported_opivx = 1'b1;  // vmsne
      6'b011010: supported_opivx = 1'b1;  // vmsltu
      6'b011011: supported_opivx = 1'b1;  // vmslt
      6'b011100: supported_opivx = 1'b1;  // vmsleu
      6'b011101: supported_opivx = 1'b1;  // vmsle
      6'b011110: supported_opivx = 1'b1;  // vmsgtu
      6'b011111: supported_opivx = 1'b1;  // vmsgt
      6'b100000: supported_opivx = 1'b1;  // vsaddu
      6'b100001: supported_opivx = 1'b1;  // vsadd
      6'b100010: supported_opivx = 1'b1;  // vssubu
      6'b100011: supported_opivx = 1'b1;  // vssub
      6'b100101: supported_opivx = 1'b1;  // vsll
      6'b101000: supported_opivx = 1'b1;  // vsrl
      6'b101001: supported_opivx = 1'b1;  // vsra
      6'b101010: supported_opivx = 1'b1;  // vssrl
      6'b101011: supported_opivx = 1'b1;  // vssra
      6'b101100: supported_opivx = 1'b1;  // vnsrl
      6'b101101: supported_opivx = 1'b1;  // vnsra
      6'b101110: supported_opivx = 1'b1;  // vnclipu
      6'b101111: supported_opivx = 1'b1;  // vnclip
      6'b110000: supported_opivx = 1'b1;  // vwaddu
      6'b110001: supported_opivx = 1'b1;  // vwadd
      6'b110010: supported_opivx = 1'b1;  // vwsubu
      6'b110011: supported_opivx = 1'b1;  // vwsub
      6'b110100: supported_opivx = 1'b1;  // vwaddu.w
      6'b110101: supported_opivx = 1'b1;  // vwadd.w
      6'b110110: supported_opivx = 1'b1;  // vwsubu.w
      6'b110111: supported_opivx = 1'b1;  // vwsub.w
      default:   supported_opivx = 1'b0;
    endcase
  end

  // OPIVI supported (immediate versions)
  always_comb begin
    supported_opivi = 1'b0;
    case (funct6)
      6'b000000: supported_opivi = 1'b1;  // vadd
      6'b000011: supported_opivi = 1'b1;  // vrsub
      6'b001001: supported_opivi = 1'b1;  // vand
      6'b001010: supported_opivi = 1'b1;  // vor
      6'b001011: supported_opivi = 1'b1;  // vxor
      6'b001100: supported_opivi = 1'b1;  // vrgather
      6'b001110: supported_opivi = 1'b1;  // vslideup
      6'b001111: supported_opivi = 1'b1;  // vslidedown
      6'b010111: supported_opivi = 1'b1;  // vmv/vmerge
      6'b011000: supported_opivi = 1'b1;  // vmseq
      6'b011001: supported_opivi = 1'b1;  // vmsne
      6'b011100: supported_opivi = 1'b1;  // vmsleu
      6'b011101: supported_opivi = 1'b1;  // vmsle
      6'b011110: supported_opivi = 1'b1;  // vmsgtu
      6'b011111: supported_opivi = 1'b1;  // vmsgt
      6'b100000: supported_opivi = 1'b1;  // vsaddu
      6'b100001: supported_opivi = 1'b1;  // vsadd
      6'b100101: supported_opivi = 1'b1;  // vsll
      6'b101000: supported_opivi = 1'b1;  // vsrl
      6'b101001: supported_opivi = 1'b1;  // vsra
      6'b101010: supported_opivi = 1'b1;  // vssrl
      6'b101011: supported_opivi = 1'b1;  // vssra
      6'b101100: supported_opivi = 1'b1;  // vnsrl
      6'b101101: supported_opivi = 1'b1;  // vnsra
      6'b101110: supported_opivi = 1'b1;  // vnclipu
      6'b101111: supported_opivi = 1'b1;  // vnclip
      default:   supported_opivi = 1'b0;
    endcase
  end

  // OPMVV supported
  always_comb begin
    supported_opmvv = 1'b0;
    case (funct6)
      // Reductions
      6'b000000: supported_opmvv = 1'b1;  // vredsum
      6'b000001: supported_opmvv = 1'b1;  // vredand
      6'b000010: supported_opmvv = 1'b1;  // vredor
      6'b000011: supported_opmvv = 1'b1;  // vredxor
      6'b000100: supported_opmvv = 1'b1;  // vredminu
      6'b000101: supported_opmvv = 1'b1;  // vredmin
      6'b000110: supported_opmvv = 1'b1;  // vredmaxu
      6'b000111: supported_opmvv = 1'b1;  // vredmax
      // Mask ops
      6'b010000: supported_opmvv = 1'b1;  // vcpop/vfirst (vs1 selects)
      6'b010010: supported_opmvv = 1'b1;  // LUT ops (vexp, vrecip, etc.)
      6'b010011: supported_opmvv = 1'b1;  // vpack4
      6'b010100: supported_opmvv = 1'b1;  // vmsbf/vmsif/vmsof/vid
      6'b010101: supported_opmvv = 1'b1;  // vunpack4
      // Mask logical
      6'b011000: supported_opmvv = 1'b1;  // vmand
      6'b011001: supported_opmvv = 1'b1;  // vmnand
      6'b011010: supported_opmvv = 1'b1;  // vmandn
      6'b011011: supported_opmvv = 1'b1;  // vmxor
      6'b011100: supported_opmvv = 1'b1;  // vmor
      6'b011101: supported_opmvv = 1'b1;  // vmnor
      6'b011110: supported_opmvv = 1'b1;  // vmorn
      6'b011111: supported_opmvv = 1'b1;  // vmxnor
      // Multiply
      6'b100100: supported_opmvv = 1'b1;  // vmulhu
      6'b100101: supported_opmvv = 1'b1;  // vmul
      6'b100110: supported_opmvv = 1'b1;  // vmulhsu
      6'b100111: supported_opmvv = 1'b1;  // vmulh
      // MAC
      6'b101001: supported_opmvv = 1'b1;  // vmadd
      6'b101011: supported_opmvv = 1'b1;  // vnmsub
      6'b101101: supported_opmvv = 1'b1;  // vmacc
      6'b101111: supported_opmvv = 1'b1;  // vnmsac
      // Widening multiply
      6'b111000: supported_opmvv = 1'b1;  // vwmulu
      6'b111010: supported_opmvv = 1'b1;  // vwmulsu
      6'b111011: supported_opmvv = 1'b1;  // vwmul
      // Widening MAC
      6'b111100: supported_opmvv = 1'b1;  // vwmaccu
      6'b111101: supported_opmvv = 1'b1;  // vwmacc
      6'b111110: supported_opmvv = 1'b1;  // vwmaccsu
      default:   supported_opmvv = 1'b0;
    endcase
  end

  // OPMVX supported (scalar versions)
  always_comb begin
    supported_opmvx = 1'b0;
    case (funct6)
      6'b001110: supported_opmvx = 1'b1;  // vslide1up
      6'b001111: supported_opmvx = 1'b1;  // vslide1down
      // Multiply
      6'b100100: supported_opmvx = 1'b1;  // vmulhu
      6'b100101: supported_opmvx = 1'b1;  // vmul
      6'b100110: supported_opmvx = 1'b1;  // vmulhsu
      6'b100111: supported_opmvx = 1'b1;  // vmulh
      // MAC
      6'b101001: supported_opmvx = 1'b1;  // vmadd
      6'b101011: supported_opmvx = 1'b1;  // vnmsub
      6'b101101: supported_opmvx = 1'b1;  // vmacc
      6'b101111: supported_opmvx = 1'b1;  // vnmsac
      // Widening multiply
      6'b111000: supported_opmvx = 1'b1;  // vwmulu
      6'b111010: supported_opmvx = 1'b1;  // vwmulsu
      6'b111011: supported_opmvx = 1'b1;  // vwmul
      // Widening MAC
      6'b111100: supported_opmvx = 1'b1;  // vwmaccu
      6'b111101: supported_opmvx = 1'b1;  // vwmacc
      6'b111110: supported_opmvx = 1'b1;  // vwmaccsu
      default:   supported_opmvx = 1'b0;
    endcase
  end

  //==========================================================================
  // Final Support Determination
  //==========================================================================
  always_comb begin
    if (!is_vector_o) begin
      is_supported_o = 1'b0;  // Not a vector instruction
    end else if (is_config_o) begin
      is_supported_o = 1'b1;  // Config instructions always supported
    end else begin
      case (funct3)
        F3_OPIVV: is_supported_o = supported_opivv;
        F3_OPIVX: is_supported_o = supported_opivx;
        F3_OPIVI: is_supported_o = supported_opivi;
        F3_OPMVV: is_supported_o = supported_opmvv;
        F3_OPMVX: is_supported_o = supported_opmvx;
        F3_OPFVV: is_supported_o = 1'b0;  // No FP support
        F3_OPFVF: is_supported_o = 1'b0;  // No FP support
        default:  is_supported_o = 1'b0;
      endcase
    end
  end

endmodule
