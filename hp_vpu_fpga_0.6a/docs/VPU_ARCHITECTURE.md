# Hyperplane VPU v1.1 - System Architecture

## High-Level Context

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              SYSTEM VIEW                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│    ┌──────────────┐         ┌──────────────────────────────────────────┐   │
│    │   RISC-V     │         │              VPU SUBSYSTEM               │   │
│    │   Scalar     │ CV-X-IF │  ┌────────┐    ┌────────────────────┐   │   │
│    │   Core       │◄───────►│  │  VPU   │◄──►│   Local Scratchpad │   │   │
│    │  (CV32E40P)  │         │  │  Core  │    │   (SRAM 64-128KB)  │   │   │
│    └──────────────┘         │  └────────┘    └────────────────────┘   │   │
│           │                 │       │                 ▲               │   │
│           │                 │       │                 │               │   │
│           │                 │  ┌────▼────┐            │               │   │
│           │                 │  │   DMA   │────────────┘               │   │
│           │                 │  │ Engine  │                            │   │
│           │                 │  └────┬────┘                            │   │
│           │                 └───────│──────────────────────────────────┘   │
│           │                         │                                      │
│           ▼                         ▼                                      │
│    ┌──────────────────────────────────────────────────────────────────┐   │
│    │                    System Memory / AXI Fabric                     │   │
│    └──────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Data Flow for INT4 Inference (v1.1):
1. DMA loads INT4 packed weights from memory → Scratchpad/VRF
2. Scalar core issues vunpack4.v to expand INT4 → INT8
3. Scalar core issues vwmaccu.vv for INT8×INT8 → INT16/32 MAC
4. Scalar core issues vnsrl to requantize results
5. Scalar core issues vpack4.v to compress INT8 → INT4
6. DMA stores INT4 packed results back to memory
```

## VPU Core Internal Blocks

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              VPU CORE                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  FROM SCALAR CORE (CV-X-IF)                                                 │
│  ════════════════════════════                                               │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────┐                                                           │
│  │ Instruction │  Buffers incoming instructions from scalar core           │
│  │   Queue     │  Depth: 8 entries                                         │
│  │   (IQ)      │  Decouples scalar/vector pipelines                        │
│  └──────┬──────┘                                                           │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────┐                                                           │
│  │   Decode    │  2-stage pipeline for 2GHz                                │
│  │   (D1-D2)   │  - D1: Pre-decode (opcode classification)                 │
│  │             │  - D2: Full decode (operand selection, SEW/LMUL)          │
│  └──────┬──────┘                                                           │
│         │                                                                   │
│         ▼                          ┌─────────────────────────────────┐     │
│  ┌─────────────┐                   │     Vector Register File        │     │
│  │  Operand    │◄─────────────────►│           (VRF)                 │     │
│  │   Fetch     │   3 read ports    │  32 registers × VLEN bits       │     │
│  │    (OF)     │   1 write port    │  Banked for bandwidth           │     │
│  └──────┬──────┘                   │  Connected to scratchpad        │     │
│         │                          └─────────────────────────────────┘     │
│         │ Operand data                        ▲                            │
│         ▼                                     │                            │
│  ┌─────────────────────────────────┐          │                            │
│  │      Vector Lanes (×NLANES)     │          │                            │
│  │  ┌───────┐┌───────┐    ┌───────┐│          │                            │
│  │  │Lane 0 ││Lane 1 │ .. │Lane N ││          │                            │
│  │  │ 64b   ││ 64b   │    │ 64b   ││          │                            │
│  │  └───────┘└───────┘    └───────┘│          │                            │
│  │  Three execution paths:         │          │                            │
│  │  E-pipe (arith): E1→E2→E3  (7) │          │                            │
│  │  R-pipe (reduc): R1→R2A→R2B→R3 │          │                            │
│  │                           (8)   │          │                            │
│  │  W-pipe (widen): W1→W2     (6)  │          │                            │
│  └──────────────┬──────────────────┘          │                            │
│                 │                             │                            │
│                 ▼                             │                            │
│  ┌─────────────────────────────────┐          │                            │
│  │         Writeback (WB)          │──────────┘                            │
│  │   Commits results to VRF        │                                       │
│  └─────────────────────────────────┘                                       │
│                                                                             │
│  TO SCALAR CORE (CV-X-IF Result)                                           │
│  ═══════════════════════════════                                           │
│  - Completion signals                                                       │
│  - Scalar results (vmv.x.s, vfirst, vcpop)                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Pipeline Stages (v0.3e: 300 MHz timing closure)

```
E-pipe (arithmetic):  IF → ID → OF → E1  → E2  → E3 → WB   (7 stages)
R-pipe (reductions):  IF → ID → OF → R1  → R2A → R2B → R3 → WB   (8 stages)
W-pipe (widening):    IF → ID → OF → W1  → W2  → WB   (6 stages)

Note: Pipes are unbalanced (E=7, R=8, W=6). Safe because multicycle_busy
      serializes all multicycle ops. See AUDIT_R2AB_HAZARD.md for details.
```

```
E-pipe:   IQ    D1    D2    OF    E1    E2    E3    WB
          ───   ───   ───   ───   ───   ───   ───   ───
Cycle 0:  I0
Cycle 1:  I1    I0
Cycle 2:  I2    I1    I0
Cycle 3:  I3    I2    I1    I0
Cycle 4:  I4    I3    I2    I1    I0
Cycle 5:  I5    I4    I3    I2    I1    I0
Cycle 6:  I6    I5    I4    I3    I2    I1    I0
Cycle 7:  I7    I6    I5    I4    I3    I2    I1    I0    ← First result

R-pipe:   IQ    D1    D2    OF    R1    R2A   R2B   R3    WB
          ───   ───   ───   ───   ───   ───   ───   ───   ───
          R2A/R2B split halves combinational depth for 300 MHz.
          +1 cycle latency vs v0.3d.

Pipeline Depths: E=7, R=8, W=6
Throughput: 1 vector op per cycle (when no hazards)
```

## Block Descriptions

### 1. Instruction Queue (IQ)
```
Purpose:  Decouple scalar and vector pipelines
Inputs:   - x_issue_valid, x_issue_instr, x_issue_id, x_issue_rs1/rs2
Outputs:  - instr, id, rs1, rs2 to decode
Control:  - push when valid & ready, pop when decode consumes
Size:     8 entries (configurable)
```

### 2. Decode Unit (D1-D2)
```
Purpose:  Convert RVV instruction to internal control signals
Stage D1: - Extract opcode, funct3, funct6
          - Classify: arithmetic, load/store, config
Stage D2: - Full decode: operation type, register addresses
          - Apply vtype (SEW, LMUL) to determine element count
          - Generate operand select signals
Outputs:  - op_type (ADD, MUL, MACC, etc.)
          - vd, vs1, vs2, vs3 addresses
          - sew, lmul, vl
          - scalar value (for .vx operations)
```

### 3. Vector Register File (VRF)
```
Purpose:  Store vector operands and results
Size:     32 registers × VLEN bits each
          VLEN=256 → 32 × 256 = 8Kbits = 1KB
Ports:    - 3 read (vs1, vs2, vs3/accumulator)
          - 1 write (vd result)
Banking:  8 banks for parallel access
Width:    Each access reads/writes DLEN = NLANES × 64 bits
```

### 4. Vector Lanes
```
Purpose:  Parallel compute units
Count:    NLANES (4 default)
Width:    64 bits each (handles multiple elements per SEW)
          - SEW=8:  8 elements per lane
          - SEW=16: 4 elements per lane
          - SEW=32: 2 elements per lane

Per-Lane Operations:
  - Integer: add, sub, and, or, xor, shift
  - Multiply: 8×8→16 array (4 multipliers for SEW=16)
  - MAC: multiply-accumulate
  - Compare: generate mask bits

Pipeline (3 stages for 2GHz):
  E1: Operand selection, simple logic ops (AND/OR/XOR)
  E2: Add/subtract, multiply partial products
  E3: Final sum, result mux
```

### 5. Writeback (WB)
```
Purpose:  Commit results to VRF
Inputs:   - result from lanes
          - vd address
Control:  - we signal to VRF
          - Handles write hazards
```

## Scratchpad Integration

```
┌────────────────────────────────────────────────────────────────┐
│                    SCRATCHPAD BUFFER                            │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│   Size: 64-128 KB (configurable)                               │
│   Width: 512 bits (matches 2× DLEN for double-buffering)       │
│   Banks: 8 (for conflict-free access)                          │
│                                                                │
│   ┌──────────┬──────────┬──────────┬──────────┐               │
│   │  Bank 0  │  Bank 1  │   ...    │  Bank 7  │               │
│   │  64×512b │  64×512b │          │  64×512b │               │
│   └────┬─────┴────┬─────┴────┬─────┴────┬─────┘               │
│        │          │          │          │                      │
│        └──────────┴────┬─────┴──────────┘                      │
│                        │                                       │
│                        ▼                                       │
│              ┌─────────────────┐                               │
│              │   Arbitrator    │                               │
│              └────────┬────────┘                               │
│                       │                                        │
│         ┌─────────────┼─────────────┐                          │
│         ▼             ▼             ▼                          │
│    ┌─────────┐  ┌───────────┐  ┌─────────┐                    │
│    │ System  │  │    VRF    │  │  DMA    │                    │
│    │  Port   │  │   Port    │  │  Port   │                    │
│    └─────────┘  └───────────┘  └─────────┘                    │
│         ▲             ▲             ▲                          │
│         │             │             │                          │
│    To/From       To/From       Background                      │
│    Scalar        VPU          data movement                    │
│    Core          Lanes                                         │
│                                                                │
└────────────────────────────────────────────────────────────────┘

Note: For Phase 1, VRF is standalone SRAM inside VPU.
      Scratchpad integration comes in Phase 2.
```

## Implementation Status (v1.1)

```
HYPERPLANE VPU v1.1 - PRODUCTION READY
══════════════════════════════════════

  ┌─────────┐    ┌────────┐    ┌─────┐    ┌───────┐    ┌────┐
  │   IQ    │───►│ Decode │───►│ VRF │───►│ Lanes │───►│ WB │
  └─────────┘    └────────┘    └──┬──┘    └───────┘    └──┬─┘
       ▲                          │                       │
       │                          └───────────────────────┘
  CV-X-IF                              writeback path
  from scalar

RTL Modules:
  1. hp_vpu_pkg.sv    - Parameters, types, encodings     [✓ DONE]
  2. hp_vpu_iq.sv     - Instruction queue (8 deep)       [✓ DONE]
  3. hp_vpu_decode.sv - 2-stage decoder                  [✓ DONE]
  4. hp_vpu_vrf.sv    - Vector register file (32×VLEN)   [✓ DONE]
  5. hp_vpu_lanes.sv  - Parallel compute lanes           [✓ DONE]
  6. hp_vpu_hazard.sv - Stall/forward logic              [✓ DONE]
  7. hp_vpu_top.sv    - Top integration                  [✓ DONE]
  8. hp_vpu_lut_rom.sv - LUT tables for LLM ops          [✓ DONE]
  9. hp_vpu_tb.sv     - Parameterized testbench          [✓ DONE]

Supported Operations (v1.1):
  Arithmetic:     vadd, vsub, vrsub, vmul, vmacc, vnmsac
  Logic:          vand, vor, vxor
  Shifts:         vsll, vsrl, vsra
  Min/Max:        vmin[u], vmax[u]
  Compare:        vmseq, vmsne, vmslt[u], vmsle[u], vmsgt[u]
  Fixed-Point:    vsadd[u], vssub[u], vssrl, vssra, vnclip[u]
  Reductions:     vredsum, vredmax[u], vredmin[u], vredand/or/xor
  Mask Logic:     vmand, vmnand, vmandn, vmor, vmnor, vmorn, vmxor, vmxnor
  Mask Ops:       vcpop.m, vfirst.m, vmsbf.m, vmsif.m, vmsof.m
  Permutation:    vmv.v.v/x/i, vmerge, vrgather, vslideup/down, vslide1up/down
  Widening:       vwadd[u], vwsub[u], vwmul[u/su], vwmacc[u/su]
  Narrowing:      vnsrl, vnsra
  LUT (Custom):   vexp, vrecip, vrsqrt, vgelu
  INT4 (Custom):  vpack4, vunpack4 (v1.1)

Configuration:
  - VLEN: 64-256 (from JSON)
  - DLEN: 64-256 (from JSON)
  - SEW: 8, 16, 32
  - LMUL: 1, 1/2, 1/4, 1/8 (v1.1)
```

## Data Widths at Each Stage

```
                    DLEN = NLANES × 64 = 256 bits (4 lanes)

CV-X-IF ──────────────────────────────────────────────────────►
         32b instr + 32b rs1 + 32b rs2 + 4b id

IQ ───────────────────────────────────────────────────────────►
         Same as CV-X-IF, buffered

Decode ───────────────────────────────────────────────────────►
         op[5] + vd[5] + vs1[5] + vs2[5] + sew[3] + scalar[32]

VRF Read ─────────────────────────────────────────────────────►
         vs1_data[256] + vs2_data[256] + vs3_data[256]

Lanes ────────────────────────────────────────────────────────►
         Per lane: a[64] + b[64] + c[64] → result[64]
         Total: 4 lanes × 64b = 256b

WB ───────────────────────────────────────────────────────────►
         result[256] + vd[5] + we

Back to VRF ──────────────────────────────────────────────────►
         256b write per cycle
```

## Roadmap

### v1.2 (Next)
- P0/P1 interface fixes (DMA grant, vfence, illegal trap)
- LMUL>1 via micro-op decomposition (see below)

### v1.3
- INT2 pack/unpack (4× memory density)
- viota.m (iota/prefix sum)
- vcompress instruction

### Phase 2 (Future)
- Scratchpad integration (separate VRF from compute)
- KV Cache interface (3-channel memory)
- Whole register move (vmv<nr>r.v)
- DMA controller integration

---

## Proposed: RVV Compliance Testing Integration

### Available Test Suites

| Test Suite | Source | License | Coverage |
|------------|--------|---------|----------|
| **chipsalliance/riscv-vector-tests** | GitHub | Apache-2.0 | Full RVV 1.0, Spike-golden |
| **hushenwei2000/rvv-atg** | GitHub | Open | Auto-generated, RISCOF compatible |
| **riscv-software-src/riscv-tests** | Official | BSD | Basic vector subset |
| **Imperas riscv-tests** | OVPworld | Free (registration) | Industry standard, comprehensive |

### Challenge: Coprocessor Architecture

Standard compliance tests expect a complete RISC-V system:

```
Standard Flow:
  test.S → GCC → test.elf → [RISC-V CPU + VPU + Memory] → Signature

Hyperplane VPU:
  No scalar CPU, no memory system
  Instructions injected via CV-X-IF
  Results checked directly in VRF
```

### Integration Options

#### Option A: Convert Test Vectors (Recommended First Step)

Extract expected values from chipsalliance tests and convert to our testbench format:

```
Their format (YAML config + assembly):
┌─────────────────────────────────────┐
│ vadd.vv:                            │
│   - vs1: [0x01, 0x02, 0x03, ...]   │
│   - vs2: [0x10, 0x20, 0x30, ...]   │
│   - expected: [0x11, 0x22, 0x33...]│
└─────────────────────────────────────┘
           │
           ▼ Python converter
┌─────────────────────────────────────┐
│ task test_vadd_compliance_001;      │
│   write_vrf(1, 256'h01020304...);   │
│   write_vrf(2, 256'h10203040...);   │
│   issue(encode_vadd_vv(3, 1, 2));   │
│   check_vrf(3, 256'h11223344...);   │
│ endtask                             │
└─────────────────────────────────────┘
```

**Effort:** ~200 lines Python script
**Coverage:** All instructions in their test suite
**Benefit:** Official test vectors, no system integration needed

#### Option B: Minimal Test Harness (Medium-term)

Build pseudo-CPU in testbench that parses test binaries:

```
┌────────────────────────────────────────────────────────┐
│                 Compliance Harness                      │
├────────────────────────────────────────────────────────┤
│                                                        │
│  test.elf ──► ELF Parser ──► Instruction Stream        │
│                                    │                   │
│                                    ▼                   │
│  ┌────────────┐              ┌──────────┐             │
│  │ Pseudo-CPU │──── CV-X-IF ─►│   VPU    │             │
│  │ (sequence  │              │   Core   │             │
│  │  control)  │◄── Result ───│          │             │
│  └────────────┘              └──────────┘             │
│        │                                               │
│        ▼                                               │
│  Compare signatures with golden                        │
│                                                        │
└────────────────────────────────────────────────────────┘
```

**Effort:** ~500-1000 lines SystemVerilog + Python
**Coverage:** Can run actual test binaries
**Benefit:** More authentic compliance testing

#### Option C: Full System Integration (Long-term)

Integrate with CV32E40P scalar core for native test execution:

```
┌─────────────────────────────────────────────────────────┐
│                    Full SoC Testbench                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌───────────┐         ┌───────────┐                   │
│  │ CV32E40P  │─CV-X-IF─│    VPU    │                   │
│  │  Scalar   │         │   Core    │                   │
│  └─────┬─────┘         └───────────┘                   │
│        │                                                │
│        ▼                                                │
│  ┌───────────────────────────────────────────────────┐ │
│  │                  Memory System                     │ │
│  │  (Load test binary, capture signatures)           │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Effort:** Major integration project
**Coverage:** Complete RVV compliance
**Benefit:** Production-ready verification, required for product anyway

### Test Categories from chipsalliance/riscv-vector-tests

| Category | Instructions | Our Status |
|----------|--------------|------------|
| Integer Arithmetic | vadd, vsub, vrsub, vand, vor, vxor, etc. | ✅ Implemented |
| Integer Multiply | vmul, vmulh, vmulhu, vmulhsu | ✅ Implemented |
| Integer MAC | vmacc, vnmsac, vmadd, vnmsub | ✅ Implemented |
| Integer Compare | vmseq, vmsne, vmslt, vmsle, etc. | ✅ Implemented |
| Integer Min/Max | vmin, vmax, vminu, vmaxu | ✅ Implemented |
| Shifts | vsll, vsrl, vsra | ✅ Implemented |
| Fixed-Point | vssrl, vssra, vnclip | ✅ Implemented |
| Widening | vwadd, vwsub, vwmul, vwmacc | ✅ Implemented |
| Narrowing | vnsrl, vnsra | ✅ Implemented |
| Reductions | vredsum, vredmax, vredmin, etc. | ✅ Implemented |
| Mask Logic | vmand, vmor, vmxor, etc. | ✅ Implemented |
| Mask Operations | vcpop, vfirst, vmsbf, vmsif, vmsof | ✅ Implemented |
| Permutation | vrgather, vslide, vmerge, vmv | ✅ Implemented |
| Floating-Point | vfadd, vfmul, etc. | ❌ Not planned |
| Load/Store | vle, vse, vlse, etc. | N/A (DMA model) |

### Priority Assessment

| Option | Effort | Value | Priority |
|--------|--------|-------|----------|
| A: Convert test vectors | Low (~200 LOC) | High (official vectors) | **P1** |
| B: Minimal harness | Medium (~1K LOC) | Medium (binary execution) | P2 |
| C: Full integration | High (project) | Very High (production) | P3 |

### Implementation Plan

**Phase 1 (v1.2):** Option A
- Download chipsalliance configs
- Write Python converter: YAML → SystemVerilog tasks
- Add `test_compliance_*` to hp_vpu_tb.sv
- Target: 50+ compliance test cases per instruction

**Phase 2 (v1.3+):** Option B
- Build ELF parser in testbench
- Create instruction sequencer
- Run subset of official binaries

**Phase 3 (v2.0+):** Option C
- CV32E40P integration
- Full system simulation
- Complete RVV compliance certification

### Concept

Instead of widening the datapath for LMUL=2/4/8 (which requires multi-port VRF, wider lanes, complex hazards), decompose each LMUL>1 instruction into multiple micro-ops that reuse the existing LMUL=1 datapath.

```
User instruction:  vadd.vv v0, v8, v16    ; LMUL=4, SEW=8
                   (register groups: v0-v3, v8-v11, v16-v19)

Decomposed internally to:
  μop0: vadd.vv v0,  v8,  v16   ; first register of each group
  μop1: vadd.vv v1,  v9,  v17   ; second register
  μop2: vadd.vv v2,  v10, v18   ; third register
  μop3: vadd.vv v3,  v11, v19   ; fourth register

Each μop uses existing LMUL=1 datapath - NO changes to lanes/VRF!
```

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     MICRO-OP SEQUENCER                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  From IQ:                                                       │
│  ┌──────────────────┐                                          │
│  │ vadd.vv v0,v8,v16│  LMUL=4                                  │
│  │ (single instr)   │                                          │
│  └────────┬─────────┘                                          │
│           │                                                     │
│           ▼                                                     │
│  ┌──────────────────┐     ┌─────────────────┐                  │
│  │  μop Sequencer   │────►│  Register       │                  │
│  │                  │     │  Offset Logic   │                  │
│  │  uop_count: 0-7  │     │                 │                  │
│  │  uop_total: 1-8  │     │  vd  += uop_cnt │                  │
│  │  uop_active: 0/1 │     │  vs1 += uop_cnt │                  │
│  └──────────────────┘     │  vs2 += uop_cnt │                  │
│           │               └────────┬────────┘                  │
│           │                        │                            │
│           ▼                        ▼                            │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              EXISTING LMUL=1 DATAPATH                    │   │
│  │                                                          │   │
│  │  Decode → VRF → Lanes → Writeback (unchanged)           │   │
│  │                                                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  To CV-X-IF:                                                   │
│  - Completion only when uop_count == uop_total - 1             │
│  - IQ pop only on last μop                                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Implementation Summary

| Module | Change | Estimated LOC |
|--------|--------|---------------|
| hp_vpu_decode.sv | Add μop sequencer + reg offset | ~40 |
| hp_vpu_top.sv | Completion gating on last μop | ~15 |
| hp_vpu_hazard.sv | Track μop sequence | ~10 |
| hp_vpu_lanes.sv | **None** | 0 |
| hp_vpu_vrf.sv | **None** | 0 |
| **Total** | | **~65 lines** |

### Sequencer Logic

```systemverilog
// Determine μop count from LMUL encoding
always_comb begin
  case (lmul_i)
    LMUL_1:   uop_total = 3'd1;  // 1 μop
    LMUL_2:   uop_total = 3'd2;  // 2 μops
    LMUL_4:   uop_total = 3'd4;  // 4 μops
    LMUL_8:   uop_total = 3'd8;  // 8 μops
    LMUL_F2:  uop_total = 3'd1;  // Fractional = 1 μop
    LMUL_F4:  uop_total = 3'd1;
    LMUL_F8:  uop_total = 3'd1;
    default:  uop_total = 3'd1;
  endcase
end

// Register group alignment (RVV spec requirement)
// LMUL=2: base must be even (v0,v2,v4...)
// LMUL=4: base must be multiple of 4 (v0,v4,v8...)
// LMUL=8: base must be multiple of 8 (v0,v8,v16,v24)
wire [4:0] vd_base = (uop_total == 8) ? {vd[4:3], 3'b0} :
                     (uop_total == 4) ? {vd[4:2], 2'b0} :
                     (uop_total == 2) ? {vd[4:1], 1'b0} : vd;

// Adjusted addresses for current μop
wire [4:0] vd_adjusted  = vd_base  + uop_count;
wire [4:0] vs1_adjusted = vs1_base + uop_count;
wire [4:0] vs2_adjusted = vs2_base + uop_count;
```

### Throughput Analysis

| LMUL | Elements Processed | Cycles | Elements/Cycle | Throughput |
|------|-------------------|--------|----------------|------------|
| 1/8 | VLEN/SEW/8 | 1 | VLEN/SEW/8 | Reduced |
| 1/4 | VLEN/SEW/4 | 1 | VLEN/SEW/4 | Reduced |
| 1/2 | VLEN/SEW/2 | 1 | VLEN/SEW/2 | Reduced |
| 1 | VLEN/SEW | 1 | VLEN/SEW | Baseline |
| 2 | 2×VLEN/SEW | 2 | VLEN/SEW | Same |
| 4 | 4×VLEN/SEW | 4 | VLEN/SEW | Same |
| 8 | 8×VLEN/SEW | 8 | VLEN/SEW | Same |

**Key insight:** Peak throughput (elements/cycle) is constant. LMUL>1 processes more elements over more cycles — exactly as intended.

### Comparison: Micro-ops vs True Register Grouping

| Aspect | Micro-op Approach | True Grouping |
|--------|-------------------|---------------|
| RTL complexity | ~65 lines | ~500+ lines |
| VRF changes | None | Multi-port or banking |
| Lane changes | None | Wider or multiple |
| Hazard logic | Minor additions | Major rewrite |
| Peak throughput | Same | Same |
| Instruction latency | +N-1 cycles for LMUL=N | No change |
| Register pressure | Uses more regs logically | Same |
| RVV compliance | Full | Full |

### Latency Impact

```
Single instruction latency (cycles to first result):

LMUL=1: 8 cycles (baseline)
LMUL=2: 8 cycles (first reg), 9 cycles (second reg)
LMUL=4: 8-11 cycles (spread across 4 μops)
LMUL=8: 8-15 cycles (spread across 8 μops)

For throughput-oriented workloads (LLM inference), this is acceptable.
Pipeline stays 100% utilized with back-to-back μops.
```

### Use Cases Enabled

With LMUL>1 support:

1. **Longer vectors without VLEN increase**
   - VLEN=256, LMUL=4 → 1024 bits effective vector length
   - Useful for large matrix rows

2. **Better register utilization**
   - Can use fewer "virtual" registers for same data
   - Reduces register spilling in complex kernels

3. **Full RVV compliance**
   - Compilers expect LMUL>1 support
   - Enables standard RVV toolchains

### Priority Assessment

| Factor | Score | Notes |
|--------|-------|-------|
| Implementation effort | Low (~65 LOC) | Minimal risk |
| Datapath changes | None | No timing impact |
| RVV compliance | High value | Full LMUL support |
| LLM inference benefit | Medium | Useful for large matrices |
| Compiler compatibility | High value | Standard toolchains work |

**Recommendation:** Include in v1.2 alongside P0/P1 interface fixes.
# Hyperplane VPU v0.19 Synthesis Configurations

## Available Configurations

### 1. 256-bit (Default)
- **File**: `config/vpu_config_256.json`
- **VLEN/DLEN**: 256/256
- **NLANES**: 4
- **Target**: xc7a100tcsg324-1 (Arty A7-100T)
- **Tests**: 98/98 pass

### 2. 64-bit (Arty7)
- **File**: `config/vpu_config_arty7.json`
- **VLEN/DLEN**: 64/64
- **NLANES**: 1
- **Target**: xc7a35ticsg324-1L (Arty A7-35T)
- **Tests**: 80/98 pass (all critical tests pass)

## Switching Configurations

```bash
# Switch to 64-bit (Arty7)
./scripts/switch_config.sh arty7

# Switch to 256-bit
./scripts/switch_config.sh 256

# Run tests
make sim
```

## Synthesis Scripts

All scripts updated for v0.19 with LUT ROM:

1. **step2_vpu_synthesis.sh** - Vivado synthesis
   - Reads target FPGA from config
   - Includes hp_vpu_lut_rom.sv

2. **step2_vpu_yosys_synth.sh** - Yosys synthesis
   - Includes hp_vpu_lut_rom.sv

3. **Makefile** - iverilog simulation
   - Includes hp_vpu_lut_rom.sv

## RTL Files (v0.19)

```
rtl/
├── hp_vpu_top.sv       # Top-level wrapper
├── hp_vpu_decode.sv    # Instruction decoder (F6_VLUT)
├── hp_vpu_lanes.sv     # Execution datapath (LUT integration)
├── hp_vpu_lut_rom.sv   # NEW: LUT ROM for LLM inference
├── hp_vpu_vrf.sv       # Vector register file
├── hp_vpu_hazard.sv    # Hazard detection
└── hp_vpu_iq.sv        # Issue queue
```

## LUT Instructions (v0.19)

| Instruction | Description | Use Case |
|-------------|-------------|----------|
| vexp.v | exp(x/16)*256 | Softmax numerator |
| vrecip.v | 32768/x | Softmax denominator |
| vrsqrt.v | 16384/sqrt(x) | RMSNorm/LayerNorm |
| vgelu.v | GELU(x/32)*128 | Activation function |

## Expected Resource Usage (Estimates)

| Config | LUTs | Registers | DSPs | BRAM |
|--------|------|-----------|------|------|
| 64/64 | ~2K | ~1K | 1-2 | 1 |
| 256/256 | ~8K | ~4K | 4-8 | 4 |

Run synthesis to get actual numbers for your target FPGA.
-e

---


# VPU v0.3b Test Infrastructure

## Quick Start (Docker)

All tests run through the step1_vpu_rtl_validate.sh script in Docker:

```bash
# Quick smoke test (9 tests, <5 sec)
./step1_vpu_rtl_validate.sh --quick

# Full modular suite (946 tests, ~60 sec)
./step1_vpu_rtl_validate.sh --full

# Full suite at 256-bit
./step1_vpu_rtl_validate.sh --full --256

# Specific category
./step1_vpu_rtl_validate.sh --test alu

# Original compliance tests
./step1_vpu_rtl_validate.sh -c

# Base testbench only (default)
./step1_vpu_rtl_validate.sh
```

## Test Modes

| Mode | Command | Tests | Time |
|------|---------|-------|------|
| Quick | `--quick` | 9 | <5s |
| Full | `--full` | 946 | ~60s |
| ALU | `--test alu` | 438 | ~30s |
| MUL | `--test mul` | 60 | ~5s |
| MAC | `--test mac` | 36 | ~3s |
| SAT | `--test sat` | 60 | ~5s |
| CMP | `--test cmp` | 192 | ~15s |
| RED | `--test red` | 120 | ~10s |
| LUT | `--test lut` | 40 | ~5s |
| Compliance | `-c` | 1273 | ~90s |
| Base | (default) | ~150 | ~30s |

## Configuration Options

```bash
# 64-bit (default)
./step1_vpu_rtl_validate.sh --full --64

# 256-bit
./step1_vpu_rtl_validate.sh --full --256
```

## Other Options

| Option | Description |
|--------|-------------|
| `-z, --hazard` | Run only hazard pattern tests |
| `-s, --seed N` | Set random seed (default: 99999) |
| `-l, --long` | Enable 10K instruction stress test |
| `-h, --help` | Show help |

## Test Results

Results are saved to `results/rtl/test_results_<VLEN>.log`

### Expected Results

| Mode | Tests | Expected |
|------|-------|----------|
| --quick | 9 | 9/9 (100%) |
| --full | 946 | 943/946 (99.7%) |
| --test alu | 438 | 438/438 (100%) |
| -c | 1273 | varies |

### Known Failures (3)

The `--full` mode has 3 known failures in LUT tests:
- `test_vrecip_v_sew8_000/001` - zero output is valid
- `test_vrsqrt_v_sew8_000` - zero output is valid

See `docs/KNOWN_FAILURES.md` for details.

## File Structure

```
vpu_fpga_0.3b/
├── step1_vpu_rtl_validate.sh   # Main test entry point
├── config/
│   ├── vpu_config.json         # 64-bit config
│   └── vpu_config_256.json     # 256-bit config
├── generated/tests/
│   ├── tests_modular.sv        # Master include
│   ├── tests_alu_vv.sv         # ALU .vv tests
│   ├── tests_alu_vx.sv         # ALU .vx tests
│   ├── tests_alu_vi.sv         # ALU .vi tests
│   ├── tests_mul.sv            # MUL tests
│   ├── tests_mac.sv            # MAC tests
│   ├── tests_sat.sv            # SAT tests
│   ├── tests_cmp.sv            # CMP tests
│   ├── tests_red.sv            # RED tests
│   ├── tests_lut.sv            # LUT tests
│   └── tests_known_fail.sv     # Known failures
├── results/rtl/
│   ├── test_results_64.log
│   └── test_results_256.log
└── docs/
    ├── TEST_INFRASTRUCTURE.md
    └── KNOWN_FAILURES.md
```

## Common Workflows

### Daily Development
```bash
# Quick check after RTL change
./step1_vpu_rtl_validate.sh --quick
```

### Before Commit
```bash
# Full tests at both configs
./step1_vpu_rtl_validate.sh --full --64
./step1_vpu_rtl_validate.sh --full --256
```

### Debugging Specific Category
```bash
# Run just that category
./step1_vpu_rtl_validate.sh --test mul

# Check log
cat results/rtl/test_results_64.log | grep FAIL
```

### Full Validation
```bash
# Everything
./step1_vpu_rtl_validate.sh --full -c -l --64
./step1_vpu_rtl_validate.sh --full -c -l --256
```

## Regenerating Tests

```bash
# Regenerate modular tests
python3 scripts/gen_modular_tests.py

# Regenerate package
python3 scripts/gen_pkg.py config/vpu_config.json
python3 scripts/gen_pkg.py config/vpu_config_256.json
```

## Test Coverage

| Operation | .vv | .vx | .vi | Status |
|-----------|-----|-----|-----|--------|
| vadd/vsub | ✓   | ✓   | ✓   | 100% |
| vand/vor/vxor | ✓ | ✓ | ✓ | 100% |
| vsll/vsrl/vsra | ✓ | ✓ | ✓ | 100% |
| vmin/vmax | ✓   | ✓   | -   | 100% |
| vmul/vmulh | ✓  | -   | -   | 100% |
| vmacc/vnmsac | ✓ | - | -   | 100% |
| vmadd/vnmsub | ✓ | - | -   | 100% |
| vsadd/vssub | ✓ | -   | -   | 100% |
| vmseq/vmslt etc | ✓ | - | - | 100% |
| vredsum etc | ✓ | -   | -   | 100% |
| vexp/vrecip etc | ✓ | - | - | 92.5% |
