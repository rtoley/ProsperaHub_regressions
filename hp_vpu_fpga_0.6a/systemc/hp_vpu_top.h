#ifndef HP_VPU_TOP_H
#define HP_VPU_TOP_H

#include <systemc.h>
#include "hp_vpu_pkg.h"
#include "hp_vpu_decode.h"
#include "hp_vpu_hazard.h"
#include "hp_vpu_lanes.h"
#include "hp_vpu_vrf.h" // Added VRF

namespace hp_vpu {

SC_MODULE(hp_vpu_top) {
    // Clock/Reset
    sc_in<bool> clk;
    sc_in<bool> rst_n;

    // Issue Interface
    sc_in<bool> x_issue_valid_i;
    sc_in<sc_uint<32>> x_issue_instr_i;
    sc_in<sc_uint<CVXIF_ID_W>> x_issue_id_i;
    sc_out<bool> x_issue_ready_o;

    // DMA Interface (for initializing VRF)
    sc_in<bool> dma_we_i;
    sc_in<sc_uint<5>> dma_addr_i;
    sc_in<sc_biguint<DLEN>> dma_wdata_i;

    // Internal Signals (Wires)
    sc_signal<int> dec_op;
    sc_signal<int> dec_sew;
    sc_signal<sc_uint<5>> dec_vd, dec_vs1, dec_vs2, dec_vs3;
    sc_signal<bool> dec_vm;
    sc_signal<bool> dec_is_vx;
    sc_signal<sc_uint<32>> dec_scalar;
    sc_signal<bool> dec_is_vector;

    sc_signal<bool> hazard_stall;

    // Submodules
    hp_vpu_decode* u_decode;
    hp_vpu_hazard* u_hazard;
    hp_vpu_lanes*  u_lanes;
    hp_vpu_vrf*    u_vrf; // Added VRF

    // Lanes connectivity
    sc_signal<sc_biguint<DLEN>> s_vs1_data, s_vs2_data, s_vs3_data, s_vmask;
    sc_signal<bool> s_valid_o;
    sc_signal<sc_biguint<DLEN>> s_result_o;
    sc_signal<sc_uint<5>> s_vd_o;
    sc_signal<sc_uint<CVXIF_ID_W>> s_id_o;
    sc_signal<bool> s_mac_stall, s_mul_stall;

    // VRF Mux signals (DMA priority)
    sc_signal<bool> vrf_we;
    sc_signal<sc_uint<5>> vrf_waddr;
    sc_signal<sc_biguint<DLEN>> vrf_wdata;

    // Hazard feedback signals
    sc_signal<bool> h_e1_valid, h_e1m_valid, h_e2_valid, h_e3_valid;
    sc_signal<sc_uint<5>> h_e1_vd, h_e1m_vd, h_e2_vd, h_e3_vd;

    // v0 (Mask) hardcoded read addr
    sc_signal<sc_uint<5>> c_addr_v0;

    void ready_logic() {
        x_issue_ready_o.write(!hazard_stall.read());
    }

    void vrf_control_logic() {
        if (dma_we_i.read()) {
            vrf_we.write(true);
            vrf_waddr.write(dma_addr_i.read());
            vrf_wdata.write(dma_wdata_i.read());
        } else {
            vrf_we.write(s_valid_o.read());
            vrf_waddr.write(s_vd_o.read());
            vrf_wdata.write(s_result_o.read());
        }
        c_addr_v0.write(0);
    }

    SC_CTOR(hp_vpu_top) {
        // Instantiate Decode
        u_decode = new hp_vpu_decode("u_decode");
        u_decode->instr_i(x_issue_instr_i);
        u_decode->op_o(dec_op);
        u_decode->sew_o(dec_sew);
        u_decode->vd_o(dec_vd);
        u_decode->vs1_o(dec_vs1);
        u_decode->vs2_o(dec_vs2);
        u_decode->vs3_o(dec_vs3);
        u_decode->vm_o(dec_vm);
        u_decode->is_vx_o(dec_is_vx);
        u_decode->scalar_o(dec_scalar);
        u_decode->is_vector_o(dec_is_vector);

        // Instantiate Hazard
        u_hazard = new hp_vpu_hazard("u_hazard");
        u_hazard->d_valid_i(x_issue_valid_i);
        u_hazard->d_vd_i(dec_vd);
        u_hazard->d_vs1_i(dec_vs1);
        u_hazard->d_vs2_i(dec_vs2);
        u_hazard->d_vs3_i(dec_vs3);
        u_hazard->e1_valid_i(h_e1_valid); u_hazard->e1_vd_i(h_e1_vd);
        u_hazard->e1m_valid_i(h_e1m_valid); u_hazard->e1m_vd_i(h_e1m_vd);
        u_hazard->e2_valid_i(h_e2_valid); u_hazard->e2_vd_i(h_e2_vd);
        u_hazard->e3_valid_i(h_e3_valid); u_hazard->e3_vd_i(h_e3_vd);
        u_hazard->stall_dec_o(hazard_stall);

        // Instantiate VRF
        u_vrf = new hp_vpu_vrf("u_vrf");
        u_vrf->clk(clk);
        u_vrf->raddr1_i(dec_vs1);
        u_vrf->raddr2_i(dec_vs2);
        u_vrf->raddr3_i(dec_vs3);
        u_vrf->raddr_mask_i(c_addr_v0);
        u_vrf->rdata1_o(s_vs1_data);
        u_vrf->rdata2_o(s_vs2_data);
        u_vrf->rdata3_o(s_vs3_data);
        u_vrf->rdata_mask_o(s_vmask);
        u_vrf->we_i(vrf_we);
        u_vrf->waddr_i(vrf_waddr);
        u_vrf->wdata_i(vrf_wdata);

        // Instantiate Lanes
        u_lanes = new hp_vpu_lanes("u_lanes");
        u_lanes->clk(clk);
        u_lanes->rst_n(rst_n);
        u_lanes->stall_i(hazard_stall);
        u_lanes->valid_i(x_issue_valid_i);
        u_lanes->op_i(dec_op);
        u_lanes->vs1_i(s_vs1_data);
        u_lanes->vs2_i(s_vs2_data);
        u_lanes->vs3_i(s_vs3_data);
        u_lanes->vmask_i(s_vmask);
        u_lanes->vm_i(dec_vm);
        u_lanes->scalar_i(dec_scalar);
        u_lanes->is_vx_i(dec_is_vx);
        u_lanes->sew_i(dec_sew);
        u_lanes->vd_i(dec_vd);
        u_lanes->id_i(x_issue_id_i);

        u_lanes->valid_o(s_valid_o);
        u_lanes->result_o(s_result_o);
        u_lanes->vd_o(s_vd_o);
        u_lanes->id_o(s_id_o);
        u_lanes->mac_stall_o(s_mac_stall);
        u_lanes->mul_stall_o(s_mul_stall);

        u_lanes->e1_valid_o(h_e1_valid); u_lanes->e1_vd_o(h_e1_vd);
        u_lanes->e1m_valid_o(h_e1m_valid); u_lanes->e1m_vd_o(h_e1m_vd);
        u_lanes->e2_valid_o(h_e2_valid); u_lanes->e2_vd_o(h_e2_vd);
        u_lanes->e3_valid_o(h_e3_valid); u_lanes->e3_vd_o(h_e3_vd);

        SC_METHOD(ready_logic);
        sensitive << hazard_stall;

        SC_METHOD(vrf_control_logic);
        sensitive << dma_we_i << dma_addr_i << dma_wdata_i << s_valid_o << s_vd_o << s_result_o;
    }
};

} // namespace hp_vpu

#endif // HP_VPU_TOP_H
