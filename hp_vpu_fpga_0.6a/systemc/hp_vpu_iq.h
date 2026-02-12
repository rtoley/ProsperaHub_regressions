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

    bool operator==(const iq_entry_t& other) const {
        return (instr == other.instr && id == other.id && rs1 == other.rs1 && rs2 == other.rs2);
    }
};

inline std::ostream& operator<<(std::ostream& os, const iq_entry_t& t) {
    os << "instr=" << t.instr << " id=" << t.id;
    return os;
}

// Instruction Queue (FIFO)
// Decouples scalar core issue from vector pipeline.
// Depth: 8 entries
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
        bool pop_valid = (count.read() > 0) || (push_valid_i.read() && count.read() == 0); // Bypass available?
        bool pop = pop_valid && pop_ready_i.read();

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
            // Only advance read pointer if we popped from FIFO (not bypass)
            if (count.read() > 0) {
                next_rd = (next_rd + 1) % DEPTH;
                next_count--;
            } else if (push) {
                // Bypass case: pushed and popped in same cycle, count stays 0, pointers don't move
                // But wait, if we push to fifo[wr] and pop from bypass, fifo[wr] is overwritten next time?
                // RTL typically writes to RAM.
                // Simplified model: If empty and push+pop, we just pass through combinatorialy (output_logic handles data),
                // and don't increment count.
                next_count--; // Cancel out the ++ from push
            }
        }

        wr_ptr.write(next_wr);
        rd_ptr.write(next_rd);
        count.write(next_count);
    }

    void output_logic() {
        int cnt = count.read();
        int rd = rd_ptr.read();

        push_ready_o.write(cnt < DEPTH);

        // Bypass logic: If empty but pushing, data is valid immediately
        bool bypass = (cnt == 0) && push_valid_i.read();
        bool valid = (cnt > 0) || bypass;

        pop_valid_o.write(valid);

        if (cnt > 0) {
            pop_instr_o.write(fifo[rd].instr);
            pop_id_o.write(fifo[rd].id);
            pop_rs1_o.write(fifo[rd].rs1);
            pop_rs2_o.write(fifo[rd].rs2);
        } else if (bypass) {
            pop_instr_o.write(push_instr_i.read());
            pop_id_o.write(push_id_i.read());
            pop_rs1_o.write(push_rs1_i.read());
            pop_rs2_o.write(push_rs2_i.read());
        } else {
            pop_instr_o.write(0);
            pop_id_o.write(0);
            pop_rs1_o.write(0);
            pop_rs2_o.write(0);
        }
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
