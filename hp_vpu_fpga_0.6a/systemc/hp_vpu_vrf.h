#ifndef HP_VPU_VRF_H
#define HP_VPU_VRF_H

#include <systemc.h>
#include "hp_vpu_pkg.h"

namespace hp_vpu {

// Vector Register File (Mock)
// Supports split bank modeling logic (simplified as flat array for functionality)
// Models synchronous read behavior (captured in D2/OF)
SC_MODULE(hp_vpu_vrf) {
    // Clock
    sc_in<bool> clk;

    // Read Ports
    sc_in<sc_uint<5>> raddr1_i;
    sc_in<sc_uint<5>> raddr2_i;
    sc_in<sc_uint<5>> raddr3_i;
    sc_in<sc_uint<5>> raddr_mask_i;

    sc_out<sc_biguint<DLEN>> rdata1_o;
    sc_out<sc_biguint<DLEN>> rdata2_o;
    sc_out<sc_biguint<DLEN>> rdata3_o;
    sc_out<sc_biguint<DLEN>> rdata_mask_o;

    // Write Port
    sc_in<bool> we_i;
    sc_in<sc_uint<5>> waddr_i;
    sc_in<sc_biguint<DLEN>> wdata_i;

    // Internal Storage
    sc_biguint<DLEN> regs[32];

    void read_logic() {
        // Asynchronous read model (RTL registers these at the destination)
        // In cycle-accurate simulation, we can provide them combinatorially
        // to the pipeline registers that capture them.
        rdata1_o.write(regs[raddr1_i.read()]);
        rdata2_o.write(regs[raddr2_i.read()]);
        rdata3_o.write(regs[raddr3_i.read()]);
        rdata_mask_o.write(regs[0]); // Mask usually hardwired to v0 for now
    }

    void write_logic() {
        if (we_i.read()) {
            regs[waddr_i.read()] = wdata_i.read();
        }
    }

    SC_CTOR(hp_vpu_vrf) {
        SC_METHOD(read_logic);
        sensitive << raddr1_i << raddr2_i << raddr3_i << raddr_mask_i;

        SC_METHOD(write_logic);
        sensitive << clk.pos();

        // Initialize
        for(int i=0; i<32; i++) regs[i] = 0;
    }
};

} // namespace hp_vpu

#endif // HP_VPU_VRF_H
