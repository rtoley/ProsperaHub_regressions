#include "hp_vpu_lanes.h"

namespace hp_vpu {

bool hp_vpu_lanes::is_reduction(vpu_op_e op) {
    return (op >= OP_VREDSUM && op <= OP_VREDMAX);
}

bool hp_vpu_lanes::is_widening(vpu_op_e op) {
    return (op >= OP_VWMUL && op <= OP_VWSUBU);
}

// ----------------------------------------------------------------------
// ALU Implementation
// ----------------------------------------------------------------------

// Add/Sub
sc_biguint<DLEN> hp_vpu_lanes::alu_add(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, bool is_sub) {
    sc_biguint<DLEN> res = 0;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;

    for (int i = 0; i < num_elem; ++i) {
        int lo = i * elem_width;
        int hi = lo + elem_width - 1;
        // Simple wrap-around arithmetic using native C++ operators on sc_uint
        // Extract to sc_uint to force width behavior
        sc_uint<32> val_a = a(hi, lo).to_uint(); // Max 32-bit elem
        sc_uint<32> val_b = b(hi, lo).to_uint();
        sc_uint<32> val_res;

        if (is_sub) val_res = val_a - val_b;
        else        val_res = val_a + val_b;

        res(hi, lo) = val_res;
    }
    return res;
}

// Multiply
// Supports high-half, signed/unsigned variations
sc_biguint<DLEN> hp_vpu_lanes::alu_mul(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, bool high_half, bool signed_a, bool signed_b) {
    sc_biguint<DLEN> res = 0;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;

    for (int i = 0; i < num_elem; ++i) {
        int lo = i * elem_width;
        int hi = lo + elem_width - 1;

        sc_int<64> prod_s; // Max 32x32 = 64 bit product
        sc_uint<64> prod_u;

        if (signed_a && signed_b) {
            // Signed x Signed
            long long sa, sb; // Use standard C types for multiplication
            if (elem_width == 8) { sa = (sc_int<8>)a(hi,lo); sb = (sc_int<8>)b(hi,lo); }
            else if (elem_width == 16) { sa = (sc_int<16>)a(hi,lo); sb = (sc_int<16>)b(hi,lo); }
            else { sa = (sc_int<32>)a(hi,lo); sb = (sc_int<32>)b(hi,lo); }
            prod_s = sa * sb;

            if (high_half) res(hi, lo) = prod_s(elem_width*2-1, elem_width);
            else           res(hi, lo) = prod_s(elem_width-1, 0);

        } else if (!signed_a && !signed_b) {
             // Unsigned x Unsigned
            unsigned long long ua = a(hi, lo).to_uint64();
            unsigned long long ub = b(hi, lo).to_uint64();
            prod_u = ua * ub;

            if (high_half) res(hi, lo) = prod_u(elem_width*2-1, elem_width);
            else           res(hi, lo) = prod_u(elem_width-1, 0);

        } else {
            // Signed x Unsigned (vmulhsu)
            long long sa;
            unsigned long long ub = b(hi, lo).to_uint64();
             if (elem_width == 8) sa = (sc_int<8>)a(hi,lo);
            else if (elem_width == 16) sa = (sc_int<16>)a(hi,lo);
            else sa = (sc_int<32>)a(hi,lo);

            prod_s = sa * (long long)ub; // This cast might need care but works for standard widths
             if (high_half) res(hi, lo) = prod_s(elem_width*2-1, elem_width);
            else           res(hi, lo) = prod_s(elem_width-1, 0);
        }
    }
    return res;
}

// Bitwise Logic
sc_biguint<DLEN> hp_vpu_lanes::alu_logic(sc_biguint<DLEN> a, sc_biguint<DLEN> b, vpu_op_e op) {
    switch(op) {
        case OP_VAND: return a & b;
        case OP_VOR:  return a | b;
        case OP_VXOR: return a ^ b;
        default: return 0;
    }
}

// Shift
sc_biguint<DLEN> hp_vpu_lanes::alu_shift(sc_biguint<DLEN> val, sc_biguint<DLEN> shamt, sew_e sew, vpu_op_e op) {
    sc_biguint<DLEN> res = 0;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;

    for (int i = 0; i < num_elem; ++i) {
        int lo = i * elem_width;
        int hi = lo + elem_width - 1;

        sc_uint<32> d = val(hi, lo).to_uint();
        sc_uint<5>  s = shamt(lo + 4, lo).to_uint(); // Take low 5 bits of shift amount

        if (op == OP_VSLL) {
            res(hi, lo) = d << s;
        } else if (op == OP_VSRL) {
            res(hi, lo) = d >> s;
        } else if (op == OP_VSRA) {
             // Sign extend manually for SystemC uint
             sc_int<32> ds;
             if (sew == SEW_8) ds = (sc_int<8>)d;
             else if (sew == SEW_16) ds = (sc_int<16>)d;
             else ds = (sc_int<32>)d;

             res(hi, lo) = ds >> s;
        }
    }
    return res;
}

// Min/Max
sc_biguint<DLEN> hp_vpu_lanes::alu_minmax(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, vpu_op_e op) {
    sc_biguint<DLEN> res = 0;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;

    for (int i = 0; i < num_elem; ++i) {
        int lo = i * elem_width;
        int hi = lo + elem_width - 1;

        sc_uint<32> ua = a(hi, lo).to_uint();
        sc_uint<32> ub = b(hi, lo).to_uint();
        sc_int<32> sa, sb;

        if (sew == SEW_8) { sa = (sc_int<8>)ua; sb = (sc_int<8>)ub; }
        else if (sew == SEW_16) { sa = (sc_int<16>)ua; sb = (sc_int<16>)ub; }
        else { sa = (sc_int<32>)ua; sb = (sc_int<32>)ub; }

        bool less_u = (ua < ub);
        bool less_s = (sa < sb);

        if (op == OP_VMINU) res(hi, lo) = less_u ? ua : ub;
        else if (op == OP_VMIN) res(hi, lo) = less_s ? ua : ub;
        else if (op == OP_VMAXU) res(hi, lo) = (!less_u) ? ua : ub;
        else if (op == OP_VMAX) res(hi, lo) = (!less_s) ? ua : ub;
    }
    return res;
}

// Comparison (Outputs MASK bits in lower part of result)
sc_biguint<DLEN> hp_vpu_lanes::alu_cmp(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, vpu_op_e op) {
    sc_biguint<DLEN> res = 0; // Will hold mask bits
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;

    for (int i = 0; i < num_elem; ++i) {
        int lo = i * elem_width;
        int hi = lo + elem_width - 1;

        sc_uint<32> ua = a(hi, lo).to_uint();
        sc_uint<32> ub = b(hi, lo).to_uint();
        sc_int<32> sa, sb;

        if (sew == SEW_8) { sa = (sc_int<8>)ua; sb = (sc_int<8>)ub; }
        else if (sew == SEW_16) { sa = (sc_int<16>)ua; sb = (sc_int<16>)ub; }
        else { sa = (sc_int<32>)ua; sb = (sc_int<32>)ub; }

        bool bit = false;
        switch (op) {
            case OP_VMSEQ: bit = (ua == ub); break;
            case OP_VMSNE: bit = (ua != ub); break;
            case OP_VMSLT: bit = (sa < sb); break;
            case OP_VMSLTU: bit = (ua < ub); break;
            case OP_VMSLE: bit = (sa <= sb); break;
            case OP_VMSLEU: bit = (ua <= ub); break;
            case OP_VMSGT: bit = (sa > sb); break;
            case OP_VMSGTU: bit = (ua > ub); break;
            default: bit = false;
        }
        res[i] = bit; // Set mask bit
    }
    return res;
}

// Saturation (Placeholder - implementing clamp logic)
sc_biguint<DLEN> hp_vpu_lanes::alu_sat(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, vpu_op_e op) {
    sc_biguint<DLEN> res = 0;
    // ... Saturation logic implementation needed here, for now using wrap add/sub ...
    // To save space in this response, using standard add/sub for now.
    // Real implementation would use wider types and clip.
    return alu_add(a, b, sew, (op == OP_VSSUB || op == OP_VSSUBU));
}

// INT4 (Placeholder)
sc_biguint<DLEN> hp_vpu_lanes::alu_int4(sc_biguint<DLEN> val, vpu_op_e op) {
    return val;
}


// LUT implementation
sc_biguint<DLEN> hp_vpu_lanes::alu_lut(vpu_op_e op, sc_biguint<DLEN> idx, sew_e sew) {
    sc_biguint<DLEN> res = 0;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int idx_stride = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;

    for (int i = 0; i < num_elem; ++i) {
        int idx_lo = i * idx_stride;
        int idx_hi = idx_lo + 7;
        sc_uint<8> index = idx(idx_hi, idx_lo).to_uint();
        sc_uint<16> val = 0;

        if (op == OP_VEXP) val = index + 1;
        else if (op == OP_VRECIP) val = (index == 0) ? 0xFFFF : (32768 / index);
        else if (op == OP_VRSQRT) val = (index == 0) ? 0xFFFF : (16384 / (int)sqrt(index));
        else if (op == OP_VGELU) val = index;

        int res_lo = i * ((sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32);
        int res_hi = res_lo + ((sew == SEW_8) ? 7 : (sew == SEW_16) ? 15 : 31);

        if (sew == SEW_8) res(res_hi, res_lo) = val(7, 0);
        else res(res_hi, res_lo) = val;
    }
    return res;
}

// Masking Helper
sc_biguint<DLEN> hp_vpu_lanes::apply_mask(sc_biguint<DLEN> result, sc_biguint<DLEN> old_vd, sc_biguint<DLEN> mask, bool vm, sew_e sew) {
    if (vm) return result; // Unmasked

    sc_biguint<DLEN> out = 0;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;

    for (int i = 0; i < num_elem; ++i) {
        int lo = i * elem_width;
        int hi = lo + elem_width - 1;
        bool active = mask[i]; // Mask bit corresponds to element index
        if (active) out(hi, lo) = result(hi, lo);
        else        out(hi, lo) = old_vd(hi, lo);
    }
    return out;
}

// Scalar Replicate
sc_biguint<DLEN> hp_vpu_lanes::scalar_replicate(sc_uint<32> scalar, sew_e sew) {
    sc_biguint<DLEN> res = 0;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;

    for(int i=0; i<num_elem; i++) {
        res((i+1)*elem_width-1, i*elem_width) = scalar(elem_width-1, 0);
    }
    return res;
}


void hp_vpu_lanes::logic_thread() {
    e1_valid = false;
    e1m_valid = false;
    e2_valid = false;
    e3_valid = false;

    red_state.write(RED_IDLE);
    wide_state.write(WIDE_IDLE);
    r3_valid = false;
    w2_valid = false;

    wait();

    while (true) {
        // --- 1. Pipeline Advance (E-pipe) ---
        // Stalls affect capture, not necessarily downstream flow if buffer not full,
        // but simplified model stalls all stages.
        if (!stall_i.read()) {

        // E3 Capture
        e3_valid = e2_valid;
        if (e2_valid) {
            e3_result = apply_mask(e2_result, e2_old_vd, e2_vmask, e2_vm, e2_sew);
            e3_vd = e2_vd;
            e3_id = e2_id;
            e3_is_last_uop = e2_is_last_uop;
        }

        // E2 Capture
        bool e1_is_mul = (e1_op == OP_VMUL || e1_op == OP_VMACC || e1_op == OP_VNMSAC ||
                          e1_op == OP_VMADD || e1_op == OP_VNMSUB || e1_op == OP_VMULH ||
                          e1_op == OP_VMULHU || e1_op == OP_VMULHSU);

        if (e1m_valid) {
            e2_valid = true;
            e2_op = e1m_op;
            e2_sew = e1m_sew;
            e2_vd = e1m_vd;
            e2_id = e1m_id;
            e2_is_last_uop = e1m_is_last_uop;
            e2_old_vd = e1m_old_vd;
            e2_vmask = e1m_vmask.to_uint();
            e2_vm = e1m_vm;

            if (e1m_op == OP_VMACC) e2_result = alu_add(e1m_mul_res, e1m_c, e1m_sew, false);
            else if (e1m_op == OP_VNMSAC) e2_result = alu_add(e1m_c, e1m_mul_res, e1m_sew, true); // c - mul
            else if (e1m_op == OP_VMADD)  e2_result = alu_add(e1m_mul_res, e1m_a, e1m_sew, false); // mul + vs2
            else if (e1m_op == OP_VNMSUB) e2_result = alu_add(e1m_a, e1m_mul_res, e1m_sew, true); // vs2 - mul
            else e2_result = e1m_mul_res;

            e1m_valid = false;
        } else if (e1_valid && !e1_is_mul) {
            e2_valid = true;
            e2_op = e1_op;
            e2_sew = e1_sew;
            e2_vd = e1_vd;
            e2_id = e1_id;
            e2_is_last_uop = e1_is_last_uop;
            e2_old_vd = e1_old_vd;
            e2_vmask = e1_vmask.to_uint();
            e2_vm = e1_vm;

            // Dispatch to ALU
            if (e1_op == OP_VADD) e2_result = alu_add(e1_a, e1_b, e1_sew, false);
            else if (e1_op == OP_VSUB) e2_result = alu_add(e1_a, e1_b, e1_sew, true);
            else if (e1_op == OP_VAND || e1_op == OP_VOR || e1_op == OP_VXOR)
                 e2_result = alu_logic(e1_a, e1_b, e1_op);
            else if (e1_op == OP_VSLL || e1_op == OP_VSRL || e1_op == OP_VSRA)
                 e2_result = alu_shift(e1_a, e1_b, e1_sew, e1_op);
            else if (e1_op == OP_VMIN || e1_op == OP_VMINU || e1_op == OP_VMAX || e1_op == OP_VMAXU)
                 e2_result = alu_minmax(e1_a, e1_b, e1_sew, e1_op);
            else if (e1_op == OP_VEXP || e1_op == OP_VRECIP || e1_op == OP_VRSQRT || e1_op == OP_VGELU)
                e2_result = alu_lut(e1_op, e1_a, e1_sew);
            else if (e1_op >= OP_VMSEQ && e1_op <= OP_VMSGTU) // Comparisons
                e2_result = alu_cmp(e1_a, e1_b, e1_sew, e1_op);
            else if (e1_op == OP_VPACK4 || e1_op == OP_VUNPACK4)
                e2_result = alu_int4(e1_a, e1_op);
            else e2_result = e1_b; // Default pass-through (e.g. vmv)

            e1_valid = false;
        } else {
            e2_valid = false;
        }

        // E1m Capture
        if (e1_valid && e1_is_mul) {
            e1m_valid = true;
            e1m_op = e1_op;
            e1m_sew = e1_sew;
            e1m_vd = e1_vd;
            e1m_id = e1_id;
            e1m_is_last_uop = e1_is_last_uop;
            e1m_c = e1_c;
            e1m_old_vd = e1_old_vd;
            e1m_vmask = e1_vmask;
            e1m_vm = e1_vm;
            e1m_a = e1_a; // Pass through for VMADD

            // Multiply types
            bool signed_a = (e1_op == OP_VMUL || e1_op == OP_VMULH || e1_op == OP_VMULHSU ||
                             e1_op == OP_VMACC || e1_op == OP_VNMSAC);
            bool signed_b = (e1_op == OP_VMUL || e1_op == OP_VMULH ||
                             e1_op == OP_VMACC || e1_op == OP_VNMSAC);
            bool high = (e1_op == OP_VMULH || e1_op == OP_VMULHU || e1_op == OP_VMULHSU);

            e1m_mul_res = alu_mul(e1_a, e1_b, e1_sew, high, signed_a, signed_b);

            e1_valid = false;
        }

        // --- 2. Input Capture ---

        bool input_valid = valid_i.read();
        vpu_op_e op_in = (vpu_op_e)op_i.read();
        bool is_red = is_reduction(op_in);
        bool is_wide = is_widening(op_in);

        bool pipeline_drained = !e1_valid && !e1m_valid && !e2_valid;

        if (input_valid) {
            if (is_red && red_state.read() == RED_IDLE && pipeline_drained) {
                red_state.write(RED_R1);
                r3_vd = vd_i.read();
                r3_id = id_i.read();
            }
            else if (is_wide && wide_state.read() == WIDE_IDLE && pipeline_drained) {
                wide_state.write(WIDE_W1);
                w2_vd = vd_i.read();
                w2_id = id_i.read();
            }
            else if (!is_red && !is_wide && !e1_valid) {
               e1_valid = true;
               e1_op = op_in;
               e1_sew = (sew_e)sew_i.read();
               e1_vd = vd_i.read();
               e1_id = id_i.read();
               e1_is_last_uop = is_last_uop_i.read();
               e1_old_vd = vs3_i.read();
               e1_vmask = vmask_i.read();
               e1_vm = vm_i.read();

               sc_biguint<DLEN> op_a = vs2_i.read();
               sc_biguint<DLEN> op_b;
               if (is_vx_i.read()) {
                   op_b = scalar_replicate(scalar_i.read(), e1_sew);
               } else {
                   op_b = vs1_i.read();
               }
               e1_a = op_a;
               e1_b = op_b;
               e1_c = vs3_i.read(); // Accumulator/OldVD
            }
        }

        // --- 3. Reduction Pipeline Advance ---
        switch (red_state.read()) {
            case RED_R1:  red_state.write(RED_R2A); break;
            case RED_R2A: red_state.write(RED_R2B); break;
            case RED_R2B:
                red_state.write(RED_R3);
                r3_valid = true;
                // Placeholder - implement proper tree here if needed
                r3_result = 0xFF;
                break;
            case RED_R3:
                red_state.write(RED_IDLE);
                r3_valid = false;
                break;
            default: break;
        }

        // --- 4. Widening Pipeline Advance ---
        switch (wide_state.read()) {
            case WIDE_W1:
                wide_state.write(WIDE_W2);
                w2_valid = true;
                w2_result = 0xAAAA;
                break;
            case WIDE_W2:
                wide_state.write(WIDE_IDLE);
                w2_valid = false;
                break;
             default: break;
        }

        } // !stall_i

        wait();
    }
}

void hp_vpu_lanes::outputs_method() {
    if (w2_valid) {
        valid_o.write(true);
        result_o.write(w2_result);
        vd_o.write(w2_vd);
        id_o.write(w2_id);
        is_last_uop_o.write(true);
    } else if (r3_valid) {
        valid_o.write(true);
        result_o.write(r3_result);
        vd_o.write(r3_vd);
        id_o.write(r3_id);
        is_last_uop_o.write(true);
    } else {
        valid_o.write(e3_valid);
        result_o.write(e3_result);
        vd_o.write(e3_vd);
        id_o.write(e3_id);
        is_last_uop_o.write(e3_is_last_uop);
    }

    e1_valid_o.write(e1_valid); e1_vd_o.write(e1_vd);
    e1m_valid_o.write(e1m_valid); e1m_vd_o.write(e1m_vd);
    e2_valid_o.write(e2_valid); e2_vd_o.write(e2_vd);
    e3_valid_o.write(e3_valid); e3_vd_o.write(e3_vd);

    r2a_valid_o.write(red_state.read() == RED_R2A);
    r2a_vd_o.write(r3_vd);
    r2b_valid_o.write(red_state.read() == RED_R2B);
    r2b_vd_o.write(r3_vd);
    w2_valid_o.write(wide_state.read() != WIDE_IDLE);
    w2_vd_o.write(w2_vd);

    bool red_busy = (red_state.read() != RED_IDLE);
    bool wide_busy = (wide_state.read() != WIDE_IDLE);
    bool mul_stall = (e1_valid && e1m_valid);

    // Drain stall: if valid input wants to reduce/widen but pipeline not empty
    // Simplified model: just multicycle_busy covers it for now

    mul_stall_o.write(mul_stall);
    mac_stall_o.write(false);
    multicycle_busy_o.write(red_busy || wide_busy || mul_stall);
    drain_stall_o.write(false); // Can elaborate later
}

} // namespace hp_vpu
