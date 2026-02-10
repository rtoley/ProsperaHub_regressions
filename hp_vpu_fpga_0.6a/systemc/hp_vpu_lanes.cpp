#include "hp_vpu_lanes.h"

namespace hp_vpu {

sc_biguint<DLEN> hp_vpu_lanes::alu_add(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew) {
    sc_biguint<DLEN> res = 0;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;

    for (int i = 0; i < num_elem; ++i) {
        int lo = i * elem_width;
        int hi = lo + elem_width - 1;
        // Simple add
        res(hi, lo) = a(hi, lo) + b(hi, lo);
    }
    return res;
}

sc_biguint<DLEN> hp_vpu_lanes::alu_mul(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew) {
    sc_biguint<DLEN> res = 0;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;

    for (int i = 0; i < num_elem; ++i) {
        int lo = i * elem_width;
        int hi = lo + elem_width - 1;
        sc_uint<32> val_a = a(hi, lo).to_uint();
        sc_uint<32> val_b = b(hi, lo).to_uint();
        res(hi, lo) = (val_a * val_b);
    }
    return res;
}

// LUT implementation (matches rtl/hp_vpu_lut_rom.sv)
// Tables are truncated here for brevity but functional structure is correct
sc_biguint<DLEN> hp_vpu_lanes::alu_lut(vpu_op_e op, sc_biguint<DLEN> idx, sew_e sew) {
    sc_biguint<DLEN> res = 0;
    // LUTs operate on 8-bit index regardless of SEW, output 16-bit
    // SEW=8: output 8 bits (truncated)
    // SEW=16: output 16 bits
    // SEW=32: output 32 bits (zero-ext)
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int idx_stride = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32; // Index is LSB of element

    for (int i = 0; i < num_elem; ++i) {
        int idx_lo = i * idx_stride;
        int idx_hi = idx_lo + 7; // Only 8 bits used for index
        sc_uint<8> index = idx(idx_hi, idx_lo).to_uint();
        sc_uint<16> val = 0;

        // Simplified mapping (just functional placeholder for correct flow)
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

void hp_vpu_lanes::logic_thread() {
    e1_valid = false;
    e1m_valid = false;
    e2_valid = false;
    e3_valid = false;
    wait();

    while (true) {
        if (stall_i.read()) {
            wait();
            continue;
        }

        // --- Pipeline Advance ---

        // E3 Capture (from E2)
        e3_valid = e2_valid;
        if (e2_valid) {
            e3_result = e2_result;
            e3_vd = e2_vd;
            e3_id = e2_id;
        }

        // E2 Capture (from E1 or E1m)
        bool e1_is_mul = (e1_op == OP_VMUL || e1_op == OP_VMACC);

        if (e1m_valid) {
            e2_valid = true;
            e2_op = e1m_op;
            e2_sew = e1m_sew;
            e2_vd = e1m_vd;
            e2_id = e1m_id;

            if (e1m_op == OP_VMACC) {
                e2_result = alu_add(e1m_mul_res, e1m_c, e1m_sew);
            } else {
                e2_result = e1m_mul_res;
            }
            e1m_valid = false;
        } else if (e1_valid && !e1_is_mul) {
            e2_valid = true;
            e2_op = e1_op;
            e2_sew = e1_sew;
            e2_vd = e1_vd;
            e2_id = e1_id;

            if (e1_op == OP_VADD) e2_result = alu_add(e1_a, e1_b, e1_sew);
            else if (e1_op == OP_VEXP) e2_result = alu_lut(e1_op, e1_a, e1_sew);
            else if (e1_op == OP_VRECIP) e2_result = alu_lut(e1_op, e1_a, e1_sew);
            else if (e1_op == OP_VRSQRT) e2_result = alu_lut(e1_op, e1_a, e1_sew);
            else if (e1_op == OP_VGELU) e2_result = alu_lut(e1_op, e1_a, e1_sew);
            else e2_result = e1_b;

            e1_valid = false;
        } else {
            e2_valid = false;
        }

        // E1m Capture (from E1 if mul)
        if (e1_valid && e1_is_mul) {
            e1m_valid = true;
            e1m_op = e1_op;
            e1m_sew = e1_sew;
            e1m_vd = e1_vd;
            e1m_id = e1_id;
            e1m_c = e1_c;
            e1m_mul_res = alu_mul(e1_a, e1_b, e1_sew);

            e1_valid = false;
        }

        // E1 Capture (from Inputs)
        if (valid_i.read()) {
            if (!e1_valid) {
               e1_valid = true;
               e1_op = (vpu_op_e)op_i.read();
               e1_sew = (sew_e)sew_i.read();
               e1_vd = vd_i.read();
               e1_id = id_i.read();

               sc_biguint<DLEN> op_a = vs2_i.read();
               sc_biguint<DLEN> op_b;
               if (is_vx_i.read()) {
                   sc_uint<32> s = scalar_i.read();
                   for(int k=0; k<DLEN/32; k++) op_b(k*32+31, k*32) = s;
               } else {
                   op_b = vs1_i.read();
               }
               e1_a = op_a;
               e1_b = op_b;
               e1_c = vs3_i.read();
            }
        }

        wait();
    }
}

void hp_vpu_lanes::outputs_method() {
    valid_o.write(e3_valid);
    result_o.write(e3_result);
    vd_o.write(e3_vd);
    id_o.write(e3_id);

    e1_valid_o.write(e1_valid);
    e1_vd_o.write(e1_vd);
    e1m_valid_o.write(e1m_valid);
    e1m_vd_o.write(e1m_vd);
    e2_valid_o.write(e2_valid);
    e2_vd_o.write(e2_vd);
    e3_valid_o.write(e3_valid);
    e3_vd_o.write(e3_vd);

    mul_stall_o.write(e1_valid && e1m_valid);
    mac_stall_o.write(false);
}

} // namespace hp_vpu
