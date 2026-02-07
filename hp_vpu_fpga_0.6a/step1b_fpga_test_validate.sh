#!/bin/bash
# Step 1b: FPGA Self-Checking Test RTL Validation
# Runs iverilog simulation in Docker container (same as step1)
# Tests BOTH:
#   1. Simple instruction test (10 ops) - fpga_vpu_test_top
#   2. LLM inference test (GEMV, dot product, MAC stress) - fpga_vpu_llm_test_top

set -e

echo "=========================================="
echo "  Step 1b: FPGA Self-Test RTL Validation"
echo "=========================================="
echo ""

# Check we're in the right directory
if [ ! -f "config/vpu_config.json" ]; then
    echo "❌ Error: Must run from project root"
    exit 1
fi

# Generate package from JSON config
echo "Generating hp_vpu_pkg.sv from config..."
python3 scripts/gen_pkg.py || {
    echo "❌ Error: Package generation failed"
    exit 1
}
echo ""

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

# Determine which container to use (same logic as step1)
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    if docker images | grep -q "hyperplane-dev.*latest"; then
        CONTAINER="hyperplane-dev:latest"
        echo "Using container: hyperplane-dev:latest (ARM64)"
    else
        CONTAINER="hdlc/sim:osvb"
        echo "Using container: hdlc/sim:osvb (ARM64 fallback)"
    fi
elif [ "$ARCH" = "x86_64" ]; then
    CONTAINER="hdlc/sim:osvb"
    echo "Using container: hdlc/sim:osvb (AMD64)"
else
    echo "❌ Unknown architecture: $ARCH"
    exit 1
fi

echo ""

# Clean old simulation files
echo "Cleaning old compiled files..."
rm -f sim/fpga_test*.vvp sim/llm_test*.vvp 2>/dev/null || true
mkdir -p sim results/fpga_test
echo "✓ Clean complete"
echo ""

echo "Running FPGA tests in Docker..."
echo ""

# Run tests in Docker
docker run --rm \
  -v $(pwd):/work \
  -w /work \
  $CONTAINER \
  bash -c '
    set -e

    #===========================================
    # Test 1: Simple instruction test (10 ops)
    #===========================================
    echo "=========================================="
    echo "  Test 1: Simple Instruction Test"
    echo "=========================================="
    echo ""
    echo "Compiling fpga_vpu_test_top..."
    iverilog -g2012 -DSIMULATION -I generated -o sim/fpga_test.vvp \
      generated/hp_vpu_pkg.sv \
      rtl/hp_vpu_vrf.sv \
      rtl/hp_vpu_iq.sv \
      rtl/hp_vpu_hazard.sv \
      rtl/hp_vpu_decode.sv \
      rtl/hp_vpu_lut_rom.sv \
      rtl/hp_vpu_csr.sv \
      rtl/hp_vpu_issue_check.sv \
      rtl/hp_vpu_lanes.sv \
      rtl/hp_vpu_top.sv \
      fpga/fpga_vpu_test_top.sv \
      tb/fpga_vpu_test_tb.sv

    echo "Running simple test..."
    timeout 300 vvp sim/fpga_test.vvp

    echo ""

    #===========================================
    # Test 2: LLM Inference Test
    #===========================================
    echo "=========================================="
    echo "  Test 2: LLM Inference Test"
    echo "=========================================="
    echo ""
    echo "Compiling fpga_vpu_llm_test_top..."
    iverilog -g2012 -DSIMULATION -I generated -o sim/llm_test.vvp \
      generated/hp_vpu_pkg.sv \
      rtl/hp_vpu_vrf.sv \
      rtl/hp_vpu_iq.sv \
      rtl/hp_vpu_hazard.sv \
      rtl/hp_vpu_decode.sv \
      rtl/hp_vpu_lut_rom.sv \
      rtl/hp_vpu_csr.sv \
      rtl/hp_vpu_issue_check.sv \
      rtl/hp_vpu_lanes.sv \
      rtl/hp_vpu_top.sv \
      fpga/fpga_vpu_llm_test_top.sv \
      tb/fpga_vpu_llm_test_tb.sv

    echo "Running LLM inference test..."
    timeout 300 vvp sim/llm_test.vvp

  ' 2>&1 | tee results/fpga_test/sim_output.log

# Check results
SIMPLE_PASS=$(grep -c "PASS - All" results/fpga_test/sim_output.log || echo "0")
LLM_PASS=$(grep -c "PASS - LLM inference test succeeded" results/fpga_test/sim_output.log || echo "0")

echo ""
echo "=========================================="
if [ "$SIMPLE_PASS" -ge 1 ] && [ "$LLM_PASS" -ge 1 ]; then
    echo "  ✅ Step 1b COMPLETE"
    echo "=========================================="
    echo ""
    echo "Results:"
    echo "  Simple Test: PASS (10 instruction tests)"
    echo "  LLM Test:    PASS (GEMV, dot product, MAC stress)"
    echo ""
    echo "Log: results/fpga_test/sim_output.log"
    echo ""
    echo "Next: Run ./step2b_fpga_test_synth.sh"
    exit 0
else
    echo "  ❌ Step 1b FAILED"
    echo "=========================================="
    echo ""
    echo "Results:"
    [ "$SIMPLE_PASS" -ge 1 ] && echo "  Simple Test: PASS" || echo "  Simple Test: FAIL"
    [ "$LLM_PASS" -ge 1 ] && echo "  LLM Test:    PASS" || echo "  LLM Test:    FAIL"
    echo ""

    # Show failure details
    if grep -q "FAIL" results/fpga_test/sim_output.log; then
        echo "Failure details:"
        grep -B 2 -A 5 "FAIL" results/fpga_test/sim_output.log | head -30
    fi

    echo ""
    echo "Fix issues before proceeding to synthesis"
    echo "Check: results/fpga_test/sim_output.log"
    exit 1
fi
