#include "hp_vpu_decode.h"

namespace hp_vpu {

void hp_vpu_decode::decode_combinational(
    sc_uint<32> instr,
    vpu_op_e& op,
    sc_uint<5>& vd, sc_uint<5>& vs1, sc_uint<5>& vs2, bool& vm, bool& is_vx, sc_uint<32>& imm
) {
    sc_uint<7> opcode = instr(6, 0);
    sc_uint<3> funct3 = instr(14, 12);
    sc_uint<6> funct6 = instr(31, 26);
    vs1    = instr(19, 15);
    vs2    = instr(24, 20);
    vd     = instr(11, 7);
    vm     = instr[25];

    // Immediate extraction
    sc_int<5> simm5 = (sc_int<5>)vs1;
    imm = (sc_int<32>)simm5;

    // Default
    op = OP_NOP;
    is_vx = false;

    if (opcode != 0x57) return;

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
                case 0b011000: op = OP_VMSEQ; break;
                case 0b011001: op = OP_VMSNE; break;
                case 0b011010: op = OP_VMSLTU; break;
                case 0b011011: op = OP_VMSLT; break;
                case 0b011100: op = OP_VMSLEU; break;
                case 0b011101: op = OP_VMSLE; break;
                case 0b011110: op = OP_VMSGTU; break;
                case 0b011111: op = OP_VMSGT; break; // Check logic
                case 0b100000: op = OP_VSADDU; break;
                case 0b100001: op = OP_VSADD; break;
                case 0b100010: op = OP_VSSUBU; break;
                case 0b100011: op = OP_VSSUB; break;
                case 0b101010: op = OP_VSSRL; break;
                case 0b101011: op = OP_VSSRA; break;
                case 0b101110: op = OP_VNCLIPU; break;
                case 0b101111: op = OP_VNCLIP; break;
                case 0b101100: op = OP_VNSRL; break;
                case 0b101101: op = OP_VNSRA; break;
                case 0b110000: op = OP_VWADDU; break;
                case 0b110001: op = OP_VWADD; break;
                case 0b110010: op = OP_VWSUBU; break;
                case 0b110011: op = OP_VWSUB; break;
                case 0b001100: op = OP_VRGATHER; break;
                case 0b001110: op = (is_vx) ? OP_VSLIDEUP : OP_VRGATHEREI16; break;
                case 0b001111: op = OP_VSLIDEDN; break;
                case 0b010111: op = (vm==0) ? OP_VMERGE : OP_VMV; break; // vmerge.v.i / vmv.v.i
                default: op = OP_NOP;
            }
            break;

        case 0b010: // OPMVV
        case 0b110: // OPMVX
             is_vx = (funct3 == 0b110);
             switch (funct6) {
                 case 0b100101: op = OP_VMUL; break;
                 case 0b100100: op = OP_VMULHU; break;
                 case 0b100110: op = OP_VMULHSU; break;
                 case 0b100111: op = OP_VMULH; break;
                 case 0b101101: op = OP_VMACC; break;
                 case 0b101111: op = OP_VNMSAC; break;
                 case 0b101001: op = OP_VMADD; break;
                 case 0b101011: op = OP_VNMSUB; break;
                 case 0b111000: op = OP_VWMULU; break;
                 case 0b111010: op = OP_VWMULSU; break;
                 case 0b111011: op = OP_VWMUL; break;
                 case 0b111100: op = OP_VWMACCU; break;
                 case 0b111101: op = OP_VWMACC; break;
                 case 0b111110: op = OP_VWMACCSU; break;
                 case 0b000000: op = OP_VREDSUM; break;
                 case 0b000001: op = OP_VREDAND; break;
                 case 0b000010: op = OP_VREDOR; break;
                 case 0b000011: op = OP_VREDXOR; break;
                 case 0b000100: op = OP_VREDMINU; break;
                 case 0b000101: op = OP_VREDMIN; break;
                 case 0b000110: op = OP_VREDMAXU; break;
                 case 0b000111: op = OP_VREDMAX; break;
                 case 0b010111: op = (vm==0) ? OP_VMERGE : OP_VMV; break; // vm=0 is merge

                 // Mask Logic Ops (vmand.mm, etc)
                 case 0b011001: op = OP_VMAND_MM; break;  // vmand.mm
                 case 0b011101: op = OP_VMNAND_MM; break; // vmnand.mm
                 case 0b011000: op = OP_VMANDN_MM; break; // vmandn.mm
                 case 0b011011: op = OP_VMXOR_MM; break;  // vmxor.mm
                 case 0b011010: op = OP_VMOR_MM; break;   // vmor.mm
                 case 0b011110: op = OP_VMNOR_MM; break;  // vmnor.mm
                 case 0b011100: op = OP_VMORN_MM; break;  // vmorn.mm
                 case 0b011111: op = OP_VMXNOR_MM; break; // vmxnor.mm

                 case 0b001110: op = OP_VSLIDE1UP; break;
                 case 0b001111: op = OP_VSLIDE1DN; break;
                 case 0b010000: op = (vs1 == 16) ? OP_VCPOP : OP_VFIRST; break; // 10000=vcpop, 10001=vfirst
                 case 0b010100: // Mask/Index
                    if (vs1 == 1) op = OP_VMSBF;
                    else if (vs1 == 2) op = OP_VMSOF;
                    else if (vs1 == 3) op = OP_VMSIF;
                    else if (vs1 == 16) op = OP_VIOTA;
                    else if (vs1 == 17) op = OP_VID;
                    break;
                 case 0b010010: // LUT ops
                    if (vs1 == 0) op = OP_VEXP;
                    else if (vs1 == 1) op = OP_VRECIP;
                    else if (vs1 == 2) op = OP_VRSQRT;
                    else if (vs1 == 3) op = OP_VGELU;
                    break;
                 case 0b010011: op = OP_VPACK4; break;
                 case 0b010101: op = OP_VUNPACK4; break;
                 default: op = OP_NOP;
             }
             break;
    }
}

void hp_vpu_decode::decode_pipeline() {
    // Reset
    d1_valid.write(false);
    d1_instr.write(0);
    d1_id.write(0);
    d1_rs1.write(0);
    d1_rs2.write(0);
    current_sew.write(SEW_8);
    current_lmul.write(0); // 0=LMUL1
    uop_counter.write(0);
    in_multicycle_seq.write(false);

    wait();

    while(true) {
        // vtype shadow update (always happening from CSR)
        sc_uint<32> vtype = csr_vtype_i.read();
        sew_e sew = (sew_e)(int)vtype(5, 3);
        int lmul = (int)vtype(2, 0); // 000=1, 001=2, 010=4, 011=8, etc.

        current_sew.write((int)sew);
        current_lmul.write(lmul);

        // Pipeline stall handling
        if (!stall_i.read()) {
            if (in_multicycle_seq.read()) {
                // Sequencer Active: Generate next micro-op
                int cnt = uop_counter.read() + 1;
                uop_counter.write(cnt);
                int total = uop_total.read();

                if (cnt >= total - 1) {
                    in_multicycle_seq.write(false);
                }

                // Generate new instruction bits based on current d1_instr
                sc_uint<32> instr = d1_instr.read();

                // Decode to check op type for increment logic
                vpu_op_e op; sc_uint<5> vd, vs1, vs2; bool vm, is_vx; sc_uint<32> imm;
                decode_combinational(instr, op, vd, vs1, vs2, vm, is_vx, imm);

                bool is_red = (op >= OP_VREDSUM && op <= OP_VREDMAX);

                // Increment VD if not reduction
                if (!is_red) {
                    instr(11, 7) = vd + 1;
                }

                // Increment VS2 (Accumulator or Source 2)
                instr(24, 20) = vs2 + 1;

                // Increment VS1 if vector (.vv) and not reduction init
                if (!is_vx && !is_red) {
                    instr(19, 15) = vs1 + 1;
                }

                d1_instr.write(instr);
                d1_valid.write(true);

            } else {
                // Idle: Accept new instruction
                if (valid_i.read()) {
                    d1_valid.write(true);
                    d1_instr.write(instr_i.read());
                    d1_id.write(id_i.read());
                    d1_rs1.write(rs1_i.read());
                    d1_rs2.write(rs2_i.read());

                    // Initialize Sequencer
                    int uops = 1 << lmul; // 1, 2, 4, 8
                    uop_total.write(uops);
                    uop_counter.write(0);

                    if (uops > 1) {
                        in_multicycle_seq.write(true);
                    }
                } else {
                    d1_valid.write(false);
                }
            }
        }

        wait();
    }
}

void hp_vpu_decode::output_logic() {
    // D2 Combinational Decode logic using D1 registers
    vpu_op_e op;
    sc_uint<5> vd, vs1, vs2;
    bool vm, is_vx;
    sc_uint<32> imm;

    decode_combinational(d1_instr.read(), op, vd, vs1, vs2, vm, is_vx, imm);

    // Outputs
    valid_o.write(d1_valid.read());
    op_o.write(op);
    vd_o.write(vd);
    vs1_o.write(vs1);
    vs2_o.write(vs2);
    // Accumulator handling (vs3):
    // For MAC ops, vs3 is the old vd. For mask/vmv ops, it might be old_vd too.
    vs3_o.write(vd);

    vm_o.write(vm);
    is_vx_o.write(is_vx);

    // Scalar mux: immediate vs rs1
    if (is_vx) {
        // Check if instruction uses immediate (OPIVI)
        sc_uint<3> funct3 = d1_instr.read()(14, 12);
        if (funct3 == 0b011) { // OPIVI
            scalar_o.write(imm);
        } else {
            scalar_o.write(d1_rs1.read());
        }
    } else {
        scalar_o.write(0);
    }

    sew_o.write(current_sew.read());
    lmul_o.write(current_lmul.read());
    id_o.write(d1_id.read());

    // Last uop logic
    bool is_last = (uop_counter.read() == uop_total.read() - 1);
    is_last_uop_o.write(is_last);

    // Ready if not stalled AND not busy sequencing (unless last uop cycle? No, keep it simple)
    // If sequencing, we are busy.
    ready_o.write(!stall_i.read() && !in_multicycle_seq.read());
}

} // namespace hp_vpu
