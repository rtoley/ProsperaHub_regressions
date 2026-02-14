#include <systemc.h>
#include "hp_vpu_top.h"
#include "golden_model.h"
#include <iomanip>

using namespace hp_vpu;
using namespace std;

// Helper to print DLEN sized biguints
void print_vec(const char* name, sc_biguint<DLEN> val) {
    cout << name << " = ";
    for (int i = DLEN/8 - 1; i >= 0; i--) {
        int lo = i * 8;
        int hi = lo + 7;
        cout << hex << setw(2) << setfill('0') << val(hi, lo).to_uint();
        if (i % 4 == 0 && i != 0) cout << "_";
    }
    cout << dec << endl;
}

int sc_main(int argc, char* argv[]) {
    sc_clock clk("clk", 2, SC_NS);
    sc_signal<bool> rst_n;

    // Issue Interface
    sc_signal<bool> x_issue_valid;
    sc_signal<sc_uint<32>> x_issue_instr;
    sc_signal<sc_uint<CVXIF_ID_W>> x_issue_id;
    sc_signal<sc_uint<32>> x_issue_rs1;
    sc_signal<sc_uint<32>> x_issue_rs2;
    sc_signal<bool> x_issue_ready;

    // CSRs
    sc_signal<sc_uint<32>> csr_vtype;
    sc_signal<sc_uint<32>> csr_vl;

    // DMA (unused for now)
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
    sc_trace_file *tf = sc_create_vcd_trace_file("wave_full");
    sc_trace(tf, clk, "clk");
    sc_trace(tf, rst_n, "rst_n");
    sc_trace(tf, x_issue_valid, "valid");
    sc_trace(tf, top.s_valid_o, "res_valid");
    sc_trace(tf, top.s_result_o, "res_data");
    sc_trace(tf, top.s_vd_o, "res_vd");
    sc_trace(tf, top.u_lanes->red_state, "red_state");
    sc_trace(tf, top.u_lanes->wide_state, "wide_state");

    // Initialize
    x_issue_valid = 0;
    x_issue_instr = 0;
    x_issue_id = 0;
    x_issue_rs1 = 0;
    x_issue_rs2 = 0;
    csr_vtype = 0; // SEW=8, LMUL=1
    csr_vl = DLEN/8;
    dma_we = 0;
    rst_n = 0;

    // Reset
    sc_start(10, SC_NS);
    rst_n = 1;
    sc_start(10, SC_NS);

    int errors = 0;
    int tests_run = 0;

    // Helper Lambda for running a test
    auto run_test_op = [&](
        const char* test_name,
        sc_uint<32> instr_word,
        vpu_op_e op_enum,
        sew_e sew,
        sc_biguint<DLEN> vs1_val,
        sc_biguint<DLEN> vs2_val,
        sc_biguint<DLEN> vs3_val, // old vd
        sc_biguint<DLEN> vmask_val,
        bool vm,
        bool is_vx,
        sc_uint<32> scalar_val
    ) {
        // 1. Load Registers (Backdoor or via DMA - using DMA here to be cleaner)
        // Extract register indices from instr
        sc_uint<5> vd  = instr_word(11, 7);
        sc_uint<5> vs1 = instr_word(19, 15);
        sc_uint<5> vs2 = instr_word(24, 20);

        // Write VS1
        dma_we = 1; dma_addr = vs1; dma_wdata = vs1_val;
        sc_start(2, SC_NS);
        // Write VS2
        dma_we = 1; dma_addr = vs2; dma_wdata = vs2_val;
        sc_start(2, SC_NS);
        // Write VS3 (Old VD)
        dma_we = 1; dma_addr = vd; dma_wdata = vs3_val;
        sc_start(2, SC_NS);
        // Write Mask (v0)
        dma_we = 1; dma_addr = 0; dma_wdata = vmask_val;
        sc_start(2, SC_NS);
        dma_we = 0;

        // 2. Setup Issue
        // Assuming we set VTYPE separately
        csr_vtype = (int)sew << 3; // Shift to SEW position

        x_issue_valid = 1;
        x_issue_instr = instr_word;
        x_issue_id = tests_run;
        if (is_vx) x_issue_rs1 = scalar_val;
        else x_issue_rs1 = 0;

        // Wait for ready
        int timeout = 0;
        while (!x_issue_ready.read() && timeout < 100) {
            sc_start(2, SC_NS);
            timeout++;
        }
        if (timeout >= 100) {
            cout << "TIMEOUT waiting for ready on " << test_name << endl;
            errors++;
            x_issue_valid = 0;
            return;
        }

        // Clock once to issue
        sc_start(2, SC_NS);
        x_issue_valid = 0;

        // 3. Wait for Result
        timeout = 0;
        while (!top.s_valid_o.read() && timeout < 500) {
            sc_start(2, SC_NS);
            timeout++;
        }

        if (timeout >= 500) {
            cout << "TIMEOUT waiting for result on " << test_name << endl;
            errors++;
            return;
        }

        // Capture Result
        sc_biguint<DLEN> dut_res = top.s_result_o.read();

        // Compute Golden
        // Re-construct logic for golden model arguments
        // Note: decode logic inside GoldenModel call needs to match or we pass explicit args
        // Here we pass explicit args to GoldenModel::compute
        sc_biguint<DLEN> gold_res = GoldenModel::compute(
            op_enum, sew, vs1_val, vs2_val, vs3_val, vmask_val, vm, is_vx, scalar_val
        );

        // Compare
        if (dut_res != gold_res) {
            cout << "FAIL: " << test_name << endl;
            print_vec("  DUT ", dut_res);
            print_vec("  GOLD", gold_res);
            errors++;
        } else {
            // cout << "PASS: " << test_name << endl;
        }
        tests_run++;

        // Wait a few cycles to clear
        sc_start(4, SC_NS);
    };

    cout << "---------------------------------------" << endl;
    cout << "Starting Full VPU Verification Suite" << endl;
    cout << "---------------------------------------" << endl;

    // --- Test 1: VREDSUM.VS (Reduction) ---
    // Opcode: 1010111 (0x57), funct3=010 (OPMVV), funct6=000000 (VREDSUM)
    // vd=10, vs2=2, vs1=3 (start val)
    {
        sc_uint<32> instr = 0;
        instr(6,0) = 0x57; instr(11,7) = 10; instr(14,12) = 0b010;
        instr(19,15) = 3; instr(24,20) = 2; instr(25,25) = 1; instr(31,26) = 0b000000;

        sc_biguint<DLEN> vs2; vs2 = 0;
        for(int i=0; i<DLEN/8; i++) vs2(i*8+7, i*8) = 1; // All 1s
        sc_biguint<DLEN> vs1; vs1 = 10; // Start value 10

        run_test_op("VREDSUM.VS (All 1s + 10)", instr, OP_VREDSUM, SEW_8, vs1, vs2, 0, 0, true, false, 0);
    }

    // --- Test 2: VWMUL.VV (Widening Mul) ---
    // Opcode: 0x57, funct3=010, funct6=111011 (VWMUL)
    {
        sc_uint<32> instr = 0;
        instr(6,0) = 0x57; instr(11,7) = 11; instr(14,12) = 0b010;
        instr(19,15) = 3; instr(24,20) = 2; instr(25,25) = 1; instr(31,26) = 0b111011;

        sc_biguint<DLEN> vs2; vs2 = 0;
        sc_biguint<DLEN> vs1; vs1 = 0;
        // Test values: 0x03 * 0x05 = 0x000F (Widened)
        for(int i=0; i<DLEN/8; i++) {
             vs2(i*8+7, i*8) = 3;
             vs1(i*8+7, i*8) = 5;
        }

        run_test_op("VWMUL.VV (3 * 5 = 15)", instr, OP_VWMUL, SEW_8, vs1, vs2, 0, 0, true, false, 0);
    }

    // --- Test 3: VSADD.VV (Saturating Add) ---
    // Opcode: 0x57, funct3=000 (OPIVV), funct6=100001 (VSADD)
    {
        sc_uint<32> instr = 0;
        instr(6,0) = 0x57; instr(11,7) = 12; instr(14,12) = 0b000;
        instr(19,15) = 3; instr(24,20) = 2; instr(25,25) = 1; instr(31,26) = 0b100001;

        sc_biguint<DLEN> vs2; vs2 = 0;
        sc_biguint<DLEN> vs1; vs1 = 0;
        // 100 + 100 = 200 (signed 8-bit saturates to 127)
        for(int i=0; i<DLEN/8; i++) {
            vs2(i*8+7, i*8) = 100;
            vs1(i*8+7, i*8) = 100;
        }

        run_test_op("VSADD.VV (Sat 100+100)", instr, OP_VSADD, SEW_8, vs1, vs2, 0, 0, true, false, 0);
    }

    // --- Test 4: VMUL.VV (Signedness Check) ---
    // -1 * 1 = -1
    // If unsigned: 255 * 1 = 255
    {
        sc_uint<32> instr = 0;
        instr(6,0) = 0x57; instr(11,7) = 13; instr(14,12) = 0b010; // OPMVV
        instr(19,15) = 3; instr(24,20) = 2; instr(25,25) = 1; instr(31,26) = 0b100101; // VMUL

        sc_biguint<DLEN> vs2; vs2 = 0;
        sc_biguint<DLEN> vs1; vs1 = 0;
        // 0xFF (-1) * 0x01 (1)
        for(int i=0; i<DLEN/8; i++) {
            vs2(i*8+7, i*8) = 0xFF;
            vs1(i*8+7, i*8) = 0x01;
        }

        run_test_op("VMUL.VV (-1 * 1)", instr, OP_VMUL, SEW_8, vs1, vs2, 0, 0, true, false, 0);
    }

    // --- Test 5: VMERGE.VIM (Merge Immediate with Mask) ---
    // Opcode: 0x57, funct3=011 (OPIVI), funct6=010111 (VMERGE/VMV), vm=0
    {
        sc_uint<32> instr = 0;
        instr(6,0) = 0x57; instr(11,7) = 14; instr(14,12) = 0b011; // OPIVI
        instr(19,15) = 5; // imm=5
        instr(24,20) = 4; // vs2
        instr(25,25) = 0; // vm=0 (Merge)
        instr(31,26) = 0b010111; // VMERGE

        sc_biguint<DLEN> vs2; vs2 = 0; // Old value
        sc_biguint<DLEN> mask; mask = 0;
        // Mask pattern: 10101010
        for(int i=0; i<DLEN/8; i++) {
            if(i%2==0) mask[i] = 1; else mask[i] = 0;
            vs2(i*8+7, i*8) = 0xAA; // Old val
        }

        // Expected: if mask=1, result=5. if mask=0, result=vs2(0xAA).
        // Since OPIVI passes imm via scalar port (handled in decode)
        // Wait, decode passes imm to scalar_o. Lanes sees is_vx=1 (from OPIVI logic).
        // Lanes alu_int4/logic? No, vmerge is usually just ALU pass-through of "op_b" (which is imm here)
        // but with masking applied.
        // My lane logic for OP_VMERGE?
        // Lanes decode dispatch:
        // else if (e1_op == OP_VMERGE || e1_op == OP_VMV) raw_res = e1_b;
        // And then apply_mask handles the merge.
        // So this tests decode of OPIVI-VMERGE and masking logic.

        run_test_op("VMERGE.VIM (Masked Merge)", instr, OP_VMERGE, SEW_8, 0, vs2, vs2, mask, false, true, 5);
    }

    cout << "---------------------------------------" << endl;
    cout << "Tests Run: " << tests_run << endl;
    cout << "Errors:    " << errors << endl;
    cout << "---------------------------------------" << endl;

    sc_close_vcd_trace_file(tf);
    return errors;
}
