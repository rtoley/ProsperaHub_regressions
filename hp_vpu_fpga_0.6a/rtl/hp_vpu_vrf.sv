//==============================================================================
// Hyperplane VPU - Vector Register File
// v0.6: Fully separated compute and DMA write ports, BRAM-friendly
//
// Architecture:
//   Registers 0-15  ("base"):   single array, 16 × DLEN
//   Registers 16-31 ("weight"): dual banks A/B, each 16 × DLEN
//
// Write-port analysis (per physical array):
//   base_mem:  Compute writes accumulators during GEMV.
//              DMA writes during init only (never overlaps compute).
//              Single muxed write port: compute priority, else DMA.
//   weight_a:  When A is active → compute reads, DMA writes B.
//              When B is active → DMA writes A (shadow).
//              Single muxed write port per array. Never 2 simultaneous.
//   weight_b:  Mirror of weight_a.
//
// Each array has 1W (muxed) + 3R → Vivado replicates to 2 TDP BRAMs.
// Byte-write enables supported natively by BRAM write-enable pins.
//
// Synthesis: (* ram_style = "block" *) forces Xilinx block RAM inference.
//   At VLEN=64:  16×64-bit  = 1Kbit/array, 3 arrays → 6 BRAM18 (w/ replication)
//   At VLEN=256: 16×256-bit = 4Kbit/array → better BRAM utilization
//==============================================================================

module hp_vpu_vrf
  import hp_vpu_pkg::*;
#(
  parameter int unsigned VLEN   = hp_vpu_pkg::VLEN,
  parameter int unsigned NLANES = hp_vpu_pkg::NLANES,
  parameter int unsigned NREGS  = hp_vpu_pkg::NUM_REGS
)(
  input  logic                      clk,
  input  logic                      rst_n,

  // Read interface (3 ports + mask)
  input  logic                      rd_en_i,
  input  logic [4:0]                vs1_i,
  input  logic [4:0]                vs2_i,
  input  logic [4:0]                vs3_i,
  input  logic [4:0]                vm_i,
  output logic [NLANES*64-1:0]      vs1_o,
  output logic [NLANES*64-1:0]      vs2_o,
  output logic [NLANES*64-1:0]      vs3_o,
  output logic [NLANES*64-1:0]      vm_o,

  // Write port 1: compute pipeline WB ONLY (with byte enables)
  input  logic                      wr_en_i,
  input  logic [4:0]                vd_i,
  input  logic [NLANES*64-1:0]      wd_i,
  input  logic [NLANES*8-1:0]       wr_be_i,

  // Write port 2: DMA writes — all addresses (with byte enables)
  input  logic                      dma_wr_en_i,
  input  logic [4:0]                dma_wr_addr_i,
  input  logic [NLANES*64-1:0]      dma_wr_data_i,
  input  logic [NLANES*8-1:0]       dma_wr_be_i,

  // Weight bank control
  input  logic                      weight_bank_sel_i,  // 0=A active, 1=B active
  input  logic                      dma_dbuf_en_i,      // Double-buffer mode enable

  // Debug read interface
  input  logic [4:0]                mem_rd_addr_i,
  output logic [NLANES*64-1:0]      mem_rd_data_o
);

  localparam int unsigned DLEN  = NLANES * 64;
  localparam int unsigned NBYTE = DLEN / 8;

  // DMA write target decode
  wire dma_to_base   = dma_wr_en_i && !dma_wr_addr_i[4];
  wire dma_to_weight = dma_wr_en_i &&  dma_wr_addr_i[4];
  wire dma_to_shadow = dma_to_weight &&  dma_dbuf_en_i;
  wire dma_to_active = dma_to_weight && !dma_dbuf_en_i;

  // Compute write target decode
  wire comp_to_base = wr_en_i && !vd_i[4];
  wire comp_to_wgt  = wr_en_i &&  vd_i[4];

  //==========================================================================
  // Physical Storage — flat arrays, BRAM-inferred
  //==========================================================================
  (* ram_style = "block" *) logic [DLEN-1:0] base_mem   [0:15];
  (* ram_style = "block" *) logic [DLEN-1:0] weight_a   [0:15];
  (* ram_style = "block" *) logic [DLEN-1:0] weight_b   [0:15];

  //==========================================================================
  // base_mem: single muxed write port (compute priority, then DMA)
  // During GEMV: compute writes accumulators here. DMA never touches base.
  // During init: DMA writes here. Compute idle.
  //==========================================================================
  always_ff @(posedge clk) begin
    if (comp_to_base) begin
      for (int j = 0; j < NBYTE; j++)
        if (wr_be_i[j])
          base_mem[vd_i[3:0]][j*8 +: 8] <= wd_i[j*8 +: 8];
    end else if (dma_to_base) begin
      for (int j = 0; j < NBYTE; j++)
        if (dma_wr_be_i[j])
          base_mem[dma_wr_addr_i[3:0]][j*8 +: 8] <= dma_wr_data_i[j*8 +: 8];
    end
  end

  //==========================================================================
  // weight_a: single muxed write port
  // Compute writes here when A is active bank (weight_bank_sel=0).
  // DMA writes here when A is shadow (weight_bank_sel=1, dbuf on).
  // DMA writes here when dbuf off and sel=0 (non-dbuf mode init).
  // Never 2 simultaneous writers: shadow write only when A is NOT active.
  //==========================================================================
  always_ff @(posedge clk) begin
    if (comp_to_wgt && !weight_bank_sel_i) begin
      // Compute writes to active bank A
      for (int j = 0; j < NBYTE; j++)
        if (wr_be_i[j])
          weight_a[vd_i[3:0]][j*8 +: 8] <= wd_i[j*8 +: 8];
    end else if (dma_to_shadow && weight_bank_sel_i) begin
      // DMA writes to shadow A (B is active)
      for (int j = 0; j < NBYTE; j++)
        if (dma_wr_be_i[j])
          weight_a[dma_wr_addr_i[3:0]][j*8 +: 8] <= dma_wr_data_i[j*8 +: 8];
    end else if (dma_to_active && !weight_bank_sel_i) begin
      // DMA writes to active A (dbuf disabled, init mode)
      for (int j = 0; j < NBYTE; j++)
        if (dma_wr_be_i[j])
          weight_a[dma_wr_addr_i[3:0]][j*8 +: 8] <= dma_wr_data_i[j*8 +: 8];
    end
  end

  //==========================================================================
  // weight_b: single muxed write port (mirror of weight_a logic)
  //==========================================================================
  always_ff @(posedge clk) begin
    if (comp_to_wgt && weight_bank_sel_i) begin
      // Compute writes to active bank B
      for (int j = 0; j < NBYTE; j++)
        if (wr_be_i[j])
          weight_b[vd_i[3:0]][j*8 +: 8] <= wd_i[j*8 +: 8];
    end else if (dma_to_shadow && !weight_bank_sel_i) begin
      // DMA writes to shadow B (A is active)
      for (int j = 0; j < NBYTE; j++)
        if (dma_wr_be_i[j])
          weight_b[dma_wr_addr_i[3:0]][j*8 +: 8] <= dma_wr_data_i[j*8 +: 8];
    end else if (dma_to_active && weight_bank_sel_i) begin
      // DMA writes to active B (dbuf disabled, init mode)
      for (int j = 0; j < NBYTE; j++)
        if (dma_wr_be_i[j])
          weight_b[dma_wr_addr_i[3:0]][j*8 +: 8] <= dma_wr_data_i[j*8 +: 8];
    end
  end

  //==========================================================================
  // Read port 1 (vs1) — registered for BRAM output register
  //==========================================================================
  logic [DLEN-1:0] rd1_base_q, rd1_wa_q, rd1_wb_q;
  logic             rd1_is_wgt_q;

  always_ff @(posedge clk) begin
    if (rd_en_i) begin
      rd1_base_q   <= base_mem[vs1_i[3:0]];
      rd1_wa_q     <= weight_a[vs1_i[3:0]];
      rd1_wb_q     <= weight_b[vs1_i[3:0]];
      rd1_is_wgt_q <= vs1_i[4];
    end
  end

  wire [DLEN-1:0] rd1_active_wgt = weight_bank_sel_i ? rd1_wb_q : rd1_wa_q;
  assign vs1_o = rd1_is_wgt_q ? rd1_active_wgt : rd1_base_q;

  //==========================================================================
  // Read port 2 (vs2)
  //==========================================================================
  logic [DLEN-1:0] rd2_base_q, rd2_wa_q, rd2_wb_q;
  logic             rd2_is_wgt_q;

  always_ff @(posedge clk) begin
    if (rd_en_i) begin
      rd2_base_q   <= base_mem[vs2_i[3:0]];
      rd2_wa_q     <= weight_a[vs2_i[3:0]];
      rd2_wb_q     <= weight_b[vs2_i[3:0]];
      rd2_is_wgt_q <= vs2_i[4];
    end
  end

  wire [DLEN-1:0] rd2_active_wgt = weight_bank_sel_i ? rd2_wb_q : rd2_wa_q;
  assign vs2_o = rd2_is_wgt_q ? rd2_active_wgt : rd2_base_q;

  //==========================================================================
  // Read port 3 (vs3 — accumulator/old_vd for MAC)
  //==========================================================================
  logic [DLEN-1:0] rd3_base_q, rd3_wa_q, rd3_wb_q;
  logic             rd3_is_wgt_q;

  always_ff @(posedge clk) begin
    if (rd_en_i) begin
      rd3_base_q   <= base_mem[vs3_i[3:0]];
      rd3_wa_q     <= weight_a[vs3_i[3:0]];
      rd3_wb_q     <= weight_b[vs3_i[3:0]];
      rd3_is_wgt_q <= vs3_i[4];
    end
  end

  wire [DLEN-1:0] rd3_active_wgt = weight_bank_sel_i ? rd3_wb_q : rd3_wa_q;
  assign vs3_o = rd3_is_wgt_q ? rd3_active_wgt : rd3_base_q;

  //==========================================================================
  // Read port 4 (mask — v0, always base_mem)
  //==========================================================================
  logic [DLEN-1:0] rdm_q;

  always_ff @(posedge clk) begin
    if (rd_en_i) rdm_q <= base_mem[vm_i[3:0]];
  end

  assign vm_o = rdm_q;

  //==========================================================================
  // Debug read — registered (BRAM-compatible, 1-cycle latency)
  //==========================================================================
  logic [DLEN-1:0] dbg_data_q;

  always_ff @(posedge clk) begin
    if (!mem_rd_addr_i[4])
      dbg_data_q <= base_mem[mem_rd_addr_i[3:0]];
    else if (!weight_bank_sel_i)
      dbg_data_q <= weight_a[mem_rd_addr_i[3:0]];
    else
      dbg_data_q <= weight_b[mem_rd_addr_i[3:0]];
  end

  assign mem_rd_data_o = dbg_data_q;

  // Simulation init
  initial begin
    for (int i = 0; i < 16; i++) begin
      base_mem[i] = '0;
      weight_a[i] = '0;
      weight_b[i] = '0;
    end
  end

endmodule
