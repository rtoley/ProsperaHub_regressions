#!/usr/bin/env python3
"""
Hyperplane VPU - RVV Compliance Test Generator (Industry Standard)

Generates SystemVerilog tests using actual RISC-V Vector instruction encodings.
Tests are directly traceable to the RVV 1.0 specification.

Instruction Format Reference (RVV 1.0):
  [31:26] funct6
  [25]    vm (0=masked, 1=unmasked)
  [24:20] vs2
  [19:15] vs1/rs1/imm5
  [14:12] funct3 (000=OPIVV, 011=OPIVI, 100=OPIVX, 010=OPMVV, 110=OPMVX)
  [11:7]  vd/rd
  [6:0]   opcode (1010111 = VECTOR)

Usage: python3 gen_compliance_tests.py <toml_dir> <output_file>
"""

import sys
import os
import json
import tomllib
from pathlib import Path

#=============================================================================
# RVV Instruction Encoding Tables (from RVV 1.0 Spec)
#=============================================================================

# Vector opcode
OP_V = 0b1010111

# funct3 encodings
F3_OPIVV = 0b000  # Vector-vector (integer)
F3_OPIVI = 0b011  # Vector-immediate (integer)
F3_OPIVX = 0b100  # Vector-scalar (integer)
F3_OPMVV = 0b010  # Vector-vector (multiply/reduction)
F3_OPMVX = 0b110  # Vector-scalar (multiply)
F3_OPCFG = 0b111  # Configuration

# funct6 encodings (from RVV 1.0 spec Table)
FUNCT6 = {
    # Integer arithmetic
    'vadd':    0b000000,
    'vsub':    0b000010,
    'vrsub':   0b000011,
    # Logical
    'vand':    0b001001,
    'vor':     0b001010,
    'vxor':    0b001011,
    # Shift
    'vsll':    0b100101,
    'vsrl':    0b101000,
    'vsra':    0b101001,
    # Min/Max
    'vminu':   0b000100,
    'vmin':    0b000101,
    'vmaxu':   0b000110,
    'vmax':    0b000111,
    # Compare (result to mask)
    'vmseq':   0b011000,
    'vmsne':   0b011001,
    'vmsltu':  0b011010,
    'vmslt':   0b011011,
    'vmsleu':  0b011100,
    'vmsle':   0b011101,
    'vmsgtu':  0b011110,
    'vmsgt':   0b011111,
    # Integer multiply (OPMVV/OPMVX)
    'vmul':    0b100101,
    'vmulh':   0b100111,
    'vmulhu':  0b100100,
    'vmulhsu': 0b100110,
    # Integer multiply-add (OPMVV/OPMVX)
    'vmacc':   0b101101,
    'vnmsac':  0b101111,
    'vmadd':   0b101001,
    'vnmsub':  0b101011,
    # Widening multiply
    'vwmul':   0b111011,
    'vwmulu':  0b111000,
    'vwmulsu': 0b111010,
    # Widening add/sub
    'vwadd':   0b110001,
    'vwaddu':  0b110000,
    'vwsub':   0b110011,
    'vwsubu':  0b110010,
    # Widening MAC
    'vwmacc':  0b111101,
    'vwmaccu': 0b111100,
    'vwmaccsu':0b111111,
    # Reduction operations
    'vredsum': 0b000000,
    'vredand': 0b000001,
    'vredor':  0b000010,
    'vredxor': 0b000011,
    'vredminu':0b000100,
    'vredmin': 0b000101,
    'vredmaxu':0b000110,
    'vredmax': 0b000111,
    # Mask operations
    'vmand':   0b011001,
    'vmnand':  0b011101,
    'vmandn':  0b011000,
    'vmxor':   0b011011,
    'vmor':    0b011010,
    'vmnor':   0b011110,
    'vmorn':   0b011100,
    'vmxnor':  0b011111,
    # Permutation
    'vrgather':0b001100,
    'vslideup':0b001110,
    'vslidedown':0b001111,
    # Narrowing
    'vnsrl':   0b101100,
    'vnsra':   0b101101,
    # Fixed-point
    'vsaddu':  0b100000,
    'vsadd':   0b100001,
    'vssubu':  0b100010,
    'vssub':   0b100011,
    'vssrl':   0b101010,
    'vssra':   0b101011,
    'vnclipu': 0b101110,
    'vnclip':  0b101111,
    # Move
    'vmv':     0b010111,  # vmv.v.v, vmv.v.x, vmv.v.i
}

# Instruction format classification
OPIVV_OPS = ['vadd', 'vsub', 'vand', 'vor', 'vxor', 'vsll', 'vsrl', 'vsra',
             'vminu', 'vmin', 'vmaxu', 'vmax', 'vmseq', 'vmsne', 'vmsltu',
             'vmslt', 'vmsleu', 'vmsle', 'vrgather']

OPIVX_OPS = ['vadd', 'vsub', 'vrsub', 'vand', 'vor', 'vxor', 'vsll', 'vsrl', 'vsra',
             'vminu', 'vmin', 'vmaxu', 'vmax', 'vmseq', 'vmsne', 'vmsltu',
             'vmslt', 'vmsleu', 'vmsle', 'vmsgtu', 'vmsgt', 'vslideup', 'vslidedown']

OPIVI_OPS = ['vadd', 'vrsub', 'vand', 'vor', 'vxor', 'vsll', 'vsrl', 'vsra',
             'vmseq', 'vmsne', 'vmsleu', 'vmsle', 'vmsgtu', 'vmsgt']

OPMVV_OPS = ['vmul', 'vmulh', 'vmulhu', 'vmulhsu', 'vmacc', 'vnmsac', 'vmadd', 'vnmsub',
             'vwmul', 'vwmulu', 'vwmulsu',  # Widening MUL uses OPMVV
             'vwmacc', 'vwmaccu', 'vwmaccsu',  # Widening MAC uses OPMVV
             'vredsum', 'vredand', 'vredor', 'vredxor', 'vredminu', 'vredmin', 'vredmaxu', 'vredmax']
# NOTE: vwadd, vwaddu, vwsub, vwsubu use OPIVV (funct3=000), NOT OPMVV!

OPMVX_OPS = ['vmul', 'vmulh', 'vmulhu', 'vmulhsu', 'vmacc', 'vnmsac', 'vmadd', 'vnmsub']

MASK_OPS = ['vmand', 'vmnand', 'vmandn', 'vmxor', 'vmor', 'vmnor', 'vmorn', 'vmxnor']

# Compare ops produce mask output
COMPARE_OPS = ['vmseq', 'vmsne', 'vmsltu', 'vmslt', 'vmsleu', 'vmsle', 'vmsgtu', 'vmsgt']

# MAC ops read vd as input
MAC_OPS = ['vmacc', 'vnmsac', 'vmadd', 'vnmsub', 'vwmacc', 'vwmaccu', 'vwmaccsu']

# Reduction ops produce scalar result in element 0
REDUCTION_OPS = ['vredsum', 'vredand', 'vredor', 'vredxor', 'vredminu', 'vredmin', 'vredmaxu', 'vredmax']

# Widening ops produce 2*SEW result from SEW inputs
WIDENING_OPS = ['vwmul', 'vwmulu', 'vwmulsu', 'vwadd', 'vwaddu', 'vwsub', 'vwsubu']

# Widening MAC ops (vd is 2*SEW accumulator, inputs are SEW)
WIDENING_MAC_OPS = ['vwmacc', 'vwmaccu', 'vwmaccsu']

# Narrowing ops produce SEW result from 2*SEW input
NARROWING_OPS = ['vnsrl', 'vnsra']

#=============================================================================
# Instruction Encoding Functions
#=============================================================================

def encode_vv(funct6, vd, vs2, vs1, vm=1):
    """Encode OPIVV format instruction."""
    return (funct6 << 26) | (vm << 25) | (vs2 << 20) | (vs1 << 15) | (F3_OPIVV << 12) | (vd << 7) | OP_V

def encode_vx(funct6, vd, vs2, rs1, vm=1):
    """Encode OPIVX format instruction."""
    return (funct6 << 26) | (vm << 25) | (vs2 << 20) | (rs1 << 15) | (F3_OPIVX << 12) | (vd << 7) | OP_V

def encode_vi(funct6, vd, vs2, imm5, vm=1):
    """Encode OPIVI format instruction."""
    imm5 = imm5 & 0x1F  # 5-bit immediate
    return (funct6 << 26) | (vm << 25) | (vs2 << 20) | (imm5 << 15) | (F3_OPIVI << 12) | (vd << 7) | OP_V

def encode_mvv(funct6, vd, vs2, vs1, vm=1):
    """Encode OPMVV format instruction (multiply, MAC, reduction)."""
    return (funct6 << 26) | (vm << 25) | (vs2 << 20) | (vs1 << 15) | (F3_OPMVV << 12) | (vd << 7) | OP_V

def encode_mvx(funct6, vd, vs2, rs1, vm=1):
    """Encode OPMVX format instruction."""
    return (funct6 << 26) | (vm << 25) | (vs2 << 20) | (rs1 << 15) | (F3_OPMVX << 12) | (vd << 7) | OP_V

def encode_instruction(op_name, vd, vs2, vs1_or_rs1_or_imm, vm=1):
    """
    Encode a complete RVV instruction based on operation name.
    Returns (encoding, comment) tuple.
    """
    # Parse operation name: e.g., "vadd.vv" -> base="vadd", fmt="vv"
    parts = op_name.split('.')
    base = parts[0]
    fmt = parts[1] if len(parts) > 1 else 'vv'

    if base not in FUNCT6:
        raise ValueError(f"Unknown instruction: {op_name}")

    funct6 = FUNCT6[base]

    # Determine encoding based on format
    if fmt == 'vv':
        if base in OPMVV_OPS:
            enc = encode_mvv(funct6, vd, vs2, vs1_or_rs1_or_imm, vm)
        else:
            enc = encode_vv(funct6, vd, vs2, vs1_or_rs1_or_imm, vm)
    elif fmt == 'vx':
        if base in OPMVX_OPS:
            enc = encode_mvx(funct6, vd, vs2, vs1_or_rs1_or_imm, vm)
        else:
            enc = encode_vx(funct6, vd, vs2, vs1_or_rs1_or_imm, vm)
    elif fmt == 'vi':
        enc = encode_vi(funct6, vd, vs2, vs1_or_rs1_or_imm, vm)
    elif fmt == 'mm':
        # Mask-mask operations use OPMVV encoding
        enc = encode_mvv(funct6, vd, vs2, vs1_or_rs1_or_imm, vm)
    elif fmt == 'vs':
        # Reduction operations: vredsum.vs etc
        enc = encode_mvv(funct6, vd, vs2, vs1_or_rs1_or_imm, vm)
    elif fmt == 'wv':
        # Narrowing operations with vector shift: vnsrl.wv, vnsra.wv
        # Use OPIVV encoding (funct3 = 000)
        enc = encode_vv(funct6, vd, vs2, vs1_or_rs1_or_imm, vm)
    elif fmt == 'wi':
        # Narrowing operations with immediate shift: vnsrl.wi, vnsra.wi
        # Use OPIVI encoding (funct3 = 011)
        enc = encode_vi(funct6, vd, vs2, vs1_or_rs1_or_imm, vm)
    else:
        raise ValueError(f"Unknown format: {fmt}")

    # Generate comment with instruction disassembly
    if fmt == 'vi' or fmt == 'wi':
        comment = f"{op_name} v{vd}, v{vs2}, {vs1_or_rs1_or_imm}"
    elif fmt == 'vx':
        comment = f"{op_name} v{vd}, v{vs2}, x{vs1_or_rs1_or_imm}"
    elif fmt == 'vs':
        comment = f"{op_name} v{vd}, v{vs2}, v{vs1_or_rs1_or_imm}"
    elif fmt == 'wv':
        comment = f"{op_name} v{vd}, v{vs2}, v{vs1_or_rs1_or_imm}"
    else:
        comment = f"{op_name} v{vd}, v{vs2}, v{vs1_or_rs1_or_imm}"

    return enc, comment

#=============================================================================
# Test Vector Generation
#=============================================================================

def to_signed(val, bits):
    """Convert unsigned to signed."""
    if val >= (1 << (bits - 1)):
        return val - (1 << bits)
    return val

def to_unsigned(val, bits):
    """Convert signed to unsigned."""
    return val & ((1 << bits) - 1)

def compute_result(op_name, vs2, vs1, vd_old, sew):
    """Compute expected result for a single element."""
    mask = (1 << sew) - 1
    vs2 = vs2 & mask
    vs1 = vs1 & mask
    vd_old = vd_old & mask

    # Signed versions
    vs2_s = to_signed(vs2, sew)
    vs1_s = to_signed(vs1, sew)
    vd_old_s = to_signed(vd_old, sew)

    base = op_name.split('.')[0]

    if base == 'vadd':
        return (vs2 + vs1) & mask
    elif base == 'vsub':
        return (vs2 - vs1) & mask
    elif base == 'vrsub':
        return (vs1 - vs2) & mask
    elif base == 'vand':
        return vs2 & vs1
    elif base == 'vor':
        return vs2 | vs1
    elif base == 'vxor':
        return vs2 ^ vs1
    elif base == 'vsll':
        shift = vs1 & (sew - 1)
        return (vs2 << shift) & mask
    elif base == 'vsrl':
        shift = vs1 & (sew - 1)
        return vs2 >> shift
    elif base == 'vsra':
        shift = vs1 & (sew - 1)
        return to_unsigned(vs2_s >> shift, sew)
    elif base == 'vmin':
        return to_unsigned(min(vs2_s, vs1_s), sew)
    elif base == 'vmax':
        return to_unsigned(max(vs2_s, vs1_s), sew)
    elif base == 'vminu':
        return min(vs2, vs1)
    elif base == 'vmaxu':
        return max(vs2, vs1)
    elif base == 'vmul':
        return (vs2_s * vs1_s) & mask
    elif base == 'vmulh':
        prod = vs2_s * vs1_s
        return to_unsigned(prod >> sew, sew)
    elif base == 'vmulhu':
        prod = vs2 * vs1
        return (prod >> sew) & mask
    elif base == 'vmulhsu':
        prod = vs2_s * vs1  # vs2 signed, vs1 unsigned
        return to_unsigned(prod >> sew, sew)
    elif base == 'vmacc':
        prod = (vs1_s * vs2_s) & mask
        return (vd_old + prod) & mask
    elif base == 'vnmsac':
        prod = (vs1_s * vs2_s) & mask
        return (vd_old - prod) & mask
    elif base == 'vmadd':
        prod = (vs1_s * vd_old_s) & mask
        return (prod + vs2) & mask
    elif base == 'vnmsub':
        prod = (vs1_s * vd_old_s) & mask
        return (vs2 - prod) & mask
    elif base == 'vmseq':
        return 1 if vs2 == vs1 else 0
    elif base == 'vmsne':
        return 1 if vs2 != vs1 else 0
    elif base == 'vmslt':
        return 1 if vs2_s < vs1_s else 0
    elif base == 'vmsltu':
        return 1 if vs2 < vs1 else 0
    elif base == 'vmsle':
        return 1 if vs2_s <= vs1_s else 0
    elif base == 'vmsleu':
        return 1 if vs2 <= vs1 else 0
    elif base == 'vmsgt':
        return 1 if vs2_s > vs1_s else 0
    elif base == 'vmsgtu':
        return 1 if vs2 > vs1 else 0
    # Mask-register logic
    elif base == 'vmand':
        return vs2 & vs1
    elif base == 'vmnand':
        return ~(vs2 & vs1) & mask
    elif base == 'vmandn':
        return vs2 & (~vs1 & mask)
    elif base == 'vmxor':
        return vs2 ^ vs1
    elif base == 'vmor':
        return vs2 | vs1
    elif base == 'vmnor':
        return ~(vs2 | vs1) & mask
    elif base == 'vmorn':
        return vs2 | (~vs1 & mask)
    elif base == 'vmxnor':
        return ~(vs2 ^ vs1) & mask
    # Widening operations (result is 2*SEW)
    elif base == 'vwmul':
        # Signed widening multiply
        return to_unsigned(vs2_s * vs1_s, sew * 2)
    elif base == 'vwmulu':
        # Unsigned widening multiply
        return (vs2 * vs1) & ((1 << (sew * 2)) - 1)
    elif base == 'vwmulsu':
        # Signed*unsigned widening multiply
        return to_unsigned(vs2_s * vs1, sew * 2)
    elif base == 'vwadd':
        # Signed widening add
        return to_unsigned(vs2_s + vs1_s, sew * 2)
    elif base == 'vwaddu':
        # Unsigned widening add
        return (vs2 + vs1) & ((1 << (sew * 2)) - 1)
    elif base == 'vwsub':
        # Signed widening subtract
        return to_unsigned(vs2_s - vs1_s, sew * 2)
    elif base == 'vwsubu':
        # Unsigned widening subtract
        return (vs2 - vs1) & ((1 << (sew * 2)) - 1)
    # Widening MAC (vd_old is 2*SEW, inputs are SEW)
    elif base == 'vwmacc':
        prod = vs1_s * vs2_s
        mask_2sew = (1 << (sew * 2)) - 1
        return (vd_old + prod) & mask_2sew
    elif base == 'vwmaccu':
        prod = vs1 * vs2
        mask_2sew = (1 << (sew * 2)) - 1
        return (vd_old + prod) & mask_2sew
    elif base == 'vwmaccsu':
        prod = vs1_s * vs2  # vs1 signed, vs2 unsigned
        mask_2sew = (1 << (sew * 2)) - 1
        return (vd_old + prod) & mask_2sew
    # Narrowing operations (input is 2*SEW, output is SEW)
    elif base == 'vnsrl':
        # vs2 is 2*SEW wide, shift by vs1 (SEW), produce SEW result
        shift = vs1 & ((sew * 2) - 1)
        return (vs2 >> shift) & mask
    elif base == 'vnsra':
        # vs2 is 2*SEW wide (signed), shift right arithmetic, produce SEW result
        vs2_2sew_s = to_signed(vs2, sew * 2)
        shift = vs1 & ((sew * 2) - 1)
        return to_unsigned(vs2_2sew_s >> shift, sew) & mask
    else:
        raise ValueError(f"No compute_result for: {op_name}")

def parse_value(v):
    """Parse a value that might be int or hex string."""
    if isinstance(v, str):
        return int(v, 16) if v.startswith('0x') else int(v)
    return v

#=============================================================================
# SystemVerilog Test Generation
#=============================================================================

def generate_test_task(op_name, test_id, sew, vs2_val, vs1_val):
    """
    Generate a single compliance test task with industry-standard encoding.

    Uses actual RVV instruction encodings and DLEN-parameterized vectors.
    """
    base = op_name.split('.')[0]
    fmt = op_name.split('.')[1] if '.' in op_name else 'vv'
    is_mac = base in MAC_OPS
    is_cmp = base in COMPARE_OPS
    is_imm = (fmt == 'vi' or fmt == 'wi')  # Immediate format
    is_scalar = (fmt == 'vx')  # Scalar format
    is_reduction = base in REDUCTION_OPS
    is_widening = base in WIDENING_OPS or base in WIDENING_MAC_OPS
    is_narrowing = base in NARROWING_OPS
    is_widening_mac = base in WIDENING_MAC_OPS

    vs2_val = parse_value(vs2_val)
    vs1_val = parse_value(vs1_val)

    # Register allocation
    vd = 3
    vs2 = 2
    vs1 = 1  # Used for .vv format
    rs1 = 1  # Used for .vx format (scalar in x1)
    vd_old_val = 0x5A  # Known pattern for MAC

    # For immediate format, use actual immediate value in encoding
    # For scalar format, use rs1 register number (scalar passed via rs1_i port)
    if is_imm:
        # Immediate is sign-extended 5-bit, take lower 5 bits
        imm5 = vs1_val & 0x1F
        enc, asm_comment = encode_instruction(op_name, vd, vs2, imm5, vm=1)
    else:
        enc, asm_comment = encode_instruction(op_name, vd, vs2, vs1, vm=1)

    # Task name
    safe_name = op_name.replace('.', '_')
    task_name = f"test_{safe_name}_sew{sew}_{test_id:03d}"

    # vsetvli vtypei encoding: vsew in bits [5:3], vlmul in bits [2:0]
    # SEW=8 -> vsew=000, SEW=16 -> vsew=001, SEW=32 -> vsew=010
    vsew_enc = {8: 0, 16: 1, 32: 2}[sew]
    vtypei = (vsew_enc << 3) | 0  # LMUL=1 (000)

    # vsetvli x0, x0, vtypei  (rd=0, rs1=0 means set vl=vlmax)
    # Encoding: imm[10:0] | rs1 | 111 | rd | 1010111
    vsetvli_enc = (vtypei << 20) | (0 << 15) | (0b111 << 12) | (0 << 7) | 0b1010111

    # Build SystemVerilog task
    lines = []
    lines.append(f"  task automatic {task_name};")
    if is_reduction:
        lines.append(f"    // {op_name} SEW={sew}: vs2_elem=0x{vs2_val:x}, vs1_scalar=0x{vs1_val:x}")
    elif is_imm:
        lines.append(f"    // {op_name} SEW={sew}: vs2=0x{vs2_val:x}, imm={vs1_val & 0x1F}")
    elif is_scalar:
        lines.append(f"    // {op_name} SEW={sew}: vs2=0x{vs2_val:x}, rs1=0x{vs1_val:x}")
    else:
        lines.append(f"    // {op_name} SEW={sew}: vs2=0x{vs2_val:x}, vs1=0x{vs1_val:x}")
    lines.append(f"    // Encoding: 0x{enc:08x} = {asm_comment}")
    lines.append(f"    begin")

    # For widening operations, we need VL that fits output in DLEN
    # Output is 2*SEW, so VL_max = DLEN/(2*SEW) = VLEN/(2*SEW) for DLEN=VLEN
    # For VLEN=256: SEW=8 → VL=16, SEW=16 → VL=8
    if is_widening or is_widening_mac:
        # Use set_vtype to properly configure VL for widening output
        sew_code = {8: 0, 16: 1, 32: 2}[sew]
        # VL = VLEN/(2*SEW) = 256/(2*sew) for widening
        vl_for_widening = 256 // (2 * sew)
        lines.append(f"      // Widening: set VL={vl_for_widening} so output (2*SEW={2*sew}) fits in DLEN")
        lines.append(f"      set_vtype(3'b{sew_code:03b}, 3'b000, {vl_for_widening});  // SEW={sew}, LMUL=1, VL={vl_for_widening}")
    else:
        # Issue vsetvli to configure SEW (industry-standard approach)
        lines.append(f"      // Configure: vsetvli x0, x0, e{sew},m1 (vtypei=0x{vtypei:03x})")
        lines.append(f"      issue(32'h{vsetvli_enc:08x});  // vsetvli x0, x0, e{sew}")
        lines.append(f"      wait_done(100);")

    # Write source registers based on format and operation type
    if is_reduction:
        # Reduction: vs2 has replicated elements, vs1[0] is the scalar accumulator
        lines.append(f"      vrf_write(5'd{vs2}, replicate_{sew}(DLEN, {sew}'h{vs2_val:x}));  // All elements same")
        lines.append(f"      vrf_write(5'd{vs1}, replicate_{sew}(DLEN, {sew}'h{vs1_val:x}));  // vs1[0] = scalar init")
        # Initialize vd with FF pattern to verify only element 0 is modified
        lines.append(f"      vrf_write(5'd{vd}, {{DLEN{{1'b1}}}});  // Init vd to all-1s")
    elif is_narrowing:
        # Narrowing: vs2 is 2*SEW wide, vs1 provides shift amount
        lines.append(f"      vrf_write(5'd{vs2}, replicate_{sew*2}(DLEN, {sew*2}'h{vs2_val:x}));  // 2*SEW input")
        lines.append(f"      vrf_write(5'd{vs1}, replicate_{sew}(DLEN, {sew}'h{vs1_val:x}));  // shift amount")
    elif is_imm:
        # Immediate format: only write vs2, immediate is in instruction
        lines.append(f"      vrf_write(5'd{vs2}, replicate_{sew}(DLEN, {sew}'h{vs2_val:x}));")
    elif is_scalar:
        # Scalar format: write vs2, scalar passed via rs1_i port
        lines.append(f"      vrf_write(5'd{vs2}, replicate_{sew}(DLEN, {sew}'h{vs2_val:x}));")
        # Scalar value needs sign-extension to 32 bits
    else:
        # Vector-vector format: write both vs1 and vs2
        lines.append(f"      vrf_write(5'd{vs1}, replicate_{sew}(DLEN, {sew}'h{vs1_val:x}));")
        lines.append(f"      vrf_write(5'd{vs2}, replicate_{sew}(DLEN, {sew}'h{vs2_val:x}));")

    if is_mac and not is_widening_mac:
        lines.append(f"      vrf_write(5'd{vd}, replicate_{sew}(DLEN, {sew}'h{vd_old_val:x}));  // vd accumulator")
    elif is_widening_mac:
        # Widening MAC: vd accumulator is 2*SEW wide
        lines.append(f"      vrf_write(5'd{vd}, replicate_{sew*2}(DLEN, {sew*2}'h{vd_old_val:x}));  // vd 2*SEW accumulator")

    # Issue instruction with actual encoding
    if is_scalar:
        # Sign-extend scalar value to 32 bits based on SEW
        scalar_val = vs1_val & ((1 << sew) - 1)  # Mask to SEW bits
        if scalar_val & (1 << (sew - 1)):  # Check sign bit
            # Sign extend to 32 bits
            scalar_32 = scalar_val | (0xFFFFFFFF ^ ((1 << sew) - 1))
        else:
            scalar_32 = scalar_val
        scalar_32 = scalar_32 & 0xFFFFFFFF  # Ensure 32-bit
        lines.append(f"      issue(32'h{enc:08x}, 32'h{scalar_32:08x});  // {asm_comment}, rs1=0x{vs1_val:x} (sign-ext)")
    else:
        lines.append(f"      issue(32'h{enc:08x});  // {asm_comment}")
    lines.append(f"      wait_done(100);")

    # Compute expected result based on operation type
    mask = (1 << sew) - 1

    if is_reduction:
        # Compute reduction result
        # For replicated elements, the reduction produces a known result
        result = compute_reduction_scalar(base, vs2_val, vs1_val, sew)
        # Check only element 0 with SEW-aware masking (upper bits preserved as all-1s)
        lines.append(f"      // Reduction: check element 0 only (SEW={sew})")
        lines.append(f"      check_vrf_elem0_sew(5'd{vd}, {sew}, {sew}'h{result:x}, \"{task_name}\");")
    elif is_narrowing:
        # Compute narrowing result
        if is_imm:
            shift = vs1_val & 0x1F
        else:
            shift = vs1_val & ((sew * 2) - 1)
        result = compute_result(op_name, vs2_val, shift, 0, sew)
        lines.append(f"      check_vrf(5'd{vd}, replicate_{sew}(DLEN, {sew}'h{result:x}), \"{task_name}\");")
    elif is_widening:
        # Widening result is 2*SEW
        if is_widening_mac:
            result = compute_result(op_name, vs2_val, vs1_val, vd_old_val, sew)
        else:
            result = compute_result(op_name, vs2_val, vs1_val, 0, sew)
        result_2sew = result & ((1 << (sew * 2)) - 1)
        lines.append(f"      check_vrf(5'd{vd}, replicate_{sew*2}(DLEN, {sew*2}'h{result_2sew:x}), \"{task_name}\");")
    elif is_cmp:
        # Compare produces mask - compute mask bits
        lines.append(f"      // Compare result: mask bit per element")
        compute_vs1 = vs1_val
        if is_imm:
            imm5 = vs1_val & 0x1F
            if imm5 & 0x10:
                compute_vs1 = imm5 | (((1 << sew) - 1) ^ 0x1F)
            else:
                compute_vs1 = imm5
        result = compute_result(op_name, vs2_val, compute_vs1, 0, sew)
        if result:
            lines.append(f"      check_vrf_mask(5'd{vd}, {{(VLEN/{sew}){{1'b1}}}}, \"{task_name}\");")
        else:
            lines.append(f"      check_vrf_mask(5'd{vd}, {{(VLEN/{sew}){{1'b0}}}}, \"{task_name}\");")
    else:
        # Standard element-wise operation
        if is_imm:
            imm5 = vs1_val & 0x1F
            if imm5 & 0x10:
                compute_vs1 = imm5 | (((1 << sew) - 1) ^ 0x1F)
            else:
                compute_vs1 = imm5
        else:
            compute_vs1 = vs1_val
        vd_old = vd_old_val if is_mac else 0
        result = compute_result(op_name, vs2_val, compute_vs1, vd_old, sew)
        lines.append(f"      check_vrf(5'd{vd}, replicate_{sew}(DLEN, {sew}'h{result:x}), \"{task_name}\");")

    lines.append(f"    end")
    lines.append(f"  endtask")

    return '\n'.join(lines), task_name

def compute_reduction_scalar(base, vs2_elem, vs1_scalar, sew):
    """
    Compute the result of a reduction operation where all vs2 elements are the same.
    This is used for compliance testing with replicated element vectors.

    Per RVV 1.0 Spec (Section 14.3):
    All reduction operations use vs1[0] as the initial scalar accumulator.
    Result = op(vs1[0], reduce_op(vs2[*]))

    NOTE: Current hardware has a BUG - vredand/vredor/vredxor ignore vs1[0].
    See docs/BUG_REDUCTION_VS1_IGNORED.md for details.
    These tests will FAIL until RTL is fixed. This is intentional.
    """
    mask = (1 << sew) - 1
    vs2 = vs2_elem & mask
    vs1 = vs1_scalar & mask
    vs2_s = to_signed(vs2, sew)
    vs1_s = to_signed(vs1, sew)

    # VLMAX for VLEN=256
    n = 256 // sew

    if base == 'vredsum':
        # vd[0] = vs1[0] + sum(vs2[*])
        return (vs1 + n * vs2) & mask
    elif base == 'vredand':
        # vd[0] = vs1[0] & and(vs2[*])
        # and(N identical values) = the value
        return vs1 & vs2
    elif base == 'vredor':
        # vd[0] = vs1[0] | or(vs2[*])
        # or(N identical values) = the value
        return vs1 | vs2
    elif base == 'vredxor':
        # vd[0] = vs1[0] ^ xor(vs2[*])
        # xor(N identical values) = value if N odd, 0 if N even
        xor_result = vs2 if (n % 2 == 1) else 0
        return vs1 ^ xor_result
    elif base == 'vredmax':
        # vd[0] = max(vs1[0], max(vs2[*])) - signed
        return to_unsigned(max(vs1_s, vs2_s), sew)
    elif base == 'vredmin':
        # vd[0] = min(vs1[0], min(vs2[*])) - signed
        return to_unsigned(min(vs1_s, vs2_s), sew)
    elif base == 'vredmaxu':
        # vd[0] = maxu(vs1[0], maxu(vs2[*])) - unsigned
        return max(vs1, vs2)
    elif base == 'vredminu':
        # vd[0] = minu(vs1[0], minu(vs2[*])) - unsigned
        return min(vs1, vs2)
    else:
        raise ValueError(f"Unknown reduction: {base}")

def process_toml(toml_path):
    """Process a single TOML file and generate tests."""
    with open(toml_path, 'rb') as f:
        config = tomllib.load(f)

    op_name = config['name']
    base = op_name.split('.')[0]

    # Check if we support this instruction's encoding
    if base not in FUNCT6:
        print(f"  Skipping {op_name} (encoding not defined)")
        return [], []

    tests = config.get('tests', {})

    tasks = []
    task_names = []
    test_id = 0

    # Process each SEW (skip SEW=64, we only support up to 32)
    for sew_key, sew_val in [('sew8', 8), ('sew16', 16), ('sew32', 32)]:
        test_vectors = tests.get(sew_key, [])
        for vec in test_vectors[:5]:  # Limit to 5 tests per SEW
            if len(vec) >= 2:
                try:
                    task_code, task_name = generate_test_task(
                        op_name, test_id, sew_val, vec[0], vec[1]
                    )
                    tasks.append(task_code)
                    task_names.append(task_name)
                    test_id += 1
                except Exception as e:
                    print(f"  Warning: {op_name} test {test_id}: {e}")

    # Also use base tests for SEW=8
    base_tests = tests.get('base', [])
    for vec in base_tests[:3]:
        if len(vec) >= 2:
            try:
                task_code, task_name = generate_test_task(
                    op_name, test_id, 8, vec[0], vec[1]
                )
                tasks.append(task_code)
                task_names.append(task_name)
                test_id += 1
            except Exception as e:
                print(f"  Warning: {op_name} base test {test_id}: {e}")

    return tasks, task_names

def generate_helper_functions():
    """
    Helper functions are now in the main testbench (hp_vpu_tb.sv).
    This function returns just a comment for documentation.
    """
    return '''
  //--------------------------------------------------------------------------
  // NOTE: Helper functions (replicate_8/16/32, check_vrf_mask) are defined
  // in the main testbench hp_vpu_tb.sv
  //--------------------------------------------------------------------------
'''

#=============================================================================
# Stress Test Generation
#=============================================================================

import random

# Instruction pool for stress testing (mix all pipeline types)
STRESS_OPS_NORMAL = [
    ('vadd.vv', 'vv'), ('vsub.vv', 'vv'), ('vand.vv', 'vv'), ('vor.vv', 'vv'),
    ('vxor.vv', 'vv'), ('vsll.vv', 'vv'), ('vsra.vv', 'vv'),
    ('vmul.vv', 'vv'), ('vmacc.vv', 'vv'),
]
STRESS_OPS_REDUCTION = [
    ('vredsum.vs', 'vs'), ('vredmax.vs', 'vs'), ('vredmin.vs', 'vs'),
    ('vredand.vs', 'vs'), ('vredor.vs', 'vs'), ('vredxor.vs', 'vs'),
]
STRESS_OPS_WIDENING = [
    ('vwmulu.vv', 'vv'), ('vwmul.vv', 'vv'), ('vwadd.vv', 'vv'), ('vwaddu.vv', 'vv'),
]
STRESS_OPS_NARROWING = [
    ('vnsrl.wv', 'wv'), ('vnsra.wv', 'wv'),
]

def compute_reduction_result(op_name, vs2_elements, vs1_scalar, sew):
    """Compute reduction result: fold vs2 elements with vs1 scalar."""
    base = op_name.split('.')[0]
    mask = (1 << sew) - 1

    if base == 'vredsum':
        acc = vs1_scalar & mask
        for elem in vs2_elements:
            acc = (acc + elem) & mask
        return acc
    elif base == 'vredand':
        acc = vs1_scalar & mask
        for elem in vs2_elements:
            acc = acc & elem
        return acc
    elif base == 'vredor':
        acc = vs1_scalar & mask
        for elem in vs2_elements:
            acc = acc | elem
        return acc
    elif base == 'vredxor':
        acc = vs1_scalar & mask
        for elem in vs2_elements:
            acc = acc ^ elem
        return acc
    elif base == 'vredmax':
        acc = to_signed(vs1_scalar & mask, sew)
        for elem in vs2_elements:
            acc = max(acc, to_signed(elem, sew))
        return to_unsigned(acc, sew)
    elif base == 'vredmin':
        acc = to_signed(vs1_scalar & mask, sew)
        for elem in vs2_elements:
            acc = min(acc, to_signed(elem, sew))
        return to_unsigned(acc, sew)
    elif base == 'vredmaxu':
        acc = vs1_scalar & mask
        for elem in vs2_elements:
            acc = max(acc, elem)
        return acc
    elif base == 'vredminu':
        acc = vs1_scalar & mask
        for elem in vs2_elements:
            acc = min(acc, elem)
        return acc
    else:
        raise ValueError(f"Unknown reduction: {op_name}")

def generate_stress_test(num_instructions, seed, sew=8, vlen=256):
    """
    Generate a stress test with randomized instructions mixing all pipeline types.

    Returns SystemVerilog code for a stress test task that:
    1. Initializes VRF with random data
    2. Issues num_instructions back-to-back (no wait_done)
    3. Computes expected final VRF state via golden model
    4. Verifies final state after pipeline drains
    """
    random.seed(seed)

    nlanes = vlen // 64
    dlen = nlanes * 64
    num_elems = vlen // sew
    mask = (1 << sew) - 1

    # VRF state simulation (32 registers, each VLEN bits)
    vrf = {}
    for i in range(32):
        # Initialize with deterministic random data
        vrf[i] = [random.randint(0, mask) for _ in range(num_elems)]

    # Build instruction list with proper encodings
    all_ops = STRESS_OPS_NORMAL + STRESS_OPS_REDUCTION + STRESS_OPS_WIDENING
    # Skip narrowing for now as it requires 2*SEW input setup

    lines = []
    lines.append(f"  task automatic stress_test_{num_instructions}_{seed};")
    lines.append(f"    // Stress test: {num_instructions} instructions, seed={seed}, SEW={sew}")
    lines.append(f"    logic [31:0] instr;")
    lines.append(f"    begin")

    # vsetvli configuration
    vsew_enc = {8: 0, 16: 1, 32: 2}[sew]
    vtypei = (vsew_enc << 3) | 0  # LMUL=1
    vsetvli_enc = (vtypei << 20) | (0 << 15) | (0b111 << 12) | (0 << 7) | 0b1010111
    lines.append(f"      $display(\"[STRESS] Starting {num_instructions} instructions, seed={seed}\");")
    lines.append(f"      issue(32'h{vsetvli_enc:08x});  // vsetvli x0, x0, e{sew},m1")
    lines.append(f"      wait_done(100);")
    lines.append(f"")

    # Initialize VRF
    lines.append(f"      // Initialize VRF with deterministic random data")
    for vreg in range(1, 16):  # Use v1-v15 (avoid v0 for masking)
        data_hex = ''.join([f'{vrf[vreg][i]:02x}' for i in range(num_elems-1, -1, -1)])
        lines.append(f"      vrf_write(5'd{vreg}, {dlen}'h{data_hex});")
    lines.append(f"")

    # Generate instructions
    lines.append(f"      // Issue {num_instructions} instructions back-to-back")
    instructions_issued = []

    for i in range(num_instructions):
        op_name, fmt = random.choice(all_ops)
        base = op_name.split('.')[0]

        # Select registers avoiding hazards (simple allocation)
        # For stress test, we want hazards - that's the point!
        vd = random.randint(1, 15)
        vs2 = random.randint(1, 15)
        vs1 = random.randint(1, 15)

        # Encode and compute result based on operation type
        funct6 = FUNCT6[base]
        vm = 1

        if base in REDUCTION_OPS:
            enc = encode_mvv(funct6, vd, vs2, vs1, vm)
            # Compute reduction result and update VRF model
            result = compute_reduction_result(op_name, vrf[vs2], vrf[vs1][0], sew)
            # Reduction only writes element 0, preserves rest
            vrf[vd] = vrf[vd].copy()
            vrf[vd][0] = result
        elif base in WIDENING_OPS:
            # Widening: result is 2*SEW, so we need even vd and write 2 regs
            # For simplicity, just compute element-wise and store lower SEW
            enc = encode_mvv(funct6, vd, vs2, vs1, vm)
            new_vrf = []
            for j in range(num_elems):
                r = compute_result(op_name, vrf[vs2][j], vrf[vs1][j], 0, sew)
                new_vrf.append(r & mask)  # Take lower SEW bits
            vrf[vd] = new_vrf
        elif base in MAC_OPS:
            enc = encode_mvv(funct6, vd, vs2, vs1, vm)
            new_vrf = []
            for j in range(num_elems):
                r = compute_result(op_name, vrf[vs2][j], vrf[vs1][j], vrf[vd][j], sew)
                new_vrf.append(r)
            vrf[vd] = new_vrf
        else:
            # Normal OPIVV or OPMVV operation
            if base in OPMVV_OPS:
                enc = encode_mvv(funct6, vd, vs2, vs1, vm)
            else:
                enc = encode_vv(funct6, vd, vs2, vs1, vm)
            new_vrf = []
            for j in range(num_elems):
                r = compute_result(op_name, vrf[vs2][j], vrf[vs1][j], 0, sew)
                new_vrf.append(r)
            vrf[vd] = new_vrf

        lines.append(f"      issue(32'h{enc:08x});  // {op_name} v{vd}, v{vs2}, v{vs1}")
        instructions_issued.append((op_name, vd, vs2, vs1))

    lines.append(f"")
    lines.append(f"      // Wait for pipeline to drain")
    lines.append(f"      wait_done(1000);")
    lines.append(f"")

    # Verify final VRF state
    lines.append(f"      // Verify final VRF state")
    for vreg in range(1, 16):
        data_hex = ''.join([f'{vrf[vreg][i]:02x}' for i in range(num_elems-1, -1, -1)])
        lines.append(f"      check_vrf(5'd{vreg}, {dlen}'h{data_hex}, \"stress_v{vreg}\");")

    lines.append(f"")
    lines.append(f"      $display(\"[STRESS] Completed {num_instructions} instructions\");")
    lines.append(f"    end")
    lines.append(f"  endtask")

    return '\n'.join(lines), f"stress_test_{num_instructions}_{seed}"

def generate_stress_tests_file(output_file, num_tests, instrs_per_test, base_seed):
    """Generate a file containing multiple stress tests."""

    all_tasks = []
    all_task_names = []

    print(f"Generating {num_tests} stress tests with {instrs_per_test} instructions each...")

    for i in range(num_tests):
        seed = base_seed + i
        task, name = generate_stress_test(instrs_per_test, seed)
        all_tasks.append(task)
        all_task_names.append(name)
        if (i + 1) % 10 == 0:
            print(f"  Generated {i + 1}/{num_tests} tests...")

    with open(output_file, 'w') as f:
        f.write("//============================================================================\n")
        f.write("// Hyperplane VPU - Stress Tests (AUTO-GENERATED)\n")
        f.write("//\n")
        f.write(f"// Tests: {num_tests} x {instrs_per_test} = {num_tests * instrs_per_test} total instructions\n")
        f.write(f"// Base seed: {base_seed}\n")
        f.write("// Mixes all pipeline types: normal, reduction, widening\n")
        f.write("//============================================================================\n\n")

        for task in all_tasks:
            f.write(task)
            f.write('\n\n')

        # Write runner task
        f.write("  //==========================================================================\n")
        f.write("  // Stress Test Runner\n")
        f.write("  //==========================================================================\n")
        f.write("  task automatic run_stress_tests;\n")
        f.write("    begin\n")
        f.write('      $display("");\n')
        f.write('      $display("========================================");\n')
        f.write(f'      $display("  STRESS TESTS ({num_tests} x {instrs_per_test} = {num_tests * instrs_per_test} instrs)");\n')
        f.write('      $display("========================================");\n')
        f.write('      $display("");\n')

        for name in all_task_names:
            f.write(f"      {name}();\n")

        f.write('      $display("");\n')
        f.write(f'      $display("Stress tests completed: {num_tests * instrs_per_test} instructions");\n')
        f.write("    end\n")
        f.write("  endtask\n")

    print(f"\nGenerated {num_tests} stress tests to {output_file}")
    print(f"Total instructions: {num_tests * instrs_per_test}")


def main():
    if len(sys.argv) < 3:
        print("Usage: python3 gen_compliance_tests.py <toml_dir> <output_file> [--stress N] [--seed S]")
        print("\nGenerates industry-standard RVV compliance tests with actual instruction encodings.")
        print("\nOptions:")
        print("  --stress N    Generate stress tests with N instructions each (generates 10 tests)")
        print("  --seed S      Base seed for stress test randomization (default: 42)")
        print("\nExamples:")
        print("  python3 gen_compliance_tests.py tests/toml generated/compliance_tests.sv")
        print("  python3 gen_compliance_tests.py tests/toml generated/stress_tests.sv --stress 1000")
        print("  python3 gen_compliance_tests.py tests/toml generated/stress_100k.sv --stress 10000 --seed 12345")
        sys.exit(1)

    toml_dir = Path(sys.argv[1])
    output_file = Path(sys.argv[2])

    # Parse optional arguments
    stress_mode = False
    stress_instrs = 1000
    base_seed = 42
    num_stress_tests = 10

    i = 3
    while i < len(sys.argv):
        if sys.argv[i] == '--stress':
            stress_mode = True
            if i + 1 < len(sys.argv):
                stress_instrs = int(sys.argv[i + 1])
                i += 1
        elif sys.argv[i] == '--seed':
            if i + 1 < len(sys.argv):
                base_seed = int(sys.argv[i + 1])
                i += 1
        elif sys.argv[i] == '--num':
            if i + 1 < len(sys.argv):
                num_stress_tests = int(sys.argv[i + 1])
                i += 1
        i += 1

    if stress_mode:
        generate_stress_tests_file(output_file, num_stress_tests, stress_instrs, base_seed)
        return

    all_tasks = []
    all_task_names = []
    processed_ops = []

    print(f"Processing TOML files from {toml_dir}...")

    # Process all TOML files
    for toml_file in sorted(toml_dir.glob('*.toml')):
        print(f"  {toml_file.name}...", end="")
        tasks, names = process_toml(toml_file)
        if tasks:
            all_tasks.extend(tasks)
            all_task_names.extend(names)
            processed_ops.append(toml_file.stem)
            print(f" {len(names)} tests")
        else:
            print(" skipped")

    # Generate output file
    with open(output_file, 'w') as f:
        f.write("//============================================================================\n")
        f.write("// Hyperplane VPU - RVV Compliance Tests (AUTO-GENERATED)\n")
        f.write("//\n")
        f.write("// Source: chipsalliance/riscv-vector-tests TOML test vectors\n")
        f.write("// Format: Industry-standard RVV 1.0 instruction encodings\n")
        f.write("//\n")
        f.write("// Instruction encoding reference (RVV 1.0 spec):\n")
        f.write("//   [31:26] funct6  [25] vm  [24:20] vs2  [19:15] vs1/rs1/imm\n")
        f.write("//   [14:12] funct3  [11:7] vd  [6:0] opcode=1010111\n")
        f.write("//\n")
        f.write(f"// Operations: {len(processed_ops)}\n")
        f.write(f"// Test cases: {len(all_task_names)}\n")
        f.write("//============================================================================\n")

        # Write helper functions
        f.write(generate_helper_functions())
        f.write("\n")

        # Write all test tasks
        for task in all_tasks:
            f.write(task)
            f.write('\n\n')

        # Write runner task
        f.write("  //==========================================================================\n")
        f.write("  // Compliance Test Runner\n")
        f.write("  //==========================================================================\n")
        f.write("  task automatic run_compliance_tests;\n")
        f.write("    begin\n")
        f.write('      $display("");\n')
        f.write('      $display("========================================");\n')
        f.write('      $display("  RVV COMPLIANCE TESTS (%0d cases)", ' + str(len(all_task_names)) + ');\n')
        f.write('      $display("========================================");\n')
        f.write('      $display("");\n')

        for name in all_task_names:
            f.write(f"      {name}();\n")

        f.write('      $display("");\n')
        f.write('      $display("Compliance tests completed: %0d tests", ' + str(len(all_task_names)) + ');\n')
        f.write("    end\n")
        f.write("  endtask\n")

    print(f"\nGenerated {len(all_task_names)} compliance tests from {len(processed_ops)} operations")
    print(f"Output: {output_file}")
    print(f"Operations: {', '.join(processed_ops)}")
    print("\nInstruction encodings follow RVV 1.0 specification.")
    print("Tests are DLEN-parameterized and portable across configurations.")

if __name__ == '__main__':
    main()
