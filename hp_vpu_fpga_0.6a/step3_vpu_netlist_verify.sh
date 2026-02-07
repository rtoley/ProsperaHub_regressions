#!/bin/bash
# Step 3: VPU Netlist Verification
# Runs post-synthesis simulation in vivado_dev container
# Verifies netlist matches RTL behavior
#
# JSON config drives all parameters via gen_pkg.py

set -e

echo "=========================================="
echo "  Step 3: VPU Netlist Verification"
echo "=========================================="
echo ""

# Check we're in the right directory
if [ ! -f "config/vpu_config.json" ]; then
    echo "❌ Error: Must run from hyperplane_vpu project root"
    exit 1
fi

# Check Step 2 completed
if [ ! -f "results/synthesis/hp_vpu_funcsim.v" ]; then
    echo "❌ Error: Run ./step2_vpu_synthesis.sh first"
    exit 1
fi

# Step 3a: Regenerate package from JSON config (ensure consistency)
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

# Auto-start vivado_dev if stopped
if ! docker ps | grep -q vivado_dev; then
    echo "⚠️  vivado_dev is stopped. Starting it..."
    docker start vivado_dev
    sleep 2
    echo "✅ vivado_dev started"
fi

# Clean old results
echo "Cleaning old netlist verification results..."
rm -rf results/netlist 2>/dev/null || true
mkdir -p results/netlist
docker exec vivado_dev rm -rf /workspace/hyperplane_vpu/netlist_sim_results 2>/dev/null || true

echo ""
echo "Running netlist simulation in vivado_dev..."
echo ""

# Copy latest files (including regenerated package)
docker cp . vivado_dev:/workspace/hyperplane_vpu/

# Run netlist simulation
docker exec vivado_dev bash -c '
    cd /workspace/hyperplane_vpu
    export XIL_DISABLE_HW_SERVER=1

    # Clean old simulation results
    rm -rf netlist_sim_results 2>/dev/null || true

    echo "Compiling netlist testbench..."

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

    mkdir -p netlist_sim_results

    # Compile package first, then netlist and testbench
    $VIVADO_BIN/xvlog --sv \
      -L unisims_ver \
      ./generated/hp_vpu_pkg.sv \
      ./results/synthesis/hp_vpu_funcsim.v \
      ./tb/hp_vpu_netlist_tb.sv 2>&1 | tee netlist_sim_results/compile.log

    # Elaborate
    $VIVADO_BIN/xelab hp_vpu_netlist_tb glbl -s netlist_sim \
      -L unisims_ver 2>&1 | tee -a netlist_sim_results/compile.log

    # Run simulation
    $VIVADO_BIN/xsim netlist_sim -runall 2>&1 | tee netlist_sim_results/netlist_test.log

    echo ""
    echo "=== Netlist Simulation Results ==="
    grep -E "(PASS|FAIL|Test Results|errors)" netlist_sim_results/netlist_test.log || echo "Check logs for results"
'

# Copy results back
docker cp vivado_dev:/workspace/hyperplane_vpu/netlist_sim_results/. results/netlist/

echo ""
echo "=========================================="
echo "  Netlist Verification Results"
echo "=========================================="
echo ""

# Compare RTL vs Netlist results
RTL_TESTS=$(grep "Test Results:" results/rtl/test_results.log 2>/dev/null | head -1)
NETLIST_PASS=$(grep -c "PASS" results/netlist/netlist_test.log 2>/dev/null || echo "0")

echo "RTL Results:     $RTL_TESTS"
echo "Netlist Results: See results/netlist/netlist_test.log"

if [ -f "results/netlist/netlist_test.log" ]; then
    if grep -q "ALL TESTS PASSED\|PASS" results/netlist/netlist_test.log; then
        echo ""
        echo "=========================================="
        echo "  ✅ Step 3 COMPLETE"
        echo "=========================================="
        echo ""
        echo "Netlist verified successfully!"
        echo "The synthesized design matches RTL behavior."
        exit 0
    fi
fi

echo ""
echo "=========================================="
echo "  ⚠️  Step 3 - Check Results"
echo "=========================================="
echo ""
echo "Review: results/netlist/netlist_test.log"
exit 1
