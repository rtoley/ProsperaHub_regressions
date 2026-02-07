#!/usr/bin/env python3
"""
Hyperplane VPU Configuration Generator

Reads vpu_config.json and generates:
  - Verilog package (hp_vpu_pkg.sv)
  - SystemC configuration header (hp_vpu_config.h)
  - Unified stimulus format header (hp_stimulus.h / hp_stimulus.vh)
  - SDC timing constraints
  - Makefile fragment

Usage: python3 generate_all.py [config.json] [output_dir]
"""

import json
import os
import sys
import math
from datetime import datetime

class HPConfigGenerator:
    def __init__(self, config_path):
        with open(config_path) as f:
            self.cfg = json.load(f)
        self.timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    def generate_all(self, out_dir):
        """Generate all derived files"""
        os.makedirs(out_dir, exist_ok=True)

        self.gen_verilog_pkg(f"{out_dir}/hp_vpu_pkg.sv")
        self.gen_systemc_header(f"{out_dir}/hp_vpu_config.h")
        self.gen_stimulus_header_v(f"{out_dir}/hp_stimulus.vh")
        self.gen_stimulus_header_c(f"{out_dir}/hp_stimulus.h")
        self.gen_sdc(f"{out_dir}/hp_vpu.sdc")
        self.gen_xdc(f"{out_dir}/hp_vpu.xdc")
        self.gen_makefile_inc(f"{out_dir}/config.mk")

        print(f"Generated all files in {out_dir}/")

    def gen_verilog_pkg(self, path):
        """Generate SystemVerilog package"""
        arch = self.cfg['architecture']
        pipe = self.cfg['pipeline']
        mem = self.cfg['memory']
        iface = self.cfg['interfaces']
        timing = self.cfg['timing']
        stim = self.cfg['stimulus']

        # Derived parameters
        dlen = arch['nlanes'] * 64
        vrf_addr_w = int(math.ceil(math.log2(arch['vrf_entries'])))
        sram_addr_w = int(math.ceil(math.log2(mem['sram_depth_kb'] * 1024 * 8 / mem['sram_width_bits'])))

        content = f'''//==============================================================================
// Hyperplane VPU Package - Auto-Generated from vpu_config.json
// Generated: {self.timestamp}
// Version: {self.cfg['meta']['version']}
// Target: {pipe['target_freq_ghz']} GHz ASIC / {self.cfg['synthesis']['fpga']['target_freq_mhz']} MHz FPGA
//==============================================================================
// DO NOT EDIT - Regenerate with: python3 generate_all.py
//==============================================================================

`ifndef HP_VPU_PKG_SV
`define HP_VPU_PKG_SV

package hp_vpu_pkg;

  //============================================================================
  // Architecture Parameters
  //============================================================================
  parameter int unsigned VLEN         = {arch['vlen']};          // Vector register length (bits)
  parameter int unsigned NLANES       = {arch['nlanes']};            // Parallel lanes
  parameter int unsigned ELEN         = {arch['elen']};           // Max element width (bits)
  parameter int unsigned DLEN         = {dlen};          // Datapath width = NLANES * 64
  parameter int unsigned VLEN_BYTES   = VLEN / 8;
  parameter int unsigned DLEN_BYTES   = DLEN / 8;

  parameter int unsigned VRF_ENTRIES  = {arch['vrf_entries']};           // v0-v31
  parameter int unsigned VRF_ADDR_W   = {vrf_addr_w};            // $clog2(32)
  parameter int unsigned VRF_RD_PORTS = {arch['vrf_rd_ports']};            // Read ports
  parameter int unsigned VRF_WR_PORTS = {arch['vrf_wr_ports']};            // Write ports

  //============================================================================
  // Pipeline Parameters (2 GHz target)
  //============================================================================
  parameter int unsigned PIPE_FETCH   = {pipe['stages']['fetch']};
  parameter int unsigned PIPE_DECODE  = {pipe['stages']['decode']};
  parameter int unsigned PIPE_ISSUE   = {pipe['stages']['issue']};
  parameter int unsigned PIPE_OPREAD  = {pipe['stages']['operand_read']};
  parameter int unsigned PIPE_EXEC    = {pipe['stages']['execute']};
  parameter int unsigned PIPE_MEM     = {pipe['stages']['memory']};
  parameter int unsigned PIPE_WB      = {pipe['stages']['writeback']};
  parameter int unsigned PIPE_DEPTH   = {pipe['total_depth']};

  parameter int unsigned IQ_DEPTH     = {pipe['iq_depth']};           // Instruction queue

  //============================================================================
  // Memory Parameters
  //============================================================================
  parameter int unsigned SRAM_WIDTH   = {mem['sram_width_bits']};         // SRAM interface width
  parameter int unsigned SRAM_BANKS   = {mem['sram_banks']};           // Bank count
  parameter int unsigned SRAM_ADDR_W  = {sram_addr_w};          // Address width
  parameter int unsigned SRAM_LATENCY = {mem['sram_latency_cycles']};           // Access latency

  //============================================================================
  // Interface Parameters
  //============================================================================
  parameter int unsigned CVXIF_ID_W   = {iface['cvxif']['id_width']};           // CV-X-IF transaction ID
  parameter int unsigned AXI_DATA_W   = {iface['axi']['data_width']};         // AXI data width
  parameter int unsigned AXI_ADDR_W   = {iface['axi']['addr_width']};          // AXI address width
  parameter int unsigned AXI_ID_W     = {iface['axi']['id_width']};           // AXI ID width

  //============================================================================
  // Timing Parameters
  //============================================================================
  parameter int unsigned RESET_CYCLES = {timing['reset_cycles']};
  parameter bit          RESET_ACTIVE_LOW = {1 if timing['reset_active_low'] else 0};

  //============================================================================
  // Stimulus Packet Format ({stim['packet_width_bits']} bits)
  //============================================================================
  parameter int unsigned STIM_WIDTH   = {stim['packet_width_bits']};

  //============================================================================
  // RVV 1.0 Instruction Encodings
  //============================================================================
  // Major Opcodes
  typedef enum logic [6:0] {{
    OPC_LOAD_FP  = 7'b0000111,
    OPC_STORE_FP = 7'b0100111,
    OPC_VECTOR   = 7'b1010111
  }} rvv_opcode_e;

  // funct3 for OPC_VECTOR
  typedef enum logic [2:0] {{
    F3_OPIVV = 3'b000,  // Vector-vector integer
    F3_OPFVV = 3'b001,  // Vector-vector FP
    F3_OPMVV = 3'b010,  // Mask/reduction
    F3_OPIVI = 3'b011,  // Vector-immediate
    F3_OPIVX = 3'b100,  // Vector-scalar integer
    F3_OPFVF = 3'b101,  // Vector-scalar FP
    F3_OPMVX = 3'b110,  // Vector-scalar mask
    F3_OPCFG = 3'b111   // Configuration
  }} rvv_funct3_e;

  // funct6 for arithmetic operations
  typedef enum logic [5:0] {{
    F6_VADD      = 6'b000000,
    F6_VSUB      = 6'b000010,
    F6_VRSUB     = 6'b000011,
    F6_VMINU     = 6'b000100,
    F6_VMIN      = 6'b000101,
    F6_VMAXU     = 6'b000110,
    F6_VMAX      = 6'b000111,
    F6_VAND      = 6'b001001,
    F6_VOR       = 6'b001010,
    F6_VXOR      = 6'b001011,
    F6_VRGATHER  = 6'b001100,
    F6_VSLIDEUP  = 6'b001110,
    F6_VSLIDEDN  = 6'b001111,
    F6_VMSEQ     = 6'b011000,
    F6_VMSNE     = 6'b011001,
    F6_VMSLTU    = 6'b011010,
    F6_VMSLT     = 6'b011011,
    F6_VMSLEU    = 6'b011100,
    F6_VMSLE     = 6'b011101,
    F6_VMSGTU    = 6'b011110,
    F6_VMSGT     = 6'b011111,
    F6_VSLL      = 6'b100101,
    F6_VSRL      = 6'b101000,
    F6_VSRA      = 6'b101001,
    F6_VMUL      = 6'b100101,
    F6_VMULH     = 6'b100111,
    F6_VMULHU    = 6'b100100,
    F6_VMACC     = 6'b101101,
    F6_VNMSAC    = 6'b101111,
    F6_VMADD     = 6'b101001,
    F6_VNMSUB    = 6'b101011
  }} rvv_funct6_e;

  // SEW encoding in vtype
  typedef enum logic [2:0] {{
    SEW_8  = 3'b000,
    SEW_16 = 3'b001,
    SEW_32 = 3'b010,
    SEW_64 = 3'b011
  }} sew_e;

  // LMUL encoding in vtype
  typedef enum logic [2:0] {{
    LMUL_1   = 3'b000,
    LMUL_2   = 3'b001,
    LMUL_4   = 3'b010,
    LMUL_8   = 3'b011,
    LMUL_F8  = 3'b101,
    LMUL_F4  = 3'b110,
    LMUL_F2  = 3'b111
  }} lmul_e;

  //============================================================================
  // Internal Operation Codes
  //============================================================================
  typedef enum logic [4:0] {{
    OP_NOP      = 5'd0,
    OP_VLOAD    = 5'd1,
    OP_VSTORE   = 5'd2,
    OP_VADD     = 5'd3,
    OP_VSUB     = 5'd4,
    OP_VMUL     = 5'd5,
    OP_VMACC    = 5'd6,
    OP_VAND     = 5'd7,
    OP_VOR      = 5'd8,
    OP_VXOR     = 5'd9,
    OP_VSLL     = 5'd10,
    OP_VSRL     = 5'd11,
    OP_VSRA     = 5'd12,
    OP_VMIN     = 5'd13,
    OP_VMAX     = 5'd14,
    OP_VCMP     = 5'd15,
    OP_VREDSUM  = 5'd16,
    OP_VSLIDE   = 5'd17,
    OP_VRGATHER = 5'd18,
    OP_VMASK    = 5'd19,
    OP_VCONFIG  = 5'd20
  }} vpu_op_e;

  //============================================================================
  // Stimulus Packet Types
  //============================================================================
  typedef enum logic [3:0] {{
    PKT_NOP     = 4'h0,
    PKT_CONFIG  = 4'h1,
    PKT_INSTR   = 4'h2,
    PKT_VDATA   = 4'h3,
    PKT_SDATA   = 4'h4,
    PKT_EXPECT  = 4'h5,
    PKT_CHECK   = 4'h6,
    PKT_SYNC    = 4'h7,
    PKT_MEMWR   = 4'h8,
    PKT_MEMRD   = 4'h9,
    PKT_END     = 4'hF
  }} stim_pkt_type_e;

  //============================================================================
  // Stimulus Packet Structure (512 bits total)
  //============================================================================
  // [511:508]  4-bit   pkt_type
  // [507:504]  4-bit   flags
  // [503:472] 32-bit   aux0 (instruction / address / control)
  // [471:440] 32-bit   aux1 (rs1 / stride / expected_hi[63:32])
  // [439:408] 32-bit   aux2 (rs2 / count / expected_hi[31:0])
  // [407:400]  8-bit   sew
  // [399:392]  8-bit   lmul
  // [391:376] 16-bit   vl
  // [375:372]  4-bit   tid
  // [371:368]  4-bit   reserved
  // [367:256] 112-bit  reserved
  // [255:0]  256-bit   data payload

  typedef struct packed {{
    logic [3:0]   pkt_type;
    logic [3:0]   flags;
    logic [31:0]  aux0;
    logic [31:0]  aux1;
    logic [31:0]  aux2;
    logic [7:0]   sew;
    logic [7:0]   lmul;
    logic [15:0]  vl;
    logic [3:0]   tid;
    logic [3:0]   rsvd0;
    logic [111:0] rsvd1;
    logic [255:0] data;
  }} stim_packet_t;

  // Packet flags
  typedef struct packed {{
    logic masked;
    logic last;
    logic check;
    logic error;
  }} stim_flags_t;

endpackage

`endif // HP_VPU_PKG_SV
'''
        with open(path, 'w') as f:
            f.write(content)
        print(f"  Generated: {path}")

    def gen_systemc_header(self, path):
        """Generate SystemC configuration header"""
        arch = self.cfg['architecture']
        pipe = self.cfg['pipeline']
        mem = self.cfg['memory']
        iface = self.cfg['interfaces']
        stim = self.cfg['stimulus']

        dlen = arch['nlanes'] * 64
        vrf_addr_w = int(math.ceil(math.log2(arch['vrf_entries'])))

        content = f'''//==============================================================================
// Hyperplane VPU Configuration - SystemC Header
// Generated: {self.timestamp}
// Version: {self.cfg['meta']['version']}
//==============================================================================
// DO NOT EDIT - Regenerate with: python3 generate_all.py
//==============================================================================

#ifndef HP_VPU_CONFIG_H
#define HP_VPU_CONFIG_H

#include <cstdint>
#include <systemc>

namespace hp {{

//==============================================================================
// Architecture Parameters
//==============================================================================
constexpr unsigned VLEN         = {arch['vlen']};
constexpr unsigned NLANES       = {arch['nlanes']};
constexpr unsigned ELEN         = {arch['elen']};
constexpr unsigned DLEN         = {dlen};
constexpr unsigned VLEN_BYTES   = VLEN / 8;
constexpr unsigned DLEN_BYTES   = DLEN / 8;

constexpr unsigned VRF_ENTRIES  = {arch['vrf_entries']};
constexpr unsigned VRF_ADDR_W   = {vrf_addr_w};
constexpr unsigned VRF_RD_PORTS = {arch['vrf_rd_ports']};
constexpr unsigned VRF_WR_PORTS = {arch['vrf_wr_ports']};

//==============================================================================
// Pipeline Parameters
//==============================================================================
constexpr unsigned PIPE_DEPTH   = {pipe['total_depth']};
constexpr unsigned IQ_DEPTH     = {pipe['iq_depth']};
constexpr double   TARGET_FREQ  = {pipe['target_freq_ghz']}e9;  // Hz

//==============================================================================
// Memory Parameters
//==============================================================================
constexpr unsigned SRAM_WIDTH   = {mem['sram_width_bits']};
constexpr unsigned SRAM_BANKS   = {mem['sram_banks']};
constexpr unsigned SRAM_LATENCY = {mem['sram_latency_cycles']};

//==============================================================================
// Interface Parameters
//==============================================================================
constexpr unsigned CVXIF_ID_W   = {iface['cvxif']['id_width']};
constexpr unsigned AXI_DATA_W   = {iface['axi']['data_width']};
constexpr unsigned AXI_ADDR_W   = {iface['axi']['addr_width']};

//==============================================================================
// Stimulus Parameters
//==============================================================================
constexpr unsigned STIM_WIDTH   = {stim['packet_width_bits']};
constexpr unsigned STIM_BYTES   = STIM_WIDTH / 8;

//==============================================================================
// RVV Encodings
//==============================================================================
namespace rvv {{
  // Opcodes
  constexpr uint8_t OPC_LOAD_FP  = 0b0000111;
  constexpr uint8_t OPC_STORE_FP = 0b0100111;
  constexpr uint8_t OPC_VECTOR   = 0b1010111;

  // funct3
  constexpr uint8_t F3_OPIVV = 0b000;
  constexpr uint8_t F3_OPFVV = 0b001;
  constexpr uint8_t F3_OPMVV = 0b010;
  constexpr uint8_t F3_OPIVI = 0b011;
  constexpr uint8_t F3_OPIVX = 0b100;
  constexpr uint8_t F3_OPFVF = 0b101;
  constexpr uint8_t F3_OPMVX = 0b110;
  constexpr uint8_t F3_OPCFG = 0b111;

  // funct6
  constexpr uint8_t F6_VADD  = 0b000000;
  constexpr uint8_t F6_VSUB  = 0b000010;
  constexpr uint8_t F6_VAND  = 0b001001;
  constexpr uint8_t F6_VOR   = 0b001010;
  constexpr uint8_t F6_VXOR  = 0b001011;
  constexpr uint8_t F6_VMUL  = 0b100101;
  constexpr uint8_t F6_VMACC = 0b101101;

  // SEW
  constexpr uint8_t SEW_8  = 0b000;
  constexpr uint8_t SEW_16 = 0b001;
  constexpr uint8_t SEW_32 = 0b010;
  constexpr uint8_t SEW_64 = 0b011;

  // LMUL
  constexpr uint8_t LMUL_1  = 0b000;
  constexpr uint8_t LMUL_2  = 0b001;
  constexpr uint8_t LMUL_4  = 0b010;
  constexpr uint8_t LMUL_8  = 0b011;
}} // namespace rvv

//==============================================================================
// VPU Operations
//==============================================================================
enum class VpuOp : uint8_t {{
  NOP = 0, VLOAD, VSTORE, VADD, VSUB, VMUL, VMACC,
  VAND, VOR, VXOR, VSLL, VSRL, VSRA, VMIN, VMAX,
  VCMP, VREDSUM, VSLIDE, VRGATHER, VMASK, VCONFIG
}};

//==============================================================================
// Stimulus Packet Types
//==============================================================================
enum class PktType : uint8_t {{
  NOP = 0, CONFIG, INSTR, VDATA, SDATA, EXPECT, CHECK, SYNC,
  MEMWR, MEMRD, END = 0xF
}};

//==============================================================================
// Stimulus Packet Structure (512 bits = 64 bytes)
//==============================================================================
#pragma pack(push, 1)
struct StimPacket {{
  uint8_t  data[32];     // [255:0]   256-bit data payload
  uint8_t  rsvd1[14];    // [367:256] reserved
  uint8_t  rsvd0   : 4;  // [371:368]
  uint8_t  tid     : 4;  // [375:372]
  uint16_t vl;           // [391:376]
  uint8_t  lmul;         // [399:392]
  uint8_t  sew;          // [407:400]
  uint32_t aux2;         // [439:408]
  uint32_t aux1;         // [471:440]
  uint32_t aux0;         // [503:472]
  uint8_t  flags  : 4;   // [507:504]
  uint8_t  pkt_type : 4; // [511:508]
}};
#pragma pack(pop)

static_assert(sizeof(StimPacket) == 64, "StimPacket must be 64 bytes");

// Flag bits
constexpr uint8_t FLAG_MASKED = 0x1;
constexpr uint8_t FLAG_LAST   = 0x2;
constexpr uint8_t FLAG_CHECK  = 0x4;
constexpr uint8_t FLAG_ERROR  = 0x8;

}} // namespace hp

#endif // HP_VPU_CONFIG_H
'''
        with open(path, 'w') as f:
            f.write(content)
        print(f"  Generated: {path}")

    def gen_stimulus_header_v(self, path):
        """Generate Verilog stimulus format header"""
        stim = self.cfg['stimulus']

        content = f'''//==============================================================================
// Hyperplane VPU - Unified Stimulus Format (Verilog)
// Generated: {self.timestamp}
//==============================================================================
// This header defines the binary stimulus packet format used by BOTH
// Verilog and SystemC testbenches to ensure identical test sequences.
//==============================================================================

`ifndef HP_STIMULUS_VH
`define HP_STIMULUS_VH

//==============================================================================
// Stimulus Packet (512 bits = 64 bytes)
//==============================================================================
// Byte layout (little-endian, matches C struct):
//
// Bytes [0:31]   - 256-bit data payload
// Bytes [32:45]  - Reserved
// Byte  [46]     - tid[3:0] | rsvd0[7:4]
// Bytes [47:48]  - vl (16-bit)
// Byte  [49]     - lmul
// Byte  [50]     - sew
// Bytes [51:54]  - aux2 (32-bit)
// Bytes [55:58]  - aux1 (32-bit)
// Bytes [59:62]  - aux0 (32-bit)
// Byte  [63]     - pkt_type[7:4] | flags[3:0]

`define STIM_WIDTH      {stim['packet_width_bits']}
`define STIM_BYTES      64

// Field positions (bit indices in 512-bit packet)
`define STIM_DATA_LO    0
`define STIM_DATA_HI    255
`define STIM_TID_LO     372
`define STIM_TID_HI     375
`define STIM_VL_LO      376
`define STIM_VL_HI      391
`define STIM_LMUL_LO    392
`define STIM_LMUL_HI    399
`define STIM_SEW_LO     400
`define STIM_SEW_HI     407
`define STIM_AUX2_LO    408
`define STIM_AUX2_HI    439
`define STIM_AUX1_LO    440
`define STIM_AUX1_HI    471
`define STIM_AUX0_LO    472
`define STIM_AUX0_HI    503
`define STIM_FLAGS_LO   504
`define STIM_FLAGS_HI   507
`define STIM_TYPE_LO    508
`define STIM_TYPE_HI    511

// Packet types
`define PKT_NOP         4'h0
`define PKT_CONFIG      4'h1
`define PKT_INSTR       4'h2
`define PKT_VDATA       4'h3
`define PKT_SDATA       4'h4
`define PKT_EXPECT      4'h5
`define PKT_CHECK       4'h6
`define PKT_SYNC        4'h7
`define PKT_MEMWR       4'h8
`define PKT_MEMRD       4'h9
`define PKT_END         4'hF

// Flags
`define FLAG_MASKED     4'b0001
`define FLAG_LAST       4'b0010
`define FLAG_CHECK      4'b0100
`define FLAG_ERROR      4'b1000

`endif // HP_STIMULUS_VH
'''
        with open(path, 'w') as f:
            f.write(content)
        print(f"  Generated: {path}")

    def gen_stimulus_header_c(self, path):
        """Generate C/C++ stimulus format header (for test generators)"""
        content = f'''//==============================================================================
// Hyperplane VPU - Unified Stimulus Format (C/C++)
// Generated: {self.timestamp}
//==============================================================================
// Use this header when writing test vector generators.
// The binary format is consumed by both Verilog and SystemC testbenches.
//==============================================================================

#ifndef HP_STIMULUS_H
#define HP_STIMULUS_H

#include <cstdint>
#include <cstring>
#include <fstream>
#include <vector>

namespace hp {{
namespace stim {{

//==============================================================================
// Packet Types
//==============================================================================
enum PktType : uint8_t {{
  PKT_NOP    = 0x0,
  PKT_CONFIG = 0x1,
  PKT_INSTR  = 0x2,
  PKT_VDATA  = 0x3,
  PKT_SDATA  = 0x4,
  PKT_EXPECT = 0x5,
  PKT_CHECK  = 0x6,
  PKT_SYNC   = 0x7,
  PKT_MEMWR  = 0x8,
  PKT_MEMRD  = 0x9,
  PKT_END    = 0xF
}};

//==============================================================================
// Packet Flags
//==============================================================================
constexpr uint8_t FLAG_MASKED = 0x1;
constexpr uint8_t FLAG_LAST   = 0x2;
constexpr uint8_t FLAG_CHECK  = 0x4;
constexpr uint8_t FLAG_ERROR  = 0x8;

//==============================================================================
// 512-bit Stimulus Packet (64 bytes)
//==============================================================================
#pragma pack(push, 1)
struct Packet {{
  uint8_t  data[32];     // 256-bit payload
  uint8_t  rsvd[14];     // reserved
  uint8_t  tid_rsvd;     // tid[3:0], rsvd[7:4]
  uint8_t  vl_lo;        // vl[7:0]
  uint8_t  vl_hi;        // vl[15:8]
  uint8_t  lmul;
  uint8_t  sew;
  uint32_t aux2;
  uint32_t aux1;
  uint32_t aux0;
  uint8_t  type_flags;   // type[7:4], flags[3:0]

  // Accessors
  PktType  get_type() const {{ return static_cast<PktType>((type_flags >> 4) & 0xF); }}
  uint8_t  get_flags() const {{ return type_flags & 0xF; }}
  uint8_t  get_tid() const {{ return tid_rsvd & 0xF; }}
  uint16_t get_vl() const {{ return vl_lo | (uint16_t(vl_hi) << 8); }}

  void set_type(PktType t) {{ type_flags = (type_flags & 0x0F) | (uint8_t(t) << 4); }}
  void set_flags(uint8_t f) {{ type_flags = (type_flags & 0xF0) | (f & 0x0F); }}
  void set_tid(uint8_t t) {{ tid_rsvd = (tid_rsvd & 0xF0) | (t & 0x0F); }}
  void set_vl(uint16_t v) {{ vl_lo = v & 0xFF; vl_hi = (v >> 8) & 0xFF; }}
}};
#pragma pack(pop)

static_assert(sizeof(Packet) == 64, "Packet must be 64 bytes");

//==============================================================================
// Stimulus Builder
//==============================================================================
class Builder {{
public:
  std::vector<Packet> packets;

  void clear() {{ packets.clear(); }}

  // Add configuration packet
  void config(uint8_t sew, uint8_t lmul, uint16_t vl) {{
    Packet p = {{}};
    p.set_type(PKT_CONFIG);
    p.sew = sew;
    p.lmul = lmul;
    p.set_vl(vl);
    packets.push_back(p);
  }}

  // Add instruction packet
  void instr(uint32_t insn, uint32_t rs1 = 0, uint32_t rs2 = 0, uint8_t tid = 0) {{
    Packet p = {{}};
    p.set_type(PKT_INSTR);
    p.aux0 = insn;
    p.aux1 = rs1;
    p.aux2 = rs2;
    p.set_tid(tid);
    packets.push_back(p);
  }}

  // Add vector data packet (256 bits max per packet)
  void vdata(const uint8_t* dat, size_t len, bool last = false) {{
    Packet p = {{}};
    p.set_type(PKT_VDATA);
    if (last) p.set_flags(FLAG_LAST);
    size_t copy_len = (len > 32) ? 32 : len;
    std::memcpy(p.data, dat, copy_len);
    packets.push_back(p);
  }}

  // Add expected result packet
  void expect(const uint8_t* dat, size_t len) {{
    Packet p = {{}};
    p.set_type(PKT_EXPECT);
    p.set_flags(FLAG_CHECK);
    size_t copy_len = (len > 32) ? 32 : len;
    std::memcpy(p.data, dat, copy_len);
    packets.push_back(p);
  }}

  // Add sync/barrier
  void sync() {{
    Packet p = {{}};
    p.set_type(PKT_SYNC);
    packets.push_back(p);
  }}

  // Add end marker
  void end() {{
    Packet p = {{}};
    p.set_type(PKT_END);
    packets.push_back(p);
  }}

  // Write binary file
  bool write_bin(const std::string& path) {{
    std::ofstream f(path, std::ios::binary);
    if (!f) return false;
    for (const auto& p : packets) {{
      f.write(reinterpret_cast<const char*>(&p), sizeof(p));
    }}
    return f.good();
  }}

  // Write hex file (for $readmemh)
  bool write_hex(const std::string& path) {{
    std::ofstream f(path);
    if (!f) return false;
    for (const auto& p : packets) {{
      const uint8_t* bytes = reinterpret_cast<const uint8_t*>(&p);
      // Write MSB first (big-endian hex representation)
      for (int i = 63; i >= 0; --i) {{
        char buf[3];
        snprintf(buf, sizeof(buf), "%02x", bytes[i]);
        f << buf;
      }}
      f << "\\n";
    }}
    return f.good();
  }}
}};

//==============================================================================
// RVV Instruction Encoder
//==============================================================================
namespace enc {{
  inline uint32_t vv(uint8_t f6, uint8_t vd, uint8_t vs1, uint8_t vs2, bool vm = true) {{
    return (uint32_t(f6) << 26) | (vm ? (1u << 25) : 0) |
           (uint32_t(vs2) << 20) | (uint32_t(vs1) << 15) |
           (0b000u << 12) | (uint32_t(vd) << 7) | 0b1010111;
  }}

  inline uint32_t vx(uint8_t f6, uint8_t vd, uint8_t vs2, uint8_t rs1, bool vm = true) {{
    return (uint32_t(f6) << 26) | (vm ? (1u << 25) : 0) |
           (uint32_t(vs2) << 20) | (uint32_t(rs1) << 15) |
           (0b100u << 12) | (uint32_t(vd) << 7) | 0b1010111;
  }}

  inline uint32_t vi(uint8_t f6, uint8_t vd, uint8_t vs2, int8_t imm, bool vm = true) {{
    return (uint32_t(f6) << 26) | (vm ? (1u << 25) : 0) |
           (uint32_t(vs2) << 20) | (uint32_t(imm & 0x1F) << 15) |
           (0b011u << 12) | (uint32_t(vd) << 7) | 0b1010111;
  }}

  inline uint32_t vle(uint8_t vd, uint8_t rs1, uint8_t width = 0, bool vm = true) {{
    // width: 0=8, 5=16, 6=32, 7=64 (encoded in funct3)
    uint8_t f3 = (width == 0) ? 0b000 : (width == 16) ? 0b101 : (width == 32) ? 0b110 : 0b111;
    return (vm ? (1u << 25) : 0) | (uint32_t(rs1) << 15) |
           (uint32_t(f3) << 12) | (uint32_t(vd) << 7) | 0b0000111;
  }}

  inline uint32_t vse(uint8_t vs3, uint8_t rs1, uint8_t width = 0, bool vm = true) {{
    uint8_t f3 = (width == 0) ? 0b000 : (width == 16) ? 0b101 : (width == 32) ? 0b110 : 0b111;
    return (vm ? (1u << 25) : 0) | (uint32_t(rs1) << 15) |
           (uint32_t(f3) << 12) | (uint32_t(vs3) << 7) | 0b0100111;
  }}

  // funct6 constants
  constexpr uint8_t F6_VADD = 0b000000;
  constexpr uint8_t F6_VSUB = 0b000010;
  constexpr uint8_t F6_VAND = 0b001001;
  constexpr uint8_t F6_VOR  = 0b001010;
  constexpr uint8_t F6_VXOR = 0b001011;
  constexpr uint8_t F6_VMUL = 0b100101;
  constexpr uint8_t F6_VMACC= 0b101101;
}}

}} // namespace stim
}} // namespace hp

#endif // HP_STIMULUS_H
'''
        with open(path, 'w') as f:
            f.write(content)
        print(f"  Generated: {path}")

    def gen_sdc(self, path):
        """Generate SDC timing constraints for 2 GHz ASIC"""
        synth = self.cfg['synthesis']['asic']
        period_ps = int(1000 / synth['target_freq_ghz'])
        period_ns = period_ps / 1000.0

        content = f'''##==============================================================================
## Hyperplane VPU - SDC Timing Constraints (ASIC)
## Generated: {self.timestamp}
## Target: {synth['target_freq_ghz']} GHz ({period_ps} ps period)
##==============================================================================

## Create clock
create_clock -name clk -period {period_ns:.3f} [get_ports clk]

## Clock uncertainty
set_clock_uncertainty {synth['clock_uncertainty_ps']/1000.0:.4f} [get_clocks clk]

## Input delays
set_input_delay -clock clk {synth['input_delay_ps']/1000.0:.4f} [remove_from_collection [all_inputs] {{clk rst_n}}]

## Output delays
set_output_delay -clock clk {synth['output_delay_ps']/1000.0:.4f} [all_outputs]

## Reset is async - false path
set_false_path -from [get_ports rst_n]

## Max transition
set_max_transition {synth['max_transition_ps']/1000.0:.4f} [current_design]

## Max fanout
set_max_fanout {synth['max_fanout']} [current_design]

##------------------------------------------------------------------------------
## Pipeline Stage Timing Groups
##------------------------------------------------------------------------------
## Registers are grouped by pipeline stage for timing analysis

## Decode stage registers
# set_multicycle_path 1 -setup -from [get_cells -hier *_dec_reg*]

## Execute stage - ALU paths are most critical
# set_max_delay {period_ns * 0.9:.3f} -from [get_cells -hier *_ex1_reg*] -to [get_cells -hier *_ex2_reg*]

## Memory stage
# set_max_delay {period_ns * 0.85:.3f} -from [get_pins -hier */sram_*] -to [get_cells -hier *_mem_reg*]

##------------------------------------------------------------------------------
## Clock Gating
##------------------------------------------------------------------------------
set_clock_gating_check -setup 0.05 -hold 0.05 [current_design]

##------------------------------------------------------------------------------
## False Paths
##------------------------------------------------------------------------------
## Configuration registers are quasi-static
set_false_path -from [get_cells -hier *vtype_reg*]
set_false_path -from [get_cells -hier *vl_reg*]

## Debug ports
set_false_path -to [get_ports dbg_*]
'''
        with open(path, 'w') as f:
            f.write(content)
        print(f"  Generated: {path}")

    def gen_xdc(self, path):
        """Generate XDC constraints for Vivado"""
        fpga = self.cfg['synthesis']['fpga']
        period_ns = 1000.0 / fpga['target_freq_mhz']

        content = f'''##==============================================================================
## Hyperplane VPU - XDC Constraints (Vivado)
## Generated: {self.timestamp}
## Target: {fpga['part']} @ {fpga['target_freq_mhz']} MHz
##==============================================================================

## Clock
create_clock -period {period_ns:.3f} -name clk [get_ports clk]

## I/O delays
set_input_delay -clock clk 1.0 [get_ports -filter {{NAME !~ clk && NAME !~ rst_n}}]
set_output_delay -clock clk 1.0 [all_outputs]

## Reset false path
set_false_path -from [get_ports rst_n]

## Use Block RAM for register file
set_property RAM_STYLE BLOCK [get_cells -hier -filter {{NAME =~ *vrf*}}]

## Use DSP for multipliers
set_property USE_DSP48 YES [get_cells -hier -filter {{NAME =~ *mul*}}]
'''
        with open(path, 'w') as f:
            f.write(content)
        print(f"  Generated: {path}")

    def gen_makefile_inc(self, path):
        """Generate Makefile configuration fragment"""
        arch = self.cfg['architecture']

        content = f'''#==============================================================================
# Hyperplane VPU - Makefile Configuration
# Generated: {self.timestamp}
#==============================================================================

# Project
PROJECT      := hyperplane_vpu
VERSION      := {self.cfg['meta']['version']}

# Architecture
VLEN         := {arch['vlen']}
NLANES       := {arch['nlanes']}
ELEN         := {arch['elen']}

# Verilog defines
V_DEFINES    := +define+VLEN=$(VLEN) +define+NLANES=$(NLANES) +define+ELEN=$(ELEN)

# Include paths
V_INCLUDES   := +incdir+$(PWD)/generated

# Tools
IVERILOG     := iverilog
VVP          := vvp
VERILATOR    := verilator

# SystemC
SYSTEMC_HOME ?= /opt/systemc
SC_CXX       := g++
SC_CXXFLAGS  := -std=c++17 -O2 -Wall -I$(SYSTEMC_HOME)/include -I$(PWD)/generated
SC_LDFLAGS   := -L$(SYSTEMC_HOME)/lib-linux64 -lsystemc -lpthread

# Files
RTL_SRCS     := $(wildcard rtl/*.sv rtl/*.v)
TB_SRCS      := $(wildcard tb/*.sv tb/*.v)
SC_SRCS      := $(wildcard systemc/*.cpp)
STIM_FILE    := stimulus/test_vectors.bin
'''
        with open(path, 'w') as f:
            f.write(content)
        print(f"  Generated: {path}")


def main():
    config_path = sys.argv[1] if len(sys.argv) > 1 else "config/vpu_config.json"
    out_dir = sys.argv[2] if len(sys.argv) > 2 else "generated"

    print(f"Hyperplane VPU Configuration Generator")
    print(f"  Config: {config_path}")
    print(f"  Output: {out_dir}")
    print()

    gen = HPConfigGenerator(config_path)
    gen.generate_all(out_dir)


if __name__ == "__main__":
    main()
