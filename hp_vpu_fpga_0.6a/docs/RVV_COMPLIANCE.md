# RISC-V Vector Extension Compliance - Hyperplane VPU v1.1

## v0.3e Note

Reduction pipeline split R2→R2A+R2B for 300 MHz timing closure.
Reduction latency is +1 cycle vs v0.3d. All reduction instructions pass
compliance at both VLEN=64 and VLEN=256. See `AUDIT_R2AB_HAZARD.md`.

## Overview

The Hyperplane VPU implements a subset of the RISC-V Vector Extension (RVV) v1.0 specification, optimized for embedded FPGA deployment and INT4/INT8 quantized inference.

## Configuration

| Parameter | Value | RVV Spec |
|-----------|-------|----------|
| VLEN | 64-256 (configurable) | Implementation-defined |
| ELEN | 32 | Max 64 in spec |
| SLEN | VLEN | SLEN ≥ VLEN allowed |
| LMUL | 1, 1/2, 1/4, 1/8 | 1/8 to 8 in spec |
| SEW | 8, 16, 32 | 8-64 in spec |

## Implemented Instructions

### Configuration Instructions
| Instruction | Status | Notes |
|-------------|--------|-------|
| vsetvli | ✅ Full | rd, rs1, vtypei |
| vsetvl | ✅ Full | rd, rs1, rs2 |
| vsetivli | ⚠️ Partial | Treated as vsetvli |

### Integer Arithmetic (OPIVV/OPIVX/OPIVI)
| Instruction | .vv | .vx | .vi | Notes |
|-------------|-----|-----|-----|-------|
| vadd | ✅ | ✅ | ✅ | |
| vsub | ✅ | ✅ | - | |
| vrsub | - | ✅ | ✅ | |
| vand | ✅ | ✅ | ✅ | |
| vor | ✅ | ✅ | ✅ | |
| vxor | ✅ | ✅ | ✅ | |
| vsll | ✅ | ✅ | ✅ | |
| vsrl | ✅ | ✅ | ✅ | |
| vsra | ✅ | ✅ | ✅ | |
| vminu | ✅ | ✅ | - | Unsigned |
| vmaxu | ✅ | ✅ | - | Unsigned |
| vmin | ✅ | ✅ | - | Signed |
| vmax | ✅ | ✅ | - | Signed |

### Integer Compare (OPIVV/OPIVX/OPIVI)
| Instruction | .vv | .vx | .vi | Notes |
|-------------|-----|-----|-----|-------|
| vmseq | ✅ | ✅ | ✅ | |
| vmsne | ✅ | ✅ | ✅ | |
| vmsltu | ✅ | ✅ | - | Unsigned |
| vmslt | ✅ | ✅ | - | Signed |
| vmsleu | ✅ | ✅ | ✅ | Unsigned |
| vmsle | ✅ | ✅ | ✅ | Signed |
| vmsgtu | - | ✅ | ✅ | Unsigned |
| vmsgt | - | ✅ | ✅ | Signed |

### Integer Multiply (OPMVV/OPMVX)
| Instruction | .vv | .vx | Notes |
|-------------|-----|-----|-------|
| vmul | ✅ | ✅ | Low bits |
| vmulh | ✅ | ✅ | Signed high |
| vmulhu | ✅ | ✅ | Unsigned high |
| vmulhsu | ✅ | ✅ | Signed×Unsigned high |

### Integer Multiply-Add (OPMVV/OPMVX)
| Instruction | .vv | .vx | Notes |
|-------------|-----|-----|-------|
| vmacc | ✅ | ✅ | vd += vs1 * vs2 |
| vnmsac | ✅ | ✅ | vd -= vs1 * vs2 |
| vmadd | ⚙️ | ⚙️ | Configurable (ENABLE_VMADD) |
| vnmsub | ⚙️ | ⚙️ | Configurable (ENABLE_VMADD) |

### Integer Divide (OPMVV/OPMVX)
| Instruction | Status | Notes |
|-------------|--------|-------|
| vdiv[u] | ❌ | Not implemented |
| vrem[u] | ❌ | Not implemented |

### Fixed-Point Arithmetic
| Instruction | .vv | .vx | .vi | Notes |
|-------------|-----|-----|-----|-------|
| vsaddu | ✅ | ✅ | ✅ | Saturating add unsigned |
| vsadd | ✅ | ✅ | ✅ | Saturating add signed |
| vssubu | ✅ | ✅ | - | Saturating sub unsigned |
| vssub | ✅ | ✅ | - | Saturating sub signed |
| vssrl | ✅ | ✅ | ✅ | Scaling shift right logical |
| vssra | ✅ | ✅ | ✅ | Scaling shift right arithmetic |
| vnclipu | ✅ | ✅ | ✅ | Narrowing clip unsigned |
| vnclip | ✅ | ✅ | ✅ | Narrowing clip signed |

### Reduction Operations (OPMVV)
| Instruction | Status | Notes |
|-------------|--------|-------|
| vredsum | ✅ | Sum reduction (pipelined tree) |
| vredmaxu | ✅ | Max unsigned (pipelined tree) |
| vredmax | ✅ | Max signed (pipelined tree) |
| vredminu | ✅ | Min unsigned (pipelined tree) |
| vredmin | ✅ | Min signed (pipelined tree) |
| vredand | ✅ | AND reduction (pipelined tree) |
| vredor | ✅ | OR reduction (pipelined tree) |
| vredxor | ✅ | XOR reduction (pipelined tree) |
| vwredsumu | ❌ | Widening sum |
| vwredsum | ❌ | Widening signed sum |

### Mask Operations
| Instruction | Status | Notes |
|-------------|--------|-------|
| vmand.mm | ✅ | |
| vmnand.mm | ✅ | |
| vmandn.mm | ✅ | |
| vmxor.mm | ✅ | |
| vmor.mm | ✅ | |
| vmnor.mm | ✅ | |
| vmorn.mm | ✅ | |
| vmxnor.mm | ✅ | |
| vcpop.m | ✅ | Population count (v0.16) |
| vfirst.m | ✅ | Find first set (v0.16) |
| vmsbf.m | ✅ | Set before first (v0.16) |
| vmsif.m | ✅ | Set including first (v0.16) |
| vmsof.m | ✅ | Set only first (v0.16) |
| viota.m | ❌ | Iota (prefix sum) |
| vid.v | ✅ | Element index |

### Permutation Operations
| Instruction | Status | Notes |
|-------------|--------|-------|
| vmv.v.v | ✅ | Vector move |
| vmv.v.x | ✅ | Scalar to vector |
| vmv.v.i | ✅ | Immediate to vector |
| vrgather.vv | ✅ | Gather |
| vrgather.vx | ⚠️ | Partial |
| vrgatherei16.vv | ✅ | Gather with 16-bit indices (v0.16) |
| vslideup | ✅ | .vx, .vi |
| vslidedown | ✅ | .vx, .vi |
| vslide1up.vx | ✅ | Slide up by 1, insert scalar (v0.16) |
| vslide1down.vx | ✅ | Slide down by 1, insert scalar (v0.16) |
| vcompress | ❌ | |
| vmerge.vvm | ✅ | Mask-based merge (v0.16) |
| vmerge.vxm | ✅ | Scalar merge (v0.16) |
| vmerge.vim | ✅ | Immediate merge (v0.16) |

### Widening Operations
| Instruction | Status | Notes |
|-------------|--------|-------|
| vwadd.vv | ✅ | Signed widening add (v0.17) |
| vwaddu.vv | ✅ | Unsigned widening add (v0.17) |
| vwsub.vv | ✅ | Signed widening sub (v0.17) |
| vwsubu.vv | ✅ | Unsigned widening sub (v0.17) |
| vwmul.vv | ✅ | Signed widening multiply (v0.17) |
| vwmulu.vv | ✅ | Unsigned widening multiply (v0.17) |
| vwmulsu.vv | ✅ | Signed×Unsigned widening multiply (v0.17) |
| vwmaccu.vv | ✅ | Unsigned widening MAC (v0.18) |
| vwmacc.vv | ✅ | Signed widening MAC (v0.18) |
| vwmaccsu.vv | ✅ | Signed×Unsigned widening MAC (v0.18) |
| vwadd.wv | ❌ | Add to widened operand |
| vwsub.wv | ❌ | Sub from widened operand |

**Note**: Widening operations use W1→W2 pipeline, processing first VLMAX/2 elements (SEW=8: 16 elem, SEW=16: 8 elem). Results are 2×SEW width.

### Narrowing Operations (v0.18)
| Instruction | Status | Notes |
|-------------|--------|-------|
| vnsrl.wv | ✅ | Narrowing logical shift right |
| vnsrl.wx | ✅ | Narrowing logical shift right |
| vnsrl.wi | ✅ | Narrowing logical shift right |
| vnsra.wv | ✅ | Narrowing arithmetic shift right |
| vnsra.wx | ✅ | Narrowing arithmetic shift right |
| vnsra.wi | ✅ | Narrowing arithmetic shift right |

**Note**: Narrowing shifts take 2×SEW input and produce SEW output.

### Memory Operations
| Instruction | Status | Notes |
|-------------|--------|-------|
| vle8/16/32 | N/A | Handled by external DMA engine |
| vse8/16/32 | N/A | Handled by external DMA engine |
| vlse* | N/A | Handled by external DMA engine |
| vsse* | N/A | Handled by external DMA engine |
| vluxei* | N/A | Handled by external DMA engine |
| vsuxei* | N/A | Handled by external DMA engine |

**Architecture Decision**: Hyperplane VPU uses a DMA-based memory model. Vector load/store
operations are handled by an external DMA engine writing directly to the VRF via the
`mem_vrf_*` interface. This keeps the VPU as a pure compute unit with lower complexity
and area. See [Memory Architecture](#memory-architecture) section below.

### Floating-Point Operations
| Category | Status |
|----------|--------|
| FP Arithmetic | ❌ Not planned (strategic decision) |
| FP Compare | ❌ Not planned |
| FP Conversions | ❌ Not planned |
| FP Reductions | ❌ Not planned |

**Strategic Decision**: FP16/BF16 support is intentionally omitted to minimize area and
complexity. The target market is INT8 quantized inference where floating-point is not
required. This allows Hyperplane VPU to fit on smaller FPGAs and lower-cost ASICs.

## Compliance Notes

### Deviations from RVV 1.0

1. **LMUL Limited to ≤1**
   - Supports LMUL = 1, 1/2, 1/4, 1/8 (v1.1)
   - No register grouping (LMUL > 1) support

2. **SEW=64 Not Supported**
   - ELEN=32 limits maximum element width

3. **DMA-Based Memory Model**
   - VPU does not decode vle/vse instructions internally
   - External DMA engine handles memory transfers via `mem_vrf_*` interface
   - This is a deliberate architectural choice, not a limitation
   - See [Memory Architecture](#memory-architecture) section

4. **No Floating-Point**
   - Strategic decision to minimize area
   - Target: INT8 quantized inference only

5. **vstart Always 0**
   - No exception/trap resume support

6. **vxrm/vxsat Read-Only**
   - Fixed rounding mode (round-to-nearest-even)

## Memory Architecture

Hyperplane VPU uses a **DMA-based memory model** where vector load/store operations
are handled externally rather than decoded by the VPU itself.

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                          SoC                                 │
│                                                              │
│  ┌──────────┐     ┌──────────┐     ┌───────────────────┐    │
│  │  RISC-V  │     │   DMA    │     │  Hyperplane VPU   │    │
│  │   Core   │     │  Engine  │     │                   │    │
│  └────┬─────┘     └────┬─────┘     │  ┌─────────────┐  │    │
│       │                │           │  │     VRF     │  │    │
│       │ CV-X-IF        │ mem_vrf_* │  │  (v0-v31)   │  │    │
│       │ (instructions) │ (data)    │  └──────┬──────┘  │    │
│       │                │           │         │         │    │
│       ▼                ▼           │  ┌──────▼──────┐  │    │
│  ┌─────────────────────────────────┤  │   Compute   │  │    │
│  │        x_issue_*                │  │    Lanes    │  │    │
│  └─────────────────────────────────┤  └─────────────┘  │    │
│                                    └───────────────────┘    │
│                                                              │
│       ┌────────────────────────────────┐                    │
│       │           Memory               │                    │
│       └────────────────────────────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

### VRF Memory Interface

The VPU exposes a direct memory interface to the Vector Register File:

```systemverilog
// Memory/DMA interface for VRF access
input  logic                      mem_vrf_wr_en_i,    // Write enable
input  logic [4:0]                mem_vrf_addr_i,     // Register address (v0-v31)
input  logic [DLEN-1:0]           mem_vrf_wdata_i,    // Write data
output logic [DLEN-1:0]           mem_vrf_rdata_o,    // Read data
```

### Operation Sequence

**Vector Load (equivalent to vle8/16/32):**
1. CPU configures DMA: source=memory_addr, dest=vrf_reg, size=VLEN/8
2. DMA reads from memory, writes to VRF via `mem_vrf_wr_en_i`
3. CPU issues compute instruction via CV-X-IF

**Vector Store (equivalent to vse8/16/32):**
1. CPU configures DMA: source=vrf_reg, dest=memory_addr, size=VLEN/8
2. DMA reads from VRF via `mem_vrf_rdata_o`, writes to memory

### Advantages of DMA-Based Model

| Aspect | Benefit |
|--------|---------|
| **Simplicity** | VPU is pure compute, no memory state machines |
| **Area** | No AGU, no TLB, no cache interface logic |
| **Flexibility** | DMA can handle strided, indexed, scatter/gather |
| **Decoupling** | Memory and compute can overlap with double-buffering |
| **Portability** | VPU works with any memory system via standard DMA |

### Implementation Quality

| Aspect | Status |
|--------|--------|
| Masking (vm=0) | ✅ Fully supported |
| Tail Agnostic | ⚠️ Tail elements undisturbed |
| Mask Agnostic | ⚠️ Inactive elements undisturbed |
| Illegal Instruction | ✅ Detected and flagged |

## Verification Status

### RTL Verification (v1.1)
- 102 directed tests (both VLEN=64 and VLEN=256)
- Fully parameterized testbench works with all VLEN/DLEN configurations
- Includes v1.1 new instruction tests:
  - Fractional LMUL (1/2, 1/4)
  - INT4 pack/unpack (vpack4.v, vunpack4.v)

### Randomized Stress Testing (v1.1)
| Seed | Instructions | Result |
|------|--------------|--------|
| 12345 | 100 | ✅ PASS |
| 67890 | 100 | ✅ PASS |
| 11111 | 100 | ✅ PASS |
| 99887 | 300 | ✅ PASS |
| 55555 | 500 | ✅ PASS |
| 77777 | 1000 | ✅ PASS |
| 88888 | 10000 | ✅ PASS (run locally with ENABLE_LONG_STRESS_TEST) |

**Total: 12,100 randomized back-to-back instructions with 0 errors**

### Configuration Testing (v1.1)
| Config | VLEN | DLEN | Tests |
|--------|------|------|-------|
| Arty7 | 64 | 64 | 102/102 PASS |
| A100T | 256 | 256 | 102/102 PASS |

### Netlist Verification
- 100 randomized tests on synthesized netlist
- Operations: vadd, vsub, vand, vor, vxor, vmul
- All tests passing

### Coverage
- All implemented instructions exercised
- Multiple SEW values (8, 16, 32)
- Masked and unmasked operations
- Edge cases (saturation, overflow)

## Synthesis Results

### Vivado (FPGA - Arty A7-100T)
| Metric | v0.12 | v0.14 | v0.16 |
|--------|-------|-------|-------|
| Timing Slack @ 100MHz | -10.834ns | -0.862ns | TBD |
| Critical Path | 43 levels (reduction) | 16 levels (multiply) | TBD |
| Status | ❌ Failing | ⚠️ Near closure | TBD |

### Yosys (Open-Source)
| Metric | Value |
|--------|-------|
| Total Cells | ~108,682 |
| Flip-Flops | ~6,803 |
| MUX | ~30,153 |
| Logic Gates | ~71,726 |

## v0.17 Changes

### New Instructions Implemented

| Instruction | Description | Pipeline Stage |
|-------------|-------------|----------------|
| vwmul.vv | Signed widening multiply | OF→W1→W2 |
| vwmulu.vv | Unsigned widening multiply | OF→W1→W2 |
| vwmulsu.vv | Signed×Unsigned widening multiply | OF→W1→W2 |
| vwadd.vv | Signed widening add | OF→W1→W2 |
| vwaddu.vv | Unsigned widening add | OF→W1→W2 |
| vwsub.vv | Signed widening subtract | OF→W1→W2 |
| vwsubu.vv | Unsigned widening subtract | OF→W1→W2 |

### Widening Pipeline Architecture
- New W1→W2 two-stage pipeline (like R1→R2→R3 for reductions)
- Stalls main E1→E2→E3 pipeline during widening execution
- Supports SEW=8→16 and SEW=16→32 widening
- Processes first VLMAX/2 elements (due to LMUL=1 limitation)

### Test Infrastructure
- Long stress test conditionally compiled via `ENABLE_LONG_STRESS_TEST`
- JSON test config: `test.stress_test_max_instructions`, `test.enable_long_stress_test`

### Files Modified
- `config/vpu_config.json` - Added widening feature flag, test configuration
- `scripts/gen_pkg.py` - Added widening funct6/opcode encodings
- `rtl/hp_vpu_decode.sv` - Added widening instruction decode
- `rtl/hp_vpu_lanes.sv` - Added W1→W2 widening pipeline
- `tb/hp_vpu_tb.sv` - Added 6 widening tests, conditional long test

## v0.16 Changes

### New Instructions Implemented

| Instruction | Description | Pipeline Stage |
|-------------|-------------|----------------|
| vmerge.vvm/vxm/vim | Mask-based element merge | OF→E1→E2 |
| vcpop.m | Population count of mask | OF→E1→E2 |
| vfirst.m | Find first set bit in mask | OF→E1→E2 |
| vmsbf.m | Set-before-first mask | OF→E1→E2 |
| vmsif.m | Set-including-first mask | OF→E1→E2 |
| vmsof.m | Set-only-first mask | OF→E1→E2 |
| vslide1up.vx | Slide up by 1, insert scalar at [0] | OF→E1→E2 |
| vslide1down.vx | Slide down by 1, insert scalar at [vl-1] | OF→E1→E2 |
| vrgatherei16.vv | Gather with 16-bit indices | OF→E1→E2 |

### Pipeline Timing Fixes
- Added e1_slide1up_res, e1_slide1dn_res, e1_merge_res pipeline registers
- Fixed operand capture timing for slide1 and merge operations
- Fixed vmsof.m logic (vmsbf_res[i-1] instead of vmsbf_res[i])

### Files Modified
- `scripts/gen_pkg.py` - Added funct6 encodings, expanded vpu_op_e to 7 bits
- `generated/hp_vpu_pkg.sv` - Regenerated with new opcodes
- `rtl/hp_vpu_decode.sv` - Added decode logic for 9 new instructions
- `rtl/hp_vpu_lanes.sv` - Added execution logic and pipeline registers
- `tb/hp_vpu_tb.sv` - Added tests (directed + extended random stress tests)

## Roadmap

### v0.18 (Next)
- [ ] Close remaining timing gap (multiply path optimization)
- [ ] viota.m (iota/prefix sum)
- [ ] vcompress instruction
- [ ] Whole register move (vmv<nr>r.v)
- [ ] vwmacc (widening multiply-accumulate)

### v0.19
- [ ] Widening add/sub (vwadd/vwsub)
- [ ] LMUL=2 support

### Future
- [ ] Memory interface (vle/vse)
- [ ] Floating-point operations
- [ ] Full RVV 1.0 compliance

---

## v0.19 Additions - LUT Instructions for LLM Inference

### Custom LUT Instructions (Not Standard RVV)

These are Hyperplane extensions using reserved opcode space:

| Instruction | Encoding | Description | LLM Use Case |
|-------------|----------|-------------|--------------|
| vexp.v vd, vs2 | funct6=010010, vs1=0 | exp(x/16)*256 lookup | Softmax numerator |
| vrecip.v vd, vs2 | funct6=010010, vs1=1 | 32768/x lookup | Softmax denominator |
| vrsqrt.v vd, vs2 | funct6=010010, vs1=2 | 16384/sqrt(x) lookup | RMSNorm, LayerNorm |
| vgelu.v vd, vs2 | funct6=010010, vs1=3 | GELU(x/32)*128 lookup | Activation function |

### LUT Implementation

- **Simulation**: Inline tables (hp_vpu_lut_rom.sv) - 1024 initial statements
- **Synthesis**: BRAM with $readmemh (hp_vpu_lut_rom_bram.sv) - avoids Vivado OOM
- **Tables**: 4 × 256 × 16-bit = 2KB total ROM

### Accuracy (from gen_lut_tables.py --validate)

| Function | Max Error | Avg Error | Notes |
|----------|-----------|-----------|-------|
| recip | 0.388% | 0.093% | ✓ Excellent |
| rsqrt | 0.047% | 0.017% | ✓ Excellent |
| gelu | 1.166% | 0.257% | ✓ Good |
| exp | 90.858% | 13.0% | Only negative range used in softmax |

---

## v1.0 - Production Release

### Parameterization Complete
- All RTL fully parameterized by VLEN/DLEN from JSON config
- Testbench parameterized (no hardcoded 256-bit values)
- Config flow: `vpu_config.json` → `gen_pkg.py` → `hp_vpu_pkg.sv` → RTL

### Verified Configurations
| Config | VLEN | DLEN | Tests |
|--------|------|------|-------|
| Arty7 (xc7a35t) | 64 | 64 | 98/98 PASS |
| A100T (xc7a100t) | 256 | 256 | 98/98 PASS |

---

## v1.1 - Fractional LMUL + INT4 Pack/Unpack

### Fractional LMUL Support

VLMAX is now computed with LMUL scaling:
```
VLMAX = (VLEN / SEW) × LMUL
```

| LMUL | Encoding | VLMAX (SEW=8, VLEN=64) |
|------|----------|------------------------|
| 1 | 000 | 8 |
| 1/2 | 111 | 4 |
| 1/4 | 110 | 2 |
| 1/8 | 101 | 1 |

**Use Case**: Fractional LMUL allows widening operations to stay within a single register:
```
LMUL=1/2, SEW=8  → 4 source elements (half register)
    widening multiply
LMUL=1,   SEW=16 → 4 result elements (full register)
```

### Custom INT4 Pack/Unpack Instructions (v1.1)

These Hyperplane extensions enable 2× memory density for INT4 quantized models:

| Instruction | Encoding | Description |
|-------------|----------|-------------|
| vunpack4.v vd, vs2 | funct6=010101 | Unpack INT4 pairs → INT8 (sign-extend) |
| vpack4.v vd, vs2 | funct6=010011 | Pack INT8 → INT4 (saturate to [-8,7]) |

### INT4 Inference Flow

```
DMA: Load INT4 packed weights (2× memory density)
         ↓
vunpack4.v v1, v_packed     # INT4 pairs → INT8
         ↓
vwmaccu.vv v_acc, v1, v2    # INT8 × INT8 → INT16/32 accumulate
         ↓
vnsrl.wi v_scaled, v_acc, N # Requantize (narrowing shift)
         ↓
vpack4.v v_out, v_scaled    # INT8 → INT4 (saturate)
         ↓
DMA: Store INT4 packed result
```

### Model Size Impact

| Quantization | Bits/Weight | Model Size | Arty-7 (1MB BRAM) |
|--------------|-------------|------------|-------------------|
| INT8 | 8 | 1× | ~1M params |
| INT4 | 4 | 0.5× | ~2M params |

### Verification Status (v1.1)

| Config | VLEN | DLEN | Tests |
|--------|------|------|-------|
| Arty7 | 64 | 64 | **102/102 PASS** |
| A100T | 256 | 256 | **102/102 PASS** |

### Files Modified (v1.1)
- `config/vpu_config.json` - Added `fractional_lmul`, `int4_pack_unpack`, `enable_vcd_dump`
- `scripts/gen_pkg.py` - Added F6_VPACK4, F6_VUNPACK4, OP_VPACK4, OP_VUNPACK4
- `rtl/hp_vpu_top.sv` - Fractional LMUL in VLMAX calculation
- `rtl/hp_vpu_decode.sv` - INT4 instruction decode
- `rtl/hp_vpu_lanes.sv` - INT4 pack/unpack execution logic
- `tb/hp_vpu_tb.sv` - Fractional LMUL tests, INT4 tests, VCD conditional

---

## Roadmap

### v1.2 (Next)
- [ ] INT2 pack/unpack (4× memory density)
- [ ] viota.m (iota/prefix sum)
- [ ] vcompress instruction

### Future
- [ ] LMUL=2 support (register grouping)
- [ ] Whole register move (vmv<nr>r.v)
