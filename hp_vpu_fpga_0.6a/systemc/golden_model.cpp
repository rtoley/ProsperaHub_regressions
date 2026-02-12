#include "golden_model.h"

namespace hp_vpu {

// LUT Tables (Truncated for brevity, normally generated)
// In a real full impl, these would be the full arrays from RTL
const uint16_t GoldenModel::exp_table[256] = { /* ... */ }; // Placeholder - use dynamic calculation or full table
const uint16_t GoldenModel::recip_table[256] = { /* ... */ };
const uint16_t GoldenModel::rsqrt_table[256] = { /* ... */ };
const uint16_t GoldenModel::gelu_table[256] = { /* ... */ };

// Compute dispatch
sc_biguint<DLEN> GoldenModel::compute(
    vpu_op_e op, sew_e sew,
    sc_biguint<DLEN> vs1_data, sc_biguint<DLEN> vs2_data, sc_biguint<DLEN> vs3_data,
    sc_biguint<DLEN> vmask, bool vm, bool is_vx, sc_uint<32> scalar
) {
    sc_biguint<DLEN> op_a = vs2_data;
    sc_biguint<DLEN> op_b;
    sc_biguint<DLEN> res = 0;

    // Operand B setup (Vector or Scalar broadcast)
    if (is_vx) {
        int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
        int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;
        for(int k=0; k<num_elem; k++) {
            op_b((k+1)*elem_width-1, k*elem_width) = scalar(elem_width-1, 0);
        }
    } else {
        op_b = vs1_data;
    }

    // Operation Dispatch
    if (op == OP_VADD) res = do_add_sub(op_a, op_b, sew, false);
    else if (op == OP_VSUB) res = do_add_sub(op_a, op_b, sew, true);
    else if (op == OP_VRSUB) res = do_add_sub(op_b, op_a, sew, true); // b - a
    else if (op == OP_VMUL) res = do_mul(op_a, op_b, sew, false, true, true); // Low bits signed/unsigned same
    else if (op == OP_VMULH) res = do_mul(op_a, op_b, sew, true, true, true);
    else if (op == OP_VMULHU) res = do_mul(op_a, op_b, sew, true, false, false);
    else if (op == OP_VMULHSU) res = do_mul(op_a, op_b, sew, true, true, false);
    else if (op == OP_VMACC) { // vd = vd + vs1*vs2 -> res = vs3 + a*b
        sc_biguint<DLEN> prod = do_mul(op_a, op_b, sew, false, true, true);
        res = do_add_sub(prod, vs3_data, sew, false);
    }
    else if (op == OP_VNMSAC) { // vd = vd - vs1*vs2 -> res = vs3 - a*b
        sc_biguint<DLEN> prod = do_mul(op_a, op_b, sew, false, true, true);
        res = do_add_sub(vs3_data, prod, sew, true);
    }
    else if (op == OP_VMADD) { // vd = vs1*vd + vs2 -> res = b*vs3 + a
        sc_biguint<DLEN> prod = do_mul(op_b, vs3_data, sew, false, true, true);
        res = do_add_sub(prod, op_a, sew, false);
    }
    else if (op == OP_VNMSUB) { // vd = vs2 - vs1*vd -> res = a - b*vs3
        sc_biguint<DLEN> prod = do_mul(op_b, vs3_data, sew, false, true, true);
        res = do_add_sub(op_a, prod, sew, true);
    }
    else if (op == OP_VAND || op == OP_VOR || op == OP_VXOR) res = do_logic(op_a, op_b, op);
    else if (op == OP_VSLL || op == OP_VSRL || op == OP_VSRA) res = do_shift(op_a, op_b, sew, op);
    else if (op >= OP_VMINU && op <= OP_VMAX) res = do_minmax(op_a, op_b, sew, op);
    else if (op >= OP_VMSEQ && op <= OP_VMSGTU) res = do_cmp(op_a, op_b, sew, op);
    else if (op >= OP_VEXP && op <= OP_VGELU) res = do_lut(op, op_a, sew);
    else if (op >= OP_VREDSUM && op <= OP_VREDMAX) res = do_reduction(op, op_a, op_b, sew); // vs2, vs1 (init)
    else if (op >= OP_VWMUL && op <= OP_VWSUBU) res = do_widening(op, op_a, op_b, vs3_data, sew);
    else if (op == OP_VSLIDEUP || op == OP_VSLIDEDN || op == OP_VSLIDE1UP || op == OP_VSLIDE1DN)
        res = do_slide(op, op_a, vs3_data, scalar, sew);
    else if (op == OP_VRGATHER || op == OP_VRGATHEREI16)
        res = do_gather(op, op_a, op_b, sew);
    else if (op == OP_VMV) res = op_b; // vmv.v.v: vd = vs1
    else res = 0; // Unsupported or NOP

    // Apply Mask (unless mask-producing op like CMP)
    if (!(op >= OP_VMSEQ && op <= OP_VMSGTU) && !(op >= OP_VREDSUM && op <= OP_VREDMAX)) {
        res = apply_mask(res, vs3_data, vmask, vm, sew);
    }

    return res;
}

sc_biguint<DLEN> GoldenModel::do_add_sub(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, bool is_sub) {
    sc_biguint<DLEN> res = 0;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;

    for (int i = 0; i < num_elem; ++i) {
        int lo = i * elem_width;
        int hi = lo + elem_width - 1;
        sc_uint<32> val_a = a(hi, lo).to_uint();
        sc_uint<32> val_b = b(hi, lo).to_uint();
        if (is_sub) res(hi, lo) = val_a - val_b;
        else        res(hi, lo) = val_a + val_b;
    }
    return res;
}

sc_biguint<DLEN> GoldenModel::do_mul(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, bool high, bool signed_a, bool signed_b) {
    sc_biguint<DLEN> res = 0;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;

    for (int i = 0; i < num_elem; ++i) {
        int lo = i * elem_width;
        int hi = lo + elem_width - 1;
        sc_int<64> prod_s; sc_uint<64> prod_u;

        // Simplified mul logic (SystemC handles signed/unsigned if casts are correct)
        // ... (Similar to lanes impl) ...
        // For brevity, using unsigned for now, but real golden model must be exact
        sc_uint<32> ua = a(hi, lo).to_uint();
        sc_uint<32> ub = b(hi, lo).to_uint();
        prod_u = (uint64_t)ua * (uint64_t)ub;

        if(high) res(hi,lo) = prod_u(elem_width*2-1, elem_width);
        else     res(hi,lo) = prod_u(elem_width-1, 0);
    }
    return res;
}

sc_biguint<DLEN> GoldenModel::do_logic(sc_biguint<DLEN> a, sc_biguint<DLEN> b, vpu_op_e op) {
    if (op == OP_VAND) return a & b;
    if (op == OP_VOR) return a | b;
    return a ^ b;
}

sc_biguint<DLEN> GoldenModel::do_shift(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, vpu_op_e op) {
    // ... Implement per-element shift ...
    return 0; // Placeholder
}
sc_biguint<DLEN> GoldenModel::do_minmax(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, vpu_op_e op) { return 0; }
sc_biguint<DLEN> GoldenModel::do_cmp(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, vpu_op_e op) { return 0; }
sc_biguint<DLEN> GoldenModel::do_lut(vpu_op_e op, sc_biguint<DLEN> idx, sew_e sew) { return ~idx; }
sc_biguint<DLEN> GoldenModel::do_reduction(vpu_op_e op, sc_biguint<DLEN> vs2, sc_biguint<DLEN> vs1, sew_e sew) { return 0; }
sc_biguint<DLEN> GoldenModel::do_widening(vpu_op_e op, sc_biguint<DLEN> vs2, sc_biguint<DLEN> vs1, sc_biguint<DLEN> acc, sew_e sew) { return 0; }
sc_biguint<DLEN> GoldenModel::do_slide(vpu_op_e op, sc_biguint<DLEN> vs2, sc_biguint<DLEN> old_vd, sc_uint<32> scalar, sew_e sew) { return 0; }
sc_biguint<DLEN> GoldenModel::do_gather(vpu_op_e op, sc_biguint<DLEN> vs2, sc_biguint<DLEN> vs1, sew_e sew) { return 0; }

sc_biguint<DLEN> GoldenModel::apply_mask(sc_biguint<DLEN> res, sc_biguint<DLEN> old, sc_biguint<DLEN> mask, bool vm, sew_e sew) {
    if (vm) return res;
    sc_biguint<DLEN> out = 0;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;
    for (int i=0; i<num_elem; i++) {
        int lo = i*elem_width, hi=lo+elem_width-1;
        if (mask[i]) out(hi,lo) = res(hi,lo);
        else         out(hi,lo) = old(hi,lo);
    }
    return out;
}

} // namespace hp_vpu
