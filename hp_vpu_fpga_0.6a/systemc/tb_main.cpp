#include <systemc.h>
#include "hp_vpu_top.h"

using namespace hp_vpu;

int sc_main(int argc, char* argv[]) {
    sc_clock clk("clk", 2, SC_NS);
    sc_signal<bool> rst_n;
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
    top.clk(clk);
    top.rst_n(rst_n);
    top.x_issue_valid_i(x_issue_valid);
    top.x_issue_instr_i(x_issue_instr);
    top.x_issue_id_i(x_issue_id);
    top.x_issue_rs1_i(x_issue_rs1);
    top.x_issue_rs2_i(x_issue_rs2);
    top.x_issue_ready_o(x_issue_ready);
    top.csr_vtype_i(csr_vtype);
    top.csr_vl_i(csr_vl);
    top.dma_we_i(dma_we);
    top.dma_addr_i(dma_addr);
    top.dma_wdata_i(dma_wdata);

    // Trace
    sc_trace_file *tf = sc_create_vcd_trace_file("wave_systemc");
    sc_trace(tf, clk, "clk");
    sc_trace(tf, rst_n, "rst_n");
    sc_trace(tf, x_issue_valid, "valid");
    sc_trace(tf, x_issue_ready, "ready");
    sc_trace(tf, x_issue_instr, "instr");
    sc_trace(tf, top.u_lanes->e1_valid_o, "e1_valid");
    sc_trace(tf, top.u_lanes->e1m_valid_o, "e1m_valid");
    sc_trace(tf, top.u_lanes->e2_valid_o, "e2_valid");
    sc_trace(tf, top.u_lanes->e3_valid_o, "e3_valid");
    sc_trace(tf, top.u_hazard->stall_dec_o, "stall_dec");

    // Init Signals
    x_issue_valid = 0;
    x_issue_instr = 0;
    csr_vtype = 0; // SEW8, LMUL1
    csr_vl = 32;
    dma_we = 0;

    // Reset
    rst_n = 0;
    sc_start(10, SC_NS);
    rst_n = 1;
    sc_start(10, SC_NS);

    // --- 1. Sanity Check: ADD ---
    cout << "[SC] Test 1: Simple VADD" << endl;

    // Write VRF v1, v2
    dma_we = 1;
    dma_addr = 1; dma_wdata = 10; sc_start(2, SC_NS);
    dma_addr = 2; dma_wdata = 20; sc_start(2, SC_NS);
    dma_we = 0;

    // Issue vadd.vv v3, v1, v2
    sc_uint<32> instr_add = 0;
    instr_add(6, 0) = 0x57;
    instr_add(11, 7) = 3;  // vd=3
    instr_add(14, 12) = 0; // OPIVV
    instr_add(19, 15) = 1; // vs1=1
    instr_add(24, 20) = 2; // vs2=2
    instr_add[25] = 1;     // vm=1
    instr_add(31, 26) = 0; // VADD

    x_issue_valid = 1;
    x_issue_instr = instr_add;

    do { sc_start(2, SC_NS); } while (x_issue_ready.read() == false);
    x_issue_valid = 0;

    sc_start(20, SC_NS); // Drain

    // --- 2. GEMV Throughput Test (16 Accumulators) ---
    int issued_count = 0;
    int target_count = 500;
    int n_acc = 16;

    cout << "[SC] Test 2: GEMV Benchmark (N_ACC=" << n_acc << ")..." << endl;
    double start_time = sc_time_stamp().to_double();

    for (int i = 0; i < target_count; i++) {
        int vd = i % n_acc;
        int vs2 = 16 + (i % n_acc);
        int rs1 = 10;

        sc_uint<32> instr = 0;
        instr(6, 0) = 0x57;
        instr(11, 7) = vd;
        instr(14, 12) = 0b110; // OPMVX
        instr(19, 15) = rs1;
        instr(24, 20) = vs2;
        instr[25] = 1; // vm
        instr(31, 26) = 0b101101; // VMACC

        x_issue_valid = 1;
        x_issue_instr = instr;
        x_issue_id = i;
        x_issue_rs1 = rs1;

        // Wait for ready
        do {
            sc_start(2, SC_NS);
        } while (x_issue_ready.read() == false);

        issued_count++;
    }

    x_issue_valid = 0;
    sc_start(100, SC_NS);

    double end_time = sc_time_stamp().to_double();
    double duration = end_time - start_time;
    int cycles = duration / 2.0;

    cout << "[SC] Done. Issued: " << issued_count << endl;
    cout << "[SC] Cycles: " << cycles << endl;
    cout << "[SC] IPC: " << (double)issued_count / cycles << endl;

    sc_close_vcd_trace_file(tf);
    return 0;
}
