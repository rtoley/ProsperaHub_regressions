#include <systemc.h>
#include "hp_vpu_top.h"

using namespace hp_vpu;

int sc_main(int argc, char* argv[]) {
    sc_clock clk("clk", 2, SC_NS);
    sc_signal<bool> rst_n;
    sc_signal<bool> x_issue_valid;
    sc_signal<sc_uint<32>> x_issue_instr;
    sc_signal<sc_uint<CVXIF_ID_W>> x_issue_id;
    sc_signal<bool> x_issue_ready;
    // Added signals for binding
    sc_signal<sc_uint<32>> x_issue_rs1;
    sc_signal<sc_uint<32>> x_issue_rs2;
    sc_signal<sc_uint<32>> csr_vtype;
    sc_signal<sc_uint<32>> csr_vl;
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

    // Reset
    rst_n = 0;
    x_issue_valid = 0;
    x_issue_instr = 0;
    sc_start(10, SC_NS);
    rst_n = 1;
    sc_start(10, SC_NS);

    // --- GEMV Throughput Test (16 Accumulators) ---
    // Mimicking run_long_gemv from RTL testbench
    // Issue stream of vmacc.vx to v0..v15

    int issued_count = 0;
    int target_count = 500; // Run 500 instructions for correlation check (500k is too slow for simple TB)
    int n_acc = 16;

    cout << "[SC] Starting GEMV Benchmark (N_ACC=" << n_acc << ")..." << endl;
    double start_time = sc_time_stamp().to_double();

    for (int i = 0; i < target_count; i++) {
        // Construct vmacc.vx instruction
        // vmacc.vx vd, rs1, vs2 -> vd = vd + rs1 * vs2
        // RTL: encode_vmacc_vx(i[4:0], 5'd10, (16 + i))
        int vd = i % n_acc;
        int vs2 = 16 + (i % n_acc);
        int rs1 = 10;

        // Encoding:
        // opcode=1010111 (0x57)
        // funct3=110 (OPMVX)
        // funct6=101101 (OP_VMACC)
        // vm=1
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

        // Wait for ready
        do {
            sc_start(2, SC_NS);
        } while (x_issue_ready.read() == false);

        // Accepted
        issued_count++;
    }

    x_issue_valid = 0;

    // Drain pipeline
    sc_start(100, SC_NS);

    double end_time = sc_time_stamp().to_double();
    double duration = end_time - start_time;
    int cycles = duration / 2.0; // 2ns period

    cout << "[SC] Done. Issued: " << issued_count << endl;
    cout << "[SC] Cycles: " << cycles << endl;
    cout << "[SC] IPC: " << (double)issued_count / cycles << endl;

    sc_close_vcd_trace_file(tf);
    return 0;
}
