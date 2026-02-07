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
