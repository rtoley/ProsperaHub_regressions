#!/usr/bin/env python3
"""
Hyperplane VPU - LUT Table Generator for LLM Inference
Generates ROM tables for exp, reciprocal, rsqrt, and GELU functions.

Usage:
    python3 gen_lut_tables.py [--validate] [--plot]

Tables are designed for INT8 quantized inference with the following conventions:
- Input: 8-bit index (0-255), interpreted as signed INT8 (-128 to 127) for exp/gelu
- Output: 16-bit fixed-point result

Scaling Conventions:
- exp:   exp(x / EXP_SCALE) * EXP_OUT_SCALE, useful range for softmax
- recip: RECIP_SCALE / x, for x in [1, 255]
- rsqrt: RSQRT_SCALE / sqrt(x), for x in [1, 255]
- gelu:  gelu(x / GELU_SCALE) * GELU_OUT_SCALE
"""

import math
import argparse
import sys
from typing import List, Tuple

# ==============================================================================
# Scaling Parameters (tuned for INT8 LLM inference)
# ==============================================================================

# Exponential: Input is INT8 (-128 to 127), scaled down for useful exp range
# For softmax, after subtracting max, values are typically in [-8, 0]
# With EXP_INPUT_SCALE=16, input range -128..127 maps to -8..~8
EXP_INPUT_SCALE = 16  # Divide input by this before exp
EXP_OUTPUT_SCALE = 256  # Multiply exp result by this (8 fractional bits)

# Reciprocal: 1/x for x in [1, 255]
# Output = RECIP_SCALE / x, gives good precision for division
RECIP_SCALE = 32768  # 2^15, gives 15-bit fractional precision

# Inverse square root: 1/sqrt(x) for x in [1, 255]
# Used in RMSNorm/LayerNorm
RSQRT_SCALE = 16384  # 2^14, balanced precision

# GELU: Smooth activation used in modern transformers
# Input scaled similarly to exp for useful range
GELU_INPUT_SCALE = 32  # Input range -128..127 maps to -4..4
GELU_OUTPUT_SCALE = 128  # 7 fractional bits

# ==============================================================================
# Table Generation Functions
# ==============================================================================

def generate_exp_table() -> List[int]:
    """
    Generate exp lookup table.
    Index i (0-255) treated as signed INT8: value = i if i < 128 else i - 256
    Output = clamp(exp(value / EXP_INPUT_SCALE) * EXP_OUTPUT_SCALE, 0, 65535)
    """
    table = []
    for i in range(256):
        # Treat as signed INT8
        x_int8 = i if i < 128 else i - 256
        # Scale to floating point
        x_float = x_int8 / EXP_INPUT_SCALE
        # Compute exp
        exp_val = math.exp(x_float)
        # Scale and clamp to uint16
        out = int(round(exp_val * EXP_OUTPUT_SCALE))
        out = max(0, min(65535, out))
        table.append(out)
    return table

def generate_recip_table() -> List[int]:
    """
    Generate reciprocal (1/x) lookup table.
    Index 0: returns max (represents 1/0 = infinity, clamped)
    Index i (1-255): Output = RECIP_SCALE / i
    """
    table = []
    for i in range(256):
        if i == 0:
            out = 65535  # Max value for 1/0
        else:
            out = int(round(RECIP_SCALE / i))
            out = max(0, min(65535, out))
        table.append(out)
    return table

def generate_rsqrt_table() -> List[int]:
    """
    Generate inverse square root (1/sqrt(x)) lookup table.
    Index 0: returns max (represents 1/sqrt(0) = infinity, clamped)
    Index i (1-255): Output = RSQRT_SCALE / sqrt(i)
    """
    table = []
    for i in range(256):
        if i == 0:
            out = 65535  # Max value for 1/sqrt(0)
        else:
            out = int(round(RSQRT_SCALE / math.sqrt(i)))
            out = max(0, min(65535, out))
        table.append(out)
    return table

def gelu(x: float) -> float:
    """GELU activation: 0.5 * x * (1 + tanh(sqrt(2/pi) * (x + 0.044715 * x^3)))"""
    return 0.5 * x * (1.0 + math.tanh(math.sqrt(2.0 / math.pi) * (x + 0.044715 * x * x * x)))

def generate_gelu_table() -> List[int]:
    """
    Generate GELU activation lookup table.
    Index i (0-255) treated as signed INT8: value = i if i < 128 else i - 256
    Output = clamp(gelu(value / GELU_INPUT_SCALE) * GELU_OUTPUT_SCALE + 128, 0, 65535)
    Note: +128 offset to handle negative outputs (GELU can be slightly negative)
    """
    table = []
    for i in range(256):
        # Treat as signed INT8
        x_int8 = i if i < 128 else i - 256
        # Scale to floating point
        x_float = x_int8 / GELU_INPUT_SCALE
        # Compute GELU
        gelu_val = gelu(x_float)
        # Scale, offset, and clamp to uint16
        # Offset by half the output scale to handle negative values
        out = int(round(gelu_val * GELU_OUTPUT_SCALE)) + (GELU_OUTPUT_SCALE // 2)
        out = max(0, min(65535, out))
        table.append(out)
    return table

# ==============================================================================
# Validation Functions
# ==============================================================================

def validate_exp_table(table: List[int]) -> Tuple[float, float, int]:
    """Validate exp table accuracy. Returns (max_rel_error, avg_rel_error, num_tested)."""
    max_err = 0.0
    sum_err = 0.0
    count = 0

    for i in range(256):
        x_int8 = i if i < 128 else i - 256
        x_float = x_int8 / EXP_INPUT_SCALE
        expected = math.exp(x_float) * EXP_OUTPUT_SCALE
        actual = table[i]

        if expected > 1.0:  # Avoid division by near-zero
            rel_err = abs(actual - expected) / expected
            max_err = max(max_err, rel_err)
            sum_err += rel_err
            count += 1

    return (max_err * 100, (sum_err / count) * 100 if count > 0 else 0, count)

def validate_recip_table(table: List[int]) -> Tuple[float, float, int]:
    """Validate reciprocal table accuracy."""
    max_err = 0.0
    sum_err = 0.0
    count = 0

    for i in range(1, 256):  # Skip 0
        expected = RECIP_SCALE / i
        actual = table[i]

        rel_err = abs(actual - expected) / expected
        max_err = max(max_err, rel_err)
        sum_err += rel_err
        count += 1

    return (max_err * 100, (sum_err / count) * 100 if count > 0 else 0, count)

def validate_rsqrt_table(table: List[int]) -> Tuple[float, float, int]:
    """Validate rsqrt table accuracy."""
    max_err = 0.0
    sum_err = 0.0
    count = 0

    for i in range(1, 256):  # Skip 0
        expected = RSQRT_SCALE / math.sqrt(i)
        actual = table[i]

        rel_err = abs(actual - expected) / expected
        max_err = max(max_err, rel_err)
        sum_err += rel_err
        count += 1

    return (max_err * 100, (sum_err / count) * 100 if count > 0 else 0, count)

def validate_gelu_table(table: List[int]) -> Tuple[float, float, int]:
    """Validate GELU table accuracy."""
    max_err = 0.0
    sum_err = 0.0
    count = 0

    for i in range(256):
        x_int8 = i if i < 128 else i - 256
        x_float = x_int8 / GELU_INPUT_SCALE
        expected_raw = gelu(x_float) * GELU_OUTPUT_SCALE + (GELU_OUTPUT_SCALE // 2)
        expected = max(0, min(65535, expected_raw))
        actual = table[i]

        # Use absolute error for GELU since values can be near zero
        if abs(expected) > 1.0:
            rel_err = abs(actual - expected) / abs(expected)
            max_err = max(max_err, rel_err)
            sum_err += rel_err
            count += 1

    return (max_err * 100, (sum_err / count) * 100 if count > 0 else 0, count)

# ==============================================================================
# SystemVerilog Generation
# ==============================================================================

def generate_systemverilog(exp_table: List[int], recip_table: List[int],
                          rsqrt_table: List[int], gelu_table: List[int]) -> str:
    """Generate SystemVerilog ROM module."""

    lines = []
    lines.append("//============================================================================")
    lines.append("// Hyperplane VPU - LUT ROM for LLM Inference Functions")
    lines.append("// AUTO-GENERATED - DO NOT EDIT")
    lines.append("// Run: python3 scripts/gen_lut_tables.py")
    lines.append("//")
    lines.append("// Tables:")
    lines.append(f"//   exp:   exp(x/{EXP_INPUT_SCALE}) * {EXP_OUTPUT_SCALE}, x in [-128, 127]")
    lines.append(f"//   recip: {RECIP_SCALE}/x, x in [1, 255]")
    lines.append(f"//   rsqrt: {RSQRT_SCALE}/sqrt(x), x in [1, 255]")
    lines.append(f"//   gelu:  gelu(x/{GELU_INPUT_SCALE}) * {GELU_OUTPUT_SCALE} + {GELU_OUTPUT_SCALE//2}, x in [-128, 127]")
    lines.append("//============================================================================")
    lines.append("")
    lines.append("`timescale 1ns/1ps")
    lines.append("")
    lines.append("module hp_vpu_lut_rom (")
    lines.append("  input  logic [7:0]  index_i,")
    lines.append("  input  logic [1:0]  func_sel_i,  // 0=exp, 1=recip, 2=rsqrt, 3=gelu")
    lines.append("  output logic [15:0] result_o")
    lines.append(");")
    lines.append("")
    lines.append("  // Function select encoding")
    lines.append("  localparam logic [1:0] FUNC_EXP   = 2'd0;")
    lines.append("  localparam logic [1:0] FUNC_RECIP = 2'd1;")
    lines.append("  localparam logic [1:0] FUNC_RSQRT = 2'd2;")
    lines.append("  localparam logic [1:0] FUNC_GELU  = 2'd3;")
    lines.append("")
    lines.append("  // Scaling constants (for software reference)")
    lines.append(f"  localparam int EXP_INPUT_SCALE  = {EXP_INPUT_SCALE};")
    lines.append(f"  localparam int EXP_OUTPUT_SCALE = {EXP_OUTPUT_SCALE};")
    lines.append(f"  localparam int RECIP_SCALE      = {RECIP_SCALE};")
    lines.append(f"  localparam int RSQRT_SCALE      = {RSQRT_SCALE};")
    lines.append(f"  localparam int GELU_INPUT_SCALE = {GELU_INPUT_SCALE};")
    lines.append(f"  localparam int GELU_OUTPUT_SCALE = {GELU_OUTPUT_SCALE};")
    lines.append("")

    # Generate each table with individual assignments (iverilog compatible)
    for name, table in [("exp", exp_table), ("recip", recip_table),
                        ("rsqrt", rsqrt_table), ("gelu", gelu_table)]:
        lines.append(f"  // {name.upper()} table (256 x 16-bit)")
        lines.append(f"  logic [15:0] {name}_table [0:255];")
        lines.append(f"  initial begin")
        for i in range(256):
            lines.append(f"    {name}_table[{i}] = 16'h{table[i]:04x};")
        lines.append("  end")
        lines.append("")

    lines.append("  // Output mux")
    lines.append("  always_comb begin")
    lines.append("    case (func_sel_i)")
    lines.append("      FUNC_EXP:   result_o = exp_table[index_i];")
    lines.append("      FUNC_RECIP: result_o = recip_table[index_i];")
    lines.append("      FUNC_RSQRT: result_o = rsqrt_table[index_i];")
    lines.append("      FUNC_GELU:  result_o = gelu_table[index_i];")
    lines.append("      default:    result_o = 16'h0000;")
    lines.append("    endcase")
    lines.append("  end")
    lines.append("")
    lines.append("endmodule")

    return "\n".join(lines)

# ==============================================================================
# Test Vector Generation (for testbench)
# ==============================================================================

def generate_test_vectors(exp_table: List[int], recip_table: List[int],
                         rsqrt_table: List[int], gelu_table: List[int]) -> str:
    """Generate test vectors for SystemVerilog testbench."""

    lines = []
    lines.append("// LUT Test Vectors - AUTO-GENERATED")
    lines.append("// Format: {index, func_sel, expected_result}")
    lines.append("")

    # Sample test points
    test_indices = [0, 1, 64, 127, 128, 192, 255]

    lines.append("// EXP tests (func_sel=0)")
    for i in test_indices:
        lines.append(f"// index={i:3d} (int8={i if i < 128 else i-256:4d}): exp_table[{i}] = 0x{exp_table[i]:04x} ({exp_table[i]})")

    lines.append("")
    lines.append("// RECIP tests (func_sel=1)")
    for i in [1, 2, 4, 8, 16, 32, 64, 128, 255]:
        lines.append(f"// index={i:3d}: recip_table[{i}] = 0x{recip_table[i]:04x} ({recip_table[i]}) = {RECIP_SCALE}/{i}")

    lines.append("")
    lines.append("// RSQRT tests (func_sel=2)")
    for i in [1, 4, 9, 16, 25, 64, 100, 144, 255]:
        lines.append(f"// index={i:3d}: rsqrt_table[{i}] = 0x{rsqrt_table[i]:04x} ({rsqrt_table[i]}) = {RSQRT_SCALE}/sqrt({i})")

    lines.append("")
    lines.append("// GELU tests (func_sel=3)")
    for i in test_indices:
        x_int8 = i if i < 128 else i - 256
        lines.append(f"// index={i:3d} (int8={x_int8:4d}): gelu_table[{i}] = 0x{gelu_table[i]:04x} ({gelu_table[i]})")

    return "\n".join(lines)

# ==============================================================================
# Main
# ==============================================================================

def main():
    parser = argparse.ArgumentParser(description="Generate LUT tables for Hyperplane VPU")
    parser.add_argument("--validate", action="store_true", help="Run validation tests")
    parser.add_argument("--plot", action="store_true", help="Plot tables (requires matplotlib)")
    parser.add_argument("--output-dir", default="rtl", help="Output directory for ROM file")
    args = parser.parse_args()

    print("=" * 60)
    print("Hyperplane VPU LUT Table Generator")
    print("=" * 60)

    # Generate tables
    print("\nGenerating tables...")
    exp_table = generate_exp_table()
    recip_table = generate_recip_table()
    rsqrt_table = generate_rsqrt_table()
    gelu_table = generate_gelu_table()

    print(f"  exp:   256 entries, range [{min(exp_table)}, {max(exp_table)}]")
    print(f"  recip: 256 entries, range [{min(recip_table)}, {max(recip_table)}]")
    print(f"  rsqrt: 256 entries, range [{min(rsqrt_table)}, {max(rsqrt_table)}]")
    print(f"  gelu:  256 entries, range [{min(gelu_table)}, {max(gelu_table)}]")

    # Validation
    if args.validate:
        print("\nValidating accuracy...")
        max_err, avg_err, n = validate_exp_table(exp_table)
        status = "✓" if max_err < 2.0 else "✗"
        print(f"  {status} exp:   max_error={max_err:.3f}%, avg_error={avg_err:.4f}% (n={n})")

        max_err, avg_err, n = validate_recip_table(recip_table)
        status = "✓" if max_err < 1.0 else "✗"
        print(f"  {status} recip: max_error={max_err:.3f}%, avg_error={avg_err:.4f}% (n={n})")

        max_err, avg_err, n = validate_rsqrt_table(rsqrt_table)
        status = "✓" if max_err < 1.0 else "✗"
        print(f"  {status} rsqrt: max_error={max_err:.3f}%, avg_error={avg_err:.4f}% (n={n})")

        max_err, avg_err, n = validate_gelu_table(gelu_table)
        status = "✓" if max_err < 2.0 else "✗"
        print(f"  {status} gelu:  max_error={max_err:.3f}%, avg_error={avg_err:.4f}% (n={n})")

    # Generate SystemVerilog
    sv_code = generate_systemverilog(exp_table, recip_table, rsqrt_table, gelu_table)
    output_path = f"{args.output_dir}/hp_vpu_lut_rom.sv"
    with open(output_path, "w") as f:
        f.write(sv_code)
    print(f"\nGenerated: {output_path}")

    # Generate test vectors
    test_vectors = generate_test_vectors(exp_table, recip_table, rsqrt_table, gelu_table)
    test_path = "generated/lut_test_vectors.txt"
    with open(test_path, "w") as f:
        f.write(test_vectors)
    print(f"Generated: {test_path}")

    # Generate .mem file for BRAM inference (Vivado synthesis)
    generate_mem_file(exp_table, recip_table, rsqrt_table, gelu_table, "generated/lut_tables.mem")

    # ROM size estimate
    rom_bytes = 4 * 256 * 2  # 4 tables * 256 entries * 2 bytes
    print(f"\nROM size: {rom_bytes} bytes ({rom_bytes/1024:.1f} KB)")

    # Plot if requested
    if args.plot:
        try:
            import matplotlib.pyplot as plt

            fig, axes = plt.subplots(2, 2, figsize=(12, 10))

            # Exp
            x_exp = [i if i < 128 else i - 256 for i in range(256)]
            axes[0, 0].plot(x_exp, exp_table)
            axes[0, 0].set_title(f"exp(x/{EXP_INPUT_SCALE}) * {EXP_OUTPUT_SCALE}")
            axes[0, 0].set_xlabel("Input (INT8)")
            axes[0, 0].set_ylabel("Output (UINT16)")
            axes[0, 0].grid(True)

            # Recip
            axes[0, 1].plot(range(1, 256), recip_table[1:])
            axes[0, 1].set_title(f"{RECIP_SCALE}/x")
            axes[0, 1].set_xlabel("Input x")
            axes[0, 1].set_ylabel("Output (UINT16)")
            axes[0, 1].grid(True)

            # Rsqrt
            axes[1, 0].plot(range(1, 256), rsqrt_table[1:])
            axes[1, 0].set_title(f"{RSQRT_SCALE}/sqrt(x)")
            axes[1, 0].set_xlabel("Input x")
            axes[1, 0].set_ylabel("Output (UINT16)")
            axes[1, 0].grid(True)

            # GELU
            x_gelu = [i if i < 128 else i - 256 for i in range(256)]
            axes[1, 1].plot(x_gelu, gelu_table)
            axes[1, 1].set_title(f"GELU(x/{GELU_INPUT_SCALE}) * {GELU_OUTPUT_SCALE} + {GELU_OUTPUT_SCALE//2}")
            axes[1, 1].set_xlabel("Input (INT8)")
            axes[1, 1].set_ylabel("Output (UINT16)")
            axes[1, 1].grid(True)

            plt.tight_layout()
            plt.savefig("generated/lut_tables.png", dpi=150)
            print(f"Generated: generated/lut_tables.png")
        except ImportError:
            print("Note: matplotlib not available, skipping plots")

    print("\n" + "=" * 60)
    print("Generation complete!")
    print("=" * 60)

    return 0


def generate_mem_file(exp_table, recip_table, rsqrt_table, gelu_table, output_path):
    """Generate combined .mem file for $readmemh (Vivado BRAM inference)."""
    # Combined table: func_sel[1:0] || index[7:0] = 10-bit address
    # func_sel: 0=exp, 1=recip, 2=rsqrt, 3=gelu

    with open(output_path, 'w') as f:
        f.write("// LUT ROM Memory File - AUTO-GENERATED\n")
        f.write("// Format: 1024 x 16-bit hex values\n")
        f.write("// Address = {func_sel[1:0], index[7:0]}\n")
        f.write("// Run: python3 scripts/gen_lut_tables.py\n\n")

        # Write tables in order: exp (0x000-0x0FF), recip (0x100-0x1FF),
        #                        rsqrt (0x200-0x2FF), gelu (0x300-0x3FF)
        for table, name in [(exp_table, "EXP"), (recip_table, "RECIP"),
                            (rsqrt_table, "RSQRT"), (gelu_table, "GELU")]:
            f.write(f"// {name} table (256 entries)\n")
            for i, val in enumerate(table):
                f.write(f"{val:04X}\n")

    print(f"Generated: {output_path}")


if __name__ == "__main__":
    sys.exit(main())
