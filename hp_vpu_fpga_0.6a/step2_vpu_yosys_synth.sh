#!/bin/bash
# Step 2 (Yosys): VPU Open-Source Synthesis
# Runs sv2v + Yosys in vivado_dev Docker container (AMD64)
# Alternative to Vivado for open-source flow

set -e

echo "=========================================="
echo "  Step 2: VPU Yosys Synthesis (v1.0)"
echo "=========================================="
echo ""

if [ ! -f "config/vpu_config.json" ]; then
    echo "❌ Error: Must run from hyperplane_vpu project root"
    exit 1
fi

echo "Generating hp_vpu_pkg.sv from config/vpu_config.json..."
python3 scripts/gen_pkg.py || { echo "❌ Package generation failed"; exit 1; }
echo ""

echo "Configuration:"
grep -E '"VLEN"|"DLEN"|"vmadd"' config/vpu_config.json | sed 's/^/  /'
echo ""

if ! docker ps -a | grep -q vivado_dev; then
    echo "❌ Error: vivado_dev container not found (AMD64 required)"
    exit 1
fi

if ! docker ps | grep -q vivado_dev; then
    echo "⚠️  vivado_dev is stopped. Starting it..."
    docker start vivado_dev
    sleep 2
fi

# Clean old results
echo "Cleaning old Yosys results..."
rm -rf results/yosys 2>/dev/null || true
mkdir -p results/yosys
docker exec vivado_dev rm -rf /workspace/hyperplane_vpu/results/yosys 2>/dev/null || true
docker exec vivado_dev rm -f /workspace/hyperplane_vpu/generated/hp_vpu_yosys.v 2>/dev/null || true

echo "Copying files to vivado_dev container..."
docker exec vivado_dev mkdir -p /workspace/hyperplane_vpu
docker cp . vivado_dev:/workspace/hyperplane_vpu/

echo ""
echo "Running Yosys synthesis in vivado_dev..."
echo ""

docker exec vivado_dev bash -c "
    cd /workspace/hyperplane_vpu
    rm -rf results/yosys 2>/dev/null || true
    mkdir -p results/yosys generated

    if ! command -v yosys &> /dev/null; then
        echo 'Installing Yosys...'
        apt-get update -qq && apt-get install -y -qq yosys wget unzip
    fi

    if ! command -v sv2v &> /dev/null; then
        echo 'Installing sv2v...'
        wget -q https://github.com/zachjs/sv2v/releases/download/v0.0.11/sv2v-Linux.zip -O /tmp/sv2v.zip
        unzip -o -qq /tmp/sv2v.zip -d /tmp
        cp /tmp/sv2v-Linux/sv2v /usr/local/bin/
    fi

    echo 'Tools:'
    echo \"  sv2v:  \$(sv2v --version 2>&1 | head -1)\"
    echo \"  yosys: \$(yosys -V 2>&1 | head -1)\"
    echo ''

    echo 'Converting SystemVerilog to Verilog...'
    sv2v -I generated \
        generated/hp_vpu_pkg.sv \
        rtl/hp_vpu_vrf.sv \
        rtl/hp_vpu_decode.sv \
        rtl/hp_vpu_hazard.sv \
        rtl/hp_vpu_iq.sv \
        rtl/hp_vpu_lut_rom.sv \
        rtl/hp_vpu_csr.sv \
        rtl/hp_vpu_issue_check.sv \
        rtl/hp_vpu_lanes.sv \
        rtl/hp_vpu_top.sv \
        -w generated/hp_vpu_yosys.v

    echo '  ✓ Generated: generated/hp_vpu_yosys.v'
    echo ''

    cat > generated/yosys_synth.ys << 'YOSYSEOF'
read_verilog generated/hp_vpu_yosys.v
hierarchy -top hp_vpu_top -check
proc; opt -full; fsm; opt
memory -nomap; opt; memory_map
techmap; opt -full; clean
stat
write_verilog results/yosys/hp_vpu_synth.v
write_json results/yosys/hp_vpu_synth.json
YOSYSEOF

    echo 'Running Yosys synthesis...'
    yosys -v2 -l results/yosys/synthesis.log generated/yosys_synth.ys
    echo '✓ Synthesis complete'
" || { echo "❌ Synthesis failed!"; exit 1; }

echo ""
mkdir -p results/yosys
docker cp vivado_dev:/workspace/hyperplane_vpu/results/yosys/. results/yosys/

if [ ! -f "results/yosys/hp_vpu_synth.v" ]; then
    echo "❌ Error: Netlist not generated"
    exit 1
fi

NUM_CELLS=$(grep "Number of cells:" results/yosys/synthesis.log | tail -1 | awk '{print $NF}')

echo "=========================================="
echo "  ✅ Yosys Synthesis Complete"
echo "=========================================="
echo "Cells: ${NUM_CELLS:-N/A}"
echo "Output: results/yosys/"
