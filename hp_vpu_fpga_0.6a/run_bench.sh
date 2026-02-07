#!/bin/bash
#==============================================================================
# Hyperplane VPU - GEMV Inference Benchmark Runner
# Usage: ./run_bench.sh [64|128|256]
#==============================================================================
set -e

CONFIG=${1:-64}

echo "=============================================="
echo "  Hyperplane VPU GEMV Benchmark"
echo "  Config: VLEN=${CONFIG}"
echo "=============================================="

# Switch config
bash scripts/switch_config.sh ${CONFIG} --enable-csr

RTL="generated/hp_vpu_pkg.sv \
     rtl/hp_vpu_csr.sv \
     rtl/hp_vpu_issue_check.sv \
     rtl/hp_vpu_top.sv \
     rtl/hp_vpu_lanes.sv \
     rtl/hp_vpu_decode.sv \
     rtl/hp_vpu_hazard.sv \
     rtl/hp_vpu_iq.sv \
     rtl/hp_vpu_vrf.sv \
     rtl/hp_vpu_lut_rom.sv"

echo "[1/2] Compiling..."
iverilog -g2012 \
    -I rtl -I generated -I generated/tests -I tb \
    -o sim/bench_${CONFIG}.vvp \
    $RTL tb/hp_vpu_tb_bench.sv

echo "[2/2] Running benchmark..."
vvp sim/bench_${CONFIG}.vvp | tee results/bench_${CONFIG}.log

echo ""
echo "Results saved to: results/bench_${CONFIG}.log"
