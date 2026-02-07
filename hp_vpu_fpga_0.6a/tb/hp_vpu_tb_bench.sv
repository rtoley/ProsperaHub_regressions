//==============================================================================
// Hyperplane VPU - GEMV Inference Benchmark
// Measures MAC throughput with register-tiled output-stationary dataflow
// v0.5d: Against current RTL with E1/E1m hazard fix
//==============================================================================
`timescale 1ns/1ps

module hp_vpu_tb_bench;
  import hp_vpu_pkg::*;

  localparam int unsigned VLEN   = hp_vpu_pkg::VLEN;
  localparam int unsigned NLANES = hp_vpu_pkg::NLANES;
  localparam int unsigned ELEN   = hp_vpu_pkg::ELEN;
  localparam int unsigned DLEN   = NLANES * 64;
  localparam int unsigned VLMAX_8  = VLEN / 8;
  localparam int unsigned VLMAX_16 = VLEN / 16;
  localparam int unsigned VLMAX_32 = VLEN / 32;

  localparam real CLK_PERIOD = 2.0;

  //==========================================================================
  // Signals
  //==========================================================================
  logic                      clk, rst_n;
  logic                      x_issue_valid, x_issue_ready;
  logic                      x_issue_accept;
  logic [31:0]               x_issue_instr;
  logic [CVXIF_ID_W-1:0]     x_issue_id;
  logic [31:0]               x_issue_rs1, x_issue_rs2;
  logic                      x_result_valid, x_result_ready;
  logic [CVXIF_ID_W-1:0]     x_result_id;
  logic [31:0]               x_result_data;
  logic                      x_result_we;
  logic [31:0]               csr_vtype, csr_vl, csr_vtype_out, csr_vl_out;
  logic                      csr_vl_valid;
  logic                      csr_req;
  logic                      csr_gnt, csr_we;
  logic [11:0]               csr_addr;
  logic [31:0]               csr_wdata, csr_rdata;
  logic                      csr_rvalid, csr_error;
  logic                      exc_valid;
  logic [31:0]               exc_cause;
  logic                      exc_ack;
  logic                      dma_valid, dma_ready, dma_we;
  logic [4:0]                dma_addr;
  logic [DLEN-1:0]           dma_wdata, dma_rdata;
  logic [DLEN/8-1:0]         dma_be;
  logic                      dma_rvalid;
  logic                      dma_dbuf_en;    // v0.5e: weight double-buffer enable
  logic                      dma_dbuf_swap;  // v0.5e: weight bank swap pulse
  logic                      x_commit_valid, x_commit_kill;
  logic [CVXIF_ID_W-1:0]     x_commit_id;
  logic                      busy;
  logic [31:0]               perf_cnt;

  //==========================================================================
  // Clock
  //==========================================================================
  initial clk = 0;
  always #(CLK_PERIOD/2) clk = ~clk;

  //==========================================================================
  // DUT
  //==========================================================================
  hp_vpu_top #(
    .VLEN(VLEN), .NLANES(NLANES), .ELEN(ELEN)
  ) u_dut (
    .clk(clk), .rst_n(rst_n),
    .x_issue_valid_i(x_issue_valid), .x_issue_ready_o(x_issue_ready),
    .x_issue_accept_o(x_issue_accept),
    .x_issue_instr_i(x_issue_instr), .x_issue_id_i(x_issue_id),
    .x_issue_rs1_i(x_issue_rs1), .x_issue_rs2_i(x_issue_rs2),
    .x_result_valid_o(x_result_valid), .x_result_ready_i(x_result_ready),
    .x_result_id_o(x_result_id), .x_result_data_o(x_result_data),
    .x_result_we_o(x_result_we),
    .csr_vtype_i(csr_vtype), .csr_vl_i(csr_vl),
    .csr_vtype_o(csr_vtype_out), .csr_vl_o(csr_vl_out),
    .csr_vl_valid_o(csr_vl_valid),
    .csr_req_i(csr_req), .csr_gnt_o(csr_gnt), .csr_we_i(csr_we),
    .csr_addr_i(csr_addr), .csr_wdata_i(csr_wdata),
    .csr_rdata_o(csr_rdata), .csr_rvalid_o(csr_rvalid), .csr_error_o(csr_error),
    .exc_valid_o(exc_valid), .exc_cause_o(exc_cause), .exc_ack_i(exc_ack),
    .dma_valid_i(dma_valid), .dma_ready_o(dma_ready), .dma_we_i(dma_we),
    .dma_addr_i(dma_addr), .dma_wdata_i(dma_wdata), .dma_be_i(dma_be),
    .dma_rvalid_o(dma_rvalid), .dma_rdata_o(dma_rdata),
    // v0.5e: Weight double-buffer
    .dma_dbuf_en_i(dma_dbuf_en), .dma_dbuf_swap_i(dma_dbuf_swap),
    .x_commit_valid_i(x_commit_valid), .x_commit_id_i(x_commit_id),
    .x_commit_kill_i(x_commit_kill),
    .busy_o(busy), .perf_cnt_o(perf_cnt)
  );

  //==========================================================================
  // Helper tasks
  //==========================================================================
  task automatic do_reset();
    rst_n = 0;
    x_issue_valid = 0; x_issue_instr = 0; x_issue_id = 0;
    x_issue_rs1 = 0; x_issue_rs2 = 0;
    x_result_ready = 1;
    csr_vtype = 0; csr_vl = 0;
    csr_req = 0; csr_we = 0; csr_addr = 0; csr_wdata = 0;
    exc_ack = 0;
    dma_valid = 0; dma_we = 0; dma_addr = 0; dma_wdata = 0;
    dma_be = 0;
    dma_dbuf_en = 0; dma_dbuf_swap = 0;  // v0.5e
    x_commit_valid = 0; x_commit_id = 0; x_commit_kill = 0;
    repeat (16) @(posedge clk);
    rst_n = 1;
    repeat (4) @(posedge clk);
  endtask

  task automatic issue(input logic [31:0] instr, input logic [31:0] rs1 = 0, input logic [31:0] rs2 = 0);
    int wait_cyc = 0;
    x_issue_valid = 1;
    x_issue_instr = instr;
    x_issue_id = x_issue_id + 1;
    x_issue_rs1 = rs1;
    x_issue_rs2 = rs2;
    @(posedge clk);
    while (!x_issue_ready) begin
      @(posedge clk);
      wait_cyc++;
      if (wait_cyc > 5000) begin
        $display("ERROR: issue timeout on 0x%08h after %0d cycles", instr, wait_cyc);
        $finish;
      end
    end
    x_issue_valid = 0;
  endtask

  task automatic wait_drain();
    repeat (5) @(posedge clk);
    while (busy) @(posedge clk);
    repeat (2) @(posedge clk);
  endtask

  task automatic vrf_write(input logic [4:0] vreg, input logic [DLEN-1:0] data);
    dma_valid = 1; dma_we = 1; dma_addr = vreg;
    dma_wdata = data; dma_be = {(DLEN/8){1'b1}};
    @(posedge clk);
    dma_valid = 0; dma_we = 0;
  endtask

  task automatic set_vtype(input logic [2:0] sew, input logic [2:0] lmul, input int vl_val);
    logic [31:0] instr;
    logic [10:0] vtypei;
    vtypei = {3'b0, 2'b0, sew, lmul};
    instr = {1'b0, vtypei[9:0], 5'd5, 3'b111, 5'd0, 7'b1010111};
    csr_vtype = {24'b0, 2'b0, sew, lmul};
    csr_vl = vl_val;
    issue(instr, vl_val);
    repeat (2) @(posedge clk);
  endtask

  //==========================================================================
  // Instruction encoders
  //==========================================================================

  // vmacc.vv vd, vs1, vs2  ->  vd = vd + vs1 * vs2
  function automatic logic [31:0] encode_vmacc_vv(logic [4:0] vd, logic [4:0] vs1, logic [4:0] vs2);
    return {6'b101101, 1'b1, vs2, vs1, 3'b010, vd, 7'b1010111};
  endfunction

  // vmacc.vx vd, rs1, vs2  ->  vd[i] = vd[i] + rs1 * vs2[i]
  function automatic logic [31:0] encode_vmacc_vx(logic [4:0] vd, logic [4:0] rs1_field, logic [4:0] vs2);
    return {6'b101101, 1'b1, vs2, rs1_field, 3'b110, vd, 7'b1010111};
  endfunction

  // vadd.vv
  function automatic logic [31:0] encode_vadd_vv(logic [4:0] vd, logic [4:0] vs1, logic [4:0] vs2);
    return {6'b000000, 1'b1, vs2, vs1, 3'b000, vd, 7'b1010111};
  endfunction

  // vmul.vx vd, rs1, vs2  ->  vd[i] = rs1 * vs2[i]
  function automatic logic [31:0] encode_vmul_vx(logic [4:0] vd, logic [4:0] rs1_field, logic [4:0] vs2);
    return {6'b100101, 1'b1, vs2, rs1_field, 3'b110, vd, 7'b1010111};
  endfunction

  // vgelu.v vd, vs2  ->  vd[i] = gelu_lut[vs2[i]]
  function automatic logic [31:0] encode_vgelu_v(logic [4:0] vd, logic [4:0] vs2);
    return {6'b010010, 1'b1, vs2, 5'b00011, 3'b010, vd, 7'b1010111};
  endfunction

  //==========================================================================
  // GEMV Benchmark: output-stationary with N accumulators
  //
  //  y[tile] = sum_k( W[tile][k] * x[k] )    for tile = 0..N_ACC-1
  //
  //  Register map:
  //    v0..v(N_ACC-1)   = accumulators y[0]..y[N_ACC-1]
  //    v16..v(16+N_ACC-1) = weight vectors W[tile][k]
  //    rs1 = x[k] (scalar, broadcast to all lanes)
  //
  //  Per k iteration: N_ACC vmacc.vx instructions, rotating accumulator.
  //  After K_DIM iterations: activate with vgelu.v
  //==========================================================================
  task automatic run_gemv_bench(
    input int N_ACC,        // Number of accumulator registers (tiling factor)
    input int K_DIM,        // Inner dimension (number of k iterations)
    input bit do_activation // Apply GELU activation at end
  );
    integer cycle_start, cycle_end, total_cycles;
    integer mac_ops, activation_ops, total_vec_ops;
    integer element_macs;
    real    mac_per_cycle, utilization;
    integer i, k;
    logic [7:0] scalar_val;
    begin
      $display("");
      $display("  ---- GEMV Benchmark: %0d accumulators, K=%0d, GELU=%0b ----", N_ACC, K_DIM, do_activation);

      // Zero accumulators v0..v(N_ACC-1)
      for (i = 0; i < N_ACC; i++)
        vrf_write(i[4:0], {DLEN{1'b0}});

      // Pre-load weight vectors v16..v(16+N_ACC-1) with pseudo-random data
      for (i = 0; i < N_ACC; i++)
        vrf_write((16 + i), {(DLEN/8){i[7:0] + 8'h10}});

      repeat (4) @(posedge clk);

      // === GEMV compute phase ===
      cycle_start = $time / CLK_PERIOD;

      for (k = 0; k < K_DIM; k++) begin
        scalar_val = k[7:0] + 8'h01;  // x[k] = k+1

        // Reload weight vectors for this k step (simulates streaming weights from memory)
        // In real system this would overlap with compute; here we just update the values
        if (k > 0) begin
          for (i = 0; i < N_ACC; i++)
            vrf_write((16 + i), {(DLEN/8){scalar_val ^ i[7:0]}});
        end

        // Issue N_ACC vmacc.vx instructions with rotating accumulators
        for (i = 0; i < N_ACC; i++) begin
          issue(encode_vmacc_vx(i[4:0], 5'd10, (16 + i)), {24'b0, scalar_val});
        end
      end

      // Drain pipeline
      wait_drain();
      cycle_end = $time / CLK_PERIOD;
      total_cycles = cycle_end - cycle_start;

      mac_ops = N_ACC * K_DIM;
      element_macs = mac_ops * VLMAX_8;  // Each vec op does VLMAX_8 element MACs

      $display("    Compute: %0d cycles for %0d vector MACs (%0d element MACs)",
               total_cycles, mac_ops, element_macs);

      // === Activation phase ===
      if (do_activation) begin
        cycle_start = $time / CLK_PERIOD;
        for (i = 0; i < N_ACC; i++) begin
          issue(encode_vgelu_v(i[4:0], i[4:0]));
        end
        wait_drain();
        cycle_end = $time / CLK_PERIOD;
        activation_ops = N_ACC;
        $display("    Activation (GELU): %0d cycles for %0d vector ops",
                 cycle_end - cycle_start, activation_ops);
        total_cycles = total_cycles + (cycle_end - cycle_start);
        total_vec_ops = mac_ops + activation_ops;
      end else begin
        total_vec_ops = mac_ops;
      end

      // === Report ===
      mac_per_cycle = real'(element_macs) / real'(total_cycles);
      utilization   = (real'(mac_ops) / real'(total_cycles)) * 100.0;

      $display("    -----------------------------------------------");
      $display("    Total cycles:      %0d", total_cycles);
      $display("    Vector ops:        %0d", total_vec_ops);
      $display("    Vec MACs/cycle:    %0.3f", real'(mac_ops) / real'(total_cycles));
      $display("    Elem MACs/cycle:   %0.1f  (peak=%0d)", mac_per_cycle, VLMAX_8);
      $display("    MAC utilization:   %0.1f%%", utilization);
      $display("    -----------------------------------------------");
    end
  endtask

  //==========================================================================
  // Non-MAC throughput baseline (vadd.vv, no accumulator conflict)
  //==========================================================================
  task automatic run_vadd_baseline(input int N_OPS);
    integer cycle_start, cycle_end, total_cycles;
    integer i;
    begin
      $display("");
      $display("  ---- Baseline: %0d vadd.vv (no hazards) ----", N_OPS);

      // Pre-load source registers
      vrf_write(5'd8, {(DLEN/8){8'h01}});
      vrf_write(5'd9, {(DLEN/8){8'h02}});
      // Use different dest registers to avoid RAW
      for (i = 0; i < 8; i++)
        vrf_write(i[4:0], {DLEN{1'b0}});

      repeat (4) @(posedge clk);
      cycle_start = $time / CLK_PERIOD;

      for (i = 0; i < N_OPS; i++) begin
        // Rotate dest across v0..v7 to avoid hazards
        issue(encode_vadd_vv(i[2:0], 5'd8, 5'd9));
      end

      wait_drain();
      cycle_end = $time / CLK_PERIOD;
      total_cycles = cycle_end - cycle_start;

      $display("    %0d cycles for %0d ops -> %0.3f vec ops/cycle",
               total_cycles, N_OPS, real'(N_OPS) / real'(total_cycles));
    end
  endtask

  //==========================================================================
  // Pure MAC throughput: no DMA reloads, just MAC issue stream
  // This isolates the pipeline throughput from memory system overhead
  //==========================================================================
  task automatic run_pure_mac(input int N_ACC, input int K_DIM);
    integer cycle_start, cycle_end, total_cycles;
    integer mac_ops, element_macs;
    integer i, k;
    begin
      $display("");
      $display("  ---- Pure MAC: %0d accumulators, K=%0d (no DMA) ----", N_ACC, K_DIM);

      // Pre-load ALL registers once before timing
      for (i = 0; i < N_ACC; i++)
        vrf_write(i[4:0], {DLEN{1'b0}});        // accumulators
      for (i = 0; i < N_ACC; i++)
        vrf_write((16 + i), {(DLEN/8){i[7:0] + 8'h10}});  // weights (static)

      repeat (4) @(posedge clk);
      cycle_start = $time / CLK_PERIOD;

      for (k = 0; k < K_DIM; k++) begin
        for (i = 0; i < N_ACC; i++) begin
          issue(encode_vmacc_vx(i[4:0], 5'd10, (16 + i)), {24'b0, k[7:0] + 8'h01});
        end
      end

      wait_drain();
      cycle_end = $time / CLK_PERIOD;
      total_cycles = cycle_end - cycle_start;
      mac_ops = N_ACC * K_DIM;
      element_macs = mac_ops * VLMAX_8;

      $display("    %0d cycles for %0d vec MACs (%0d elem MACs)",
               total_cycles, mac_ops, element_macs);
      $display("    Vec MACs/cycle:  %0.3f", real'(mac_ops) / real'(total_cycles));
      $display("    Elem MACs/cycle: %0.1f  (peak=%0d)",
               real'(element_macs) / real'(total_cycles), VLMAX_8);
      $display("    Pipeline util:   %0.1f%%",
               (real'(mac_ops) / real'(total_cycles)) * 100.0);
    end
  endtask

  //==========================================================================
  // Full inference scenario: GEMV layer stack + activation
  //==========================================================================
  task automatic run_inference_scenario();
    integer cycle_start, cycle_end, total_cycles;
    integer total_macs, total_acts;
    integer N_ACC, K_DIM, N_LAYERS;
    integer layer, k, i;
    logic [7:0] scalar_val;
    begin
      N_ACC    = 8;    // 8 output tiles
      K_DIM    = 16;   // 16-deep inner dimension
      N_LAYERS = 2;    // 2 layers (e.g. up-proj + down-proj of MLP)

      $display("");
      $display("===========================================================");
      $display("  INFERENCE SCENARIO: %0d-layer MLP", N_LAYERS);
      $display("  %0d output tiles x K=%0d, SEW=8, VLEN=%0d", N_ACC, K_DIM, VLEN);
      $display("  %0d MAC ops + %0d GELU activations per layer",
               N_ACC * K_DIM, N_ACC);
      $display("===========================================================");

      // Zero all accumulators
      for (i = 0; i < N_ACC; i++)
        vrf_write(i[4:0], {DLEN{1'b0}});
      // Pre-load initial weights
      for (i = 0; i < N_ACC; i++)
        vrf_write((16 + i), {(DLEN/8){i[7:0] + 8'h10}});

      repeat (4) @(posedge clk);
      cycle_start = $time / CLK_PERIOD;

      for (layer = 0; layer < N_LAYERS; layer++) begin
        // Zero accumulators for this layer
        for (i = 0; i < N_ACC; i++)
          vrf_write(i[4:0], {DLEN{1'b0}});

        // GEMV: y = W * x
        for (k = 0; k < K_DIM; k++) begin
          scalar_val = k[7:0] + layer[7:0] * 8'd16 + 8'h01;
          // Weight reload (simulate DMA)
          if (k > 0) begin
            for (i = 0; i < N_ACC; i++)
              vrf_write((16 + i), {(DLEN/8){scalar_val ^ i[7:0]}});
          end
          // Tiled MAC burst
          for (i = 0; i < N_ACC; i++)
            issue(encode_vmacc_vx(i[4:0], 5'd10, (16 + i)), {24'b0, scalar_val});
        end
        wait_drain();

        // Activation: GELU on each output tile
        for (i = 0; i < N_ACC; i++)
          issue(encode_vgelu_v(i[4:0], i[4:0]));
        wait_drain();
      end

      cycle_end = $time / CLK_PERIOD;
      total_cycles = cycle_end - cycle_start;
      total_macs = N_LAYERS * N_ACC * K_DIM;
      total_acts = N_LAYERS * N_ACC;

      $display("");
      $display("  INFERENCE RESULTS:");
      $display("    Total cycles:         %0d", total_cycles);
      $display("    Vector MAC ops:       %0d", total_macs);
      $display("    Activation ops:       %0d", total_acts);
      $display("    Element MACs:         %0d", total_macs * VLMAX_8);
      $display("    Elem MACs/cycle:      %0.1f  (peak=%0d)",
               real'(total_macs * VLMAX_8) / real'(total_cycles), VLMAX_8);
      $display("    Vec MAC utilization:  %0.1f%%",
               (real'(total_macs) / real'(total_cycles)) * 100.0);
      $display("===========================================================");
    end
  endtask

  //==========================================================================
  // v0.6: Double-Buffered GEMV Benchmark — separated ports
  // DMA writes next-K weights to shadow bank on port 2
  // Compute issues MACs via CV-X-IF on port 1 — fully independent
  //==========================================================================
  task automatic run_gemv_dbuf(input int N_ACC, input int K_DIM);
    integer cycle_start, cycle_end, total_cycles;
    integer mac_ops, element_macs;
    integer i, k, di;
    logic [7:0] scalar_val, next_scalar;
    begin
      $display("");
      $display("  ---- DBUF GEMV: %0d accumulators, K=%0d ----", N_ACC, K_DIM);

      // Phase 1: Single-buffer init — zero accumulators, load first weights
      dma_dbuf_en  = 1'b0;
      dma_dbuf_swap = 1'b0;
      for (i = 0; i < N_ACC; i++)
        vrf_write(i[4:0], {DLEN{1'b0}});
      for (i = 0; i < N_ACC; i++)
        vrf_write((16 + i), {(DLEN/8){8'h10 + i[7:0]}});

      // Phase 2: Enable double-buffer
      dma_dbuf_en = 1'b1;
      repeat (4) @(posedge clk);

      // Pre-load shadow bank with k=1 weights (will swap before k=1 compute)
      if (K_DIM > 1) begin
        for (i = 0; i < N_ACC; i++)
          vrf_write((16 + i), {(DLEN/8){8'h02 ^ i[7:0]}});
      end

      repeat (2) @(posedge clk);
      cycle_start = $time / CLK_PERIOD;

      // Phase 3: K-loop with overlapped DMA + compute on SEPARATE ports
      for (k = 0; k < K_DIM; k++) begin
        scalar_val = k[7:0] + 8'h01;
        next_scalar = k[7:0] + 8'h02;

        if (k < K_DIM - 1) begin
          // Overlap: fork compute issue and DMA streaming concurrently
          fork
            // Thread 1: Issue N_ACC vmacc instructions via CV-X-IF
            begin
              for (int ci = 0; ci < N_ACC; ci++)
                issue(encode_vmacc_vx(ci[4:0], 5'd10, (16 + ci)), {24'b0, scalar_val});
            end
            // Thread 2: DMA write N_ACC weights to shadow bank
            begin
              for (int di2 = 0; di2 < N_ACC; di2++) begin
                dma_valid = 1; dma_we = 1;
                dma_addr = (16 + di2);
                dma_wdata = {(DLEN/8){next_scalar ^ di2[7:0]}};
                dma_be = {(DLEN/8){1'b1}};
                @(posedge clk);
              end
              dma_valid = 0; dma_we = 0;
            end
          join
        end else begin
          // Last K step: just issue, no DMA needed
          for (i = 0; i < N_ACC; i++)
            issue(encode_vmacc_vx(i[4:0], 5'd10, (16 + i)), {24'b0, scalar_val});
        end

        // Swap banks: shadow (with next weights) becomes active
        if (k < K_DIM - 1) begin
          dma_dbuf_swap = 1'b1;
          @(posedge clk);
          dma_dbuf_swap = 1'b0;
        end
      end

      wait_drain();
      cycle_end = $time / CLK_PERIOD;
      total_cycles = cycle_end - cycle_start;
      mac_ops = N_ACC * K_DIM;
      element_macs = mac_ops * VLMAX_8;

      $display("    %0d cycles for %0d vec MACs (%0d elem MACs)",
               total_cycles, mac_ops, element_macs);
      $display("    Vec MACs/cycle:  %0.3f", real'(mac_ops) / real'(total_cycles));
      $display("    Elem MACs/cycle: %0.1f  (peak=%0d)",
               real'(element_macs) / real'(total_cycles), VLMAX_8);
      $display("    Pipeline util:   %0.1f%%",
               (real'(mac_ops) / real'(total_cycles)) * 100.0);

      // Clean up
      dma_dbuf_en  = 1'b0;
      dma_dbuf_swap = 1'b0;
    end
  endtask

  //==========================================================================
  // Task 2: Long GEMV Throughput Characterization
  // 500k instructions
  //==========================================================================
  task automatic run_long_gemv();
    integer cycle_start, cycle_end, total_cycles;
    integer mac_ops, element_macs;
    integer i, k;
    integer N_ACC = 8;
    integer K_DIM = 62500; // 8 * 62500 = 500,000 instructions

    begin
      $display("");
      $display("==========================================================");
      $display("=== TASK 2: LONG GEMV THROUGHPUT TEST ===");
      $display("  Accumulators: %0d", N_ACC);
      $display("  K Dimension:  %0d", K_DIM);
      $display("  Total Instr:  %0d", N_ACC * K_DIM);
      $display("==========================================================");

      // Pre-load registers
      for (i = 0; i < N_ACC; i++)
        vrf_write(i[4:0], {DLEN{1'b0}});        // accumulators
      for (i = 0; i < N_ACC; i++)
        vrf_write((16 + i), {(DLEN/8){i[7:0] + 8'h10}});  // weights

      repeat (4) @(posedge clk);
      cycle_start = $time / CLK_PERIOD;

      // K Loop
      for (k = 0; k < K_DIM; k++) begin
        for (i = 0; i < N_ACC; i++) begin
          issue(encode_vmacc_vx(i[4:0], 5'd10, (16 + i)), {24'b0, k[7:0]});
        end

        if (k % 5000 == 0) $display("[%0t] K=%0d...", $time, k);
      end

      wait_drain();
      cycle_end = $time / CLK_PERIOD;
      total_cycles = cycle_end - cycle_start;
      mac_ops = N_ACC * K_DIM;
      element_macs = mac_ops * VLMAX_8;

      $display("    Total cycles:    %0d", total_cycles);
      $display("    Vector MACs:     %0d", mac_ops);
      $display("    Vec MACs/cycle:  %0.4f", real'(mac_ops) / real'(total_cycles));
      $display("    Elem MACs/cycle: %0.2f  (peak=%0d)",
               real'(element_macs) / real'(total_cycles), VLMAX_8);
      $display("    Utilization:     %0.2f%%",
               (real'(mac_ops) / real'(total_cycles)) * 100.0);
      $display("==========================================================");
    end
  endtask

  //==========================================================================
  // Main
  //==========================================================================
  initial begin
    $display("##########################################################");
    $display("#  Hyperplane VPU — GEMV Inference Benchmark");
    $display("#  VLEN=%0d  DLEN=%0d  NLANES=%0d  ELEN=%0d", VLEN, DLEN, NLANES, ELEN);
    $display("#  Pipeline: D1-D2-OF-E1-E1m-E2-E3-WB (8 stages)");
    $display("##########################################################");

    do_reset();
    set_vtype(3'b000, 3'b000, VLMAX_8);  // SEW=8, LMUL=1

    // =====================================================================
    // Part 1: ALU baseline (shows pipeline can sustain ~1 op/cycle)
    // =====================================================================
    $display("");
    $display("=== PART 1: ALU BASELINE (no data hazards) ===");
    run_vadd_baseline(64);

    // =====================================================================
    // Part 2: PURE MAC PIPELINE THROUGHPUT (no memory overhead)
    // This is the key metric — shows raw pipeline capability
    // =====================================================================
    $display("");
    $display("=== PART 2: PURE MAC PIPELINE THROUGHPUT ===");
    $display("  (K=16, SEW=8, weights pre-loaded, NO DMA during compute)");

    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_pure_mac(1, 16);

    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_pure_mac(2, 16);

    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_pure_mac(4, 16);

    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_pure_mac(8, 16);

    // v0.5e: Larger K to measure sustained throughput (amortizes pipeline fill/drain)
    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_pure_mac(8, 64);

    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_pure_mac(8, 128);

    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_pure_mac(4, 128);

    // v0.5e: Also test ALU baseline with more ops for comparison
    $display("");
    $display("=== PART 2b: ALU BASELINE (larger burst) ===");
    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_vadd_baseline(256);

    // =====================================================================
    // Part 3: MAC THROUGHPUT with weight streaming (realistic DMA)
    // =====================================================================
    $display("");
    $display("=== PART 3: MAC + WEIGHT STREAMING (DMA overhead) ===");
    $display("  (K=16 inner dimension, SEW=8, DMA reload per K step)");

    // Reset between runs
    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_gemv_bench(1, 16, 0);

    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_gemv_bench(8, 16, 0);

    // v0.5e: Larger K GEMV (more realistic LLM dimensions)
    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_gemv_bench(8, 64, 0);

    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_gemv_bench(8, 128, 0);

    // =====================================================================
    // Part 4: GEMV + GELU end-to-end
    // =====================================================================
    $display("");
    $display("=== PART 4: GEMV + GELU ACTIVATION ===");

    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_gemv_bench(8, 16, 1);   // 8 accumulators + GELU

    // =====================================================================
    // Part 5: Realistic inference scenario (multi-layer)
    // =====================================================================
    $display("");
    $display("=== PART 5: FULL INFERENCE SCENARIO ===");

    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_inference_scenario();

    // =====================================================================
    // Part 6: Double-Buffered GEMV (overlapped DMA + compute)
    // =====================================================================
    $display("");
    $display("=== PART 6: DOUBLE-BUFFERED GEMV (overlapped DMA) ===");
    $display("  (DMA writes to shadow weight bank WHILE compute runs on active bank)");

    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_gemv_dbuf(8, 16);

    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_gemv_dbuf(8, 64);

    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_gemv_dbuf(8, 128);

    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_gemv_dbuf(4, 128);

    // =====================================================================
    // Task 2: LONG GEMV (500k instructions)
    // =====================================================================
`ifdef LONG_GEMV
    do_reset(); set_vtype(3'b000, 3'b000, VLMAX_8);
    run_long_gemv();
`endif

    $display("");
    $display("##########################################################");
    $display("#  BENCHMARK COMPLETE");
    $display("##########################################################");
    #100;
    $finish;
  end

endmodule
