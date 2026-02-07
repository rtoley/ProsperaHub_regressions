#!/bin/bash
# Step 2b: FPGA Self-Checking Test Synthesis
# Runs Vivado in vivado_dev Docker container
# Synthesizes fpga_vpu_test_top (wraps hp_vpu_top)
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
echo "  Step 2b: FPGA Test Synthesis"
echo "  Target: $FPGA_PART"
echo "  Config: VLEN=$VLEN, DLEN=$DLEN"
echo "=========================================="
echo ""

# Check we're in the right directory
if [ ! -f "config/vpu_config.json" ]; then
    echo "❌ Error: Must run from project root"
    exit 1
fi

# Check Step 1b completed (optional - just warn)
if [ -f "results/fpga_test/sim_output.log" ]; then
    if grep -q "PASS - All" results/fpga_test/sim_output.log; then
        echo "✓ Step 1b: FPGA test RTL simulation passed"
    else
        echo "⚠️  Warning: Step 1b did not pass (continuing anyway)"
    fi
else
    echo "⚠️  Note: Step 1b results not found (run ./step1b_fpga_test_validate.sh first)"
fi

# Generate package from JSON config (single source of truth)
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
rm -rf results/fpga_synth 2>/dev/null || true
mkdir -p results/fpga_synth
docker exec vivado_dev rm -rf /workspace/hyperplane_vpu/fpga_synth_results 2>/dev/null || true

# Create TCL script locally
echo "Creating synthesis TCL script..."
cat > synth_fpga_test.tcl << TCLEOF
# FPGA LLM Test Synthesis - Auto-generated
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
    ./fpga/fpga_vpu_llm_test_top.sv
}

# Read weight ROM data
read_mem ./fpga/weight_rom.mem

# Read constraints
read_xdc ./fpga/constraints/arty_a7_100t.xdc

# Synthesize with fpga_vpu_llm_test_top as top
synth_design -top fpga_vpu_llm_test_top -part \$part

# Apply clock constraint (50 MHz = 20ns period, matches vpu_config.json)
create_clock -period 20.0 -name clk [get_ports clk_100mhz]

# Generate post-synth reports
file mkdir ./fpga_synth_results
report_utilization -file ./fpga_synth_results/utilization_synth.txt
report_utilization -hierarchical -file ./fpga_synth_results/utilization_hier.txt
report_timing_summary -file ./fpga_synth_results/timing_synth.txt
report_drc -file ./fpga_synth_results/drc.txt

# Write post-synth netlist BEFORE implementation (in case impl crashes)
write_verilog -force ./fpga_synth_results/fpga_llm_test_synth_netlist.v
write_verilog -mode funcsim -force ./fpga_synth_results/fpga_llm_test_funcsim.v

# Implementation (place & route)
opt_design
place_design
route_design

# Post-implementation reports
report_utilization -file ./fpga_synth_results/utilization_impl.txt
report_timing_summary -file ./fpga_synth_results/timing_impl.txt

# Write bitstream
write_bitstream -force ./fpga_synth_results/fpga_vpu_llm_test.bit

# Write post-impl netlist (more accurate timing)
write_verilog -force ./fpga_synth_results/fpga_test_impl_netlist.v

puts ""
puts "========================================"
puts "  FPGA Test Synthesis Complete"
puts "========================================"
puts ""

# Print utilization summary
set fp [open "./fpga_synth_results/utilization_impl.txt" r]
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
echo "(This may take 15-30 minutes for full implementation)"
echo ""

# Run synthesis in vivado_dev container
docker exec vivado_dev bash -c '
    cd /workspace/hyperplane_vpu
    export XIL_DISABLE_HW_SERVER=1

    # Clean old synthesis outputs
    rm -rf fpga_synth_results 2>/dev/null || true

    # Run synthesis - try different Vivado paths
    /opt/Xilinx/Vivado/2024.1/bin/vivado -mode batch -source synth_fpga_test.tcl 2>&1 || \
    /opt/Xilinx/Vivado/2023.2/bin/vivado -mode batch -source synth_fpga_test.tcl 2>&1 || \
    /opt/Xilinx/2025.2/Vivado/bin/vivado -mode batch -source synth_fpga_test.tcl 2>&1
' || {
    echo ""
    echo "❌ Synthesis failed!"
    echo "Check Vivado installation in vivado_dev container"
    exit 1
}

# Clean up local TCL file
rm -f synth_fpga_test.tcl

echo ""
echo "Copying synthesis results back..."
mkdir -p results/fpga_synth
docker cp vivado_dev:/workspace/hyperplane_vpu/fpga_synth_results/. results/fpga_synth/

# Verify outputs exist
if [ ! -f "results/fpga_synth/fpga_vpu_test.bit" ]; then
    echo "❌ Error: Bitstream not generated"
    exit 1
fi

if [ ! -f "results/fpga_synth/fpga_test_funcsim.v" ]; then
    echo "❌ Error: Functional simulation netlist not generated"
    exit 1
fi

echo ""
echo "=========================================="
echo "  ✅ Step 2b COMPLETE"
echo "=========================================="
echo ""
echo "FPGA Test Synthesis Results:"
echo "  Bitstream:     results/fpga_synth/fpga_vpu_test.bit"
echo "  Utilization:   results/fpga_synth/utilization_impl.txt"
echo "  Timing:        results/fpga_synth/timing_impl.txt"
echo "  Netlist:       results/fpga_synth/fpga_test_funcsim.v"
echo ""

# Show utilization summary
if [ -f "results/fpga_synth/utilization_impl.txt" ]; then
    echo "Resource Summary:"
    grep -E "Slice LUTs|Slice Registers|DSPs|Block RAM" results/fpga_synth/utilization_impl.txt | head -10
fi

# Check utilization target
if [ -f "results/fpga_synth/utilization_impl.txt" ]; then
    LUT_LINE=$(grep "Slice LUTs" results/fpga_synth/utilization_impl.txt | head -1)
    echo ""
    echo "LUT Utilization: $LUT_LINE"
    echo "(Target < 70%)"
fi

echo ""
echo "Next: Run ./step3b_fpga_netlist_verify.sh"
