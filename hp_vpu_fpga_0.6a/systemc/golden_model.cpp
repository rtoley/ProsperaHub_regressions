#include "golden_model.h"

namespace hp_vpu {

// LUT Tables (Truncated for brevity)
const uint16_t GoldenModel::exp_table[256] = { /* ... */ };
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
    else if (op == OP_VMUL) res = do_mul(op_a, op_b, sew, false, true, true);
    else if (op == OP_VMULH) res = do_mul(op_a, op_b, sew, true, true, true);
    else if (op == OP_VMULHU) res = do_mul(op_a, op_b, sew, true, false, false);
    else if (op == OP_VMULHSU) res = do_mul(op_a, op_b, sew, true, true, false);
    else if (op == OP_VMACC) { // vd = vd + vs1*vs2
        sc_biguint<DLEN> prod = do_mul(op_a, op_b, sew, false, true, true);
        res = do_add_sub(prod, vs3_data, sew, false);
    }
    else if (op == OP_VNMSAC) { // vd = vd - vs1*vs2
        sc_biguint<DLEN> prod = do_mul(op_a, op_b, sew, false, true, true);
        res = do_add_sub(vs3_data, prod, sew, true);
    }
    else if (op == OP_VMADD) { // vd = vs1*vd + vs2
        sc_biguint<DLEN> prod = do_mul(op_b, vs3_data, sew, false, true, true);
        res = do_add_sub(prod, op_a, sew, false);
    }
    else if (op == OP_VNMSUB) { // vd = vs2 - vs1*vd
        sc_biguint<DLEN> prod = do_mul(op_b, vs3_data, sew, false, true, true);
        res = do_add_sub(op_a, prod, sew, true);
    }
    else if (op >= OP_VWMACCU && op <= OP_VWMACCSU) { // Widening MACs
         res = do_widening(op, op_a, op_b, vs3_data, sew);
    }
    else if (op == OP_VAND || op == OP_VOR || op == OP_VXOR) res = do_logic(op_a, op_b, op);
    else if (op == OP_VSLL || op == OP_VSRL || op == OP_VSRA || op == OP_VSSRL || op == OP_VSSRA) res = do_shift(op_a, op_b, sew, op);
    else if (op >= OP_VMINU && op <= OP_VMAX) res = do_minmax(op_a, op_b, sew, op);
    else if (op >= OP_VSADDU && op <= OP_VSSUB) {
        // Inline Saturation Logic using standard ints
        int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
        int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;
        int64_t smax = (1LL << (elem_width - 1)) - 1;
        int64_t smin = -(1LL << (elem_width - 1));
        uint64_t umax = (1ULL << elem_width) - 1;

        for (int i = 0; i < num_elem; ++i) {
            int lo = i * elem_width; int hi = lo + elem_width - 1;
            sc_uint<32> ua = op_a(hi, lo).to_uint();
            sc_uint<32> ub = op_b(hi, lo).to_uint();

            int64_t sa = (sew==SEW_8)?(int64_t)(int8_t)ua:(sew==SEW_16)?(int64_t)(int16_t)ua:(int64_t)(int32_t)ua;
            int64_t sb = (sew==SEW_8)?(int64_t)(int8_t)ub:(sew==SEW_16)?(int64_t)(int16_t)ub:(int64_t)(int32_t)ub;
            uint64_t u_a = (uint64_t)ua;
            uint64_t u_b = (uint64_t)ub;

            uint64_t r_u = 0;
            int64_t r_s = 0;
            bool is_signed = false;

            if (op == OP_VSADDU) {
                uint64_t sum = u_a + u_b;
                if (sum > umax) r_u = umax; else r_u = sum;
            } else if (op == OP_VSADD) {
                int64_t sum = sa + sb;
                if (sum > smax) r_s = smax; else if (sum < smin) r_s = smin; else r_s = sum;
                is_signed = true;
            } else if (op == OP_VSSUBU) {
                if (u_a < u_b) r_u = 0; else r_u = u_a - u_b;
            } else if (op == OP_VSSUB) {
                int64_t diff = sa - sb;
                if (diff > smax) r_s = smax; else if (diff < smin) r_s = smin; else r_s = diff;
                is_signed = true;
            }
            if (is_signed) res(hi, lo) = (sc_int<64>)r_s;
            else res(hi, lo) = (sc_uint<64>)r_u;
        }
    }
    else if (op >= OP_VMSEQ && op <= OP_VMSGTU) res = do_cmp(op_a, op_b, sew, op);
    else if (op >= OP_VEXP && op <= OP_VGELU) res = do_lut(op, op_a, sew);
    else if (op >= OP_VREDSUM && op <= OP_VREDMAX) res = do_reduction(op, op_a, op_b, sew);
    else if (op >= OP_VWMUL && op <= OP_VWSUBU) res = do_widening(op, op_a, op_b, vs3_data, sew);
    else if (op == OP_VSLIDEUP || op == OP_VSLIDEDN || op == OP_VSLIDE1UP || op == OP_VSLIDE1DN)
        res = do_slide(op, op_a, vs3_data, scalar, sew);
    else if (op == OP_VRGATHER || op == OP_VRGATHEREI16)
        res = do_gather(op, op_a, op_b, sew);
    else if (op == OP_VMV || op == OP_VMERGE) res = op_b;
    else res = 0;

    // Apply Mask
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

        sc_uint<32> ua = a(hi, lo).to_uint();
        sc_uint<32> ub = b(hi, lo).to_uint();

        int64_t sa = (sew==SEW_8)?(int64_t)(int8_t)ua : (sew==SEW_16)?(int64_t)(int16_t)ua : (int64_t)(int32_t)ua;
        int64_t sb = (sew==SEW_8)?(int64_t)(int8_t)ub : (sew==SEW_16)?(int64_t)(int16_t)ub : (int64_t)(int32_t)ub;

        uint64_t prod_u = (uint64_t)ua * (uint64_t)ub;
        int64_t prod_s = sa * sb;
        int64_t prod_su = sa * (int64_t)(uint64_t)ub;

        sc_uint<64> final_prod;
        if (signed_a && signed_b) final_prod = (uint64_t)prod_s;
        else if (!signed_a && !signed_b) final_prod = prod_u;
        else final_prod = (uint64_t)prod_su;

        if (high) res(hi, lo) = (final_prod >> elem_width);
        else      res(hi, lo) = final_prod;
    }
    return res;
}

sc_biguint<DLEN> GoldenModel::do_logic(sc_biguint<DLEN> a, sc_biguint<DLEN> b, vpu_op_e op) {
    if (op == OP_VAND) return a & b;
    if (op == OP_VOR) return a | b;
    return a ^ b;
}

sc_biguint<DLEN> GoldenModel::do_shift(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, vpu_op_e op) {
    sc_biguint<DLEN> res = 0;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;

    for (int i = 0; i < num_elem; ++i) {
        int lo = i * elem_width; int hi = lo + elem_width - 1;
        sc_uint<32> val = a(hi, lo).to_uint();
        sc_uint<5> shamt = b(lo + 4, lo).to_uint();

        if (op == OP_VSLL) res(hi, lo) = val << shamt;
        else if (op == OP_VSRL) res(hi, lo) = val >> shamt;
        else if (op == OP_VSRA) {
            if (sew==SEW_8) res(hi,lo) = (sc_int<8>)val >> shamt;
            else if (sew==SEW_16) res(hi,lo) = (sc_int<16>)val >> shamt;
            else res(hi,lo) = (sc_int<32>)val >> shamt;
        }
    }
    return res;
}

sc_biguint<DLEN> GoldenModel::do_minmax(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, vpu_op_e op) {
    sc_biguint<DLEN> res = 0;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;

    for (int i = 0; i < num_elem; ++i) {
        int lo = i * elem_width; int hi = lo + elem_width - 1;
        sc_uint<32> ua = a(hi, lo).to_uint();
        sc_uint<32> ub = b(hi, lo).to_uint();
        int64_t sa = (sew==SEW_8)?(int64_t)(int8_t)ua : (sew==SEW_16)?(int64_t)(int16_t)ua : (int64_t)(int32_t)ua;
        int64_t sb = (sew==SEW_8)?(int64_t)(int8_t)ub : (sew==SEW_16)?(int64_t)(int16_t)ub : (int64_t)(int32_t)ub;

        if (op == OP_VMINU) res(hi, lo) = (ua < ub) ? ua : ub;
        else if (op == OP_VMIN) res(hi, lo) = (sa < sb) ? (sc_uint<32>)(int32_t)sa : (sc_uint<32>)(int32_t)sb;
        else if (op == OP_VMAXU) res(hi, lo) = (ua > ub) ? ua : ub;
        else if (op == OP_VMAX) res(hi, lo) = (sa > sb) ? (sc_uint<32>)(int32_t)sa : (sc_uint<32>)(int32_t)sb;
    }
    return res;
}

sc_biguint<DLEN> GoldenModel::do_cmp(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, vpu_op_e op) {
    sc_biguint<DLEN> res = 0; // Mask result
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;

    for (int i = 0; i < num_elem; ++i) {
        int lo = i * elem_width; int hi = lo + elem_width - 1;
        sc_uint<32> ua = a(hi, lo).to_uint();
        sc_uint<32> ub = b(hi, lo).to_uint();
        int64_t sa = (sew==SEW_8)?(int64_t)(int8_t)ua : (sew==SEW_16)?(int64_t)(int16_t)ua : (int64_t)(int32_t)ua;
        int64_t sb = (sew==SEW_8)?(int64_t)(int8_t)ub : (sew==SEW_16)?(int64_t)(int16_t)ub : (int64_t)(int32_t)ub;

        bool bit = false;
        if (op == OP_VMSEQ) bit = (ua == ub);
        else if (op == OP_VMSNE) bit = (ua != ub);
        else if (op == OP_VMSLTU) bit = (ua < ub);
        else if (op == OP_VMSLT) bit = (sa < sb);
        else if (op == OP_VMSLEU) bit = (ua <= ub);
        else if (op == OP_VMSLE) bit = (sa <= sb);
        else if (op == OP_VMSGTU) bit = (ua > ub);
        else if (op == OP_VMSGT) bit = (sa > sb);

        res[i] = bit;
    }
    return res;
}

sc_biguint<DLEN> GoldenModel::do_lut(vpu_op_e op, sc_biguint<DLEN> idx, sew_e sew) {
    // Basic LUT simulation
    sc_biguint<DLEN> res = 0;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int idx_stride = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;
    for (int i = 0; i < num_elem; ++i) {
        int idx_lo = i * idx_stride; int idx_hi = idx_lo + 7;
        sc_uint<8> index = idx(idx_hi, idx_lo).to_uint();
        sc_uint<16> val = 0;
        if (op == OP_VEXP) val = index + 1;
        else if (op == OP_VRECIP) val = (index == 0) ? 0xFFFF : (32768 / index);
        int res_lo = i * ((sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32);
        int res_hi = res_lo + ((sew == SEW_8) ? 7 : (sew == SEW_16) ? 15 : 31);
        res(res_hi, res_lo) = val;
    }
    return res;
}

sc_biguint<DLEN> GoldenModel::do_reduction(vpu_op_e op, sc_biguint<DLEN> vs2, sc_biguint<DLEN> vs1, sew_e sew) {
    sc_biguint<DLEN> res = vs1;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;

    sc_uint<32> acc_u = vs1(elem_width-1, 0).to_uint();
    int64_t acc_s = (sew==SEW_8)?(int64_t)(int8_t)acc_u : (sew==SEW_16)?(int64_t)(int16_t)acc_u : (int64_t)(int32_t)acc_u;

    for (int i=0; i<num_elem; i++) {
        int lo = i*elem_width, hi = lo+elem_width-1;
        sc_uint<32> u = vs2(hi, lo).to_uint();
        int64_t s = (sew==SEW_8)?(int64_t)(int8_t)u : (sew==SEW_16)?(int64_t)(int16_t)u : (int64_t)(int32_t)u;

        if (op == OP_VREDSUM) {
             acc_s += s; // Wrap around
             acc_u += u;
        } else if (op == OP_VREDAND) acc_u &= u;
        else if (op == OP_VREDOR) acc_u |= u;
        else if (op == OP_VREDXOR) acc_u ^= u;
        else if (op == OP_VREDMINU) acc_u = (u < acc_u) ? u : acc_u;
        else if (op == OP_VREDMIN) acc_s = (s < acc_s) ? s : acc_s;
        else if (op == OP_VREDMAXU) acc_u = (u > acc_u) ? u : acc_u;
        else if (op == OP_VREDMAX) acc_s = (s > acc_s) ? s : acc_s;
    }

    // Result
    res = 0;
    if (op == OP_VREDSUM || op == OP_VREDMIN || op == OP_VREDMAX) res(elem_width-1, 0) = (sc_uint<32>)(int32_t)acc_s;
    else res(elem_width-1, 0) = acc_u;

    return res;
}

sc_biguint<DLEN> GoldenModel::do_widening(vpu_op_e op, sc_biguint<DLEN> vs2, sc_biguint<DLEN> vs1, sc_biguint<DLEN> acc, sew_e sew) {
    sc_biguint<DLEN> res = 0;
    int num_elem = (sew == SEW_8) ? DLEN/16 : (sew == SEW_16) ? DLEN/32 : DLEN/64;
    int in_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;
    int out_width = in_width * 2;

    for (int i=0; i<num_elem; i++) {
        int lo = i*in_width; int hi = lo+in_width-1;
        sc_uint<32> u1 = vs2(hi, lo).to_uint();
        sc_uint<32> u2 = vs1(hi, lo).to_uint();
        int64_t s1 = (sew==SEW_8)?(int64_t)(int8_t)u1 : (sew==SEW_16)?(int64_t)(int16_t)u1 : (int64_t)(int32_t)u1;
        int64_t s2 = (sew==SEW_8)?(int64_t)(int8_t)u2 : (sew==SEW_16)?(int64_t)(int16_t)u2 : (int64_t)(int32_t)u2;

        uint64_t res_u = 0; int64_t res_s = 0;
        bool is_signed = false;

        if (op == OP_VWMUL) { res_s = s1 * s2; is_signed = true; }
        else if (op == OP_VWMULU) { res_u = (uint64_t)u1 * (uint64_t)u2; }
        else if (op == OP_VWMULSU) { res_s = s1 * (uint64_t)u2; is_signed = true; }
        else if (op == OP_VWADD) { res_s = s1 + s2; is_signed = true; }
        else if (op == OP_VWADDU) { res_u = (uint64_t)u1 + (uint64_t)u2; }
        else if (op == OP_VWSUB) { res_s = s1 - s2; is_signed = true; }
        else if (op == OP_VWSUBU) { res_u = (uint64_t)u1 - (uint64_t)u2; }
        else if (op == OP_VWMACC) {
             int acc_lo = i*out_width; int acc_hi = acc_lo+out_width-1;
             int64_t old = (int64_t)(sc_int<64>)acc(acc_hi, acc_lo);
             res_s = old + s1 * s2; is_signed = true;
        }

        int out_lo = i*out_width; int out_hi = out_lo+out_width-1;
        if (is_signed) res(out_hi, out_lo) = (sc_uint<64>)res_s;
        else           res(out_hi, out_lo) = (sc_uint<64>)res_u;
    }
    return res;
}

sc_biguint<DLEN> GoldenModel::do_slide(vpu_op_e op, sc_biguint<DLEN> vs2, sc_biguint<DLEN> old_vd, sc_uint<32> scalar, sew_e sew) {
    sc_biguint<DLEN> res = old_vd;
    int num_elem = (sew == SEW_8) ? DLEN/8 : (sew == SEW_16) ? DLEN/16 : DLEN/32;
    int elem_width = (sew == SEW_8) ? 8 : (sew == SEW_16) ? 16 : 32;
    int offset = scalar.to_int();

    for (int i=0; i<num_elem; i++) {
        int src_idx = -1;
        if (op == OP_VSLIDEUP) {
            if (i >= offset) src_idx = i - offset;
        } else if (op == OP_VSLIDEDN) {
             if (i + offset < num_elem) src_idx = i + offset;
        }

        if (src_idx >= 0 && src_idx < num_elem) {
             res((i+1)*elem_width-1, i*elem_width) = vs2((src_idx+1)*elem_width-1, src_idx*elem_width);
        }
    }
    return res;
}

sc_biguint<DLEN> GoldenModel::do_gather(vpu_op_e op, sc_biguint<DLEN> vs2, sc_biguint<DLEN> vs1, sew_e sew) {
    // Implement VRGATHER
    return 0;
}

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
