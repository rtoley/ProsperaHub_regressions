#ifndef GOLDEN_MODEL_H
#define GOLDEN_MODEL_H

#include <systemc.h>
#include "hp_vpu_pkg.h"
#include <cmath>
#include <iostream>

namespace hp_vpu {

// C++ Golden Model for Hyperplane VPU
// Mirrors the logic of compute_golden_result in hp_vpu_tb.sv
class GoldenModel {
public:
    // Compute expected result for a given operation and inputs
    static sc_biguint<DLEN> compute(
        vpu_op_e op,
        sew_e sew,
        sc_biguint<DLEN> vs1_data,
        sc_biguint<DLEN> vs2_data,
        sc_biguint<DLEN> vs3_data, // old_vd/accumulator
        sc_biguint<DLEN> vmask,
        bool vm,
        bool is_vx,
        sc_uint<32> scalar
    );

private:
    // Helpers
    static sc_biguint<DLEN> apply_mask(sc_biguint<DLEN> res, sc_biguint<DLEN> old, sc_biguint<DLEN> mask, bool vm, sew_e sew);

    // ALU implementations
    static sc_biguint<DLEN> do_add_sub(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, bool is_sub);
    static sc_biguint<DLEN> do_mul(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, bool high, bool signed_a, bool signed_b);
    static sc_biguint<DLEN> do_logic(sc_biguint<DLEN> a, sc_biguint<DLEN> b, vpu_op_e op);
    static sc_biguint<DLEN> do_shift(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, vpu_op_e op);
    static sc_biguint<DLEN> do_minmax(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, vpu_op_e op);
    static sc_biguint<DLEN> do_cmp(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, vpu_op_e op);
    static sc_biguint<DLEN> do_lut(vpu_op_e op, sc_biguint<DLEN> idx, sew_e sew);
    static sc_biguint<DLEN> do_reduction(vpu_op_e op, sc_biguint<DLEN> vs2, sc_biguint<DLEN> vs1, sew_e sew);
    static sc_biguint<DLEN> do_widening(vpu_op_e op, sc_biguint<DLEN> vs2, sc_biguint<DLEN> vs1, sc_biguint<DLEN> acc, sew_e sew);
    static sc_biguint<DLEN> do_slide(vpu_op_e op, sc_biguint<DLEN> vs2, sc_biguint<DLEN> old_vd, sc_uint<32> scalar, sew_e sew);
    static sc_biguint<DLEN> do_gather(vpu_op_e op, sc_biguint<DLEN> vs2, sc_biguint<DLEN> vs1, sew_e sew);

    // LUT tables
    static const uint16_t exp_table[256];
    static const uint16_t recip_table[256];
    static const uint16_t rsqrt_table[256];
    static const uint16_t gelu_table[256];
};

} // namespace hp_vpu

#endif // GOLDEN_MODEL_H
