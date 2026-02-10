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

    // Inputs
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

    // Outputs
    sc_out<bool> valid_o;
    sc_out<sc_biguint<DLEN>> result_o;
    sc_out<sc_uint<5>> vd_o;
    sc_out<sc_uint<CVXIF_ID_W>> id_o;
    sc_out<bool> mac_stall_o;
    sc_out<bool> mul_stall_o;

    // Hazard tracking outputs (simplified)
    sc_out<bool> e1_valid_o;
    sc_out<sc_uint<5>> e1_vd_o;
    sc_out<bool> e1m_valid_o;
    sc_out<sc_uint<5>> e1m_vd_o;
    sc_out<bool> e2_valid_o;
    sc_out<sc_uint<5>> e2_vd_o;
    sc_out<bool> e3_valid_o;
    sc_out<sc_uint<5>> e3_vd_o;

    // Internal Pipeline Registers
    // E1 Stage
    bool e1_valid;
    vpu_op_e e1_op;
    sc_biguint<DLEN> e1_a, e1_b, e1_c;
    sc_uint<5> e1_vd;
    sc_uint<CVXIF_ID_W> e1_id;
    sew_e e1_sew;

    // E1m Stage
    bool e1m_valid;
    vpu_op_e e1m_op;
    sc_biguint<DLEN> e1m_mul_res; // Simplified: storing full mul result
    sc_uint<5> e1m_vd;
    sc_uint<CVXIF_ID_W> e1m_id;
    sew_e e1m_sew;
    sc_biguint<DLEN> e1m_c; // Accumulator passed through

    // E2 Stage
    bool e2_valid;
    vpu_op_e e2_op;
    sc_biguint<DLEN> e2_result;
    sc_uint<5> e2_vd;
    sc_uint<CVXIF_ID_W> e2_id;
    sew_e e2_sew;

    // E3 Stage
    bool e3_valid;
    sc_biguint<DLEN> e3_result;
    sc_uint<5> e3_vd;
    sc_uint<CVXIF_ID_W> e3_id;

    void logic_thread();
    void outputs_method();

    SC_CTOR(hp_vpu_lanes) {
        SC_CTHREAD(logic_thread, clk.pos());
        reset_signal_is(rst_n, false);
        SC_METHOD(outputs_method);
        sensitive << clk; // Just to update outputs based on internal state
    }

    // Helper ALU functions
    sc_biguint<DLEN> alu_add(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew);
    sc_biguint<DLEN> alu_mul(sc_biguint<DLEN> a, sc_biguint<DLEN> b, sew_e sew);
    sc_biguint<DLEN> alu_lut(vpu_op_e op, sc_biguint<DLEN> idx, sew_e sew);
};

} // namespace hp_vpu

#endif // HP_VPU_LANES_H
