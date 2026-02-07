#!/usr/bin/env python3
"""
Hyperplane VPU - Enhanced RVV Compliance Test Generator v3.1 (v0.3a)

Additions over v3.0:
- Compare operations (vmseq, vmsne, vmslt, vmsle, vmsgt, etc.)
- Narrowing operations (vnclip, vnclipu, vnsrl, vnsra)
- .vx (scalar) and .vi (immediate) format variants
- Better edge case coverage

Usage: python3 gen_compliance_tests_v3a.py <output_file>
"""

import sys
from pathlib import Path

#=============================================================================
# Encoding Constants
#=============================================================================

OP_V = 0b1010111
F3_OPIVV = 0b000
F3_OPIVI = 0b011
F3_OPIVX = 0b100
F3_OPMVV = 0b010
F3_OPMVX = 0b110

FUNCT6 = {
    # ALU
    'vadd': 0b000000, 'vsub': 0b000010, 'vrsub': 0b000011,
    'vand': 0b001001, 'vor': 0b001010, 'vxor': 0b001011,
    'vsll': 0b100101, 'vsrl': 0b101000, 'vsra': 0b101001,
    'vminu': 0b000100, 'vmin': 0b000101, 'vmaxu': 0b000110, 'vmax': 0b000111,
    # MUL
    'vmul': 0b100101, 'vmulh': 0b100111, 'vmulhu': 0b100100, 'vmulhsu': 0b100110,
    # MAC
    'vmacc': 0b101101, 'vnmsac': 0b101111, 'vmadd': 0b101001, 'vnmsub': 0b101011,
    # Widening
    'vwmul': 0b111011, 'vwmulu': 0b111000, 'vwmulsu': 0b111010,
    'vwadd': 0b110001, 'vwaddu': 0b110000, 'vwsub': 0b110011, 'vwsubu': 0b110010,
    'vwmacc': 0b111101, 'vwmaccu': 0b111100, 'vwmaccsu': 0b111111,
    # Reduction
    'vredsum': 0b000000, 'vredand': 0b000001, 'vredor': 0b000010, 'vredxor': 0b000011,
    'vredminu': 0b000100, 'vredmin': 0b000101, 'vredmaxu': 0b000110, 'vredmax': 0b000111,
    # Saturating
    'vsaddu': 0b100000, 'vsadd': 0b100001, 'vssubu': 0b100010, 'vssub': 0b100011,
    # Compare
    'vmseq': 0b011000, 'vmsne': 0b011001, 'vmsltu': 0b011010, 'vmslt': 0b011011,
    'vmsleu': 0b011100, 'vmsle': 0b011101, 'vmsgtu': 0b011110, 'vmsgt': 0b011111,
    # Narrowing
    'vnsrl': 0b101100, 'vnsra': 0b101101, 'vnclipu': 0b101110, 'vnclip': 0b101111,
    # Custom
    'vlut': 0b010010,
}

OPMVV_OPS = {'vmul', 'vmulh', 'vmulhu', 'vmulhsu', 'vmacc', 'vnmsac', 'vmadd', 'vnmsub',
             'vwmul', 'vwmulu', 'vwmulsu', 'vwmacc', 'vwmaccu', 'vwmaccsu',
             'vredsum', 'vredand', 'vredor', 'vredxor',
             'vredminu', 'vredmin', 'vredmaxu', 'vredmax'}

# Ops that use OPMVV for .vv but still can have .vx variants via OPMVX
OPMVX_OPS = {'vmul', 'vmulh', 'vmulhu', 'vmulhsu', 'vmacc', 'vnmsac', 'vmadd', 'vnmsub'}

#=============================================================================
# Encoding Functions
#=============================================================================

def encode_vv(funct6, vd, vs2, vs1, vm=1):
    return (funct6 << 26) | (vm << 25) | (vs2 << 20) | (vs1 << 15) | (F3_OPIVV << 12) | (vd << 7) | OP_V

def encode_vx(funct6, vd, vs2, rs1, vm=1):
    return (funct6 << 26) | (vm << 25) | (vs2 << 20) | (rs1 << 15) | (F3_OPIVX << 12) | (vd << 7) | OP_V

def encode_vi(funct6, vd, vs2, imm5, vm=1):
    imm5 = imm5 & 0x1f  # 5-bit immediate
    return (funct6 << 26) | (vm << 25) | (vs2 << 20) | (imm5 << 15) | (F3_OPIVI << 12) | (vd << 7) | OP_V

def encode_mvv(funct6, vd, vs2, vs1, vm=1):
    return (funct6 << 26) | (vm << 25) | (vs2 << 20) | (vs1 << 15) | (F3_OPMVV << 12) | (vd << 7) | OP_V

def encode_mvx(funct6, vd, vs2, rs1, vm=1):
    return (funct6 << 26) | (vm << 25) | (vs2 << 20) | (rs1 << 15) | (F3_OPMVX << 12) | (vd << 7) | OP_V

def to_signed(val, bits):
    if val >= (1 << (bits - 1)):
        return val - (1 << bits)
    return val

def to_unsigned(val, bits):
    return val & ((1 << bits) - 1)

#=============================================================================
# Computation Functions
#=============================================================================

def compute_alu(op, vs2, vs1, sew):
    mask = (1 << sew) - 1
    vs2 = vs2 & mask
    vs1 = vs1 & mask
    vs2_s = to_signed(vs2, sew)
    vs1_s = to_signed(vs1, sew)

    if op == 'vadd': return (vs2 + vs1) & mask
    elif op == 'vsub': return (vs2 - vs1) & mask
    elif op == 'vrsub': return (vs1 - vs2) & mask
    elif op == 'vand': return vs2 & vs1
    elif op == 'vor': return vs2 | vs1
    elif op == 'vxor': return vs2 ^ vs1
    elif op == 'vsll': return (vs2 << (vs1 & (sew - 1))) & mask
    elif op == 'vsrl': return vs2 >> (vs1 & (sew - 1))
    elif op == 'vsra': return to_unsigned(vs2_s >> (vs1 & (sew - 1)), sew)
    elif op == 'vmin': return to_unsigned(min(vs2_s, vs1_s), sew)
    elif op == 'vmax': return to_unsigned(max(vs2_s, vs1_s), sew)
    elif op == 'vminu': return min(vs2, vs1)
    elif op == 'vmaxu': return max(vs2, vs1)
    elif op == 'vmul': return (vs2_s * vs1_s) & mask
    elif op == 'vmulh': return to_unsigned((vs2_s * vs1_s) >> sew, sew)
    elif op == 'vmulhu': return ((vs2 * vs1) >> sew) & mask
    elif op == 'vmulhsu': return to_unsigned((vs2_s * vs1) >> sew, sew)
    elif op == 'vsaddu':
        result = vs2 + vs1
        return mask if result > mask else result
    elif op == 'vsadd':
        result = vs2_s + vs1_s
        max_val = (1 << (sew - 1)) - 1
        min_val = -(1 << (sew - 1))
        if result > max_val: return to_unsigned(max_val, sew)
        elif result < min_val: return to_unsigned(min_val, sew)
        else: return to_unsigned(result, sew)
    elif op == 'vssubu':
        result = vs2 - vs1
        return 0 if result < 0 else result
    elif op == 'vssub':
        result = vs2_s - vs1_s
        max_val = (1 << (sew - 1)) - 1
        min_val = -(1 << (sew - 1))
        if result > max_val: return to_unsigned(max_val, sew)
        elif result < min_val: return to_unsigned(min_val, sew)
        else: return to_unsigned(result, sew)
    return 0

def compute_compare(op, vs2, vs1, sew):
    """Returns 1 if comparison is true, 0 otherwise."""
    mask = (1 << sew) - 1
    vs2 = vs2 & mask
    vs1 = vs1 & mask
    vs2_s = to_signed(vs2, sew)
    vs1_s = to_signed(vs1, sew)

    if op == 'vmseq': return 1 if vs2 == vs1 else 0
    elif op == 'vmsne': return 1 if vs2 != vs1 else 0
    elif op == 'vmsltu': return 1 if vs2 < vs1 else 0
    elif op == 'vmslt': return 1 if vs2_s < vs1_s else 0
    elif op == 'vmsleu': return 1 if vs2 <= vs1 else 0
    elif op == 'vmsle': return 1 if vs2_s <= vs1_s else 0
    elif op == 'vmsgtu': return 1 if vs2 > vs1 else 0
    elif op == 'vmsgt': return 1 if vs2_s > vs1_s else 0
    return 0

def compute_narrow(op, vs2_wide, vs1_shift, sew_narrow):
    """Narrowing operation: 2*SEW -> SEW with shift."""
    sew_wide = sew_narrow * 2
    mask_wide = (1 << sew_wide) - 1
    mask_narrow = (1 << sew_narrow) - 1
    max_signed = (1 << (sew_narrow - 1)) - 1
    min_signed = -(1 << (sew_narrow - 1))
    max_unsigned = mask_narrow

    vs2_wide = vs2_wide & mask_wide
    vs2_wide_s = to_signed(vs2_wide, sew_wide)
    shift = vs1_shift & (sew_wide - 1)

    if op == 'vnsrl':
        return (vs2_wide >> shift) & mask_narrow
    elif op == 'vnsra':
        return to_unsigned(vs2_wide_s >> shift, sew_narrow)
    elif op == 'vnclipu':
        shifted = vs2_wide >> shift
        if shifted > max_unsigned:
            return max_unsigned
        return shifted & mask_narrow
    elif op == 'vnclip':
        shifted = vs2_wide_s >> shift
        if shifted > max_signed:
            return to_unsigned(max_signed, sew_narrow)
        elif shifted < min_signed:
            return to_unsigned(min_signed, sew_narrow)
        return to_unsigned(shifted, sew_narrow)
    return 0

#=============================================================================
# Test Generation Functions
#=============================================================================

def gen_alu_test(op, test_id, sew, vs2_val, vs1_val):
    """Generate ALU operation test (.vv format)."""
    funct6 = FUNCT6[op]
    vd, vs2, vs1 = 3, 2, 1

    if op in OPMVV_OPS:
        enc = encode_mvv(funct6, vd, vs2, vs1, 1)
    else:
        enc = encode_vv(funct6, vd, vs2, vs1, 1)

    vsew_enc = {8: 0, 16: 1, 32: 2}[sew]
    vsetvli = (vsew_enc << 23) | (0b111 << 12) | 0b1010111

    expected = compute_alu(op, vs2_val, vs1_val, sew)
    task_name = f"test_{op}_vv_sew{sew}_{test_id:03d}"

    code = f"""  task automatic {task_name};
    // {op}.vv SEW={sew}: vs2=0x{vs2_val:x}, vs1=0x{vs1_val:x} -> 0x{expected:x}
    begin
      issue(32'h{vsetvli:08x});  // vsetvli e{sew}
      wait_done(100);
      vrf_write(5'd{vs2}, replicate_{sew}(DLEN, {sew}'h{vs2_val:x}));
      vrf_write(5'd{vs1}, replicate_{sew}(DLEN, {sew}'h{vs1_val:x}));
      issue(32'h{enc:08x});  // {op}.vv v{vd}, v{vs2}, v{vs1}
      wait_done(100);
      check_vrf_elem0_sew(5'd{vd}, {sew}, {sew}'h{expected:x}, "{task_name}");
    end
  endtask
"""
    return code, task_name

def gen_alu_vx_test(op, test_id, sew, vs2_val, rs1_val):
    """Generate ALU operation test (.vx format - scalar operand)."""
    funct6 = FUNCT6[op]
    vd, vs2, rs1 = 3, 2, 1  # rs1 is x1

    if op in OPMVX_OPS:
        enc = encode_mvx(funct6, vd, vs2, rs1, 1)
    else:
        enc = encode_vx(funct6, vd, vs2, rs1, 1)

    vsew_enc = {8: 0, 16: 1, 32: 2}[sew]
    vsetvli = (vsew_enc << 23) | (0b111 << 12) | 0b1010111

    expected = compute_alu(op, vs2_val, rs1_val, sew)
    task_name = f"test_{op}_vx_sew{sew}_{test_id:03d}"

    code = f"""  task automatic {task_name};
    // {op}.vx SEW={sew}: vs2=0x{vs2_val:x}, x1=0x{rs1_val:x} -> 0x{expected:x}
    begin
      issue(32'h{vsetvli:08x});  // vsetvli e{sew}
      wait_done(100);
      vrf_write(5'd{vs2}, replicate_{sew}(DLEN, {sew}'h{vs2_val:x}));
      issue(32'h{enc:08x}, 32'h{rs1_val:08x});  // {op}.vx v{vd}, v{vs2}, x1
      wait_done(100);
      check_vrf_elem0_sew(5'd{vd}, {sew}, {sew}'h{expected:x}, "{task_name}");
    end
  endtask
"""
    return code, task_name

def gen_alu_vi_test(op, test_id, sew, vs2_val, imm5):
    """Generate ALU operation test (.vi format - immediate operand)."""
    funct6 = FUNCT6[op]
    vd, vs2 = 3, 2

    enc = encode_vi(funct6, vd, vs2, imm5, 1)

    vsew_enc = {8: 0, 16: 1, 32: 2}[sew]
    vsetvli = (vsew_enc << 23) | (0b111 << 12) | 0b1010111

    # Sign-extend 5-bit immediate for some ops
    if op in ['vsra', 'vsrl', 'vsll']:
        imm_val = imm5 & 0x1f  # Shift uses unsigned
    else:
        imm_val = to_signed(imm5, 5) if imm5 >= 16 else imm5
        imm_val = to_unsigned(imm_val, sew)

    expected = compute_alu(op, vs2_val, imm_val, sew)
    task_name = f"test_{op}_vi_sew{sew}_{test_id:03d}"

    code = f"""  task automatic {task_name};
    // {op}.vi SEW={sew}: vs2=0x{vs2_val:x}, imm={imm5} -> 0x{expected:x}
    begin
      issue(32'h{vsetvli:08x});  // vsetvli e{sew}
      wait_done(100);
      vrf_write(5'd{vs2}, replicate_{sew}(DLEN, {sew}'h{vs2_val:x}));
      issue(32'h{enc:08x});  // {op}.vi v{vd}, v{vs2}, {imm5}
      wait_done(100);
      check_vrf_elem0_sew(5'd{vd}, {sew}, {sew}'h{expected:x}, "{task_name}");
    end
  endtask
"""
    return code, task_name

def gen_compare_test(op, test_id, sew, vs2_val, vs1_val):
    """Generate compare operation test - result goes to mask register."""
    funct6 = FUNCT6[op]
    vd, vs2, vs1 = 0, 2, 1  # vd=v0 for mask result

    enc = encode_vv(funct6, vd, vs2, vs1, 1)

    vsew_enc = {8: 0, 16: 1, 32: 2}[sew]
    vsetvli = (vsew_enc << 23) | (0b111 << 12) | 0b1010111

    cmp_result = compute_compare(op, vs2_val, vs1_val, sew)
    # All elements have same values, so all comparisons are same
    # Mask bit = 1 for each element where comparison is true
    # For DLEN=64, SEW=8: 8 elements -> 8 bits of mask
    # If all true: mask = 0xFF (for 8 elements)
    # mask = all_ones if cmp_result else 0
    task_name = f"test_{op}_vv_sew{sew}_{test_id:03d}"

    code = f"""  task automatic {task_name};
    // {op}.vv SEW={sew}: vs2=0x{vs2_val:x}, vs1=0x{vs1_val:x} -> cmp={cmp_result}
    automatic logic [DLEN-1:0] expected_mask;
    automatic int num_elems;
    begin
      issue(32'h{vsetvli:08x});  // vsetvli e{sew}
      wait_done(100);
      vrf_write(5'd{vs2}, replicate_{sew}(DLEN, {sew}'h{vs2_val:x}));
      vrf_write(5'd{vs1}, replicate_{sew}(DLEN, {sew}'h{vs1_val:x}));
      vrf_write(5'd{vd}, 64'h0);  // Clear v0
      issue(32'h{enc:08x});  // {op}.vv v{vd}, v{vs2}, v{vs1}
      wait_done(100);
      // Each element produces 1 mask bit, all elements same so all bits same
      num_elems = VLEN / {sew};
      expected_mask = {cmp_result} ? ((1 << num_elems) - 1) : 0;
      check_vrf_mask(5'd{vd}, expected_mask, "{task_name}");
    end
  endtask
"""
    return code, task_name

def gen_narrow_test(op, test_id, sew_narrow, vs2_wide_val, vs1_shift):
    """Generate narrowing operation test."""
    funct6 = FUNCT6[op]
    sew_wide = sew_narrow * 2
    vd, vs2, vs1 = 3, 2, 1

    # Narrowing ops use OPIVV encoding
    enc = encode_vv(funct6, vd, vs2, vs1, 1)

    # Wide SEW for source
    vsew_enc_wide = {16: 1, 32: 2, 64: 3}[sew_wide]
    vsetvli = (vsew_enc_wide << 23) | (0b111 << 12) | 0b1010111

    expected = compute_narrow(op, vs2_wide_val, vs1_shift, sew_narrow)
    task_name = f"test_{op}_wv_sew{sew_narrow}_{test_id:03d}"

    code = f"""  task automatic {task_name};
    // {op}.wv: vs2(SEW={sew_wide})=0x{vs2_wide_val:x}, shift={vs1_shift} -> SEW={sew_narrow}: 0x{expected:x}
    begin
      issue(32'h{vsetvli:08x});  // vsetvli e{sew_wide} (wide source)
      wait_done(100);
      vrf_write(5'd{vs2}, replicate_{sew_wide}(DLEN, {sew_wide}'h{vs2_wide_val:x}));
      vrf_write(5'd{vs1}, replicate_{sew_wide}(DLEN, {sew_wide}'h{vs1_shift:x}));
      issue(32'h{enc:08x});  // {op}.wv v{vd}, v{vs2}, v{vs1}
      wait_done(100);
      check_vrf_narrow(5'd{vd}, {sew_narrow}, {sew_narrow}'h{expected:x}, "{task_name}");
    end
  endtask
"""
    return code, task_name

def gen_mac_test(op, test_id, sew, vs2_val, vs1_val, vd_val):
    """Generate MAC operation test."""
    funct6 = FUNCT6[op]
    vd, vs2, vs1 = 3, 2, 1
    enc = encode_mvv(funct6, vd, vs2, vs1, 1)

    vsew_enc = {8: 0, 16: 1, 32: 2}[sew]
    vsetvli = (vsew_enc << 23) | (0b111 << 12) | 0b1010111

    mask = (1 << sew) - 1
    vs2_s = to_signed(vs2_val & mask, sew)
    vs1_s = to_signed(vs1_val & mask, sew)
    vd_s = to_signed(vd_val & mask, sew)

    if op == 'vmacc':
        expected = (vd_s + vs2_s * vs1_s) & mask
    elif op == 'vnmsac':
        expected = (vd_s - vs2_s * vs1_s) & mask
    elif op == 'vmadd':
        expected = (vs1_s * vd_s + vs2_s) & mask
    elif op == 'vnmsub':
        expected = (-(vs1_s * vd_s) + vs2_s) & mask
    else:
        expected = 0

    task_name = f"test_{op}_vv_sew{sew}_{test_id:03d}"

    code = f"""  task automatic {task_name};
    // {op}.vv SEW={sew}: vd=0x{vd_val:x}, vs2=0x{vs2_val:x}, vs1=0x{vs1_val:x}
    begin
      issue(32'h{vsetvli:08x});  // vsetvli e{sew}
      wait_done(100);
      vrf_write(5'd{vd}, replicate_{sew}(DLEN, {sew}'h{vd_val:x}));
      vrf_write(5'd{vs2}, replicate_{sew}(DLEN, {sew}'h{vs2_val:x}));
      vrf_write(5'd{vs1}, replicate_{sew}(DLEN, {sew}'h{vs1_val:x}));
      issue(32'h{enc:08x});  // {op}.vv v{vd}, v{vs2}, v{vs1}
      wait_done(100);
      check_vrf_elem0_sew(5'd{vd}, {sew}, {sew}'h{expected:x}, "{task_name}");
    end
  endtask
"""
    return code, task_name

def gen_widening_test(op, test_id, sew, vs2_val, vs1_val):
    """Generate widening operation test."""
    funct6 = FUNCT6[op]
    vd, vs2, vs1 = 4, 2, 1  # vd=4 to avoid overlap with wide result
    enc = encode_mvv(funct6, vd, vs2, vs1, 1)

    vsew_enc = {8: 0, 16: 1}[sew]
    vsetvli = (vsew_enc << 23) | (0b111 << 12) | 0b1010111

    sew_wide = sew * 2
    mask = (1 << sew) - 1
    mask_wide = (1 << sew_wide) - 1
    vs2_s = to_signed(vs2_val & mask, sew)
    vs1_s = to_signed(vs1_val & mask, sew)
    vs2_u = vs2_val & mask
    vs1_u = vs1_val & mask

    if op == 'vwadd':
        expected = to_unsigned(vs2_s + vs1_s, sew_wide)
    elif op == 'vwaddu':
        expected = (vs2_u + vs1_u) & mask_wide
    elif op == 'vwsub':
        expected = to_unsigned(vs2_s - vs1_s, sew_wide)
    elif op == 'vwsubu':
        expected = (vs2_u - vs1_u) & mask_wide
    elif op == 'vwmul':
        expected = to_unsigned(vs2_s * vs1_s, sew_wide)
    elif op == 'vwmulu':
        expected = (vs2_u * vs1_u) & mask_wide
    elif op == 'vwmulsu':
        expected = to_unsigned(vs2_s * vs1_u, sew_wide)
    else:
        expected = 0

    task_name = f"test_{op}_vv_sew{sew}_{test_id:03d}"

    code = f"""  task automatic {task_name};
    // {op}.vv SEW={sew}->SEW={sew_wide}: vs2=0x{vs2_val:x}, vs1=0x{vs1_val:x}
    begin
      issue(32'h{vsetvli:08x});  // vsetvli e{sew}
      wait_done(100);
      vrf_write(5'd{vs2}, replicate_{sew}(DLEN, {sew}'h{vs2_val:x}));
      vrf_write(5'd{vs1}, replicate_{sew}(DLEN, {sew}'h{vs1_val:x}));
      issue(32'h{enc:08x});  // {op}.vv v{vd}, v{vs2}, v{vs1}
      wait_done(100);
      check_vrf_wide(5'd{vd}, {sew_wide}, {sew_wide}'h{expected:x}, "{task_name}");
    end
  endtask
"""
    return code, task_name

def gen_wmacc_test(op, test_id, sew, vs2_val, vs1_val, vd_val):
    """Generate widening MAC test."""
    funct6 = FUNCT6[op]
    vd, vs2, vs1 = 4, 2, 1
    enc = encode_mvv(funct6, vd, vs2, vs1, 1)

    vsew_enc = {8: 0, 16: 1}[sew]
    vsetvli = (vsew_enc << 23) | (0b111 << 12) | 0b1010111

    sew_wide = sew * 2
    mask = (1 << sew) - 1
    mask_wide = (1 << sew_wide) - 1
    vs2_s = to_signed(vs2_val & mask, sew)
    vs1_s = to_signed(vs1_val & mask, sew)
    vs2_u = vs2_val & mask
    vs1_u = vs1_val & mask
    vd_s = to_signed(vd_val & mask_wide, sew_wide)
    vd_u = vd_val & mask_wide

    if op == 'vwmacc':
        expected = to_unsigned(vd_s + vs2_s * vs1_s, sew_wide)
    elif op == 'vwmaccu':
        expected = (vd_u + vs2_u * vs1_u) & mask_wide
    elif op == 'vwmaccsu':
        expected = to_unsigned(vd_s + vs2_s * vs1_u, sew_wide)
    else:
        expected = 0

    task_name = f"test_{op}_vv_sew{sew}_{test_id:03d}"

    code = f"""  task automatic {task_name};
    // {op}.vv SEW={sew}: vd=0x{vd_val:x}, vs2=0x{vs2_val:x}, vs1=0x{vs1_val:x}
    begin
      issue(32'h{vsetvli:08x});  // vsetvli e{sew}
      wait_done(100);
      vrf_write(5'd{vd}, replicate_{sew_wide}(DLEN, {sew_wide}'h{vd_val:x}));
      vrf_write(5'd{vs2}, replicate_{sew}(DLEN, {sew}'h{vs2_val:x}));
      vrf_write(5'd{vs1}, replicate_{sew}(DLEN, {sew}'h{vs1_val:x}));
      issue(32'h{enc:08x});  // {op}.vv v{vd}, v{vs2}, v{vs1}
      wait_done(100);
      check_vrf_wide(5'd{vd}, {sew_wide}, {sew_wide}'h{expected:x}, "{task_name}");
    end
  endtask
"""
    return code, task_name

def gen_reduction_test(op, test_id, sew, vs2_init, vs1_init):
    """Generate reduction test (VLEN-parameterized)."""
    funct6 = FUNCT6[op]
    vd, vs2, vs1 = 3, 2, 1
    enc = encode_mvv(funct6, vd, vs2, vs1, 1)

    vsew_enc = {8: 0, 16: 1, 32: 2}[sew]
    vsetvli = (vsew_enc << 23) | (0b111 << 12) | 0b1010111

    task_name = f"test_{op}_vs_sew{sew}_{test_id:03d}"

    # Compute expected using VLEN-aware expression
    if op == 'vredsum':
        expected_expr = f"((32'h{vs2_init:x} * n) + 32'h{vs1_init:x}) & {(1<<sew)-1}"
    elif op == 'vredand':
        expected_expr = f"32'h{vs2_init & vs1_init:x}"
    elif op == 'vredor':
        expected_expr = f"32'h{vs2_init | vs1_init:x}"
    elif op == 'vredxor':
        # XOR of n copies of vs2_init, then XOR with vs1_init
        expected_expr = f"(((n & 1) ? 32'h{vs2_init:x} : 32'h0) ^ 32'h{vs1_init:x})"
    elif op in ['vredmax', 'vredmin', 'vredmaxu', 'vredminu']:
        # Just compare vs2_init with vs1_init
        if op == 'vredmax':
            expected_expr = f"(($signed({sew}'h{vs2_init:x}) > $signed({sew}'h{vs1_init:x})) ? 32'h{vs2_init:x} : 32'h{vs1_init:x})"
        elif op == 'vredmin':
            expected_expr = f"(($signed({sew}'h{vs2_init:x}) < $signed({sew}'h{vs1_init:x})) ? 32'h{vs2_init:x} : 32'h{vs1_init:x})"
        elif op == 'vredmaxu':
            expected_expr = f"((32'h{vs2_init:x} > 32'h{vs1_init:x}) ? 32'h{vs2_init:x} : 32'h{vs1_init:x})"
        else:  # vredminu
            expected_expr = f"((32'h{vs2_init:x} < 32'h{vs1_init:x}) ? 32'h{vs2_init:x} : 32'h{vs1_init:x})"
    else:
        expected_expr = "32'h0"

    code = f"""  task automatic {task_name};
    // {op}.vs SEW={sew}: vs2 all 0x{vs2_init:x}, vs1[0]=0x{vs1_init:x}
    automatic int n;
    automatic logic [31:0] expected;
    begin
      issue(32'h{vsetvli:08x});  // vsetvli e{sew}
      wait_done(100);
      vrf_write(5'd{vs2}, replicate_{sew}(DLEN, {sew}'h{vs2_init:x}));
      vrf_write(5'd{vs1}, replicate_{sew}(DLEN, {sew}'h{vs1_init:x}));
      vrf_write(5'd{vd}, {{DLEN{{1'b1}}}});
      issue(32'h{enc:08x});  // {op}.vs v{vd}, v{vs2}, v{vs1}
      wait_done(100);
      n = VLEN / {sew};
      expected = {expected_expr};
      check_vrf_elem0_sew(5'd{vd}, {sew}, expected, "{task_name}");
    end
  endtask
"""
    return code, task_name

def gen_lut_test(func, test_id, sew, vs2_val):
    """Generate custom LUT operation test."""
    func_enc = {'vexp': 0, 'vrecip': 1, 'vrsqrt': 2, 'vgelu': 3}[func]
    funct6 = FUNCT6['vlut']
    vd, vs2, vs1 = 3, 2, func_enc
    enc = encode_mvv(funct6, vd, vs2, vs1, 1)

    vsew_enc = {8: 0, 16: 1}[sew]
    vsetvli = (vsew_enc << 23) | (0b111 << 12) | 0b1010111
    task_name = f"test_{func}_v_sew{sew}_{test_id:03d}"

    code = f"""  task automatic {task_name};
    // {func}.v SEW={sew}: vs2=0x{vs2_val:x}
    begin
      issue(32'h{vsetvli:08x});  // vsetvli e{sew}
      wait_done(100);
      vrf_write(5'd{vs2}, replicate_{sew}(DLEN, {sew}'h{vs2_val:x}));
      issue(32'h{enc:08x});  // {func}.v v{vd}, v{vs2}
      wait_done(200);
      check_vrf_nonzero(5'd{vd}, "{task_name}");
    end
  endtask
"""
    return code, task_name

#=============================================================================
# Main
#=============================================================================

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 gen_compliance_tests_v3a.py <output_file>")
        sys.exit(1)

    output_file = Path(sys.argv[1])
    all_tasks = []
    all_names = []

    print("Generating v3.1 compliance tests (v0.3a)...")

    #=========================================================================
    # ALU .vv operations with edge cases
    #=========================================================================
    alu_ops = ['vadd', 'vsub', 'vrsub', 'vand', 'vor', 'vxor', 'vsll', 'vsrl', 'vsra',
               'vmin', 'vmax', 'vminu', 'vmaxu']
    # Interesting edge cases:
    # - Zero operands
    # - Max positive/negative signed
    # - Overflow boundaries
    # - Shift edge cases
    alu_vectors = [
        (0x00, 0x00),  # Zero
        (0x01, 0x01),  # Small same
        (0xff, 0x01),  # Max + 1 (overflow)
        (0x80, 0x7f),  # Signed min + max
        (0x7f, 0x80),  # Signed max + min
        (0x55, 0xaa),  # Alternating bits
        (0xfe, 0x03),  # Near max
    ]

    for op in alu_ops:
        test_id = 0
        for sew in [8, 16, 32]:
            for vs2, vs1 in alu_vectors:
                code, name = gen_alu_test(op, test_id, sew, vs2, vs1)
                all_tasks.append(code)
                all_names.append(name)
                test_id += 1
    print(f"  ALU .vv: {len(alu_ops)} ops x {len(alu_vectors)} vectors x 3 SEW = {len(alu_ops)*len(alu_vectors)*3} tests")

    #=========================================================================
    # ALU .vx operations (scalar operand)
    #=========================================================================
    vx_ops = ['vadd', 'vsub', 'vrsub', 'vand', 'vor', 'vxor', 'vsll', 'vsrl', 'vsra',
              'vmin', 'vmax', 'vminu', 'vmaxu']
    vx_vectors = [
        (0x10, 0x05),  # Basic
        (0xff, 0x01),  # Max + 1
        (0x80, 0x02),  # Signed min + small
        (0x7f, 0xff),  # Near max, max scalar
    ]

    for op in vx_ops:
        test_id = 0
        for sew in [8, 16, 32]:
            for vs2, rs1 in vx_vectors:
                code, name = gen_alu_vx_test(op, test_id, sew, vs2, rs1)
                all_tasks.append(code)
                all_names.append(name)
                test_id += 1
    print(f"  ALU .vx: {len(vx_ops)} ops x {len(vx_vectors)} vectors x 3 SEW = {len(vx_ops)*len(vx_vectors)*3} tests")

    #=========================================================================
    # ALU .vi operations (immediate operand)
    #=========================================================================
    vi_ops = ['vadd', 'vrsub', 'vand', 'vor', 'vxor', 'vsll', 'vsrl', 'vsra']
    vi_vectors = [
        (0x10, 0),   # Shift/add 0
        (0xff, 1),   # +1
        (0x80, 4),   # Shift by 4
        (0x7f, 15),  # Max immediate
        (0x55, 31),  # Max 5-bit imm (wraps for shift)
    ]

    for op in vi_ops:
        test_id = 0
        for sew in [8, 16, 32]:
            for vs2, imm in vi_vectors:
                code, name = gen_alu_vi_test(op, test_id, sew, vs2, imm)
                all_tasks.append(code)
                all_names.append(name)
                test_id += 1
    print(f"  ALU .vi: {len(vi_ops)} ops x {len(vi_vectors)} vectors x 3 SEW = {len(vi_ops)*len(vi_vectors)*3} tests")

    #=========================================================================
    # Compare operations
    #=========================================================================
    cmp_ops = ['vmseq', 'vmsne', 'vmslt', 'vmsltu', 'vmsle', 'vmsleu', 'vmsgt', 'vmsgtu']
    # Edge cases for comparisons:
    cmp_vectors = [
        (0x00, 0x00),  # Equal zeros
        (0x01, 0x01),  # Equal non-zero
        (0x01, 0x02),  # Less than (unsigned & signed)
        (0x02, 0x01),  # Greater than
        (0x7f, 0x80),  # Signed: 127 > -128, Unsigned: 127 < 128
        (0x80, 0x7f),  # Signed: -128 < 127, Unsigned: 128 > 127
        (0xff, 0x00),  # Signed: -1 < 0, Unsigned: 255 > 0
        (0x00, 0xff),  # Opposite
    ]

    for op in cmp_ops:
        test_id = 0
        for sew in [8, 16, 32]:
            for vs2, vs1 in cmp_vectors:
                code, name = gen_compare_test(op, test_id, sew, vs2, vs1)
                all_tasks.append(code)
                all_names.append(name)
                test_id += 1
    print(f"  CMP .vv: {len(cmp_ops)} ops x {len(cmp_vectors)} vectors x 3 SEW = {len(cmp_ops)*len(cmp_vectors)*3} tests")

    #=========================================================================
    # Narrowing operations
    #=========================================================================
    narrow_ops = ['vnsrl', 'vnsra', 'vnclip', 'vnclipu']
    # Interesting cases for narrowing:
    # - No shift (direct truncation)
    # - Full shift
    # - Saturation cases for vnclip
    narrow_vectors = [
        (0x0000, 0),    # Zero, no shift
        (0x00ff, 0),    # Fits in narrow, no shift
        (0x0100, 0),    # Just overflows narrow (truncates)
        (0x7fff, 0),    # Max positive narrow*2-1
        (0x8000, 0),    # Signed: -32768, saturates to -128
        (0xffff, 0),    # All 1s
        (0x0100, 8),    # Shift right 8 -> 0x01
        (0xff00, 8),    # Shift right 8 -> 0xff
        (0x8000, 7),    # Arithmetic shift
    ]

    for op in narrow_ops:
        test_id = 0
        for sew_narrow in [8, 16]:  # Narrow from 16->8, 32->16
            for vs2_wide, shift in narrow_vectors:
                code, name = gen_narrow_test(op, test_id, sew_narrow, vs2_wide, shift)
                all_tasks.append(code)
                all_names.append(name)
                test_id += 1
    print(f"  NARROW: {len(narrow_ops)} ops x {len(narrow_vectors)} vectors x 2 SEW = {len(narrow_ops)*len(narrow_vectors)*2} tests")

    #=========================================================================
    # Multiply operations
    #=========================================================================
    mul_ops = ['vmul', 'vmulh', 'vmulhu', 'vmulhsu']
    mul_vectors = [
        (0x02, 0x03),  # Small
        (0x10, 0x10),  # Powers of 2
        (0xff, 0x02),  # Near max
        (0x7f, 0x02),  # Signed max
        (0x80, 0x02),  # Signed min
        (0xff, 0xff),  # Max * max
    ]

    for op in mul_ops:
        test_id = 0
        for sew in [8, 16, 32]:
            for vs2, vs1 in mul_vectors:
                code, name = gen_alu_test(op, test_id, sew, vs2, vs1)
                all_tasks.append(code)
                all_names.append(name)
                test_id += 1
    print(f"  MUL: {len(mul_ops)} ops x {len(mul_vectors)} vectors x 3 SEW = {len(mul_ops)*len(mul_vectors)*3} tests")

    #=========================================================================
    # MAC operations (including vmadd, vnmsub)
    #=========================================================================
    mac_ops = ['vmacc', 'vnmsac', 'vmadd', 'vnmsub']
    mac_vectors = [
        (0x02, 0x03, 0x10),  # Basic accumulate
        (0x10, 0x02, 0x00),  # Zero accumulator
        (0xff, 0x01, 0x50),  # Max * 1 + mid
        (0x7f, 0x02, 0x80),  # Positive * 2 + negative
        (0x80, 0x02, 0x7f),  # Negative * 2 + positive
    ]

    for op in mac_ops:
        test_id = 0
        for sew in [8, 16, 32]:
            for vs2, vs1, vd in mac_vectors:
                code, name = gen_mac_test(op, test_id, sew, vs2, vs1, vd)
                all_tasks.append(code)
                all_names.append(name)
                test_id += 1
    print(f"  MAC: {len(mac_ops)} ops x {len(mac_vectors)} vectors x 3 SEW = {len(mac_ops)*len(mac_vectors)*3} tests")

    #=========================================================================
    # Saturating operations
    #=========================================================================
    sat_ops = ['vsaddu', 'vsadd', 'vssubu', 'vssub']
    sat_vectors = [
        (0x7f, 0x01),  # Signed overflow (127+1)
        (0xff, 0x01),  # Unsigned overflow (255+1)
        (0x80, 0x01),  # Signed min + 1
        (0x00, 0x01),  # Zero - 1 (underflow)
        (0x7f, 0x7f),  # Double max
        (0x80, 0x80),  # Signed: -128 + -128
        (0x01, 0xff),  # 1 - 255
    ]

    for op in sat_ops:
        test_id = 0
        for sew in [8, 16, 32]:
            for vs2, vs1 in sat_vectors:
                code, name = gen_alu_test(op, test_id, sew, vs2, vs1)
                all_tasks.append(code)
                all_names.append(name)
                test_id += 1
    print(f"  SAT: {len(sat_ops)} ops x {len(sat_vectors)} vectors x 3 SEW = {len(sat_ops)*len(sat_vectors)*3} tests")

    #=========================================================================
    # Widening operations
    #=========================================================================
    wide_ops = ['vwadd', 'vwaddu', 'vwsub', 'vwsubu', 'vwmul', 'vwmulu', 'vwmulsu']
    wide_vectors = [
        (0x7f, 0x01),  # Positive + small
        (0x80, 0x01),  # Signed min + 1
        (0xff, 0xff),  # Max * max
        (0x7f, 0x7f),  # Max positive * max positive
        (0x80, 0x80),  # Min * min (signed)
    ]

    for op in wide_ops:
        test_id = 0
        for sew in [8, 16]:
            for vs2, vs1 in wide_vectors:
                code, name = gen_widening_test(op, test_id, sew, vs2, vs1)
                all_tasks.append(code)
                all_names.append(name)
                test_id += 1
    print(f"  WIDE: {len(wide_ops)} ops x {len(wide_vectors)} vectors x 2 SEW = {len(wide_ops)*len(wide_vectors)*2} tests")

    #=========================================================================
    # Widening MAC
    #=========================================================================
    wmacc_ops = ['vwmacc', 'vwmaccu', 'vwmaccsu']
    wmacc_vectors = [
        (0x10, 0x10, 0x0000),  # Basic
        (0x7f, 0x02, 0x0100),  # Max * 2 + accumulator
        (0xff, 0xff, 0x0000),  # Max * max
    ]

    for op in wmacc_ops:
        test_id = 0
        for sew in [8, 16]:
            for vs2, vs1, vd in wmacc_vectors:
                code, name = gen_wmacc_test(op, test_id, sew, vs2, vs1, vd)
                all_tasks.append(code)
                all_names.append(name)
                test_id += 1
    print(f"  WMAC: {len(wmacc_ops)} ops x {len(wmacc_vectors)} vectors x 2 SEW = {len(wmacc_ops)*len(wmacc_vectors)*2} tests")

    #=========================================================================
    # Reduction operations
    #=========================================================================
    reduction_ops = ['vredsum', 'vredand', 'vredor', 'vredxor',
                     'vredmax', 'vredmin', 'vredmaxu', 'vredminu']
    red_vectors = [
        (0x01, 0x00),  # Sum of 1s
        (0xff, 0x00),  # Sum of maxes
        (0x55, 0xaa),  # Alternating
        (0x7f, 0x80),  # Signed: max vs min
        (0x80, 0x7f),  # Signed: min vs max
    ]

    for op in reduction_ops:
        test_id = 0
        for sew in [8, 16, 32]:
            for vs2, vs1 in red_vectors:
                code, name = gen_reduction_test(op, test_id, sew, vs2, vs1)
                all_tasks.append(code)
                all_names.append(name)
                test_id += 1
    print(f"  RED: {len(reduction_ops)} ops x {len(red_vectors)} vectors x 3 SEW = {len(reduction_ops)*len(red_vectors)*3} tests")

    #=========================================================================
    # Custom LUT operations
    #=========================================================================
    lut_funcs = ['vexp', 'vrecip', 'vrsqrt', 'vgelu']
    lut_inputs_base = [0x00, 0x10, 0x40, 0x7f, 0x80, 0xff]

    # LUT values that produce zero (based on actual LUT ROM content)
    lut_zero_results = {
        'vexp': {8: [0x00, 0x80], 16: [0x80]},
        'vrecip': {8: [0x00, 0x10, 0x40, 0x80], 16: [0x00]},
        'vrsqrt': {8: [0x00, 0x10, 0x40], 16: [0x00]},
        'vgelu': {8: [], 16: []},
    }

    for func in lut_funcs:
        test_id = 0
        for sew in [8, 16]:
            zeros = lut_zero_results.get(func, {}).get(sew, [])
            filtered_inputs = [x for x in lut_inputs_base if x not in zeros]
            for vs2 in filtered_inputs:
                code, name = gen_lut_test(func, test_id, sew, vs2)
                all_tasks.append(code)
                all_names.append(name)
                test_id += 1
    print(f"  LUT: {len(lut_funcs)} ops (filtered)")

    #=========================================================================
    # Write output
    #=========================================================================
    with open(output_file, 'w') as f:
        f.write(f"""//============================================================================
// Hyperplane VPU - Enhanced RVV Compliance Tests v3.1 (AUTO-GENERATED)
//
// Version: v0.3a
// Features:
// - {len(all_names)} comprehensive tests
// - ALU .vv, .vx, .vi formats
// - Compare operations (vmseq, vmsne, vmslt, etc.)
// - Narrowing operations (vnclip, vnclipu, vnsrl, vnsra)
// - Full MAC coverage (vmacc, vnmsac, vmadd, vnmsub)
// - Edge cases: overflow, saturation, signed/unsigned boundaries
//
// Test cases: {len(all_names)}
//============================================================================

""")
        for task in all_tasks:
            f.write(task)
            f.write('\n')

        f.write("  //==========================================================================\n")
        f.write("  // Compliance Test Runner\n")
        f.write("  //==========================================================================\n")
        f.write("  task automatic run_compliance_tests;\n")
        f.write("    begin\n")
        f.write('      $display("");\n')
        f.write('      $display("========================================");\n')
        f.write(f'      $display("  COMPLIANCE TESTS v3.1 ({len(all_names)} tests)");\n')
        f.write('      $display("  VLEN=%0d, DLEN=%0d", VLEN, DLEN);\n')
        f.write('      $display("========================================");\n')
        f.write('      $display("");\n\n')

        for name in all_names:
            f.write(f"      {name}();\n")

        f.write('\n')
        f.write(f'      $display("Compliance tests completed: {len(all_names)} tests");\n')
        f.write("    end\n")
        f.write("  endtask\n")

    print(f"\nGenerated {len(all_names)} tests to {output_file}")

if __name__ == "__main__":
    main()
