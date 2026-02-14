#ifndef HP_VPU_VRF_H
#define HP_VPU_VRF_H

#include <systemc.h>
#include "hp_vpu_pkg.h"

namespace hp_vpu {

// Vector Register File (Cycle Accurate)
// - Registered reads (BRAM style): Data available 1 cycle after address
// - Byte-level write enables
// - Flat 32-register model (simplification of bank structure but timing accurate)
SC_MODULE(hp_vpu_vrf) {
    // Clock
    sc_in<bool> clk;

    // Read Ports (Addresses)
    sc_in<sc_uint<5>> raddr1_i;
    sc_in<sc_uint<5>> raddr2_i;
    sc_in<sc_uint<5>> raddr3_i;
    sc_in<sc_uint<5>> raddr_mask_i;

    // Read Enables (optional, but good for power/timing)
    sc_in<bool> ren1_i;
    sc_in<bool> ren2_i;
    sc_in<bool> ren3_i;
    sc_in<bool> ren_mask_i;

    // Read Data (Output)
    sc_out<sc_biguint<DLEN>> rdata1_o;
    sc_out<sc_biguint<DLEN>> rdata2_o;
    sc_out<sc_biguint<DLEN>> rdata3_o;
    sc_out<sc_biguint<DLEN>> rdata_mask_o;

    // Write Port
    sc_in<bool> we_i;
    sc_in<sc_uint<5>> waddr_i;
    sc_in<sc_biguint<DLEN>> wdata_i;
    sc_in<sc_biguint<DLEN/8>> be_i; // Byte enables (1 bit per byte)

    // Internal Storage: 32 registers of DLEN width
    // Using uint64_t chunks if DLEN=64, but biguint is generic.
    sc_biguint<DLEN> regs[32];

    // Read Logic (Synchronous)
    void read_process() {
        if (ren1_i.read()) rdata1_o.write(regs[raddr1_i.read()]);
        if (ren2_i.read()) rdata2_o.write(regs[raddr2_i.read()]);
        if (ren3_i.read()) rdata3_o.write(regs[raddr3_i.read()]);
        if (ren_mask_i.read()) rdata_mask_o.write(regs[raddr_mask_i.read()]);
    }

    // Write Logic (Synchronous)
    void write_process() {
        if (we_i.read()) {
            sc_uint<5> addr = waddr_i.read();
            sc_biguint<DLEN> data = wdata_i.read();
            sc_biguint<DLEN/8> be = be_i.read();
            sc_biguint<DLEN> current = regs[addr];

            // Byte-enable application
            for (int i = 0; i < DLEN/8; ++i) {
                if (be[i]) {
                    current((i+1)*8-1, i*8) = data((i+1)*8-1, i*8);
                }
            }
            regs[addr] = current;
        }
    }

    SC_CTOR(hp_vpu_vrf) {
        SC_METHOD(read_process);
        sensitive << clk.pos(); // Registered read

        SC_METHOD(write_process);
        sensitive << clk.pos();

        // Initialize
        for(int i=0; i<32; i++) regs[i] = 0;
    }
};

} // namespace hp_vpu

#endif // HP_VPU_VRF_H
