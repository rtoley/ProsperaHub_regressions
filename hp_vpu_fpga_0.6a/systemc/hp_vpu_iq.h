#ifndef HP_VPU_IQ_H
#define HP_VPU_IQ_H

#include <systemc.h>
#include "hp_vpu_pkg.h"

namespace hp_vpu {

// Instruction Queue Entry
struct iq_entry_t {
    sc_uint<32> instr;
    sc_uint<CVXIF_ID_W> id;
    sc_uint<32> rs1;
    sc_uint<32> rs2;

    // Equality operator for SystemC signal support
    bool operator==(const iq_entry_t& other) const {
        return (instr == other.instr && id == other.id && rs1 == other.rs1 && rs2 == other.rs2);
    }
};

// Define ostream operator for logging
inline std::ostream& operator<<(std::ostream& os, const iq_entry_t& t) {
    os << "instr=" << t.instr << " id=" << t.id;
    return os;
}

// Instruction Queue (FIFO)
// Decouples scalar core issue from vector pipeline.
// Depth: 8 entries (matching RTL)
SC_MODULE(hp_vpu_iq) {
    // Clock/Reset
    sc_in<bool> clk;
    sc_in<bool> rst_n;

    // Push Interface (from Core)
    sc_in<bool> push_valid_i;
    sc_in<sc_uint<32>> push_instr_i;
    sc_in<sc_uint<CVXIF_ID_W>> push_id_i;
    sc_in<sc_uint<32>> push_rs1_i;
    sc_in<sc_uint<32>> push_rs2_i;
    sc_out<bool> push_ready_o;

    // Pop Interface (to Decode)
    sc_out<bool> pop_valid_o;
    sc_out<sc_uint<32>> pop_instr_o;
    sc_out<sc_uint<CVXIF_ID_W>> pop_id_o;
    sc_out<sc_uint<32>> pop_rs1_o;
    sc_out<sc_uint<32>> pop_rs2_o;
    sc_in<bool> pop_ready_i; // Stall from Decode

    // Control
    sc_in<bool> flush_i;

    // Internal FIFO
    static const int DEPTH = 8;
    iq_entry_t fifo[DEPTH];
    sc_signal<int> wr_ptr;
    sc_signal<int> rd_ptr;
    sc_signal<int> count;

    void iq_logic() {
        if (!rst_n.read() || flush_i.read()) {
            wr_ptr.write(0);
            rd_ptr.write(0);
            count.write(0);
            return;
        }

        bool push = push_valid_i.read() && (count.read() < DEPTH);
        bool pop = pop_valid_o.read() && pop_ready_i.read(); // Valid output and consumer ready (consumer ready is !stall)

        // Update pointers and count
        int next_wr = wr_ptr.read();
        int next_rd = rd_ptr.read();
        int next_count = count.read();

        if (push) {
            fifo[next_wr].instr = push_instr_i.read();
            fifo[next_wr].id = push_id_i.read();
            fifo[next_wr].rs1 = push_rs1_i.read();
            fifo[next_wr].rs2 = push_rs2_i.read();
            next_wr = (next_wr + 1) % DEPTH;
            next_count++;
        }

        if (pop) {
            next_rd = (next_rd + 1) % DEPTH;
            next_count--;
        }

        // Simultaneous push/pop adjustment
        // If both happen, count stays same (already handled by ++ and -- above logic if sequential,
        // but here we used if/if so we need to be careful. count update should be net change)
        if (push && pop) next_count = count.read(); // No change

        wr_ptr.write(next_wr);
        rd_ptr.write(next_rd);
        count.write(next_count);

        // Output logic (Combinational based on current state)
        // Note: In SystemC SC_CTHREAD/METHOD updates next cycle.
        // We need combinatorial outputs for ready/valid handshake?
        // RTL hp_vpu_iq.sv likely has combinatorial valid/ready outputs logic based on count.
    }

    void output_logic() {
        int cnt = count.read();
        int rd = rd_ptr.read();
        bool push = push_valid_i.read();

        // Bypass logic
        bool empty = (cnt == 0);
        bool bypass = empty && push;

        // Pop valid if not empty OR bypass
        bool valid = !empty || bypass;
        pop_valid_o.write(valid);

        if (bypass) {
            pop_instr_o.write(push_instr_i.read());
            pop_id_o.write(push_id_i.read());
            pop_rs1_o.write(push_rs1_i.read());
            pop_rs2_o.write(push_rs2_i.read());
        } else if (!empty) {
            pop_instr_o.write(fifo[rd].instr);
            pop_id_o.write(fifo[rd].id);
            pop_rs1_o.write(fifo[rd].rs1);
            pop_rs2_o.write(fifo[rd].rs2);
        } else {
            pop_instr_o.write(0);
            pop_id_o.write(0);
            pop_rs1_o.write(0);
            pop_rs2_o.write(0);
        }

        // Push ready if not full
        push_ready_o.write(cnt < DEPTH);
    }

    SC_CTOR(hp_vpu_iq) {
        SC_CTHREAD(iq_logic, clk.pos());
        reset_signal_is(rst_n, false);

        SC_METHOD(output_logic);
        sensitive << count << rd_ptr << push_valid_i << push_instr_i << push_id_i << push_rs1_i << push_rs2_i;
    }
};

} // namespace hp_vpu

#endif // HP_VPU_IQ_H
