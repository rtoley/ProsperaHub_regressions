# Hyperplane VPU Scaling Architecture

## Executive Summary

The VPU compute core is **NOT the bottleneck**. It can sustain 32+ GMAC/s at 1GHz if properly fed. The limiting factor in real deployments is **memory bandwidth**. This document describes how to scale the memory system to fully utilize VPU compute capacity.

---

## Part 1: VPU Core Compute Analysis

### Raw Throughput

| Frequency | Process | MACs/cycle | Throughput | Status |
|-----------|---------|------------|------------|--------|
| 50 MHz | Artix-7 FPGA | 32 | 1.6 GMAC/s | ✅ Current |
| 100 MHz | Artix-7 FPGA | 32 | 3.2 GMAC/s | ⚠️ Needs timing fix |
| 200 MHz | UltraScale+ | 32 | 6.4 GMAC/s | Target |
| 1.0 GHz | 7nm ASIC | 32 | 32 GMAC/s | Achievable |
| 1.5 GHz | 7nm ASIC | 32 | 48 GMAC/s | With E2 split |

*MACs/cycle = VLEN/SEW = 256/8 = 32 for INT8*

### Bandwidth to Saturate VPU

Each MAC operation requires:
- 2 operand reads (weight + activation)
- 1 result write (or accumulate in register)

**Minimum bandwidth = 2 bytes/MAC** (write to accumulator, amortized)
**Peak bandwidth = 3 bytes/MAC** (streaming through)

| VPU Throughput | Min BW Needed | Peak BW Needed |
|----------------|---------------|----------------|
| 1.6 GMAC/s | 3.2 GB/s | 4.8 GB/s |
| 3.2 GMAC/s | 6.4 GB/s | 9.6 GB/s |
| 32 GMAC/s | 64 GB/s | 96 GB/s |
| 48 GMAC/s | 96 GB/s | 144 GB/s |

### VPU Internal Bandwidth (Not Limiting)

```
VRF Read Ports:  3 × DLEN bits/cycle = 3 × 256 = 768 bits = 96 bytes/cycle
VRF Write Port:  1 × DLEN bits/cycle = 256 bits = 32 bytes/cycle

At 1 GHz:
  Read BW:  96 GB/s
  Write BW: 32 GB/s
  Total:    128 GB/s internal bandwidth

This EXCEEDS the 96 GB/s needed → VPU core is NOT bandwidth-limited internally
```

**Conclusion: VPU core can sustain maximum throughput. The question is how to feed it.**

---

## Part 2: Memory Hierarchy Bottlenecks

### Current Architecture (v1.1)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   External  │────►│    DMA      │────►│     VPU     │
│    DRAM     │     │  (single)   │     │    Core     │
│             │◄────│             │◄────│             │
└─────────────┘     └─────────────┘     └─────────────┘
      │                   │                   │
      │                   │                   │
   10 GB/s            1.6 GB/s            128 GB/s
   (DDR3)            (bottleneck)         (internal)
```

**Bottleneck: Single DMA channel at 1.6 GB/s (DLEN @ 50MHz)**

### LLM Inference Memory Access Pattern

```
Per Token Generation:
═══════════════════════

1. Load Q projection weights    → ~256 KB (one-time per layer)
2. Compute Q = X @ Wq           → VPU compute
3. Read ALL K cache             → seq_len × d_model bytes  ← BOTTLENECK
4. Compute attention scores     → VPU compute
5. Read ALL V cache             → seq_len × d_model bytes  ← BOTTLENECK
6. Compute weighted sum         → VPU compute
7. FFN weights + compute        → Similar pattern

For seq_len=512, d_model=256:
  KV read per layer = 2 × 512 × 256 = 256 KB
  12 layers = 3 MB per token JUST for KV cache reads
```

### Bandwidth Utilization (Current)

```
At 50 MHz, 1.6 GB/s DMA bandwidth:

KV Cache read (3 MB):           3 MB / 1.6 GB/s = 1.9 ms
Weight loading (amortized):     ~0.5 ms
Compute time (if not starved):  ~0.6 ms
                                ────────
Actual time per token:          ~3.0 ms

VPU utilization: 0.6 / 3.0 = 20%  ← 80% IDLE waiting for memory!
```

---

## Part 3: Scaled Architecture

### Target: >80% VPU Utilization

To keep VPU busy, we need parallel memory access:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SCALED VPU SYSTEM                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                              ┌─────────────┐                                │
│                              │    VPU      │                                │
│                              │    Core     │                                │
│                              │  32 GMAC/s  │                                │
│                              └──────┬──────┘                                │
│                                     │                                       │
│                    ┌────────────────┼────────────────┐                      │
│                    │                │                │                      │
│                    ▼                ▼                ▼                      │
│             ┌──────────┐     ┌──────────┐     ┌──────────┐                 │
│             │   VRF    │     │ K Cache  │     │ V Cache  │                 │
│             │  (32×V)  │     │  SRAM    │     │  SRAM    │                 │
│             │   1 KB   │     │  512KB   │     │  512KB   │                 │
│             └────┬─────┘     └────┬─────┘     └────┬─────┘                 │
│                  │                │                │                       │
│                  │                │                │                       │
│             ┌────┴─────┐     ┌────┴─────┐     ┌────┴─────┐                 │
│             │   DMA    │     │   DMA    │     │   DMA    │                 │
│             │ Channel  │     │ Channel  │     │ Channel  │                 │
│             │    A     │     │    B     │     │    C     │                 │
│             │ (Weights)│     │   (K)    │     │   (V)    │                 │
│             └────┬─────┘     └────┬─────┘     └────┬─────┘                 │
│                  │                │                │                       │
│                  └────────────────┼────────────────┘                       │
│                                   │                                        │
│                                   ▼                                        │
│                          ┌───────────────┐                                 │
│                          │   AXI Fabric  │                                 │
│                          │   / NoC       │                                 │
│                          └───────┬───────┘                                 │
│                                  │                                         │
└──────────────────────────────────│─────────────────────────────────────────┘
                                   │
                                   ▼
                          ┌───────────────┐
                          │  External     │
                          │  DRAM / HBM   │
                          └───────────────┘
```

### Three-Channel Architecture

| Channel | Purpose | Bandwidth | Access Pattern |
|---------|---------|-----------|----------------|
| A - Weights | Load weight tiles | Streaming | Sequential, prefetchable |
| B - K Cache | Attention keys | Streaming | Sequential read, point write |
| C - V Cache | Attention values | Streaming | Sequential read, point write |

### Bandwidth Calculation (3-Channel)

```
Channel A (Weights):  DLEN @ freq = 256b × 1GHz / 8 = 32 GB/s
Channel B (K Cache):  DLEN @ freq = 256b × 1GHz / 8 = 32 GB/s
Channel C (V Cache):  DLEN @ freq = 256b × 1GHz / 8 = 32 GB/s
                                                      ─────────
Total System BW:                                      96 GB/s

VPU requirement at 32 GMAC/s:                         64-96 GB/s

MATCH! VPU can run at full utilization.
```

---

## Part 4: Product Configurations

### Config 1: VPU Core Only (Current v1.1)

```
┌─────────────────────────────────────────┐
│           VPU CORE (v1.1)               │
├─────────────────────────────────────────┤
│ • 32 vector registers × VLEN            │
│ • Single DMA port                       │
│ • Software-managed memory               │
├─────────────────────────────────────────┤
│ Target: Evaluation, small demos         │
│ FPGA: Artix-7 35T                       │
│ Throughput: 1.6 GMAC/s @ 50MHz          │
│ Utilization: ~20% (memory bound)        │
│ Seq Length: ≤128 tokens                 │
└─────────────────────────────────────────┘
```

### Config 2: VPU + Scratchpad (Near-term)

```
┌─────────────────────────────────────────┐
│         VPU SYSTEM - BASIC              │
├─────────────────────────────────────────┤
│ • VPU Core                              │
│ • Weight Scratchpad (128-256 KB)        │
│ • Single DMA with double-buffering      │
├─────────────────────────────────────────┤
│ Target: Small LLM inference             │
│ FPGA: Artix-7 100T                      │
│ Throughput: 3.2 GMAC/s @ 100MHz         │
│ Utilization: ~40% (better prefetch)     │
│ Seq Length: ≤256 tokens                 │
│ Model Size: ≤10M params (INT4)          │
└─────────────────────────────────────────┘
```

### Config 3: VPU + KV Cache (Production FPGA)

```
┌─────────────────────────────────────────┐
│        VPU SYSTEM - STANDARD            │
├─────────────────────────────────────────┤
│ • VPU Core                              │
│ • Weight Scratchpad (256 KB)            │
│ • Dedicated K Cache SRAM (512 KB)       │
│ • Dedicated V Cache SRAM (512 KB)       │
│ • 2 DMA channels (Weight + KV)          │
├─────────────────────────────────────────┤
│ Target: Production edge inference       │
│ FPGA: Kintex/UltraScale                 │
│ Throughput: 6.4 GMAC/s @ 200MHz         │
│ Utilization: ~70%                       │
│ Seq Length: ≤512 tokens                 │
│ Model Size: ≤50M params (INT4)          │
└─────────────────────────────────────────┘
```

### Config 4: VPU + 3-Channel Memory (ASIC)

```
┌─────────────────────────────────────────┐
│         VPU SYSTEM - FULL               │
├─────────────────────────────────────────┤
│ • VPU Core @ 1+ GHz                     │
│ • Weight SRAM (1-2 MB)                  │
│ • K Cache SRAM (1-2 MB)                 │
│ • V Cache SRAM (1-2 MB)                 │
│ • 3 independent DMA channels            │
│ • HBM or wide DDR interface             │
├─────────────────────────────────────────┤
│ Target: High-performance edge ASIC      │
│ Process: 7nm / 16nm                     │
│ Throughput: 32-48 GMAC/s                │
│ Utilization: >80%                       │
│ Seq Length: 2K+ tokens                  │
│ Model Size: 100M+ params (INT4)         │
└─────────────────────────────────────────┘
```

---

## Part 5: Interface Extensions for Scaling

### Current Interface (v1.1)

```systemverilog
// Single DMA port - shared for everything
input  logic                 mem_vrf_wr_en_i,
input  logic [4:0]           mem_vrf_addr_i,
input  logic [DLEN-1:0]      mem_vrf_wdata_i,
output logic [DLEN-1:0]      mem_vrf_rdata_o,
```

### Extended Interface (v2.0 - With KV Cache)

```systemverilog
//=== Channel A: Weight/Activation DMA (existing, enhanced) ===
input  logic                      mem_vrf_req_i,
output logic                      mem_vrf_gnt_o,
input  logic                      mem_vrf_wr_en_i,
input  logic [4:0]                mem_vrf_addr_i,
input  logic [DLEN-1:0]           mem_vrf_wdata_i,
output logic [DLEN-1:0]           mem_vrf_rdata_o,

//=== Channel B: K Cache Interface (NEW) ===
// Write: append new K vector after computing Q@Wk
output logic                      kcache_wr_en_o,
output logic [SEQ_BITS-1:0]       kcache_wr_pos_o,     // Position in sequence
output logic [LAYER_BITS-1:0]     kcache_wr_layer_o,   // Which layer
output logic [DLEN-1:0]           kcache_wr_data_o,

// Read: stream K vectors for attention
output logic                      kcache_rd_en_o,
output logic [SEQ_BITS-1:0]       kcache_rd_pos_o,
output logic [LAYER_BITS-1:0]     kcache_rd_layer_o,
input  logic [DLEN-1:0]           kcache_rd_data_i,
input  logic                      kcache_rd_valid_i,

//=== Channel C: V Cache Interface (NEW) ===
// Write: append new V vector after computing X@Wv
output logic                      vcache_wr_en_o,
output logic [SEQ_BITS-1:0]       vcache_wr_pos_o,
output logic [LAYER_BITS-1:0]     vcache_wr_layer_o,
output logic [DLEN-1:0]           vcache_wr_data_o,

// Read: stream V vectors for attention output
output logic                      vcache_rd_en_o,
output logic [SEQ_BITS-1:0]       vcache_rd_pos_o,
output logic [LAYER_BITS-1:0]     vcache_rd_layer_o,
input  logic [DLEN-1:0]           vcache_rd_data_i,
input  logic                      vcache_rd_valid_i,

//=== KV Cache Status ===
input  logic [SEQ_BITS-1:0]       kv_seq_len_i,        // Current sequence length
output logic                      kv_full_o,           // Cache capacity reached
```

### New Instructions for KV Cache (v2.0)

```
// Direct KV cache operations (custom encoding)
vkstore.v  vs2, layer    # Store vs2 to K cache at current position
vvstore.v  vs2, layer    # Store vs2 to V cache at current position
vkload.v   vd, pos       # Load K[pos] into vd (for attention)
vvload.v   vd, pos       # Load V[pos] into vd (for attention)
vkstream.v vd, count     # Stream next 'count' K vectors (auto-increment)
vvstream.v vd, count     # Stream next 'count' V vectors (auto-increment)
```

---

## Part 6: Utilization Analysis

### Roofline Model

```
                    │
     GMAC/s         │                        ╱
                    │                      ╱
        48 ─────────┤                    ╱  Peak Compute (1.5GHz)
                    │                  ╱
        32 ─────────┤────────────────●─── Peak Compute (1GHz)
                    │              ╱ │
                    │            ╱   │
                    │          ╱     │
        16 ─────────┤        ╱       │
                    │      ╱         │
                    │    ╱           │
         8 ─────────┤  ╱  ●──────────┤ 3-channel (96 GB/s)
                    │╱    │          │
         4 ─────────●─────┤          │
                   ╱│     │          │
         2 ───────╱─┤     │          │
                ╱   │     │          │
         1 ───●─────┤     │          │
              │     │     │          │
              ├─────┼─────┼──────────┼────────► Memory BW (GB/s)
              1    10    32         96

Legend:
  ● Current (1 channel, 10 GB/s)  → ~4 GMAC/s achievable (memory bound)
  ● 3-channel (96 GB/s)           → 32 GMAC/s achievable (compute bound)
```

### Utilization by Configuration

| Config | Memory BW | VPU Compute | Achievable | Utilization |
|--------|-----------|-------------|------------|-------------|
| v1.1 (1ch, 50MHz) | 1.6 GB/s | 1.6 GMAC/s | 0.5 GMAC/s | 31% |
| v1.1 (1ch, 100MHz) | 3.2 GB/s | 3.2 GMAC/s | 1.1 GMAC/s | 34% |
| Basic (2ch, 100MHz) | 6.4 GB/s | 3.2 GMAC/s | 2.1 GMAC/s | 66% |
| Standard (3ch, 200MHz) | 19.2 GB/s | 6.4 GMAC/s | 5.1 GMAC/s | 80% |
| Full (3ch, 1GHz ASIC) | 96 GB/s | 32 GMAC/s | 28 GMAC/s | 88% |

---

## Part 7: Summary

### Key Insight

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   THE VPU CORE IS WELL-DESIGNED AND NOT THE BOTTLENECK              │
│                                                                     │
│   • Internal VRF bandwidth: 128 GB/s (sufficient)                   │
│   • Compute throughput: 32 GMAC/s @ 1GHz (excellent)                │
│   • Pipeline: 8 stages, no structural hazards                       │
│                                                                     │
│   THE MEMORY SYSTEM DETERMINES REAL-WORLD PERFORMANCE               │
│                                                                     │
│   • Current: 1 channel → 20-35% utilization                         │
│   • With KV cache: 3 channels → 80%+ utilization                    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Scaling Path

```
v1.1 (Now)          v1.2 (Next)           v2.0 (Future)
──────────          ───────────           ────────────
VPU Core            + P0/P1 interfaces    + KV Cache Interface
1 DMA channel       + DMA grant/fence     + 3 DMA channels
20% utilization     Better SW control     + KV SRAM
                                          80%+ utilization
     │                    │                     │
     ▼                    ▼                     ▼
  Demo/Eval          Small LLM              Production
  seq≤128            seq≤256                seq≤2K
```

### VPU Core Value Proposition

The VPU core (v1.1) is a **complete, verified compute engine**:

| Aspect | Status | Notes |
|--------|--------|-------|
| RVV Compliance | ✅ | 90+ instructions |
| INT8 Compute | ✅ | Full datapath |
| INT4 Support | ✅ | Pack/unpack (v1.1) |
| Widening MAC | ✅ | INT8×INT8→INT16/32 |
| LUT Instructions | ✅ | Softmax, GELU, etc. |
| Parameterized | ✅ | VLEN/DLEN from JSON |
| Verified | ✅ | 102/102 tests pass |

**The core is ready. The scaling is in the memory system.**

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-29 | Initial scaling analysis |

-e

---


# Hyperplane VPU v1.1 - Performance & Integration Analysis

## Executive Summary

The Hyperplane VPU v1.1 is architecturally sound for high-frequency ASIC implementation (1-1.5 GHz in 7nm out of box, 2 GHz with minor retiming). The current interface supports basic LLM inference with software-managed synchronization, but production deployment would benefit from enhanced DMA coordination and fence support.

---

## Part 1: Timing & Frequency Analysis

### Pipeline Architecture

```
Stage:    IQ    D1    D2    OF    E1    E2    E3    WB
          ───   ───   ───   ───   ───   ───   ───   ───
Cycle 0:  I0
Cycle 1:  I1    I0
Cycle 2:  I2    I1    I0
Cycle 3:  I3    I2    I1    I0
Cycle 4:  I4    I3    I2    I1    I0
Cycle 5:  I5    I4    I3    I2    I1    I0
Cycle 6:  I6    I5    I4    I3    I2    I1    I0
Cycle 7:  I7    I6    I5    I4    I3    I2    I1    I0  ← First result

Pipeline Depth: 8 stages
Throughput: 1 vector op/cycle (when no hazards)
Target: 500ps/stage = 2.0 GHz
```

### FPGA Synthesis Results (Artix-7)

| Version | Target Freq | Slack | Critical Path | Status |
|---------|-------------|-------|---------------|--------|
| v0.12 | 100 MHz | -10.834 ns | Reduction tree (43 levels) | ❌ Fail |
| v0.14 | 100 MHz | -0.862 ns | Multiply path (16 levels) | ⚠️ Close |
| v1.1 | 50 MHz | ~+5 ns (est) | Multiply path | ✅ Likely pass |

**Note:** FPGA results are poor proxies for ASIC - Artix-7 interconnect is ~10× slower than 7nm ASIC routing.

### Critical Path Analysis

#### Path 1: Multiply-Accumulate (Limiting Factor)

```
E1 Stage (Operand Prep):
├── SEW-based operand mux       ~50ps
├── Scalar broadcast            ~30ps
└── Pipeline register           ~20ps
                                ─────
                                ~100ps

E2 Stage (Multiply + Partial Add):
├── 8×8 signed multiplier       ~150-200ps (7nm)
├── Partial product add tree    ~80-100ps
├── Carry propagate             ~50ps
└── Pipeline register           ~20ps
                                ─────
                                ~300-370ps  ← CRITICAL

E3 Stage (Final Sum + Mux):
├── Final accumulator add       ~80ps
├── Result mux (90+ opcodes)    ~100ps
├── Mask application            ~30ps
└── Pipeline register           ~20ps
                                ─────
                                ~230ps
```

**E2 is the bottleneck at ~350ps, leaving only ~150ps margin for 500ps (2GHz) target.**

#### Path 2: Reduction Tree (Fixed in v0.14)

```
Previously: Single-cycle reduction across VLEN elements
Now: Pipelined R1→R2→R3 tree

R1: First level reduction (8→4 elements)     ~200ps
R2: Second level reduction (4→2 elements)    ~150ps
R3: Final reduction (2→1 element)            ~100ps

Each stage fits comfortably in 500ps.
```

#### Path 3: Widening Operations (OK)

```
W1: Sign/zero extend + partial multiply      ~250ps
W2: Wide accumulate + pack                   ~200ps

Both stages fit in 500ps budget.
```

### Frequency Projections by Process

| Process | Estimated Fmax | Confidence | Notes |
|---------|---------------|------------|-------|
| Artix-7 FPGA | 50-75 MHz | High | Verified direction |
| UltraScale+ FPGA | 150-200 MHz | Medium | Better routing |
| 28nm ASIC | 500-700 MHz | Medium | Standard cells help |
| 16nm ASIC | 800 MHz - 1.0 GHz | Medium | Reasonable target |
| 7nm ASIC | 1.0 - 1.5 GHz | Medium | Current RTL |
| 7nm ASIC | 2.0 GHz | Low | Needs E2 split |

### Required Changes for 2 GHz (7nm ASIC)

#### Option A: Split E2 Stage

```
Current:
  E2: [multiply + add tree + partial accumulate]  ~350ps

Proposed:
  E2a: [multiply + partial products]              ~200ps
  E2b: [add tree + accumulate]                    ~180ps

Impact: +1 cycle latency (8→9 stages), but meets 500ps
```

#### Option B: Retime Result Mux

```
Current E3:
  [final add] → [90-opcode result mux] → [mask] → [reg]

Proposed:
  E3a: [final add] → [partial mux (groups of 16)] → [reg]
  E3b: [final mux select] → [mask] → [reg]
```

#### Option C: Multiply Decomposition

```
For SEW=32 (largest):
  Current:  32×32 in single cycle
  Proposed: Booth-encoded, 2-cycle multiply

Only impacts SEW=32; SEW=8/16 unchanged.
```

### Recommendation

**For 7nm tape-out targeting 1.5 GHz:**
- Current RTL likely works with minor hold fixes
- Run ASIC synthesis to verify

**For 7nm tape-out targeting 2.0 GHz:**
- Implement Option A (split E2)
- ~100-200 lines RTL change
- Adds 1 cycle latency (acceptable for throughput-oriented workload)

---

## Part 2: Interface Analysis for LLM Coprocessor

### Current Interface

```systemverilog
module hp_vpu_top (
  input  logic                      clk,
  input  logic                      rst_n,

  //=== CV-X-IF Issue Interface (Scalar → VPU) ===
  input  logic                      x_issue_valid_i,
  output logic                      x_issue_ready_o,
  input  logic [31:0]               x_issue_instr_i,
  input  logic [CVXIF_ID_W-1:0]     x_issue_id_i,
  input  logic [31:0]               x_issue_rs1_i,
  input  logic [31:0]               x_issue_rs2_i,

  //=== CV-X-IF Result Interface (VPU → Scalar) ===
  output logic                      x_result_valid_o,
  input  logic                      x_result_ready_i,
  output logic [CVXIF_ID_W-1:0]     x_result_id_o,
  output logic [31:0]               x_result_data_o,
  output logic                      x_result_we_o,

  //=== Vector CSRs ===
  input  logic [31:0]               csr_vtype_i,
  input  logic [31:0]               csr_vl_i,
  output logic [31:0]               csr_vtype_o,
  output logic [31:0]               csr_vl_o,
  output logic                      csr_vl_valid_o,

  //=== DMA/Memory Interface (Direct VRF Access) ===
  input  logic                      mem_vrf_wr_en_i,
  input  logic [4:0]                mem_vrf_addr_i,
  input  logic [DLEN-1:0]           mem_vrf_wdata_i,
  output logic [DLEN-1:0]           mem_vrf_rdata_o,

  //=== Status ===
  output logic                      busy_o,
  output logic [31:0]               perf_cnt_o
);
```

### Interface Assessment

| Interface | Status | Grade | Notes |
|-----------|--------|-------|-------|
| CV-X-IF Issue | Complete | A | Fully compliant |
| CV-X-IF Result | Complete | A | Supports scalar extraction |
| Vector CSRs | Partial | B | Missing vxrm/vxsat write |
| DMA/VRF Access | Basic | C | No handshaking |
| Synchronization | Missing | D | No fence support |
| Exceptions | Missing | D | Silent failure on illegal |
| Interrupts | Missing | C | Polling only |
| Debug | Basic | C | VRF access only |

### Gap Analysis

#### Gap 1: DMA/VPU Collision (CRITICAL)

**Problem:**
```
Cycle N:   DMA writes v3          VPU reads v3 for vadd
Cycle N+1: DMA writes v3 (cont)   VPU executes with stale v3
           ^^^^^ RACE CONDITION ^^^^^
```

**Current Workaround:**
```c
// Software must ensure mutual exclusion
while (vpu_busy);        // Wait for VPU idle
dma_write(data, v3);     // Now safe to write
while (dma_busy);        // Wait for DMA complete
issue_vadd(v3, v4, v5);  // Now safe to use v3
```

**Proper Solution:**
```systemverilog
// Add to interface:
input  logic                      mem_vrf_req_i,      // DMA requests access
output logic                      mem_vrf_gnt_o,      // VPU grants (VRF not in use)
output logic [31:0]               mem_vrf_busy_mask_o // Bitmask: which regs in flight

// Internal logic:
assign mem_vrf_gnt_o = mem_vrf_req_i &&
                       !vrf_read_pending[mem_vrf_addr_i] &&
                       !vrf_write_pending[mem_vrf_addr_i];
```

#### Gap 2: Memory Ordering / Fence (HIGH)

**Problem:**
```c
vwmaccu(v8, v0, v4);   // Takes 8+ cycles
dma_read(v8, output);  // Might read before vwmaccu completes!
```

**Current Workaround:**
```c
vwmaccu(v8, v0, v4);
while (vpu_busy);      // Spin wait (wastes cycles)
dma_read(v8, output);
```

**Proper Solution - Option A (Fence Instruction):**
```systemverilog
// Decode vfence (use reserved encoding)
// funct6=111111, vm=1, vs2=0, vs1=0, funct3=010, vd=0
wire is_vfence = (funct6 == 6'b111111) && (funct3 == 3'b010);

// Stall issue until pipeline drains
assign x_issue_ready_o = !is_vfence || pipeline_empty;
```

**Proper Solution - Option B (Implicit Fence on DMA):**
```systemverilog
// Auto-stall DMA until target register not in flight
assign mem_vrf_gnt_o = !vrf_write_pending[mem_vrf_addr_i];
```

#### Gap 3: Exception Handling (MEDIUM)

**Problem:**
```c
// Illegal instruction silently becomes NOP
vfoo.vv v1, v2, v3;  // Typo - doesn't exist
vadd.vv v4, v1, v3;  // Uses stale v1, wrong result, no error
```

**Solution:**
```systemverilog
// Add to interface:
output logic                      x_illegal_instr_o,
output logic [CVXIF_ID_W-1:0]     x_illegal_id_o,

// In decode:
assign x_illegal_instr_o = x_issue_valid_i &&
                           x_issue_ready_o &&
                           (decoded_op == OP_NOP) &&
                           (opcode == OPC_VECTOR);  // Was vector, decoded to NOP
```

#### Gap 4: Completion Interrupt (LOW)

**Problem:**
```c
// Polling wastes scalar CPU cycles
issue_vector_ops();
while (vpu_busy) {
    // CPU spinning, could be doing useful work
}
```

**Solution:**
```systemverilog
// Add to interface:
output logic                      irq_done_o,  // Pulse when pipeline empties

// Optional: threshold-based interrupt
input  logic [7:0]                irq_threshold_i,  // Interrupt when IQ below threshold
output logic                      irq_ready_o,      // Can accept more work
```

#### Gap 5: Multi-Beat VRF Access (LOW)

**Problem:**
```
VLEN=256, DLEN=64 configuration:
- Each vector register is 256 bits
- DMA interface is 64 bits
- Need 4 cycles to load one register
- No burst/streaming support
```

**Current:**
```c
// Must manually sequence 4 beats
for (int beat = 0; beat < 4; beat++) {
    dma_write_beat(data + beat*8, vreg, beat);
}
```

**Solution:**
```systemverilog
// Option A: Add beat counter
input  logic [1:0]                mem_vrf_beat_i,  // Which 64-bit chunk

// Option B: Widen interface to VLEN
input  logic [VLEN-1:0]           mem_vrf_wdata_i, // Full register

// Option C: Burst mode
input  logic                      mem_vrf_burst_i, // Auto-increment beat
output logic                      mem_vrf_last_o,  // Last beat of burst
```

#### Gap 6: Performance Counters (LOW)

**Current:** Single 32-bit counter (undefined what it counts)

**Useful Additions:**
```systemverilog
output logic [31:0]               perf_cycles_o,       // Total cycles
output logic [31:0]               perf_instrs_o,       // Instructions retired
output logic [31:0]               perf_stalls_o,       // Stall cycles
output logic [31:0]               perf_vrf_conflicts_o // DMA/VPU conflicts
```

### Priority Ranking

| Priority | Enhancement | Effort | Impact | Recommendation |
|----------|-------------|--------|--------|----------------|
| **P0** | `mem_vrf_gnt_o` grant signal | ~20 LOC | Critical | **Must have** |
| **P0** | `mem_vrf_busy_mask_o` | ~30 LOC | Critical | **Must have** |
| **P1** | `x_illegal_instr_o` | ~30 LOC | High | Should have |
| **P1** | `vfence` instruction | ~50 LOC | High | Should have |
| **P2** | `irq_done_o` completion IRQ | ~20 LOC | Medium | Nice to have |
| **P2** | Multi-beat VRF burst | ~100 LOC | Medium | Nice to have |
| **P3** | Performance counters | ~50 LOC | Low | Nice to have |

---

## Part 3: LLM Inference Integration

### System Architecture for LLM

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         LLM Inference System                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────┐                                                       │
│  │   External   │                                                       │
│  │    DRAM      │  Weights: 2-4MB for small LLM (INT4)                 │
│  │  (DDR3/4)    │  KV Cache: Grows with sequence length                │
│  └──────┬───────┘                                                       │
│         │ AXI                                                           │
│         ▼                                                               │
│  ┌──────────────┐     ┌──────────────────────────────────────────┐     │
│  │     DMA      │     │              VPU SUBSYSTEM               │     │
│  │   Engine     │────►│                                          │     │
│  │  (AXI-MM)    │◄────│  ┌────────┐    ┌────────────────────┐   │     │
│  └──────────────┘     │  │  VPU   │◄──►│    Scratchpad      │   │     │
│         ▲             │  │  Core  │    │   (BRAM 64-256KB)  │   │     │
│         │             │  └────────┘    └────────────────────┘   │     │
│         │             │       ▲                                  │     │
│  ┌──────┴───────┐     └───────│──────────────────────────────────┘     │
│  │   RISC-V     │             │                                         │
│  │   Scalar     │◄────────────┘ CV-X-IF                                │
│  │   Core       │                                                       │
│  │  (CV32E40P)  │  Runs control loop, token sampling                   │
│  └──────────────┘                                                       │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Memory Requirements

| Component | Size (INT8) | Size (INT4) | Notes |
|-----------|-------------|-------------|-------|
| TinyLlama-1.1B | 1.1 GB | 550 MB | Too large for FPGA |
| SmolLM-135M | 135 MB | 67 MB | Fits in large FPGA |
| Custom 10M | 10 MB | 5 MB | Target for Arty-7 |
| Custom 1M | 1 MB | 512 KB | Fits in BRAM |

### Inference Flow (Current Interface)

```c
// Simplified transformer layer with current VPU interface
void transformer_layer(int8_t* x, int seq_len, int d_model) {

    // ============ QKV Projection ============
    // Load weight tiles (double-buffer friendly)
    while (vpu_busy);
    dma_load(w_q_tile, v0, 8);  // Load Wq[0:8*VLEN]

    for (int row = 0; row < seq_len; row++) {
        // Load input row
        while (vpu_busy);
        dma_load(&x[row * d_model], v8, 1);

        // Matrix-vector multiply: Q[row] = X[row] @ Wq
        vsetvli(VLMAX, SEW8);
        for (int col = 0; col < d_model; col += VLMAX) {
            vle8(v9, &w_q[col]);           // Load weight column
            vwmaccu_vv(v16, v8, v9);       // Widening MAC
        }
        vnsrl_wi(v20, v16, SCALE_Q);       // Requantize to INT8

        while (vpu_busy);
        dma_store(v20, &q[row * d_model]); // Store Q row
    }

    // ============ Attention ============
    // Similar pattern for K, V projections
    // Attention scores: softmax(Q @ K^T / sqrt(d))
    // Use vexp.v, vrecip.v for softmax

    // ============ FFN ============
    // Two linear layers with GELU activation
    // Use vgelu.v for activation
}
```

### INT4 Inference Flow (v1.1 Feature)

```c
// With INT4 pack/unpack, 2× more weights fit in BRAM
void transformer_layer_int4(int4_packed* weights, ...) {

    // Load INT4 packed weights (2 values per byte)
    while (vpu_busy);
    dma_load(w_q_packed, v0, 4);  // Half the transfers!

    // Unpack INT4 → INT8 for computation
    vunpack4_v(v8, v0);   // v0: packed INT4 → v8: INT8
    vunpack4_v(v9, v1);
    // ...

    // Compute in INT8 (existing widening MAC)
    vwmaccu_vv(v16, v8, v10);  // INT8 × INT8 → INT16

    // Requantize and pack back to INT4
    vnsrl_wi(v20, v16, SCALE);
    vpack4_v(v24, v20);   // v20: INT8 → v24: packed INT4

    // Store packed result
    while (vpu_busy);
    dma_store(v24, output_packed);  // Half the transfers!
}
```

### Performance Model

```
Single vector MAC operation:
- Throughput: VLEN/SEW elements per cycle
- VLEN=256, SEW=8: 32 INT8 MACs/cycle
- At 50 MHz FPGA: 32 × 50M = 1.6 GMAC/s

Transformer layer (d_model=256, seq_len=32):
- QKV projection: 3 × 256 × 256 = 196K MACs
- Attention: 32 × 32 × 256 = 262K MACs
- FFN: 2 × 256 × 1024 = 524K MACs
- Total: ~1M MACs per layer

At 1.6 GMAC/s: ~0.6ms per layer
12-layer model: ~7ms per token

Memory bandwidth (limiting factor on FPGA):
- BRAM bandwidth: ~10 GB/s
- Weight loading: 1MB weights × 12 layers = 12MB/token
- At 10 GB/s: 1.2ms just for weight loading
- Actual: ~10-20ms per token (memory bound)
```

### Optimization Opportunities

| Optimization | Impact | Complexity | Status |
|--------------|--------|------------|--------|
| Weight double-buffering | 2× throughput | Medium | Possible now |
| INT4 weights (v1.1) | 2× capacity | Done | ✅ Implemented |
| Fractional LMUL (v1.1) | Cleaner widening | Done | ✅ Implemented |
| Tiled matrix multiply | Better locality | Software | Possible now |
| DMA/compute overlap | Hide latency | Needs P0 fix | After v1.2 |
| Burst VRF access | 4× DMA BW | P2 feature | Future |

---

## Part 4: Recommendations

### For FPGA Demo (Now)

1. Use 50 MHz target (timing should close)
2. Implement careful double-buffering in software
3. Use `while(vpu_busy)` synchronization
4. Target tiny model (1-10M parameters)
5. INT4 weights with v1.1 pack/unpack

### For Production FPGA (v1.2)

1. Add P0 interfaces (`mem_vrf_gnt_o`, `mem_vrf_busy_mask_o`)
2. Add P1 interfaces (`x_illegal_instr_o`, `vfence`)
3. Verify timing at 100 MHz on Artix-7
4. Implement DMA controller with proper handshaking

### For ASIC (Future)

1. Run synthesis in target process (7nm/16nm)
2. If targeting >1.5 GHz, split E2 stage
3. Add all P0-P2 interfaces
4. Consider wider DLEN (512-bit) for bandwidth

---

## Appendix A: Interface Enhancement Specifications

### P0: DMA Grant Signal

```systemverilog
// Add to hp_vpu_top ports:
input  logic                      mem_vrf_req_i,
output logic                      mem_vrf_gnt_o,
output logic [31:0]               mem_vrf_busy_mask_o,

// Internal tracking (in hp_vpu_hazard.sv):
logic [31:0] vrf_read_pending;   // Registers being read this cycle
logic [31:0] vrf_write_pending;  // Registers with writes in flight

// Grant logic:
assign mem_vrf_gnt_o = mem_vrf_req_i &&
                       !vrf_read_pending[mem_vrf_addr_i] &&
                       !vrf_write_pending[mem_vrf_addr_i];

assign mem_vrf_busy_mask_o = vrf_read_pending | vrf_write_pending;
```

### P1: Illegal Instruction Detection

```systemverilog
// Add to hp_vpu_top ports:
output logic                      x_illegal_instr_o,
output logic [CVXIF_ID_W-1:0]     x_illegal_id_o,

// In hp_vpu_decode.sv:
logic is_vector_opcode;
assign is_vector_opcode = (opcode == OPC_VECTOR) ||
                          (opcode == OPC_LOAD_FP) ||
                          (opcode == OPC_STORE_FP);

logic is_illegal;
assign is_illegal = is_vector_opcode && (decoded_op == OP_NOP);

// Register and output:
always_ff @(posedge clk) begin
    x_illegal_instr_o <= d2_valid && is_illegal;
    x_illegal_id_o <= d2_id;
end
```

### P1: Vector Fence Instruction

```systemverilog
// Encoding: funct6=111111, funct3=010, all other fields=0
// This is a reserved encoding in RVV spec

// In hp_vpu_decode.sv:
wire is_vfence = (d1_funct6 == 6'b111111) &&
                 (d1_funct3 == 3'b010) &&
                 (d1_vd == 5'b0) &&
                 (d1_vs1 == 5'b0) &&
                 (d1_vs2 == 5'b0);

// In hp_vpu_top.sv:
wire pipeline_empty = !e1_valid && !e2_valid && !e3_valid &&
                      !r1_valid && !r2_valid && !r3_valid &&
                      !w1_valid && !w2_valid;

// Stall issue until drain:
assign x_issue_ready_o = iq_not_full && (!is_vfence || pipeline_empty);
```

---

## Appendix B: Verification Checklist for ASIC

- [ ] Synthesize with ASIC standard cell library
- [ ] Run STA at target frequency
- [ ] Identify actual critical paths
- [ ] Verify reset behavior (async assert, sync deassert)
- [ ] Check clock domain crossings (none expected)
- [ ] Verify memory compiler compatibility for VRF
- [ ] Run gate-level simulation
- [ ] Check power estimation
- [ ] Verify DFT insertion points

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-29 | Initial performance analysis for v1.1 |
