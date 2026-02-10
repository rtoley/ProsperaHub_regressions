#ifndef HP_VPU_HAZARD_H
#define HP_VPU_HAZARD_H

#include <systemc.h>
#include "hp_vpu_pkg.h"

namespace hp_vpu {

SC_MODULE(hp_vpu_hazard) {
    // Inputs
    sc_in<bool> d_valid_i;
    sc_in<sc_uint<5>> d_vd_i;
    sc_in<sc_uint<5>> d_vs1_i;
    sc_in<sc_uint<5>> d_vs2_i;
    sc_in<sc_uint<5>> d_vs3_i;

    // Pipeline stage valid/vd
    sc_in<bool> e1_valid_i; sc_in<sc_uint<5>> e1_vd_i;
    sc_in<bool> e1m_valid_i; sc_in<sc_uint<5>> e1m_vd_i;
    sc_in<bool> e2_valid_i; sc_in<sc_uint<5>> e2_vd_i;
    sc_in<bool> e3_valid_i; sc_in<sc_uint<5>> e3_vd_i;

    // Outputs
    sc_out<bool> stall_dec_o;

    void hazard_logic() {
        bool hazard = false;
        if (d_valid_i.read()) {
            sc_uint<5> s1 = d_vs1_i.read();
            sc_uint<5> s2 = d_vs2_i.read();
            sc_uint<5> s3 = d_vs3_i.read();

            // Check E1
            if (e1_valid_i.read()) {
                sc_uint<5> vd = e1_vd_i.read();
                if (vd == s1 || vd == s2 || vd == s3) hazard = true;
            }
            // Check E1m
            if (e1m_valid_i.read()) {
                sc_uint<5> vd = e1m_vd_i.read();
                if (vd == s1 || vd == s2 || vd == s3) hazard = true;
            }
            // Check E2
            if (e2_valid_i.read()) {
                sc_uint<5> vd = e2_vd_i.read();
                if (vd == s1 || vd == s2 || vd == s3) hazard = true;
            }
            // Check E3
            if (e3_valid_i.read()) {
                sc_uint<5> vd = e3_vd_i.read();
                if (vd == s1 || vd == s2 || vd == s3) hazard = true;
            }
        }
        stall_dec_o.write(hazard);
    }

    SC_CTOR(hp_vpu_hazard) {
        SC_METHOD(hazard_logic);
        sensitive << d_valid_i << d_vs1_i << d_vs2_i << d_vs3_i
                  << e1_valid_i << e1_vd_i
                  << e1m_valid_i << e1m_vd_i
                  << e2_valid_i << e2_vd_i
                  << e3_valid_i << e3_vd_i;
    }
};

} // namespace hp_vpu

#endif // HP_VPU_HAZARD_H
