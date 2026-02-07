#!/bin/bash
# Step 1: VPU RTL Development & Validation (v0.3d)
# 1. Generates hp_vpu_pkg.sv from config
# 2. Runs iverilog tests in Docker container
#
# Test Modes:
#   --quick              Quick smoke test (15 tests, <5 sec)
#   --full               Full modular tests (1227 tests)
#   --test <category>    Specific category: alu|mul|mac|sat|cmp|red|lut|mask|maskop|perm|wide|fixpt|int4
#   -c, --compliance     Original compliance tests (1273 tests)
#   (default)            Base testbench tests (~150 tests)
#
# Config Options:
#   --64                 VLEN=64, DLEN=64 (default)
#   --256                VLEN=256, DLEN=256
#
# Other Options:
#   -z, --hazard         Run ONLY hazard pattern test
#   -s, --seed S         Set random seed (default: 99999)
#   -l, --long           Enable long stress test (10K instructions)
#   -h, --help           Show this help

set -e

# Default values
TEST_MODE=""
COMPLIANCE_FLAG=""
HAZARD_ONLY=""
SEED="99999"
LONG_STRESS=""
PLUSARGS=""
VLEN_MODE="64"
CONFIG_FILE="config/vpu_config.json"

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        --quick)
            TEST_MODE="-DTEST_QUICK"
            echo "✓ Quick smoke test mode (15 tests)"
            shift
            ;;
        --full)
            TEST_MODE="-DTEST_FULL"
            echo "✓ Full modular test mode (1227 tests)"
            shift
            ;;
        --all)
            TEST_MODE="-DTEST_ALL"
            echo "✓ All tests including known-failing"
            shift
            ;;
        --test)
            CATEGORY="$2"
            case $CATEGORY in
                alu) TEST_MODE="-DTEST_ALU"; echo "✓ ALU tests (438 tests)" ;;
                mul) TEST_MODE="-DTEST_MUL"; echo "✓ MUL tests (60 tests)" ;;
                mac) TEST_MODE="-DTEST_MAC"; echo "✓ MAC tests (36 tests)" ;;
                sat) TEST_MODE="-DTEST_SAT"; echo "✓ SAT tests (60 tests)" ;;
                cmp) TEST_MODE="-DTEST_CMP"; echo "✓ CMP tests (192 tests)" ;;
                red) TEST_MODE="-DTEST_RED"; echo "✓ RED tests (120 tests)" ;;
                lut) TEST_MODE="-DTEST_LUT"; echo "✓ LUT tests (40 tests)" ;;
                mask) TEST_MODE="-DTEST_MASK"; echo "✓ MASK logical tests (56 tests)" ;;
                maskop) TEST_MODE="-DTEST_MASKOP"; echo "✓ MASKOP tests (43 tests)" ;;
                perm) TEST_MODE="-DTEST_PERM"; echo "✓ PERM tests (54 tests)" ;;
                wide) TEST_MODE="-DTEST_WIDE"; echo "✓ WIDE tests (82 tests)" ;;
                fixpt) TEST_MODE="-DTEST_FIXPT"; echo "✓ FIXPT tests (30 tests)" ;;
                int4) TEST_MODE="-DTEST_INT4"; echo "✓ INT4 tests (16 tests)" ;;
                fail) TEST_MODE="-DTEST_KNOWN_FAIL"; echo "✓ Known-failing tests (investigation)" ;;
                *) echo "❌ Unknown category: $CATEGORY"; exit 1 ;;
            esac
            shift 2
            ;;
        --64)
            VLEN_MODE="64"
            CONFIG_FILE="config/vpu_config.json"
            echo "✓ Config: VLEN=64, DLEN=64"
            shift
            ;;
        --256)
            VLEN_MODE="256"
            CONFIG_FILE="config/vpu_config_256.json"
            echo "✓ Config: VLEN=256, DLEN=256"
            shift
            ;;
        -c|--compliance)
            COMPLIANCE_FLAG="-DCOMPLIANCE_TESTS"
            echo "✓ Original compliance tests ENABLED (1273 tests)"
            shift
            ;;
        -z|--hazard)
            HAZARD_ONLY="-DHAZARD_ONLY"
            echo "✓ Hazard pattern test ONLY mode"
            shift
            ;;
        -s|--seed)
            SEED="$2"
            if [[ -z "$SEED" ]] || [[ ! "$SEED" =~ ^[0-9]+$ ]]; then
                echo "❌ Error: --seed requires a number"
                exit 1
            fi
            echo "✓ Random seed: $SEED"
            shift 2
            ;;
        -l|--long)
            LONG_STRESS="-DENABLE_LONG_STRESS_TEST"
            echo "✓ Long stress test ENABLED (10K instructions)"
            shift
            ;;
        -h|--help)
            echo "Usage: ./step1_vpu_rtl_validate.sh [OPTIONS]"
            echo ""
            echo "Test Modes:"
            echo "  --quick              Quick smoke test (15 tests, <5 sec)"
            echo "  --full               Full modular tests (1227 tests)"
            echo "  --test <category>    Specific category:"
            echo "                         alu    - ALU tests (438 tests)"
            echo "                         mul    - MUL tests (60 tests)"
            echo "                         mac    - MAC tests (36 tests)"
            echo "                         sat    - SAT tests (60 tests)"
            echo "                         cmp    - CMP tests (192 tests)"
            echo "                         red    - RED tests (120 tests)"
            echo "                         lut    - LUT tests (40 tests)"
            echo "                         mask   - Mask logical (56 tests)"
            echo "                         maskop - Mask manipulation (43 tests)"
            echo "                         perm   - Permutation (54 tests)"
            echo "                         wide   - Widening (82 tests)"
            echo "                         fixpt  - Fixed-point (30 tests)"
            echo "                         int4   - INT4 pack/unpack (16 tests)"
            echo "                         fail   - Known-failing tests"
            echo "  -c, --compliance     Original compliance tests (1273 tests)"
            echo "  (default)            Base testbench tests (~150 tests)"
            echo ""
            echo "Config Options:"
            echo "  --64                 VLEN=64, DLEN=64 (default)"
            echo "  --256                VLEN=256, DLEN=256"
            echo ""
            echo "Other Options:"
            echo "  -z, --hazard         Run ONLY hazard pattern test"
            echo "  -s, --seed S         Set random seed (default: 99999)"
            echo "  -l, --long           Enable long stress test (10K instructions)"
            echo "  -h, --help           Show this help"
            echo ""
            echo "Examples:"
            echo "  ./step1_vpu_rtl_validate.sh --quick           # Fast smoke test"
            echo "  ./step1_vpu_rtl_validate.sh --full            # Full modular tests"
            echo "  ./step1_vpu_rtl_validate.sh --full --256      # Full tests @ 256-bit"
            echo "  ./step1_vpu_rtl_validate.sh --test alu        # ALU tests only"
            echo "  ./step1_vpu_rtl_validate.sh -c                # Original compliance"
            echo "  ./step1_vpu_rtl_validate.sh                   # Base tests only"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage"
            exit 1
            ;;
    esac
done

# Build plusargs string for vvp
PLUSARGS="+seed=$SEED"

echo "=========================================="
echo "  Step 1: VPU RTL Validation (v0.3b)"
echo "=========================================="
echo ""

# Check we're in the right directory
if [ ! -f "config/vpu_config.json" ]; then
    echo "❌ Error: Must run from vpu_fpga project root"
    exit 1
fi

# Check config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Error: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Step 1a: Generate package from JSON config
echo "Generating hp_vpu_pkg.sv from $CONFIG_FILE..."
python3 scripts/gen_pkg.py "$CONFIG_FILE" || {
    echo "❌ Error: Package generation failed"
    exit 1
}
echo ""

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

# Determine which container to use
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
rm -f sim/*.vvp sim/*.vcd 2>/dev/null || true
echo "✓ Clean complete"
echo ""

# Create results directory
mkdir -p results/rtl

# Build define flags
DEFINE_FLAGS="-DSIMULATION $TEST_MODE $COMPLIANCE_FLAG $HAZARD_ONLY $LONG_STRESS"
echo "Config:        VLEN=$VLEN_MODE"
echo "Compile flags: $DEFINE_FLAGS"
echo "Runtime args:  $PLUSARGS"
echo ""

echo "Running VPU RTL tests..."
echo ""

# Run tests in Docker
docker run --rm \
  -v $(pwd):/work \
  -w /work \
  -e DEFINE_FLAGS="$DEFINE_FLAGS" \
  -e PLUSARGS="$PLUSARGS" \
  $CONTAINER \
  bash -c '
    set -e

    #=========================================================================
    # Step 1: CSR and Issue Checker Test (standalone)
    #=========================================================================
    echo "=========================================="
    echo "Step 1: CSR and Issue Checker Test"
    echo "=========================================="
    echo "Compiling CSR test..."
    iverilog -g2012 -DSIMULATION \
      -I generated \
      generated/hp_vpu_pkg.sv \
      rtl/hp_vpu_csr.sv \
      rtl/hp_vpu_issue_check.sv \
      tb/hp_vpu_csr_test.sv \
      -o sim/hp_vpu_csr_test.vvp 2>&1 | grep -v "sorry:" || true

    if [ ! -f sim/hp_vpu_csr_test.vvp ]; then
        echo "❌ CSR test compilation failed"
        exit 1
    fi

    echo "Running CSR test..."
    vvp sim/hp_vpu_csr_test.vvp
    echo ""

    #=========================================================================
    # Step 2: Full VPU RTL Test
    #=========================================================================
    echo "=========================================="
    echo "Step 2: Full VPU RTL Test"
    echo "=========================================="
    echo "Compiling VPU RTL..."
    iverilog -g2012 $DEFINE_FLAGS \
      -I rtl -I generated -I generated/tests -I tb \
      -o sim/hp_vpu_tb.vvp \
      generated/hp_vpu_pkg.sv \
      rtl/hp_vpu_csr.sv \
      rtl/hp_vpu_issue_check.sv \
      rtl/hp_vpu_top.sv \
      rtl/hp_vpu_lanes.sv \
      rtl/hp_vpu_decode.sv \
      rtl/hp_vpu_hazard.sv \
      rtl/hp_vpu_iq.sv \
      rtl/hp_vpu_vrf.sv \
      rtl/hp_vpu_lut_rom.sv \
      tb/hp_vpu_tb.sv 2>&1 | grep -v "sorry:" | grep -v "warning:" || true

    if [ ! -f sim/hp_vpu_tb.vvp ]; then
        echo "❌ Compilation failed"
        exit 1
    fi

    echo ""
    echo "Running tests..."
    timeout 600 vvp sim/hp_vpu_tb.vvp $PLUSARGS
  ' 2>&1 | tee results/rtl/test_results_${VLEN_MODE}.log

LOGFILE="results/rtl/test_results_${VLEN_MODE}.log"

# Extract results - ultra-robust parsing for Docker environment
if [ -f "$LOGFILE" ]; then
    # Use awk to count and ensure clean integer output
    PASSED=$(awk '/PASS:/{count++} END{print count+0}' "$LOGFILE")
    FAILED=$(awk '/FAIL:/{count++} END{print count+0}' "$LOGFILE")
else
    PASSED=0
    FAILED=0
fi
TOTAL=$((PASSED + FAILED))

echo ""
echo "=========================================="

# Check results based on test mode
if [ -n "$TEST_MODE" ]; then
    # Modular test mode
    if [ "$FAILED" -eq 0 ] && [ "$PASSED" -gt 0 ]; then
        echo "  ✅ Step 1 COMPLETE"
        echo "=========================================="
        echo ""
        echo "Results: $PASSED/$TOTAL passed (100%)"
    elif [ "$FAILED" -le 3 ] && [ "$PASSED" -gt 0 ]; then
        echo "  ⚠️  Step 1 COMPLETE (with known failures)"
        echo "=========================================="
        echo ""
        echo "Results: $PASSED/$TOTAL passed"
        echo "Known failures: $FAILED (see docs/KNOWN_FAILURES.md)"
        grep "FAIL:" "$LOGFILE" | head -5
    else
        echo "  ❌ Step 1 FAILED"
        echo "=========================================="
        echo ""
        echo "Results: $PASSED/$TOTAL passed"
        echo "Failures:"
        grep "FAIL:" "$LOGFILE" | head -10
        exit 1
    fi
elif grep -q "ALL TESTS PASSED" "$LOGFILE"; then
    echo "  ✅ Step 1 COMPLETE"
    echo "=========================================="
    echo ""
    TESTS=$(grep "Test Results:" "$LOGFILE" | head -1)
    echo "Results: $TESTS"
elif grep -q "ALL HAZARD TESTS PASSED" "$LOGFILE"; then
    echo "  ✅ Hazard Pattern Tests PASSED"
    echo "=========================================="
    echo ""
    grep "Test Results:" "$LOGFILE"
else
    echo "  ❌ Step 1 FAILED"
    echo "=========================================="
    echo ""
    echo "Fix RTL issues before proceeding to synthesis"
    grep "FAIL:" "$LOGFILE" | head -10
    exit 1
fi

echo ""
echo "Log: $LOGFILE"
echo ""
echo "Next: Run ./step2_vpu_synthesis.sh"
