#ifndef HP_VPU_DECODE_H
#define HP_VPU_DECODE_H

#include <systemc.h>
#include "hp_vpu_pkg.h"

namespace hp_vpu {

// v0.10: Updated Decode with 2-stage pipeline (D1->D2)
// D1: Pre-decode, vtype/vl handling, multicycle sequencer
// D2: Operand Fetch setup, hazard check interface
SC_MODULE(hp_vpu_decode) {
    // Clock/Reset
    sc_in<bool> clk;
    sc_in<bool> rst_n;

    // Input from IQ
    sc_in<bool> valid_i;
    sc_in<sc_uint<32>> instr_i;
    sc_in<sc_uint<CVXIF_ID_W>> id_i;
    sc_in<sc_uint<32>> rs1_i;
    sc_in<sc_uint<32>> rs2_i;

    // CSR Interface (for vtype/vl)
    sc_in<sc_uint<32>> csr_vtype_i;
    sc_in<sc_uint<32>> csr_vl_i;

    // Handshake
    sc_in<bool> stall_i; // Stall from hazard unit
    sc_out<bool> ready_o; // To IQ

    // D2 Outputs (to Hazard Unit & Lanes)
    sc_out<bool> valid_o;
    sc_out<int>  op_o; // vpu_op_e
    sc_out<int>  sew_o; // sew_e
    sc_out<int>  lmul_o;
    sc_out<sc_uint<5>> vd_o;
    sc_out<sc_uint<5>> vs1_o;
    sc_out<sc_uint<5>> vs2_o;
    sc_out<sc_uint<5>> vs3_o; // Accumulator
    sc_out<bool>       vm_o;
    sc_out<bool>       is_vx_o;
    sc_out<sc_uint<32>> scalar_o;
    sc_out<sc_uint<CVXIF_ID_W>> id_o;

    // Micro-op Control (for LMUL > 1)
    sc_out<bool> is_last_uop_o;

    // Internal state
    // D1 Registers
    sc_signal<bool> d1_valid;
    sc_signal<sc_uint<32>> d1_instr;
    sc_signal<sc_uint<CVXIF_ID_W>> d1_id;
    sc_signal<sc_uint<32>> d1_rs1;
    sc_signal<sc_uint<32>> d1_rs2;

    // vtype state (shadow)
    sc_signal<int> current_sew; // sew_e
    sc_signal<int> current_lmul;

    // Sequencer state
    sc_signal<int> uop_counter;
    sc_signal<int> uop_total;
    sc_signal<bool> in_multicycle_seq;

    void decode_pipeline();
    void output_logic();

    // Helper to decode raw instruction bits
    void decode_combinational(
        sc_uint<32> instr,
        vpu_op_e& op,
        sc_uint<5>& vd, sc_uint<5>& vs1, sc_uint<5>& vs2, bool& vm, bool& is_vx, sc_uint<32>& imm
    );

    SC_CTOR(hp_vpu_decode) {
        SC_CTHREAD(decode_pipeline, clk.pos());
        reset_signal_is(rst_n, false);

        SC_METHOD(output_logic);
        sensitive << d1_valid << d1_instr << d1_id << d1_rs1 << d1_rs2 << current_sew << current_lmul << stall_i;
    }
};

} // namespace hp_vpu

#endif // HP_VPU_DECODE_H
