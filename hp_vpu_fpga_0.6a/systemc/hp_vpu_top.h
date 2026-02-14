#ifndef HP_VPU_TOP_H
#define HP_VPU_TOP_H

#include <systemc.h>
#include "hp_vpu_pkg.h"
#include "hp_vpu_iq.h"
#include "hp_vpu_decode.h"
#include "hp_vpu_hazard.h"
#include "hp_vpu_lanes.h"
#include "hp_vpu_vrf.h"

namespace hp_vpu {

SC_MODULE(hp_vpu_top) {
    // Clock/Reset
    sc_in<bool> clk;
    sc_in<bool> rst_n;

    // Issue Interface
    sc_in<bool> x_issue_valid_i;
    sc_in<sc_uint<32>> x_issue_instr_i;
    sc_in<sc_uint<CVXIF_ID_W>> x_issue_id_i;
    sc_in<sc_uint<32>> x_issue_rs1_i;
    sc_in<sc_uint<32>> x_issue_rs2_i;
    sc_out<bool> x_issue_ready_o;

    // CSR Interface
    sc_in<sc_uint<32>> csr_vtype_i;
    sc_in<sc_uint<32>> csr_vl_i;

    // DMA Interface
    sc_in<bool> dma_we_i;
    sc_in<sc_uint<5>> dma_addr_i;
    sc_in<sc_biguint<DLEN>> dma_wdata_i;

    // IQ <-> Decode Interface
    sc_signal<bool> iq_pop_valid;
    sc_signal<sc_uint<32>> iq_pop_instr;
    sc_signal<sc_uint<CVXIF_ID_W>> iq_pop_id;
    sc_signal<sc_uint<32>> iq_pop_rs1;
    sc_signal<sc_uint<32>> iq_pop_rs2;
    sc_signal<bool> dec_ready;

    // Decode <-> Lanes/Hazard Interface
    sc_signal<bool> dec_valid;
    sc_signal<int> dec_op;
    sc_signal<int> dec_sew;
    sc_signal<int> dec_lmul;
    sc_signal<sc_uint<5>> dec_vd, dec_vs1, dec_vs2, dec_vs3;
    sc_signal<bool> dec_vm;
    sc_signal<bool> dec_is_vx;
    sc_signal<sc_uint<32>> dec_scalar;
    sc_signal<sc_uint<CVXIF_ID_W>> dec_id;
    sc_signal<bool> dec_is_last_uop;

    sc_signal<bool> hazard_stall;

    // OF Stage Pipeline Registers
    sc_signal<bool> of_valid;
    sc_signal<int>  of_op;
    sc_signal<int>  of_sew;
    sc_signal<sc_uint<5>> of_vd;
    sc_signal<sc_uint<CVXIF_ID_W>> of_id;
    sc_signal<bool> of_is_last_uop;
    sc_signal<bool> of_vm;
    sc_signal<bool> of_is_vx;
    sc_signal<sc_uint<32>> of_scalar;
    sc_signal<sc_biguint<DLEN>> of_vmask; // Mask read from v0

    // VRF Read Data (Combinational output from VRF, but VRF has internal register)
    // Wait, VRF has registered read. So read address is latch in VRF.
    // The data appears 1 cycle later. This "1 cycle later" is the OF stage.
    // So Decode drives VRF address. Lanes read VRF data.
    // But Lanes are E1. So VRF read happens during D2->OF transition?
    // RTL: D2 presents address. OF captures data.
    // So VRF read latency aligns with OF stage.

    // Submodules
    hp_vpu_iq*     u_iq;
    hp_vpu_decode* u_decode;
    hp_vpu_hazard* u_hazard;
    hp_vpu_lanes*  u_lanes;
    hp_vpu_vrf*    u_vrf;

    // Lanes connectivity
    sc_signal<sc_biguint<DLEN>> s_vs1_data, s_vs2_data, s_vs3_data, s_vmask_data;
    sc_signal<bool> s_valid_o;
    sc_signal<sc_biguint<DLEN>> s_result_o;
    sc_signal<sc_uint<5>> s_vd_o;
    sc_signal<sc_uint<CVXIF_ID_W>> s_id_o;
    sc_signal<bool> s_is_last_uop_o;
    sc_signal<bool> s_mac_stall, s_mul_stall, s_multicycle_busy, s_drain_stall;

    // Hazard feedback signals (extended)
    sc_signal<bool> h_e1_valid, h_e1m_valid, h_e2_valid, h_e3_valid;
    sc_signal<sc_uint<5>> h_e1_vd, h_e1m_vd, h_e2_vd, h_e3_vd;
    sc_signal<bool> h_r2a_valid, h_r2b_valid;
    sc_signal<sc_uint<5>> h_r2a_vd, h_r2b_vd;
    sc_signal<bool> h_w2_valid; sc_signal<sc_uint<5>> h_w2_vd;

    // Dummy flush
    sc_signal<bool> s_flush;

    // Constant 0 addr for mask read (v0)
    sc_signal<sc_uint<5>> c_addr_v0;
    // Read enables
    sc_signal<bool> ren_all; // Simplified read enable
    sc_signal<bool> ren_mask;

    // Byte enables for write
    sc_signal<sc_biguint<DLEN/8>> vrf_be;

    // MUX signals for VRF Write Port
    sc_signal<bool> vrf_mux_we;
    sc_signal<sc_uint<5>> vrf_mux_waddr;
    sc_signal<sc_biguint<DLEN>> vrf_mux_wdata;

    // OF Stage Logic
    void of_stage_logic() {
        if (!rst_n.read() || s_flush.read()) {
            of_valid.write(false);
            of_op.write(OP_NOP);
            return;
        }

        // Stall logic: if hazard stall, freeze OF?
        // Or if hazard stall, bubble OF?
        // Usually hazard stalls decode. OF latches decode output if not stalled?
        // Simplified: stall freezes the pipeline shift.
        if (hazard_stall.read()) return;

        // Advance D -> OF
        if (dec_valid.read()) {
            of_valid.write(true);
            of_op.write(dec_op.read());
            of_sew.write(dec_sew.read());
            of_vd.write(dec_vd.read());
            of_id.write(dec_id.read());
            of_is_last_uop.write(dec_is_last_uop.read());
            of_vm.write(dec_vm.read());
            of_is_vx.write(dec_is_vx.read());
            of_scalar.write(dec_scalar.read());
        } else {
            of_valid.write(false);
        }
    }

    void vrf_control_logic() {
        c_addr_v0.write(0);
        s_flush.write(false);

        // Read enables - simple, always read if valid decode (power optimization skipped)
        ren_all.write(dec_valid.read());
        ren_mask.write(true); // Always read mask for simplicity

        // Write Byte Enables - Full width for now, or based on masking?
        // Ideally should come from Lanes/WB stage logic.
        // For this model level, we assume full write or handled by mask in lanes.
        // But VRF has be_i.
        sc_biguint<DLEN/8> all_ones = 0;
        all_ones = ~all_ones;
        vrf_be.write(all_ones);

        // Write Port MUX (DMA priority)
        if (dma_we_i.read()) {
            vrf_mux_we.write(true);
            vrf_mux_waddr.write(dma_addr_i.read());
            vrf_mux_wdata.write(dma_wdata_i.read());
        } else {
            vrf_mux_we.write(s_valid_o.read());
            vrf_mux_waddr.write(s_vd_o.read());
            vrf_mux_wdata.write(s_result_o.read());
        }
    }

    SC_CTOR(hp_vpu_top) {
        // Instantiate IQ
        u_iq = new hp_vpu_iq("u_iq");
        u_iq->clk(clk);
        u_iq->rst_n(rst_n);
        u_iq->push_valid_i(x_issue_valid_i);
        u_iq->push_instr_i(x_issue_instr_i);
        u_iq->push_id_i(x_issue_id_i);
        u_iq->push_rs1_i(x_issue_rs1_i);
        u_iq->push_rs2_i(x_issue_rs2_i);
        u_iq->push_ready_o(x_issue_ready_o);
        u_iq->pop_valid_o(iq_pop_valid);
        u_iq->pop_instr_o(iq_pop_instr);
        u_iq->pop_id_o(iq_pop_id);
        u_iq->pop_rs1_o(iq_pop_rs1);
        u_iq->pop_rs2_o(iq_pop_rs2);
        u_iq->pop_ready_i(dec_ready);
        u_iq->flush_i(s_flush);

        // Instantiate Decode
        u_decode = new hp_vpu_decode("u_decode");
        u_decode->clk(clk);
        u_decode->rst_n(rst_n);
        u_decode->valid_i(iq_pop_valid);
        u_decode->instr_i(iq_pop_instr);
        u_decode->id_i(iq_pop_id);
        u_decode->rs1_i(iq_pop_rs1);
        u_decode->rs2_i(iq_pop_rs2);
        u_decode->csr_vtype_i(csr_vtype_i);
        u_decode->csr_vl_i(csr_vl_i);
        u_decode->stall_i(hazard_stall);
        u_decode->ready_o(dec_ready);

        u_decode->valid_o(dec_valid);
        u_decode->op_o(dec_op);
        u_decode->sew_o(dec_sew);
        u_decode->lmul_o(dec_lmul);
        u_decode->vd_o(dec_vd);
        u_decode->vs1_o(dec_vs1);
        u_decode->vs2_o(dec_vs2);
        u_decode->vs3_o(dec_vs3);
        u_decode->vm_o(dec_vm);
        u_decode->is_vx_o(dec_is_vx);
        u_decode->scalar_o(dec_scalar);
        u_decode->id_o(dec_id);
        u_decode->is_last_uop_o(dec_is_last_uop);

        // Instantiate Hazard
        u_hazard = new hp_vpu_hazard("u_hazard");
        u_hazard->d_valid_i(dec_valid);
        u_hazard->d_vd_i(dec_vd);
        u_hazard->d_vs1_i(dec_vs1);
        u_hazard->d_vs2_i(dec_vs2);
        u_hazard->d_vs3_i(dec_vs3);

        u_hazard->of_valid_i(of_valid); u_hazard->of_vd_i(of_vd); // OF stage
        u_hazard->e1_valid_i(h_e1_valid); u_hazard->e1_vd_i(h_e1_vd);
        u_hazard->e1m_valid_i(h_e1m_valid); u_hazard->e1m_vd_i(h_e1m_vd);
        u_hazard->e2_valid_i(h_e2_valid); u_hazard->e2_vd_i(h_e2_vd);
        u_hazard->e3_valid_i(h_e3_valid); u_hazard->e3_vd_i(h_e3_vd);
        u_hazard->r2a_valid_i(h_r2a_valid); u_hazard->r2a_vd_i(h_r2a_vd);
        u_hazard->r2b_valid_i(h_r2b_valid); u_hazard->r2b_vd_i(h_r2b_vd);
        u_hazard->w2_valid_i(h_w2_valid); u_hazard->w2_vd_i(h_w2_vd);

        u_hazard->wb_valid_i(s_valid_o); u_hazard->wb_vd_i(s_vd_o); // WB stage (Writeback)

        u_hazard->stall_dec_o(hazard_stall);
        u_hazard->multicycle_busy_i(s_multicycle_busy);
        u_hazard->drain_stall_i(s_drain_stall);

        // Instantiate VRF
        u_vrf = new hp_vpu_vrf("u_vrf");
        u_vrf->clk(clk);
        // Address from Decode (Read in D2/OF)
        u_vrf->raddr1_i(dec_vs1);
        u_vrf->raddr2_i(dec_vs2);
        u_vrf->raddr3_i(dec_vs3);
        u_vrf->raddr_mask_i(c_addr_v0);

        u_vrf->ren1_i(ren_all);
        u_vrf->ren2_i(ren_all);
        u_vrf->ren3_i(ren_all);
        u_vrf->ren_mask_i(ren_mask);

        // Data to Lanes (Ready at OF/E1)
        u_vrf->rdata1_o(s_vs1_data);
        u_vrf->rdata2_o(s_vs2_data);
        u_vrf->rdata3_o(s_vs3_data);
        u_vrf->rdata_mask_o(s_vmask_data);

        u_vrf->we_i(vrf_mux_we);
        u_vrf->waddr_i(vrf_mux_waddr);
        u_vrf->wdata_i(vrf_mux_wdata);
        u_vrf->be_i(vrf_be);

        // Instantiate Lanes
        u_lanes = new hp_vpu_lanes("u_lanes");
        u_lanes->clk(clk);
        u_lanes->rst_n(rst_n);
        u_lanes->stall_i(s_flush); // Lanes generally don't stall, they drain

        // Lanes get inputs from OF registers
        u_lanes->valid_i(of_valid);
        u_lanes->op_i(of_op);

        // VRF Data (Ready at OF stage due to registered read)
        u_lanes->vs1_i(s_vs1_data);
        u_lanes->vs2_i(s_vs2_data);
        u_lanes->vs3_i(s_vs3_data);
        u_lanes->vmask_i(s_vmask_data);

        u_lanes->vm_i(of_vm);
        u_lanes->scalar_i(of_scalar);
        u_lanes->is_vx_i(of_is_vx);
        u_lanes->sew_i(of_sew);
        u_lanes->vd_i(of_vd);
        u_lanes->id_i(of_id);
        u_lanes->is_last_uop_i(of_is_last_uop);

        u_lanes->valid_o(s_valid_o);
        u_lanes->result_o(s_result_o);
        u_lanes->vd_o(s_vd_o);
        u_lanes->id_o(s_id_o);
        u_lanes->is_last_uop_o(s_is_last_uop_o);
        u_lanes->mac_stall_o(s_mac_stall);
        u_lanes->mul_stall_o(s_mul_stall);
        u_lanes->multicycle_busy_o(s_multicycle_busy);
        u_lanes->drain_stall_o(s_drain_stall);

        u_lanes->e1_valid_o(h_e1_valid); u_lanes->e1_vd_o(h_e1_vd);
        u_lanes->e1m_valid_o(h_e1m_valid); u_lanes->e1m_vd_o(h_e1m_vd);
        u_lanes->e2_valid_o(h_e2_valid); u_lanes->e2_vd_o(h_e2_vd);
        u_lanes->e3_valid_o(h_e3_valid); u_lanes->e3_vd_o(h_e3_vd);
        u_lanes->r2a_valid_o(h_r2a_valid); u_lanes->r2a_vd_o(h_r2a_vd);
        u_lanes->r2b_valid_o(h_r2b_valid); u_lanes->r2b_vd_o(h_r2b_vd);
        u_lanes->w2_valid_o(h_w2_valid); u_lanes->w2_vd_o(h_w2_vd);

        SC_METHOD(vrf_control_logic);
        sensitive << dma_we_i << dma_addr_i << dma_wdata_i << s_valid_o << s_vd_o << s_result_o << dec_valid;

        SC_METHOD(of_stage_logic);
        sensitive << clk.pos();
    }
};

} // namespace hp_vpu

#endif // HP_VPU_TOP_H
