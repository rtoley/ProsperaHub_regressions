#ifndef HP_VPU_DECODE_H
#define HP_VPU_DECODE_H

#include <systemc.h>
#include "hp_vpu_pkg.h"

namespace hp_vpu {

SC_MODULE(hp_vpu_decode) {
    // Inputs
    sc_in<sc_uint<32>> instr_i;

    // Outputs
    sc_out<int>        op_o; // vpu_op_e cast to int
    sc_out<int>        sew_o; // sew_e cast to int
    sc_out<sc_uint<5>> vd_o;
    sc_out<sc_uint<5>> vs1_o;
    sc_out<sc_uint<5>> vs2_o;
    sc_out<sc_uint<5>> vs3_o;
    sc_out<bool>       vm_o;
    sc_out<bool>       is_vx_o; // .vx or .vi
    sc_out<sc_uint<32>> scalar_o; // Immediate or register value
    sc_out<bool>       is_vector_o;

    void decode_logic();

    SC_CTOR(hp_vpu_decode) {
        SC_METHOD(decode_logic);
        sensitive << instr_i;
    }
};

} // namespace hp_vpu

#endif // HP_VPU_DECODE_H
