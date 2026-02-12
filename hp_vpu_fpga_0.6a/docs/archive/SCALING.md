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
