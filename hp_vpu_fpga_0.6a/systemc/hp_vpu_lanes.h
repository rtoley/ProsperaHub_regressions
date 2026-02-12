#ifndef HP_VPU_LANES_H
#define HP_VPU_LANES_H

#include <systemc.h>
#include "hp_vpu_pkg.h"

namespace hp_vpu {

SC_MODULE(hp_vpu_lanes) {
    // Clock/Reset
    sc_in<bool> clk;
    sc_in<bool> rst_n;
    sc_in<bool> stall_i;

    // Inputs (from Decode)
    sc_in<bool> valid_i;
    sc_in<int>  op_i; // vpu_op_e
    sc_in<sc_biguint<DLEN>> vs1_i;
    sc_in<sc_biguint<DLEN>> vs2_i;
    sc_in<sc_biguint<DLEN>> vs3_i; // old_vd
    sc_in<sc_biguint<DLEN>> vmask_i;
    sc_in<bool> vm_i;
    sc_in<sc_uint<32>> scalar_i;
    sc_in<bool> is_vx_i;
    sc_in<int>  sew_i; // sew_e
    sc_in<sc_uint<5>> vd_i;
    sc_in<sc_uint<CVXIF_ID_W>> id_i;
    sc_in<bool> is_last_uop_i;

    // Outputs
    sc_out<bool> valid_o;
    sc_out<sc_biguint<DLEN>> result_o;
    sc_out<sc_uint<5>> vd_o;
    sc_out<sc_uint<CVXIF_ID_W>> id_o;
    sc_out<bool> is_last_uop_o;

    sc_out<bool> mac_stall_o;
    sc_out<bool> mul_stall_o;
    sc_out<bool> drain_stall_o;      // To Hazard
    sc_out<bool> multicycle_busy_o;  // To Hazard

    // Hazard tracking outputs
    sc_out<bool> e1_valid_o; sc_out<sc_uint<5>> e1_vd_o;
    sc_out<bool> e1m_valid_o; sc_out<sc_uint<5>> e1m_vd_o;
    sc_out<bool> e2_valid_o; sc_out<sc_uint<5>> e2_vd_o;
    sc_out<bool> e3_valid_o; sc_out<sc_uint<5>> e3_vd_o;
    sc_out<bool> r2a_valid_o; sc_out<sc_uint<5>> r2a_vd_o;
    sc_out<bool> r2b_valid_o; sc_out<sc_uint<5>> r2b_vd_o;
    sc_out<bool> w2_valid_o; sc_out<sc_uint<5>> w2_vd_o; // Missing in previous version

    // Internal Pipeline Registers
    // E1 Stage
    bool e1_valid;
    vpu_op_e e1_op;
    sc_biguint<DLEN> e1_a, e1_b, e1_c, e1_old_vd, e1_vmask;
    bool e1_vm;
    sc_uint<5> e1_vd;
    sc_uint<CVXIF_ID_W> e1_id;
    sew_e e1_sew;
    bool e1_is_last_uop;

    // E1m Stage
    bool e1m_valid;
    vpu_op_e e1m_op;
    sc_biguint<DLEN> e1m_mul_res;
    sc_uint<5> e1m_vd;
    sc_uint<CVXIF_ID_W> e1m_id;
    sew_e e1m_sew;
    sc_biguint<DLEN> e1m_c, e1m_old_vd, e1m_vmask;
    bool e1m_vm;
    bool e1m_is_last_uop;

    // E2 Stage
    bool e2_valid;
    vpu_op_e e2_op;
    sc_biguint<DLEN> e2_result, e2_old_vd, e2_vmask;
    bool e2_vm;
    sc_uint<5> e2_vd;
    sc_uint<CVXIF_ID_W> e2_id;
    sew_e e2_sew;
    bool e2_is_last_uop;

    // E3 Stage
    bool e3_valid;
    sc_biguint<DLEN> e3_result;
    sc_uint<5> e3_vd;
    sc_uint<CVXIF_ID_W> e3_id;
    bool e3_is_last_uop;

    // R1 Registers (Reduction)
    sc_biguint<DLEN> r1_vs2;
    sc_biguint<DLEN> r1_vs1;
    vpu_op_e r1_op;
    sew_e r1_sew;
    sc_uint<5> r1_vd;
    sc_uint<CVXIF_ID_W> r1_id;

    // W1 Registers (Widening)
    sc_biguint<DLEN> w1_vs2, w1_vs1, w1_old_vd;
    vpu_op_e w1_op;
    sew_e w1_sew;
    sc_uint<5> w1_vd;
    sc_uint<CVXIF_ID_W> w1_id;

    // Pipeline State Machines
    enum red_state_e { RED_IDLE, RED_R1, RED_R2A, RED_R2B, RED_R3 };
    sc_signal<int> red_state;

    enum wide_state_e { WIDE_IDLE, WIDE_W1, WIDE_W2 };
    sc_signal<int> wide_state;

    // Output Stage Registers (simplified mux inputs)
    bool r3_valid;
    sc_biguint<DLEN> r3_result;
    sc_uint<5> r3_vd;
    sc_uint<CVXIF_ID_W> r3_id;

    bool w2_valid;
    sc_biguint<DLEN> w2_result;
    sc_uint<5> w2_vd;
    sc_uint<CVXIF_ID_W> w2_id;

    void logic_thread();
    void outputs_method();

    SC_CTOR(hp_vpu_lanes) {
        SC_CTHREAD(logic_thread, clk.pos());
        reset_signal_is(rst_n, false);
        SC_METHOD(outputs_method);
        sensitive << clk; // Updates based on internal state
    }

    // ALU functions declarations (Fixed signatures)
    sc_biguint<DLEN> alu_add(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, bool is_sub);
    sc_biguint<DLEN> alu_mul(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, bool high_half, bool signed_a, bool signed_b);
    sc_biguint<DLEN> alu_lut(vpu_op_e op, sc_biguint<DLEN> idx, sew_e sew);
    sc_biguint<DLEN> alu_logic(sc_biguint<DLEN> a, sc_biguint<DLEN> b, vpu_op_e op);
    sc_biguint<DLEN> alu_shift(sc_biguint<DLEN> val, sc_biguint<DLEN> shamt, sew_e sew, vpu_op_e op);
    sc_biguint<DLEN> alu_minmax(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, vpu_op_e op);
    sc_biguint<DLEN> alu_cmp(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, vpu_op_e op);
    sc_biguint<DLEN> alu_sat(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew, vpu_op_e op);
    sc_biguint<DLEN> alu_int4(sc_biguint<DLEN> val, vpu_op_e op);

    // Helpers
    sc_biguint<DLEN> apply_mask(sc_biguint<DLEN> result, sc_biguint<DLEN> old_vd, sc_biguint<DLEN> mask, bool vm, sew_e sew);
    bool is_reduction(vpu_op_e op);
    bool is_widening(vpu_op_e op);
    sc_biguint<DLEN> scalar_replicate(sc_uint<32> scalar, sew_e sew);
};

} // namespace hp_vpu

#endif // HP_VPU_LANES_H
