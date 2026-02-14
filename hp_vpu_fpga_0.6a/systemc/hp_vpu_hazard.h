#ifndef HP_VPU_HAZARD_H
#define HP_VPU_HAZARD_H

#include <systemc.h>
#include "hp_vpu_pkg.h"

namespace hp_vpu {

SC_MODULE(hp_vpu_hazard) {
    // Inputs: Decode (Destination/Sources)
    sc_in<bool> d_valid_i;
    sc_in<sc_uint<5>> d_vd_i;
    sc_in<sc_uint<5>> d_vs1_i;
    sc_in<sc_uint<5>> d_vs2_i;
    sc_in<sc_uint<5>> d_vs3_i;

    // Pipeline Stages (for RAW hazard detection)
    // OF: Operand Fetch (1 cycle after Decode)
    sc_in<bool> of_valid_i; sc_in<sc_uint<5>> of_vd_i;

    // E1, E1m, E2, E3 (Execution)
    sc_in<bool> e1_valid_i; sc_in<sc_uint<5>> e1_vd_i;
    sc_in<bool> e1m_valid_i; sc_in<sc_uint<5>> e1m_vd_i;
    sc_in<bool> e2_valid_i; sc_in<sc_uint<5>> e2_vd_i;
    sc_in<bool> e3_valid_i; sc_in<sc_uint<5>> e3_vd_i;

    // Reduction/Widening
    sc_in<bool> r2a_valid_i; sc_in<sc_uint<5>> r2a_vd_i;
    sc_in<bool> r2b_valid_i; sc_in<sc_uint<5>> r2b_vd_i;
    sc_in<bool> w2_valid_i;  sc_in<sc_uint<5>> w2_vd_i;

    // Writeback (WB)
    sc_in<bool> wb_valid_i; sc_in<sc_uint<5>> wb_vd_i;

    // Multicycle Control
    sc_in<bool> multicycle_busy_i;
    sc_in<bool> drain_stall_i; // Request to drain before complex op

    // Outputs
    sc_out<bool> stall_dec_o; // Stalls Decode and IQ

    void hazard_logic() {
        bool hazard = false;

        // 1. Structural/Protocol Stalls
        if (multicycle_busy_i.read() || drain_stall_i.read()) {
            stall_dec_o.write(true);
            return;
        }

        // 2. RAW Hazard Detection
        if (d_valid_i.read()) {
            sc_uint<5> s1 = d_vs1_i.read();
            sc_uint<5> s2 = d_vs2_i.read();
            sc_uint<5> s3 = d_vs3_i.read();

            auto check_stage = [&](bool valid, sc_uint<5> vd) {
                if (!valid) return false;
                if (vd == 0) return false; // x0/v0 never hazards? v0 is mask, so it might.
                // Assuming v0 is hazardable.
                return (vd == s1 || vd == s2 || vd == s3);
            };

            if (check_stage(of_valid_i.read(), of_vd_i.read())) hazard = true;
            if (check_stage(e1_valid_i.read(), e1_vd_i.read())) hazard = true;
            if (check_stage(e1m_valid_i.read(), e1m_vd_i.read())) hazard = true;
            if (check_stage(e2_valid_i.read(), e2_vd_i.read())) hazard = true;
            if (check_stage(e3_valid_i.read(), e3_vd_i.read())) hazard = true;

            if (check_stage(r2a_valid_i.read(), r2a_vd_i.read())) hazard = true;
            if (check_stage(r2b_valid_i.read(), r2b_vd_i.read())) hazard = true;
            if (check_stage(w2_valid_i.read(), w2_vd_i.read())) hazard = true;

            if (check_stage(wb_valid_i.read(), wb_vd_i.read())) hazard = true;
        }

        stall_dec_o.write(hazard);
    }

    SC_CTOR(hp_vpu_hazard) {
        SC_METHOD(hazard_logic);
        sensitive << d_valid_i << d_vs1_i << d_vs2_i << d_vs3_i
                  << of_valid_i << of_vd_i
                  << e1_valid_i << e1_vd_i
                  << e1m_valid_i << e1m_vd_i
                  << e2_valid_i << e2_vd_i
                  << e3_valid_i << e3_vd_i
                  << r2a_valid_i << r2a_vd_i
                  << r2b_valid_i << r2b_vd_i
                  << w2_valid_i << w2_vd_i
                  << wb_valid_i << wb_vd_i
                  << multicycle_busy_i << drain_stall_i;
    }
};

} // namespace hp_vpu

#endif // HP_VPU_HAZARD_H
