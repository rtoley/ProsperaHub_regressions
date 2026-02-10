#include "hp_vpu_decode.h"

namespace hp_vpu {

void hp_vpu_decode::decode_logic() {
    sc_uint<32> instr = instr_i.read();

    sc_uint<7> opcode = instr(6, 0);
    sc_uint<3> funct3 = instr(14, 12);
    sc_uint<6> funct6 = instr(31, 26);
    sc_uint<5> vs1    = instr(19, 15);
    sc_uint<5> vs2    = instr(24, 20);
    sc_uint<5> vd     = instr(11, 7);
    bool       vm     = instr[25];

    // Defaults
    op_o.write(OP_NOP);
    sew_o.write(SEW_8); // Default, should come from vtype/CSR logic in Top, simplified here for now or extracted from vtype if available
    vd_o.write(vd);
    vs1_o.write(vs1);
    vs2_o.write(vs2);
    vs3_o.write(vd); // Default vs3 is old vd
    vm_o.write(vm);
    is_vx_o.write(false);
    scalar_o.write(0);
    is_vector_o.write(opcode == 0x57); // OPCODE_V = 7'b1010111

    if (opcode != 0x57) return;

    // Decode Opcode
    vpu_op_e op = OP_NOP;
    bool is_vx = false;

    // OPIVV = 000, OPIVX = 100, OPIVI = 011, OPMVV = 010, OPMVX = 110
    switch (funct3) {
        case 0b000: // OPIVV
        case 0b100: // OPIVX
        case 0b011: // OPIVI
            is_vx = (funct3 != 0b000); // VX or VI
            switch (funct6) {
                case 0b000000: op = OP_VADD; break;
                case 0b000010: op = OP_VSUB; break;
                case 0b000011: op = OP_VRSUB; break;
                case 0b001001: op = OP_VAND; break;
                case 0b001010: op = OP_VOR; break;
                case 0b001011: op = OP_VXOR; break;
                case 0b100101: op = OP_VSLL; break;
                case 0b101000: op = OP_VSRL; break;
                case 0b101001: op = OP_VSRA; break;
                case 0b000101: op = OP_VMIN; break;
                case 0b000100: op = OP_VMINU; break;
                case 0b000111: op = OP_VMAX; break;
                case 0b000110: op = OP_VMAXU; break;
                // ... Add other OPIVV/VX ops ...
                case 0b101101: op = OP_VMACC; break; // Note: MACs are usually OPMVV/OPMVX? Check RTL
                default: op = OP_NOP;
            }
            break;

        case 0b010: // OPMVV
        case 0b110: // OPMVX
             is_vx = (funct3 == 0b110);
             switch (funct6) {
                 case 0b100101: op = OP_VMUL; break;
                 case 0b101101: op = OP_VMACC; break;
                 case 0b101111: op = OP_VNMSAC; break;
                 case 0b101001: op = OP_VMADD; break;
                 case 0b101011: op = OP_VNMSUB; break;
                 // Reductions (OPMVV only)
                 case 0b000000: op = OP_VREDSUM; break;
                 case 0b010010: // LUT ops
                    if (vs1 == 0) op = OP_VEXP;
                    else if (vs1 == 1) op = OP_VRECIP;
                    else if (vs1 == 2) op = OP_VRSQRT;
                    else if (vs1 == 3) op = OP_VGELU;
                    break;
                 case 0b010011: op = OP_VPACK4; break;
                 case 0b010101: op = OP_VUNPACK4; break;
                 case 0b010100: // VID etc
                    if (vs1 == 17) op = OP_VID; // 5'b10001
                    break;
                 default: op = OP_NOP;
             }
             break;
    }

    // Immediate handling for OPIVI
    if (funct3 == 0b011) {
        sc_int<5> simm5 = vs1; // Sign-extend 5-bit immediate
        scalar_o.write((sc_int<32>)simm5);
    }

    op_o.write(op);
    is_vx_o.write(is_vx);
}

} // namespace hp_vpu
