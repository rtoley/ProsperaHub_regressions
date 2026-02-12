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
    // OF stage would be here if modeled explicitly (simplified to D2/E1 in model usually)
    sc_in<bool> e1_valid_i; sc_in<sc_uint<5>> e1_vd_i;
    sc_in<bool> e1m_valid_i; sc_in<sc_uint<5>> e1m_vd_i;
    sc_in<bool> e2_valid_i; sc_in<sc_uint<5>> e2_vd_i;
    sc_in<bool> e3_valid_i; sc_in<sc_uint<5>> e3_vd_i;

    // Reduction/Widening pipeline
    sc_in<bool> r2a_valid_i; sc_in<sc_uint<5>> r2a_vd_i;
    sc_in<bool> r2b_valid_i; sc_in<sc_uint<5>> r2b_vd_i;
    sc_in<bool> w2_valid_i;  sc_in<sc_uint<5>> w2_vd_i; // W2 stage for widening

    // Multicycle Control
    sc_in<bool> multicycle_busy_i;
    sc_in<bool> drain_stall_i;

    // Outputs
    sc_out<bool> stall_dec_o;

    void hazard_logic() {
        bool hazard = false;

        // Multicycle Busy or Drain Stall Stalls Decode
        if (multicycle_busy_i.read() || drain_stall_i.read()) {
            stall_dec_o.write(true);
            return;
        }

        if (d_valid_i.read()) {
            sc_uint<5> s1 = d_vs1_i.read();
            sc_uint<5> s2 = d_vs2_i.read();
            sc_uint<5> s3 = d_vs3_i.read();

            // Helper lambda for check
            auto check = [&](bool valid, sc_uint<5> vd) {
                if (valid && (vd == s1 || vd == s2 || vd == s3)) return true;
                return false;
            };

            // Check all stages
            if (check(e1_valid_i.read(), e1_vd_i.read())) hazard = true;
            if (check(e1m_valid_i.read(), e1m_vd_i.read())) hazard = true;
            if (check(e2_valid_i.read(), e2_vd_i.read())) hazard = true;
            if (check(e3_valid_i.read(), e3_vd_i.read())) hazard = true;

            // Check Reduction/Widening
            if (check(r2a_valid_i.read(), r2a_vd_i.read())) hazard = true;
            if (check(r2b_valid_i.read(), r2b_vd_i.read())) hazard = true;
            if (check(w2_valid_i.read(), w2_vd_i.read())) hazard = true;
        }
        stall_dec_o.write(hazard);
    }

    SC_CTOR(hp_vpu_hazard) {
        SC_METHOD(hazard_logic);
        sensitive << d_valid_i << d_vs1_i << d_vs2_i << d_vs3_i
                  << e1_valid_i << e1_vd_i
                  << e1m_valid_i << e1m_vd_i
                  << e2_valid_i << e2_vd_i
                  << e3_valid_i << e3_vd_i
                  << r2a_valid_i << r2a_vd_i
                  << r2b_valid_i << r2b_vd_i
                  << w2_valid_i << w2_vd_i
                  << multicycle_busy_i << drain_stall_i;
    }
};

} // namespace hp_vpu

#endif // HP_VPU_HAZARD_H
