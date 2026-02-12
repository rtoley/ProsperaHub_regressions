//==============================================================================
// Hyperplane VPU - Instruction Queue
// Parameterized FIFO for instruction buffering
//==============================================================================

module hp_vpu_iq
  import hp_vpu_pkg::*;
#(
  parameter int unsigned DEPTH = 8,
  parameter int unsigned ID_W  = 4
)(
  input  logic                  clk,
  input  logic                  rst_n,

  // Push interface
  input  logic                  push_i,
  input  logic [31:0]           instr_i,
  input  logic [ID_W-1:0]       id_i,
  input  logic [31:0]           rs1_i,
  input  logic [31:0]           rs2_i,

  // Pop interface
  input  logic                  pop_i,
  output logic [31:0]           instr_o,
  output logic [ID_W-1:0]       id_o,
  output logic [31:0]           rs1_o,
  output logic [31:0]           rs2_o,

  // Status
  output logic                  full_o,
  output logic                  empty_o
);

  localparam int unsigned PTR_W = $clog2(DEPTH);
  localparam int unsigned ENTRY_W = 32 + ID_W + 32 + 32;

  // Storage
  logic [ENTRY_W-1:0] mem [0:DEPTH-1];

  // Pointers
  logic [PTR_W:0] wr_ptr_q, rd_ptr_q;
  logic [PTR_W:0] wr_ptr_next, rd_ptr_next;

  // Count
  wire [PTR_W:0] count = wr_ptr_q - rd_ptr_q;

  assign full_o  = (count == DEPTH[PTR_W:0]);
  assign empty_o = (count == '0);

  // Pointer updates
  assign wr_ptr_next = push_i && !full_o  ? wr_ptr_q + 1'b1 : wr_ptr_q;
  assign rd_ptr_next = pop_i  && !empty_o ? rd_ptr_q + 1'b1 : rd_ptr_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_q <= '0;
      rd_ptr_q <= '0;
    end else begin
      wr_ptr_q <= wr_ptr_next;
      rd_ptr_q <= rd_ptr_next;
    end
  end

  // Write
  always_ff @(posedge clk) begin
    if (push_i && !full_o) begin
      mem[wr_ptr_q[PTR_W-1:0]] <= {instr_i, id_i, rs1_i, rs2_i};
    end
  end

  // Read (registered for timing)
  logic [ENTRY_W-1:0] rd_data_q;

  always_ff @(posedge clk) begin
    rd_data_q <= mem[rd_ptr_q[PTR_W-1:0]];
  end

  // Output unpacking - use bypass for same-cycle push to empty queue
  // When pushing to empty queue, mem write hasn't completed yet, so bypass directly
  wire bypass_valid = push_i && empty_o;
  wire [ENTRY_W-1:0] rd_data = bypass_valid ?
                               {instr_i, id_i, rs1_i, rs2_i} :
                               mem[rd_ptr_q[PTR_W-1:0]];

  assign instr_o = rd_data[ENTRY_W-1 -: 32];
  assign id_o    = rd_data[ENTRY_W-33 -: ID_W];
  assign rs1_o   = rd_data[63:32];
  assign rs2_o   = rd_data[31:0];

endmodule
