#!/bin/bash
#==============================================================================
# HP-VPU v0.3d - CSR and Issue Checker Test
# Tests the new CSR module and instruction acceptance logic
#==============================================================================

set -e
cd "$(dirname "$0")"

echo "=============================================="
echo "HP-VPU v0.3d CSR and Issue Checker Test"
echo "=============================================="

# Compile
echo "Compiling..."
iverilog -g2012 -DSIMULATION \
  -I generated \
  generated/hp_vpu_pkg.sv \
  rtl/hp_vpu_csr.sv \
  rtl/hp_vpu_issue_check.sv \
  tb/hp_vpu_csr_test.sv \
  -o sim/hp_vpu_csr_test.vvp

# Run
echo "Running test..."
vvp sim/hp_vpu_csr_test.vvp

echo ""
echo "Test complete."
