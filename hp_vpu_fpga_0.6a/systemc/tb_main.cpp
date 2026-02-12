#include <systemc.h>
#include "hp_vpu_top.h"
#include "golden_model.h"
#include <vector>
#include <random>

using namespace hp_vpu;

struct PendingInstr {
    sc_uint<32> instr;
    sc_uint<CVXIF_ID_W> id;
    int issue_cycle;
    sc_biguint<DLEN> expected_result;
    sc_uint<5> vd;
};

int sc_main(int argc, char* argv[]) {
    sc_clock clk("clk", 2, SC_NS);
    sc_signal<bool> rst_n;

    // Issue
    sc_signal<bool> x_issue_valid;
    sc_signal<sc_uint<32>> x_issue_instr;
    sc_signal<sc_uint<CVXIF_ID_W>> x_issue_id;
    sc_signal<sc_uint<32>> x_issue_rs1;
    sc_signal<sc_uint<32>> x_issue_rs2;
    sc_signal<bool> x_issue_ready;

    // CSR
    sc_signal<sc_uint<32>> csr_vtype;
    sc_signal<sc_uint<32>> csr_vl;

    // DMA
    sc_signal<bool> dma_we;
    sc_signal<sc_uint<5>> dma_addr;
    sc_signal<sc_biguint<DLEN>> dma_wdata;

    // Instantiate Top
    hp_vpu_top top("top");
    top.clk(clk); top.rst_n(rst_n);
    top.x_issue_valid_i(x_issue_valid); top.x_issue_instr_i(x_issue_instr);
    top.x_issue_id_i(x_issue_id); top.x_issue_rs1_i(x_issue_rs1); top.x_issue_rs2_i(x_issue_rs2);
    top.x_issue_ready_o(x_issue_ready);
    top.csr_vtype_i(csr_vtype); top.csr_vl_i(csr_vl);
    top.dma_we_i(dma_we); top.dma_addr_i(dma_addr); top.dma_wdata_i(dma_wdata);

    // Simulation State
    std::vector<PendingInstr> pending_instrs;
    sc_biguint<DLEN> vrf_state[32];
    for(int i=0; i<32; i++) vrf_state[i] = 0;

    // Trace
    sc_trace_file *tf = sc_create_vcd_trace_file("wave_full");
    sc_trace(tf, clk, "clk");
    sc_trace(tf, top.s_valid_o, "wb_valid");
    sc_trace(tf, top.s_vd_o, "wb_vd");

    // Reset
    rst_n = 0; x_issue_valid = 0; x_issue_instr = 0;
    csr_vtype = 0; csr_vl = 32; dma_we = 0;
    sc_start(10, SC_NS);
    rst_n = 1;
    sc_start(10, SC_NS);

    // Init VRF
    for(int i=0; i<32; i++) {
        dma_we = 1; dma_addr = i;
        sc_biguint<DLEN> val = (i+1)*11;
        dma_wdata = val;
        vrf_state[i] = val;
        sc_start(2, SC_NS);
    }
    dma_we = 0;

    cout << "[SC] Starting Randomized Stress Test (5000 instructions)..." << endl;

    srand(12345);
    int issued = 0;
    int completed = 0;
    int errors = 0;
    int target = 5000;

    // Main Loop
    while (completed < target && errors == 0) {
        // Issue logic
        if (issued < target && x_issue_ready.read()) {
            // Generate Random Op
            int op_type = rand() % 5; // 0=ADD, 1=SUB, 2=MUL, 3=AND, 4=OR
            int vd = 1 + (rand() % 31);
            int vs1 = 1 + (rand() % 31);
            int vs2 = 1 + (rand() % 31);

            vpu_op_e op;
            sc_uint<32> instr = 0;
            instr(6,0) = 0x57;
            instr(11,7) = vd;
            instr(19,15) = vs1;
            instr(24,20) = vs2;
            instr[25] = 1; // vm=1

            switch(op_type) {
                case 0: op = OP_VADD; instr(14,12)=0; instr(31,26)=0b000000; break;
                case 1: op = OP_VSUB; instr(14,12)=0; instr(31,26)=0b000010; break;
                case 2: op = OP_VMUL; instr(14,12)=2; instr(31,26)=0b100101; break;
                case 3: op = OP_VAND; instr(14,12)=0; instr(31,26)=0b001001; break;
                case 4: op = OP_VOR;  instr(14,12)=0; instr(31,26)=0b001010; break;
            }

            // Compute Golden
            sc_biguint<DLEN> golden = GoldenModel::compute(
                op, SEW_8, vrf_state[vs1], vrf_state[vs2], vrf_state[vd], 0, true, false, 0
            );

            // Store pending
            PendingInstr pi;
            pi.instr = instr;
            pi.id = issued % 256;
            pi.vd = vd;
            pi.expected_result = golden;
            pending_instrs.push_back(pi);

            // Issue to Model
            x_issue_valid = 1;
            x_issue_instr = instr;
            x_issue_id = pi.id;

            // Update Shadow State (Assume in-order completion for model state tracking)
            vrf_state[vd] = golden;

            issued++;
        } else {
            x_issue_valid = 0;
        }

        // Step
        sc_start(2, SC_NS);

        // Check Output
        if (top.s_valid_o.read()) {
            sc_uint<5> wb_vd = top.s_vd_o.read();
            sc_biguint<DLEN> wb_res = top.s_result_o.read();
            sc_uint<CVXIF_ID_W> wb_id = top.s_id_o.read();

            // Find match
            bool found = false;
            for (auto it = pending_instrs.begin(); it != pending_instrs.end(); ++it) {
                if (it->id == wb_id) {
                    if (wb_res != it->expected_result) {
                        cout << "[ERROR] Mismatch ID=" << wb_id << " VD=" << wb_vd << endl;
                        cout << "  Exp: " << std::hex << it->expected_result << endl;
                        cout << "  Act: " << std::hex << wb_res << endl;
                        errors++;
                    }
                    pending_instrs.erase(it);
                    found = true;
                    completed++;
                    break;
                }
            }
            if (!found) {
                cout << "[ERROR] Unexpected ID=" << wb_id << endl;
                errors++;
            }
        }

        if (sc_time_stamp().to_double() > 1000000) {
            cout << "[TIMEOUT]" << endl;
            break;
        }
    }

    if (errors == 0) cout << "[PASS] " << completed << " instructions verified." << endl;
    else cout << "[FAIL] " << errors << " errors." << endl;

    sc_close_vcd_trace_file(tf);
    return errors;
}
