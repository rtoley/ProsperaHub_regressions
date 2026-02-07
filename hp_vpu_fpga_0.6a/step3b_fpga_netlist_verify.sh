#!/bin/bash
#==============================================================================
# Step 3b: FPGA Self-Test Netlist Verification
# Runs post-synthesis simulation of fpga_vpu_test_top
# Verifies netlist matches RTL behavior
#==============================================================================

set -e

echo "=========================================="
echo "  Step 3b: FPGA Test Netlist Verification"
echo "=========================================="
echo ""

# Check we're in the right directory
if [ ! -f "config/vpu_config.json" ]; then
    echo "❌ Error: Must run from VPU project root"
    exit 1
fi

# Check Step 2b completed
if [ ! -f "results/fpga_synth/fpga_llm_test_funcsim.v" ]; then
    echo "❌ Error: Run ./step2b_fpga_test_synth.sh first"
    echo "   Need: results/fpga_synth/fpga_llm_test_funcsim.v"
    exit 1
fi

# Regenerate package from JSON config (ensure consistency)
echo "Regenerating hp_vpu_pkg.sv from config/vpu_config.json..."
python3 scripts/gen_pkg.py || {
    echo "❌ Error: Package generation failed"
    exit 1
}
echo ""

# Show config being used
echo "Configuration:"
grep -E '"VLEN"|"DLEN"' config/vpu_config.json | sed 's/^/  /'
echo ""

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker not available"
    echo "   Netlist simulation requires Vivado in Docker container"
    exit 1
fi

# Auto-start vivado_dev if stopped
if ! docker ps | grep -q vivado_dev; then
    echo "⚠️  vivado_dev is stopped. Starting it..."
    docker start vivado_dev
    sleep 2
    echo "✅ vivado_dev started"
fi

# Clean old results
echo "Cleaning old netlist verification results..."
rm -rf results/fpga_netlist 2>/dev/null || true
mkdir -p results/fpga_netlist
docker exec vivado_dev rm -rf /workspace/hyperplane_vpu/fpga_netlist_results 2>/dev/null || true

echo ""
echo "Running FPGA test netlist simulation in vivado_dev..."
echo ""

# Copy latest files
docker cp . vivado_dev:/workspace/hyperplane_vpu/

# Run netlist simulation
docker exec vivado_dev bash -c '
    cd /workspace/hyperplane_vpu
    export XIL_DISABLE_HW_SERVER=1

    # Clean old simulation results
    rm -rf fpga_netlist_results 2>/dev/null || true

    echo "Compiling FPGA LLM test netlist..."

    # Find Vivado installation
    VIVADO_BIN=""
    for path in /opt/Xilinx/Vivado/2024.1/bin /opt/Xilinx/Vivado/2023.2/bin /opt/Xilinx/2025.2/Vivado/bin; do
        if [ -d "$path" ]; then
            VIVADO_BIN="$path"
            break
        fi
    done

    if [ -z "$VIVADO_BIN" ]; then
        echo "❌ Error: Vivado not found"
        exit 1
    fi

    mkdir -p fpga_netlist_results

    # Compile netlist and testbench
    # Note: The funcsim netlist includes all Xilinx primitives resolved
    $VIVADO_BIN/xvlog --sv \
      -L unisims_ver \
      ./results/fpga_synth/fpga_llm_test_funcsim.v \
      ./tb/fpga_vpu_llm_netlist_tb.sv 2>&1 | tee fpga_netlist_results/compile.log

    # Check for compile errors
    if grep -q "ERROR" fpga_netlist_results/compile.log; then
        echo "❌ Compilation failed"
        exit 1
    fi

    # Elaborate
    $VIVADO_BIN/xelab fpga_vpu_llm_netlist_tb glbl -s fpga_netlist_sim \
      -L unisims_ver 2>&1 | tee -a fpga_netlist_results/compile.log

    # Check for elaboration errors
    if grep -q "ERROR" fpga_netlist_results/compile.log; then
        echo "❌ Elaboration failed"
        exit 1
    fi

    # Run simulation
    echo ""
    echo "Running netlist simulation..."
    $VIVADO_BIN/xsim fpga_netlist_sim -runall 2>&1 | tee fpga_netlist_results/sim.log

    echo ""
    echo "=== FPGA Test Netlist Simulation Results ==="
    grep -E "(PASS|FAIL|LED|========)" fpga_netlist_results/sim.log || echo "Check logs for results"
'

# Copy results back
docker cp vivado_dev:/workspace/hyperplane_vpu/fpga_netlist_results/. results/fpga_netlist/

echo ""
echo "=========================================="
echo "  Netlist Verification Results"
echo "=========================================="
echo ""

# Check results
if [ -f "results/fpga_netlist/sim.log" ]; then
    if grep -q "NETLIST PASS" results/fpga_netlist/sim.log; then
        TESTS=$(grep "tests passed" results/fpga_netlist/sim.log | grep -o '[0-9]*' | head -1)
        echo ""
        echo "=========================================="
        echo "  ✅ Step 3b COMPLETE"
        echo "=========================================="
        echo ""
        echo "FPGA Test Netlist: $TESTS tests passed"
        echo "Post-synthesis behavior matches RTL!"
        echo ""
        echo "Ready for hardware: results/fpga_synth/fpga_vpu_test.bit"
        exit 0
    elif grep -q "NETLIST FAIL" results/fpga_netlist/sim.log; then
        echo ""
        echo "=========================================="
        echo "  ❌ Step 3b FAILED"
        echo "=========================================="
        echo ""
        echo "Netlist simulation failed!"
        echo "Review: results/fpga_netlist/sim.log"
        exit 1
    fi
fi

echo ""
echo "=========================================="
echo "  ⚠️  Step 3b - Check Results"
echo "=========================================="
echo ""
echo "Review: results/fpga_netlist/sim.log"
echo "        results/fpga_netlist/compile.log"
exit 1
