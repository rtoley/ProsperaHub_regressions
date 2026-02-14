#ifndef HP_VPU_PKG_H
#define HP_VPU_PKG_H

#include <systemc.h>
#include <iomanip>

namespace hp_vpu {

// Configuration Parameters
const int VLEN = 64;   // Default 64, can be changed
const int NLANES = 1;  // Default 1
const int ELEN = 32;
const int DLEN = NLANES * 64; // Data path width
const int NUM_REGS = 32;
const int CVXIF_ID_W = 8;
const bool ENABLE_VMADD = true;
const bool SPLIT_REDUCTION_PIPELINE = true;

// Opcodes (vpu_op_e)
enum vpu_op_e {
    OP_NOP = 0,
    // Arithmetic
    OP_VADD, OP_VSUB, OP_VRSUB,
    OP_VADC, OP_VMADC, OP_VSBC, OP_VMSBC,

    // Logic
    OP_VAND, OP_VOR, OP_VXOR,

    // Shift
    OP_VSLL, OP_VSRL, OP_VSRA,
    OP_VSSRL, OP_VSSRA,
    OP_VNSRL, OP_VNSRA,

    // Compare
    OP_VMSEQ, OP_VMSNE, OP_VMSLTU, OP_VMSLT, OP_VMSLEU, OP_VMSLE, OP_VMSGTU, OP_VMSGT,

    // Min/Max
    OP_VMINU, OP_VMIN, OP_VMAXU, OP_VMAX,

    // Multiply & MAC (Standard)
    OP_VMUL, OP_VMULH, OP_VMULHU, OP_VMULHSU,
    OP_VMACC, OP_VNMSAC, OP_VMADD, OP_VNMSUB,

    // Widening Ops (Contiguous Block)
    OP_VWMUL, OP_VWMULU, OP_VWMULSU,
    OP_VWMACC, OP_VWMACCU, OP_VWMACCSU,
    OP_VWADD, OP_VWADDU, OP_VWSUB, OP_VWSUBU,

    // Saturation
    OP_VSADDU, OP_VSADD, OP_VSSUBU, OP_VSSUB,

    // Narrowing Clip
    OP_VNCLIPU, OP_VNCLIP,

    // Move/Merge
    OP_VMV, OP_VMERGE,

    // Permutation
    OP_VRGATHER, OP_VRGATHEREI16,
    OP_VSLIDEUP, OP_VSLIDEDN,
    OP_VSLIDE1UP, OP_VSLIDE1DN,
    OP_VCOMPRESS,

    // Mask Logic
    OP_VMAND_MM, OP_VMNAND_MM, OP_VMANDN_MM, OP_VMXOR_MM,
    OP_VMOR_MM, OP_VMNOR_MM, OP_VMORN_MM, OP_VMXNOR_MM,

    // Mask Misc
    OP_VCPOP, OP_VFIRST, OP_VMSBF, OP_VMSIF, OP_VMSOF, OP_VIOTA, OP_VID,

    // Reductions
    OP_VREDSUM, OP_VREDAND, OP_VREDOR, OP_VREDXOR,
    OP_VREDMINU, OP_VREDMIN, OP_VREDMAXU, OP_VREDMAX,

    // Custom/LLM
    OP_VEXP, OP_VRECIP, OP_VRSQRT, OP_VGELU,
    OP_VPACK4, OP_VUNPACK4
};

// SEW (Standard Element Width)
enum sew_e {
    SEW_8  = 0,
    SEW_16 = 1,
    SEW_32 = 2,
    SEW_64 = 3
};

// LMUL
enum lmul_e {
    LMUL_1 = 0,
    LMUL_2 = 1,
    LMUL_4 = 2,
    LMUL_8 = 3,
    LMUL_F2 = 5,
    LMUL_F4 = 6,
    LMUL_F8 = 7
};

// Funct3 Constants
const int OPIVV = 0b000;
const int OPMVV = 0b010;
const int OPIVI = 0b011;
const int OPIVX = 0b100;
const int OPMVX = 0b110;
const int OPIVV_MASK = 0b000;

} // namespace hp_vpu

#endif // HP_VPU_PKG_H
