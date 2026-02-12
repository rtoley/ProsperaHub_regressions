#!/usr/bin/env python3
"""
Generate hp_vpu_pkg.sv from vpu_config.json
Ensures single source of truth for VPU parameters

Usage:
  python3 gen_pkg.py                     # Uses config/vpu_config.json
  python3 gen_pkg.py config/my_config.json  # Uses specified config
"""

import json
import os
import sys
from datetime import datetime

def main():
    # Find project root (where config/vpu_config.json lives)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)

    # Allow specifying config file as argument
    if len(sys.argv) > 1:
        config_path = sys.argv[1]
        if not os.path.isabs(config_path):
            config_path = os.path.join(project_root, config_path)
    else:
        config_path = os.path.join(project_root, 'config', 'vpu_config.json')

    output_path = os.path.join(project_root, 'generated', 'hp_vpu_pkg.sv')

    print(f"Generating hp_vpu_pkg.sv from {os.path.basename(config_path)}...")

    # Load config
    if not os.path.exists(config_path):
        print(f"ERROR: Config file not found: {config_path}")
        sys.exit(1)

    with open(config_path, 'r') as f:
        config = json.load(f)

    # Extract parameters
    meta = config.get('meta', {})
    version = meta.get('version', '0.0.0')

    params = config.get('parameters', {})
    VLEN = params.get('VLEN', 256)
    DLEN = params.get('DLEN', 256)
    NUM_REGS = params.get('NUM_REGS', 32)
    CVXIF_ID_W = params.get('CVXIF_ID_W', 8)

    features = config.get('features', {})
    ENABLE_VMADD = 1 if features.get('vmadd_vnmsub', True) else 0
    ENABLE_WIDENING = 1 if features.get('widening', True) else 0
    ENABLE_FRAC_LMUL = 1 if features.get('fractional_lmul', False) else 0
    ENABLE_INT4_PACK = 1 if features.get('int4_pack_unpack', False) else 0
    ENABLE_LMUL_MULTI_UOP = 1 if features.get('lmul_multi_uop', False) else 0
    ENABLE_CSR = 1 if features.get('enable_csr', False) else 0
    SPLIT_REDUCTION = 1 if features.get('split_reduction_pipeline', False) else 0

    # Test configuration
    test_config = config.get('test', {})
    STRESS_TEST_MAX = test_config.get('stress_test_max_instructions', 1000)
    ENABLE_LONG_TEST = 1 if test_config.get('enable_long_stress_test', False) else 0
    ENABLE_VCD_DUMP = 1 if test_config.get('enable_vcd_dump', False) else 0

    # Derive parameters
    NLANES = DLEN // 64
    ELEN = 32
    VLMAX_8 = VLEN // 8
    VLMAX_16 = VLEN // 16
    VLMAX_32 = VLEN // 32

    # Generate package with include guard
    pkg_content = f'''//============================================================================
// Hyperplane VPU Package - AUTO-GENERATED
// DO NOT EDIT - Generated from config/vpu_config.json
// Run: python3 scripts/gen_pkg.py
// Version: {version}
// Generated: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
//============================================================================

`timescale 1ns/1ps

`ifndef HP_VPU_PKG_SV
`define HP_VPU_PKG_SV

package hp_vpu_pkg;

  //==========================================================================
  // Core Parameters (from vpu_config.json)
  //==========================================================================
  parameter int unsigned VLEN   = {VLEN};   // Vector register length in bits
  parameter int unsigned DLEN   = {DLEN};   // Datapath width in bits
  parameter int unsigned NLANES = {NLANES}; // Parallel lanes (DLEN/64)
  parameter int unsigned ELEN   = {ELEN};   // Max element width (bits)
  parameter int unsigned NUM_REGS = {NUM_REGS}; // Number of vector registers

  // Derived parameters
  localparam int VLENB = VLEN / 8;        // VLEN in bytes
  localparam int VLMAX_8 = VLEN / 8;      // Max VL for SEW=8 ({VLMAX_8})
  localparam int VLMAX_16 = VLEN / 16;    // Max VL for SEW=16 ({VLMAX_16})
  localparam int VLMAX_32 = VLEN / 32;    // Max VL for SEW=32 ({VLMAX_32})

  // Interface parameters
  localparam int CVXIF_ID_W = {CVXIF_ID_W};  // CV-X-IF transaction ID width

  // Feature enables
  parameter bit ENABLE_VMADD = {ENABLE_VMADD};  // Enable vmadd/vnmsub (extra multipliers)
  parameter bit ENABLE_WIDENING = {ENABLE_WIDENING};  // Enable widening operations (v0.17)
  parameter bit ENABLE_FRAC_LMUL = {ENABLE_FRAC_LMUL};  // Enable fractional LMUL (v1.1)
  parameter bit ENABLE_INT4_PACK = {ENABLE_INT4_PACK};  // Enable INT4 pack/unpack (v1.1)
  parameter bit ENABLE_LMUL_MULTI_UOP = {ENABLE_LMUL_MULTI_UOP};  // Enable LMUL>1 via micro-ops (v1.2)
  parameter bit ENABLE_CSR = {ENABLE_CSR};  // Enable CSR module (saves ~500 cells if disabled)
  parameter bit SPLIT_REDUCTION_PIPELINE = {SPLIT_REDUCTION}; // Split reduction pipeline (v0.4)

  // Test configuration (for testbench)
  parameter int STRESS_TEST_MAX = {STRESS_TEST_MAX};  // Max instructions for stress test
  parameter bit ENABLE_LONG_TEST = {ENABLE_LONG_TEST};  // Enable 10K instruction test
  parameter bit ENABLE_VCD_DUMP = {ENABLE_VCD_DUMP};  // Enable VCD waveform dump

  //==========================================================================
  // RVV Encoding Constants
  //==========================================================================

  // Major opcodes
  localparam logic [6:0] OPC_LOAD_FP  = 7'b0000111;
  localparam logic [6:0] OPC_STORE_FP = 7'b0100111;
  localparam logic [6:0] OPC_VECTOR   = 7'b1010111;

  // Vector arithmetic funct3
  localparam logic [2:0] F3_OPIVV = 3'b000;
  localparam logic [2:0] F3_OPFVV = 3'b001;
  localparam logic [2:0] F3_OPMVV = 3'b010;
  localparam logic [2:0] F3_OPIVI = 3'b011;
  localparam logic [2:0] F3_OPIVX = 3'b100;
  localparam logic [2:0] F3_OPFVF = 3'b101;
  localparam logic [2:0] F3_OPMVX = 3'b110;
  localparam logic [2:0] F3_OPCFG = 3'b111;

  // Load/Store width
  localparam logic [2:0] F3_VLE8  = 3'b000;
  localparam logic [2:0] F3_VLE16 = 3'b101;
  localparam logic [2:0] F3_VLE32 = 3'b110;
  localparam logic [2:0] F3_VLE64 = 3'b111;

  // Funct6 encodings
  localparam logic [5:0] F6_VADD      = 6'b000000;
  localparam logic [5:0] F6_VSUB      = 6'b000010;
  localparam logic [5:0] F6_VRSUB     = 6'b000011;
  localparam logic [5:0] F6_VMINU     = 6'b000100;
  localparam logic [5:0] F6_VMIN      = 6'b000101;
  localparam logic [5:0] F6_VMAXU     = 6'b000110;
  localparam logic [5:0] F6_VMAX      = 6'b000111;
  localparam logic [5:0] F6_VAND      = 6'b001001;
  localparam logic [5:0] F6_VOR       = 6'b001010;
  localparam logic [5:0] F6_VXOR      = 6'b001011;
  localparam logic [5:0] F6_VRGATHER  = 6'b001100;
  localparam logic [5:0] F6_VSLIDEUP  = 6'b001110;
  localparam logic [5:0] F6_VSLIDEDN  = 6'b001111;
  localparam logic [5:0] F6_VMSEQ     = 6'b011000;
  localparam logic [5:0] F6_VMSNE     = 6'b011001;
  localparam logic [5:0] F6_VMSLTU    = 6'b011010;
  localparam logic [5:0] F6_VMSLT     = 6'b011011;
  localparam logic [5:0] F6_VMSLEU    = 6'b011100;
  localparam logic [5:0] F6_VMSLE     = 6'b011101;
  localparam logic [5:0] F6_VMSGTU    = 6'b011110;
  localparam logic [5:0] F6_VMSGT     = 6'b011111;
  localparam logic [5:0] F6_VSLL      = 6'b100101;
  localparam logic [5:0] F6_VSRL      = 6'b101000;
  localparam logic [5:0] F6_VSRA      = 6'b101001;
  localparam logic [5:0] F6_VMUL      = 6'b100101;
  localparam logic [5:0] F6_VMULH     = 6'b100111;
  localparam logic [5:0] F6_VMULHU    = 6'b100100;
  localparam logic [5:0] F6_VMULHSU   = 6'b100110;
  localparam logic [5:0] F6_VMACC     = 6'b101101;
  localparam logic [5:0] F6_VNMSAC    = 6'b101111;
  localparam logic [5:0] F6_VMADD     = 6'b101001;
  localparam logic [5:0] F6_VNMSUB    = 6'b101011;
  localparam logic [5:0] F6_VMERGE    = 6'b010111;
  localparam logic [5:0] F6_VID       = 6'b010100;
  localparam logic [5:0] F6_VREDSUM   = 6'b000000;
  localparam logic [5:0] F6_VREDAND   = 6'b000001;
  localparam logic [5:0] F6_VREDOR    = 6'b000010;
  localparam logic [5:0] F6_VREDXOR   = 6'b000011;
  localparam logic [5:0] F6_VREDMINU  = 6'b000100;
  localparam logic [5:0] F6_VREDMIN   = 6'b000101;
  localparam logic [5:0] F6_VREDMAXU  = 6'b000110;
  localparam logic [5:0] F6_VREDMAX   = 6'b000111;
  localparam logic [5:0] F6_VMANDN    = 6'b011000;
  localparam logic [5:0] F6_VMAND     = 6'b011001;
  localparam logic [5:0] F6_VMOR      = 6'b011010;
  localparam logic [5:0] F6_VMXOR     = 6'b011011;
  localparam logic [5:0] F6_VMORN     = 6'b011100;
  localparam logic [5:0] F6_VMNAND    = 6'b011101;
  localparam logic [5:0] F6_VMNOR     = 6'b011110;
  localparam logic [5:0] F6_VMXNOR    = 6'b011111;
  localparam logic [5:0] F6_VSADDU    = 6'b100000;
  localparam logic [5:0] F6_VSADD     = 6'b100001;
  localparam logic [5:0] F6_VSSUBU    = 6'b100010;
  localparam logic [5:0] F6_VSSUB     = 6'b100011;
  localparam logic [5:0] F6_VSSRL     = 6'b101010;
  localparam logic [5:0] F6_VSSRA     = 6'b101011;
  localparam logic [5:0] F6_VNCLIPU   = 6'b101110;
  localparam logic [5:0] F6_VNCLIP    = 6'b101111;
  // v0.15: New mask/permutation funct6 encodings
  localparam logic [5:0] F6_VCPOP_VFIRST = 6'b010000;  // vcpop.m/vfirst.m (vs1 selects)
  localparam logic [5:0] F6_VMUNARY0   = 6'b010100;    // vmsbf/vmsif/vmsof/vid (vs1 selects)
  localparam logic [5:0] F6_VSLIDE1UP  = 6'b001110;    // vslide1up.vx (OPMVX)
  localparam logic [5:0] F6_VSLIDE1DN  = 6'b001111;    // vslide1down.vx (OPMVX)
  localparam logic [5:0] F6_VRGATHEREI16 = 6'b001110;  // vrgatherei16.vv (OPIVV)

  // v0.17: Widening arithmetic funct6 encodings (OPIVV/OPIVX)
  localparam logic [5:0] F6_VWADDU    = 6'b110000;    // vwaddu.vv/vx
  localparam logic [5:0] F6_VWADD     = 6'b110001;    // vwadd.vv/vx
  localparam logic [5:0] F6_VWSUBU    = 6'b110010;    // vwsubu.vv/vx
  localparam logic [5:0] F6_VWSUB     = 6'b110011;    // vwsub.vv/vx

  // v0.17: Widening multiply funct6 encodings (OPMVV/OPMVX)
  localparam logic [5:0] F6_VWMULU    = 6'b111000;    // vwmulu.vv/vx
  localparam logic [5:0] F6_VWMULSU   = 6'b111010;    // vwmulsu.vv/vx
  localparam logic [5:0] F6_VWMUL     = 6'b111011;    // vwmul.vv/vx

  // v0.18: Widening MAC funct6 encodings (OPMVV/OPMVX)
  localparam logic [5:0] F6_VWMACCU   = 6'b111100;    // vwmaccu.vv/vx
  localparam logic [5:0] F6_VWMACC    = 6'b111101;    // vwmacc.vv/vx
  localparam logic [5:0] F6_VWMACCSU  = 6'b111111;    // vwmaccsu.vv/vx

  // v0.18: Narrowing shift funct6 encodings (OPIVV/OPIVX/OPIVI)
  localparam logic [5:0] F6_VNSRL     = 6'b101100;    // vnsrl.wv/wx/wi
  localparam logic [5:0] F6_VNSRA     = 6'b101101;    // vnsra.wv/wx/wi

  // v0.19: LUT-based instructions for LLM inference (OPMVV, vs1 selects function)
  localparam logic [5:0] F6_VLUT      = 6'b010010;    // vexp/vrecip/vrsqrt/vgelu.v
  // vs1 field encoding for LUT functions:
  //   00000 = vexp.v    (exponential)
  //   00001 = vrecip.v  (reciprocal)
  //   00010 = vrsqrt.v  (inverse sqrt)
  //   00011 = vgelu.v   (GELU activation)

  // v1.1: INT4 pack/unpack instructions (OPMVV, custom encoding)
  localparam logic [5:0] F6_VPACK4    = 6'b010011;    // vpack4.v (INT8 -> INT4)
  localparam logic [5:0] F6_VUNPACK4  = 6'b010101;    // vunpack4.v (INT4 -> INT8)

  // v0.5a: Compress/permutation instructions
  localparam logic [5:0] F6_VCOMPRESS  = 6'b010111;    // vcompress.vm (OPMVV only)

  // SEW encoding
  typedef enum logic [2:0] {{
    SEW_8  = 3'b000,
    SEW_16 = 3'b001,
    SEW_32 = 3'b010,
    SEW_64 = 3'b011
  }} sew_e;

  // LMUL encoding
  typedef enum logic [2:0] {{
    LMUL_1   = 3'b000,
    LMUL_2   = 3'b001,
    LMUL_4   = 3'b010,
    LMUL_8   = 3'b011,
    LMUL_F8  = 3'b101,
    LMUL_F4  = 3'b110,
    LMUL_F2  = 3'b111
  }} lmul_e;

  //==========================================================================
  // Internal Operation Encoding (v0.15: expanded to 7 bits)
  //==========================================================================
  typedef enum logic [6:0] {{
    OP_NOP      = 7'd0,  OP_VLOAD    = 7'd1,  OP_VSTORE   = 7'd2,
    OP_VADD     = 7'd3,  OP_VSUB     = 7'd4,  OP_VMUL     = 7'd5,
    OP_VMACC    = 7'd6,  OP_VAND     = 7'd7,  OP_VOR      = 7'd8,
    OP_VXOR     = 7'd9,  OP_VSLL     = 7'd10, OP_VSRL     = 7'd11,
    OP_VSRA     = 7'd12, OP_VMIN     = 7'd13, OP_VMAX     = 7'd14,
    OP_VMINU    = 7'd15, OP_VMAXU    = 7'd16, OP_VMULH    = 7'd17,
    OP_VRGATHER = 7'd18, OP_VSLIDEUP = 7'd19, OP_VSLIDEDN = 7'd20,
    OP_VREDSUM  = 7'd21, OP_VREDMAX  = 7'd22, OP_VREDMIN  = 7'd23,
    OP_VMSEQ    = 7'd24, OP_VMSNE    = 7'd25, OP_VMSLT    = 7'd26,
    OP_VMSLTU   = 7'd27, OP_VMSLE    = 7'd28, OP_VMSLEU   = 7'd29,
    OP_VMSGT    = 7'd30, OP_VMSGTU   = 7'd31, OP_VMASK    = 7'd32,
    OP_VCONFIG  = 7'd33, OP_VID      = 7'd34, OP_VSLIDE   = 7'd35,
    OP_VMULHU   = 7'd36, OP_VREDMAXU = 7'd37, OP_VREDMINU = 7'd38,
    OP_VREDAND  = 7'd39, OP_VREDOR   = 7'd40, OP_VREDXOR  = 7'd41,
    OP_VMAND_MM  = 7'd42, OP_VMNAND_MM = 7'd43, OP_VMANDN_MM = 7'd44,
    OP_VMXOR_MM  = 7'd45, OP_VMOR_MM   = 7'd46, OP_VMNOR_MM  = 7'd47,
    OP_VMORN_MM  = 7'd48, OP_VMXNOR_MM = 7'd49,
    OP_VSADDU   = 7'd50, OP_VSADD    = 7'd51, OP_VSSUBU   = 7'd52,
    OP_VSSUB    = 7'd53, OP_VSSRL    = 7'd54, OP_VSSRA    = 7'd55,
    OP_VNCLIPU  = 7'd56, OP_VNCLIP   = 7'd57, OP_VNMSAC   = 7'd58,
    OP_VMADD    = 7'd59, OP_VNMSUB   = 7'd60, OP_VRSUB    = 7'd61,
    OP_VMULHSU  = 7'd62, OP_VMV      = 7'd63,
    // v0.15: New instructions
    OP_VMERGE   = 7'd64,  // vmerge.vvm/vxm/vim (mask-based merge)
    OP_VCPOP    = 7'd65,  // vcpop.m (population count)
    OP_VFIRST   = 7'd66,  // vfirst.m (find first set)
    OP_VMSBF    = 7'd67,  // vmsbf.m (set-before-first)
    OP_VMSIF    = 7'd68,  // vmsif.m (set-including-first)
    OP_VMSOF    = 7'd69,  // vmsof.m (set-only-first)
    OP_VSLIDE1UP = 7'd70, // vslide1up.vx
    OP_VSLIDE1DN = 7'd71, // vslide1down.vx
    OP_VRGATHEREI16 = 7'd72,  // vrgatherei16.vv
    // v0.17: Widening operations
    OP_VWADDU   = 7'd73,  // vwaddu.vv/vx (unsigned widening add)
    OP_VWADD    = 7'd74,  // vwadd.vv/vx (signed widening add)
    OP_VWSUBU   = 7'd75,  // vwsubu.vv/vx (unsigned widening sub)
    OP_VWSUB    = 7'd76,  // vwsub.vv/vx (signed widening sub)
    OP_VWMULU   = 7'd77,  // vwmulu.vv/vx (unsigned widening multiply)
    OP_VWMULSU  = 7'd78,  // vwmulsu.vv/vx (signed*unsigned widening multiply)
    OP_VWMUL    = 7'd79,  // vwmul.vv/vx (signed widening multiply)
    // v0.18: Widening MAC operations
    OP_VWMACCU  = 7'd80,  // vwmaccu.vv/vx (unsigned widening MAC)
    OP_VWMACC   = 7'd81,  // vwmacc.vv/vx (signed widening MAC)
    OP_VWMACCSU = 7'd82,  // vwmaccsu.vv/vx (signed*unsigned widening MAC)
    // v0.18: Narrowing shift operations
    OP_VNSRL    = 7'd83,  // vnsrl.wv/wx/wi (narrowing logical shift right)
    OP_VNSRA    = 7'd84,  // vnsra.wv/wx/wi (narrowing arithmetic shift right)
    // v0.19: LUT-based operations for LLM inference
    OP_VEXP     = 7'd85,  // vexp.v (exponential via LUT)
    OP_VRECIP   = 7'd86,  // vrecip.v (reciprocal via LUT)
    OP_VRSQRT   = 7'd87,  // vrsqrt.v (inverse sqrt via LUT)
    OP_VGELU    = 7'd88,  // vgelu.v (GELU activation via LUT)
    // v1.1: INT4 pack/unpack for lower quantization
    OP_VUNPACK4 = 7'd89,  // vunpack4.v (unpack INT4 pairs to INT8)
    OP_VPACK4   = 7'd90,  // vpack4.v (pack INT8 to INT4 with saturation)
    // v0.5a: Compress and prefix-sum operations
    OP_VCOMPRESS = 7'd91, // vcompress.vm (compress active elements)
    OP_VIOTA     = 7'd92  // viota.m (inclusive prefix sum of mask bits)
  }} vpu_op_e;

  typedef enum logic [3:0] {{
    PKT_NOP = 4'h0, PKT_CONFIG = 4'h1, PKT_ARITH = 4'h2,
    PKT_LOAD = 4'h3, PKT_STORE = 4'h4, PKT_DONE = 4'hF
  }} pkt_type_e;

endpackage

`endif // HP_VPU_PKG_SV
'''

    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # Write package file
    with open(output_path, 'w') as f:
        f.write(pkg_content)

    print(f"Generated: {output_path}")
    print(f"  VLEN={VLEN}, DLEN={DLEN}, NLANES={NLANES}")
    print(f"  ENABLE_VMADD={ENABLE_VMADD}, ENABLE_WIDENING={ENABLE_WIDENING}")
    print(f"  ENABLE_FRAC_LMUL={ENABLE_FRAC_LMUL}, ENABLE_INT4_PACK={ENABLE_INT4_PACK}")
    print(f"  ENABLE_LMUL_MULTI_UOP={ENABLE_LMUL_MULTI_UOP}, ENABLE_CSR={ENABLE_CSR}")
    print(f"  STRESS_TEST_MAX={STRESS_TEST_MAX}, ENABLE_VCD_DUMP={ENABLE_VCD_DUMP}")
    return 0

if __name__ == '__main__':
    sys.exit(main())
