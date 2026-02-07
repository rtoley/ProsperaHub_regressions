#!/bin/bash
# Step 2: VPU FPGA Synthesis
# Runs Vivado in vivado_dev Docker container
# Target FPGA read from config/vpu_config.json
#
# JSON config drives all parameters via gen_pkg.py

set -e

# Extract target FPGA from config
FPGA_PART=$(grep -o '"fpga"[[:space:]]*:[[:space:]]*"[^"]*"' config/vpu_config.json | cut -d'"' -f4)
FPGA_PART=${FPGA_PART:-"xc7a100tcsg324-1"}  # Default to A7-100T

# Extract VLEN/DLEN for display
VLEN=$(grep -o '"VLEN"[[:space:]]*:[[:space:]]*[0-9]*' config/vpu_config.json | grep -o '[0-9]*$')
DLEN=$(grep -o '"DLEN"[[:space:]]*:[[:space:]]*[0-9]*' config/vpu_config.json | grep -o '[0-9]*$')

echo "=========================================="
echo "  Step 2: VPU FPGA Synthesis"
echo "  Target: $FPGA_PART"
echo "  Config: VLEN=$VLEN, DLEN=$DLEN"
echo "=========================================="
echo ""

# Check we're in the right directory
if [ ! -f "config/vpu_config.json" ]; then
    echo "❌ Error: Must run from hyperplane_vpu project root"
    exit 1
fi

# Check Step 1 completed (skip if results don't exist for quick iteration)
if [ -f "results/rtl/test_results.log" ]; then
    if grep -q "ALL TESTS PASSED" results/rtl/test_results.log; then
        echo "✓ Step 1: All tests passed"
    elif grep -q "0 errors" results/rtl/test_results.log && grep -q "Random test completed" results/rtl/test_results.log; then
        echo "✓ Step 1: Random tests passed (RTL verified)"
    else
        echo "⚠️  Warning: Step 1 tests did not all pass (continuing anyway)"
    fi
else
    echo "⚠️  Note: Step 1 results not found (run ./step1_vpu_rtl_validate.sh for full verification)"
fi

# Step 2a: Generate package from JSON config (single source of truth)
echo ""
echo "Generating hp_vpu_pkg.sv from config/vpu_config.json..."
python3 scripts/gen_pkg.py || {
    echo "❌ Error: Package generation failed"
    exit 1
}
echo ""

# Show config being used
echo "Configuration:"
grep -E '"VLEN"|"DLEN"|"fpga"' config/vpu_config.json | sed 's/^/  /'
echo ""

# Check if vivado_dev container exists
if ! docker ps -a | grep -q vivado_dev; then
    echo "❌ Error: vivado_dev container not found"
    echo ""
    echo "You need a container with Vivado installed."
    exit 1
fi

# Check if vivado_dev is running, start if needed
if ! docker ps | grep -q vivado_dev; then
    echo "⚠️  vivado_dev is stopped. Starting it..."
    docker start vivado_dev
    sleep 2
    echo "✅ vivado_dev started"
fi

echo ""

# Clean old results
echo "Cleaning old synthesis results..."
rm -rf results/synthesis 2>/dev/null || true
mkdir -p results/synthesis
docker exec vivado_dev rm -rf /workspace/hyperplane_vpu/synthesis_results 2>/dev/null || true

# Create TCL script locally
echo "Creating synthesis TCL script..."
cat > synth_vpu.tcl << TCLEOF
# VPU Synthesis - Auto-generated
# Target: $FPGA_PART
set part "$FPGA_PART"

# Read package first, then all RTL files
read_verilog -sv ./generated/hp_vpu_pkg.sv
read_verilog -sv {
    ./rtl/hp_vpu_vrf.sv
    ./rtl/hp_vpu_iq.sv
    ./rtl/hp_vpu_hazard.sv
    ./rtl/hp_vpu_decode.sv
    ./rtl/hp_vpu_lut_rom_bram.sv
    ./rtl/hp_vpu_csr.sv
    ./rtl/hp_vpu_issue_check.sv
    ./rtl/hp_vpu_lanes.sv
    ./rtl/hp_vpu_top.sv
}

# Synthesize
synth_design -top hp_vpu_top -part \$part

# Apply clock constraint (100 MHz = 10ns period)
create_clock -period 10.0 -name clk [get_ports clk]

# Generate reports
file mkdir ./synthesis_results
report_utilization -file ./synthesis_results/hp_vpu_utilization.txt
report_utilization -hierarchical -file ./synthesis_results/hp_vpu_utilization_hier.txt
report_timing_summary -file ./synthesis_results/hp_vpu_timing.txt
report_drc -file ./synthesis_results/hp_vpu_drc.txt

# Write netlists
write_verilog -force ./synthesis_results/hp_vpu_netlist.v
write_verilog -mode funcsim -force ./synthesis_results/hp_vpu_funcsim.v

puts ""
puts "========================================"
puts "  Synthesis Complete"
puts "========================================"
puts ""

# Print utilization summary
set fp [open "./synthesis_results/hp_vpu_utilization.txt" r]
set content [read \$fp]
close \$fp
puts \$content

exit
TCLEOF

echo "Copying files to vivado_dev container..."
docker exec vivado_dev mkdir -p /workspace/hyperplane_vpu
docker cp . vivado_dev:/workspace/hyperplane_vpu/

echo ""
echo "Running synthesis in vivado_dev..."
echo "(This may take 10-20 minutes)"
echo ""

# Run synthesis in vivado_dev container
docker exec vivado_dev bash -c '
    cd /workspace/hyperplane_vpu
    export XIL_DISABLE_HW_SERVER=1

    # Clean old synthesis outputs
    rm -rf synthesis_results 2>/dev/null || true

    # Run synthesis - try different Vivado paths
    /opt/Xilinx/Vivado/2024.1/bin/vivado -mode batch -source synth_vpu.tcl 2>&1 || \
    /opt/Xilinx/Vivado/2023.2/bin/vivado -mode batch -source synth_vpu.tcl 2>&1 || \
    /opt/Xilinx/2025.2/Vivado/bin/vivado -mode batch -source synth_vpu.tcl 2>&1
' || {
    echo ""
    echo "❌ Synthesis failed!"
    echo "Check Vivado installation in vivado_dev container"
    exit 1
}

# Clean up local TCL file
rm -f synth_vpu.tcl

echo ""
echo "Copying synthesis results back..."
mkdir -p results/synthesis
docker cp vivado_dev:/workspace/hyperplane_vpu/synthesis_results/. results/synthesis/

# Verify outputs exist
if [ ! -f "results/synthesis/hp_vpu_funcsim.v" ]; then
    echo "❌ Error: Netlist not generated"
    exit 1
fi

echo ""
echo "=========================================="
echo "  ✅ Step 2 COMPLETE"
echo "=========================================="
echo ""
echo "Synthesis Results:"
echo "  Utilization: results/synthesis/hp_vpu_utilization.txt"
echo "  Timing:      results/synthesis/hp_vpu_timing.txt"
echo "  Netlist:     results/synthesis/hp_vpu_funcsim.v"
echo ""

# Show utilization summary
if [ -f "results/synthesis/hp_vpu_utilization.txt" ]; then
    echo "Resource Summary:"
    grep -E "Slice LUTs|Slice Registers|DSPs|Block RAM" results/synthesis/hp_vpu_utilization.txt | head -10
fi

echo ""
echo "Next: Run ./step3_vpu_netlist_verify.sh"
