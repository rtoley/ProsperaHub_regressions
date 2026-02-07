#!/bin/bash
# Run the standalone hazard pattern test
# Tests MAC/MUL vs non-MAC pipeline hazards at various distances

set -e

cd "$(dirname "$0")"

echo "=========================================="
echo "  Hazard Pattern Test"
echo "=========================================="

# Generate package if needed
if [ ! -f "generated/hp_vpu_pkg.sv" ]; then
    python3 scripts/gen_pkg.py
fi

# Compile
echo "Compiling hazard test..."
iverilog -g2012 -DSIMULATION -I generated -o sim/hp_vpu_hazard_test.vvp \
  generated/hp_vpu_pkg.sv \
  rtl/hp_vpu_top.sv \
  rtl/hp_vpu_lanes.sv \
  rtl/hp_vpu_decode.sv \
  rtl/hp_vpu_hazard.sv \
  rtl/hp_vpu_iq.sv \
  rtl/hp_vpu_vrf.sv \
  rtl/hp_vpu_lut_rom.sv \
  rtl/hp_vpu_csr.sv \
  rtl/hp_vpu_issue_check.sv \
  tb/hp_vpu_hazard_test.sv

# Run
echo "Running hazard test..."
vvp sim/hp_vpu_hazard_test.vvp | tee results/rtl/hazard_test.log

# Check results
if grep -q "HAZARD TEST PASS" results/rtl/hazard_test.log; then
    echo ""
    echo "=========================================="
    echo "  ✅ Hazard Test PASSED"
    echo "=========================================="
    exit 0
else
    echo ""
    echo "=========================================="
    echo "  ❌ Hazard Test FAILED"
    echo "=========================================="
    grep "FAIL" results/rtl/hazard_test.log
    exit 1
fi
