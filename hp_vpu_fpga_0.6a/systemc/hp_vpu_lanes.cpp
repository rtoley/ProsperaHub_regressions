#include "hp_vpu_lanes.h"

namespace hp_vpu {

sc_biguint<DLEN> hp_vpu_lanes::alu_add(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew) {
    sc_biguint<DLEN> res = 0;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;

    for (int i = 0; i < num_elem; ++i) {
        int lo = i * elem_width;
        int hi = lo + elem_width - 1;
        // Simple add, ignoring overflow behavior specifics for this simplified model
        // but typically should wrap.
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
        // Unsigned multiply for now (simplified)
        sc_uint<32> val_a = a(hi, lo).to_uint();
        sc_uint<32> val_b = b(hi, lo).to_uint();
        res(hi, lo) = (val_a * val_b); // Truncated to element width
    }
    return res;
}

// Mock LUT behavior
sc_biguint<DLEN> hp_vpu_lanes::alu_lut(vpu_op_e op, sc_biguint<DLEN> idx, sew_e sew) {
    // Return dummy non-zero value for correlation
    return ~idx;
}

void hp_vpu_lanes::logic_thread() {
    // Reset
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

        // E2 accepts from E1m if valid, OR from E1 if non-mul
        if (e1m_valid) {
            e2_valid = true;
            e2_op = e1m_op;
            e2_sew = e1m_sew;
            e2_vd = e1m_vd;
            e2_id = e1m_id;

            // MAC Add logic (simplified)
            if (e1m_op == OP_VMACC) {
                e2_result = alu_add(e1m_mul_res, e1m_c, e1m_sew);
            } else {
                e2_result = e1m_mul_res;
            }

            e1m_valid = false; // Drain E1m
        } else if (e1_valid && !e1_is_mul) {
            e2_valid = true;
            e2_op = e1_op;
            e2_sew = e1_sew;
            e2_vd = e1_vd;
            e2_id = e1_id;

            // ALU Logic
            if (e1_op == OP_VADD) e2_result = alu_add(e1_a, e1_b, e1_sew);
            else if (e1_op == OP_VEXP) e2_result = alu_lut(e1_op, e1_a, e1_sew); // LUT
            else e2_result = e1_b; // Pass through (e.g. vid/vmv)

            // Clear E1 (it moved to E2)
            e1_valid = false;
        } else {
            e2_valid = false;
        }

        // E1m Capture (from E1 if mul)
        // Note: Simultaneous drain+capture logic from RTL v1.6
        if (e1_valid && e1_is_mul) {
            e1m_valid = true;
            e1m_op = e1_op;
            e1m_sew = e1_sew;
            e1m_vd = e1_vd;
            e1m_id = e1_id;
            e1m_c = e1_c; // Accumulator
            // Multiply logic
            e1m_mul_res = alu_mul(e1_a, e1_b, e1_sew);

            e1_valid = false; // Moved to E1m
        }

        // E1 Capture (from Inputs)
        if (valid_i.read()) {
            // Check backpressure? (simplified: infinite IQ for model)
            // In reality, E1 capture depends on stalls.
            // If E1 is full (valid=true) and didn't move, we drop input?
            // RTL holds IQ ready low. Here we assume testbench respects ready (not modeled).
            // But if E1 cleared above, we can accept.
            if (!e1_valid) {
               e1_valid = true;
               e1_op = (vpu_op_e)op_i.read();
               e1_sew = (sew_e)sew_i.read();
               e1_vd = vd_i.read();
               e1_id = id_i.read();

               // Operand setup
               sc_biguint<DLEN> op_a = vs2_i.read(); // vs2
               sc_biguint<DLEN> op_b;
               if (is_vx_i.read()) {
                   // Scalar broadcast
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

    // Hazard info
    e1_valid_o.write(e1_valid);
    e1_vd_o.write(e1_vd);
    e1m_valid_o.write(e1m_valid);
    e1m_vd_o.write(e1m_vd);
    e2_valid_o.write(e2_valid);
    e2_vd_o.write(e2_vd);
    e3_valid_o.write(e3_valid);
    e3_vd_o.write(e3_vd);

    // Stalls
    mul_stall_o.write(e1_valid && e1m_valid); // Roughly
    mac_stall_o.write(false);
}

} // namespace hp_vpu
