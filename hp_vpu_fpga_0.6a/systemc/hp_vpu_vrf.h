#ifndef HP_VPU_VRF_H
#define HP_VPU_VRF_H

#include <systemc.h>
#include "hp_vpu_pkg.h"

namespace hp_vpu {

SC_MODULE(hp_vpu_vrf) {
    // Clock/Reset
    sc_in<bool> clk;

    // Read Ports (Async/Sync depending on RTL behavior, usually Sync in FPGA RAM)
    // RTL hp_vpu_vrf.sv usually has sync read.
    // D2 -> OF reads vs1, vs2, vs3.
    sc_in<sc_uint<5>> raddr1_i;
    sc_in<sc_uint<5>> raddr2_i;
    sc_in<sc_uint<5>> raddr3_i;
    sc_in<sc_uint<5>> raddr_mask_i; // v0 mask read

    sc_out<sc_biguint<DLEN>> rdata1_o;
    sc_out<sc_biguint<DLEN>> rdata2_o;
    sc_out<sc_biguint<DLEN>> rdata3_o;
    sc_out<sc_biguint<DLEN>> rdata_mask_o;

    // Write Port
    sc_in<bool> we_i;
    sc_in<sc_uint<5>> waddr_i;
    sc_in<sc_biguint<DLEN>> wdata_i;

    // Storage
    sc_biguint<DLEN> regs[32];

    void read_logic() {
        // Model synchronous BRAM read latency if needed,
        // but RTL hp_vpu_vrf usually provides data in OF cycle.
        // If OF captures in posedge, we can provide data combinatorially from array
        // and let OF register capture it.
        rdata1_o.write(regs[raddr1_i.read()]);
        rdata2_o.write(regs[raddr2_i.read()]);
        rdata3_o.write(regs[raddr3_i.read()]);
        rdata_mask_o.write(regs[0]); // Mask always v0? Or indexed? v0.
    }

    void write_logic() {
        if (we_i.read()) {
            regs[waddr_i.read()] = wdata_i.read();
            // cout << "@" << sc_time_stamp() << " VRF Write v" << waddr_i.read() << " = " << wdata_i.read() << endl;
        }
    }

    SC_CTOR(hp_vpu_vrf) {
        SC_METHOD(read_logic);
        sensitive << raddr1_i << raddr2_i << raddr3_i << raddr_mask_i; // Sensitive to address changes (asynch read model for simplicity, captured by pipeline regs)

        SC_METHOD(write_logic);
        sensitive << clk.pos();

        // Initialize
        for(int i=0; i<32; i++) regs[i] = 0;
    }
};

} // namespace hp_vpu

#endif // HP_VPU_VRF_H
