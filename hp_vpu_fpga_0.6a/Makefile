#==============================================================================
# Hyperplane VPU Makefile v0.3f
#==============================================================================

# Tools
IVERILOG = iverilog
VVP = vvp
PYTHON = python3

# Directories
RTL_DIR = rtl
TB_DIR = tb
GEN_DIR = generated
SIM_DIR = sim
RESULTS_DIR = results/rtl

# Config (override with: make VLEN=256)
VLEN ?= 64
ifeq ($(VLEN),256)
    CONFIG = config/vpu_config_256.json
else
    CONFIG = config/vpu_config.json
endif

# Default flags
VFLAGS = -g2012 -DSIMULATION
VFLAGS += -I $(RTL_DIR) -I $(GEN_DIR) -I $(GEN_DIR)/tests -I $(TB_DIR)

# RTL files
RTL_FILES = $(GEN_DIR)/hp_vpu_pkg.sv \
            $(RTL_DIR)/hp_vpu_top.sv \
            $(RTL_DIR)/hp_vpu_decode.sv \
            $(RTL_DIR)/hp_vpu_lanes.sv \
            $(RTL_DIR)/hp_vpu_hazard.sv \
            $(RTL_DIR)/hp_vpu_iq.sv \
            $(RTL_DIR)/hp_vpu_issue_check.sv \
            $(RTL_DIR)/hp_vpu_vrf.sv \
            $(RTL_DIR)/hp_vpu_lut_rom.sv

#==============================================================================
# Main targets
#==============================================================================

.PHONY: all quick full clean help

all: quick

# Quick smoke test (fastest)
quick: pkg tests
	@echo "=== Quick Smoke Test (VLEN=$(VLEN)) ==="
	$(IVERILOG) $(VFLAGS) -DTEST_QUICK -o $(SIM_DIR)/tb_quick.vvp \
		$(RTL_FILES) $(TB_DIR)/hp_vpu_tb_modular.sv
	$(VVP) $(SIM_DIR)/tb_quick.vvp | tee $(RESULTS_DIR)/quick_$(VLEN).log | \
		grep -E "PASS:|FAIL:|Test Results:|==="
	@echo ""
	@grep "Test Results:" $(RESULTS_DIR)/quick_$(VLEN).log

# Full test suite
full: pkg tests
	@echo "=== Full Test Suite (VLEN=$(VLEN)) ==="
	$(IVERILOG) $(VFLAGS) -DTEST_FULL -o $(SIM_DIR)/tb_full.vvp \
		$(RTL_FILES) $(TB_DIR)/hp_vpu_tb_modular.sv
	$(VVP) $(SIM_DIR)/tb_full.vvp | tee $(RESULTS_DIR)/full_$(VLEN).log
	@echo ""
	@grep "Test Results:" $(RESULTS_DIR)/full_$(VLEN).log

#==============================================================================
# Category tests
#==============================================================================

.PHONY: alu mul mac sat cmp red lut stress timing

alu: pkg tests
	@echo "=== ALU Tests ==="
	$(IVERILOG) $(VFLAGS) -DTEST_ALU -o $(SIM_DIR)/tb_alu.vvp \
		$(RTL_FILES) $(TB_DIR)/hp_vpu_tb_modular.sv
	$(VVP) $(SIM_DIR)/tb_alu.vvp | tee $(RESULTS_DIR)/alu_$(VLEN).log | \
		grep -E "PASS:|FAIL:|Test Results:|==="

mul: pkg tests
	@echo "=== MUL Tests ==="
	$(IVERILOG) $(VFLAGS) -DTEST_MUL -o $(SIM_DIR)/tb_mul.vvp \
		$(RTL_FILES) $(TB_DIR)/hp_vpu_tb_modular.sv
	$(VVP) $(SIM_DIR)/tb_mul.vvp | tee $(RESULTS_DIR)/mul_$(VLEN).log | \
		grep -E "PASS:|FAIL:|Test Results:|==="

mac: pkg tests
	@echo "=== MAC Tests ==="
	$(IVERILOG) $(VFLAGS) -DTEST_MAC -o $(SIM_DIR)/tb_mac.vvp \
		$(RTL_FILES) $(TB_DIR)/hp_vpu_tb_modular.sv
	$(VVP) $(SIM_DIR)/tb_mac.vvp | tee $(RESULTS_DIR)/mac_$(VLEN).log | \
		grep -E "PASS:|FAIL:|Test Results:|==="

sat: pkg tests
	@echo "=== Saturating Tests ==="
	$(IVERILOG) $(VFLAGS) -DTEST_SAT -o $(SIM_DIR)/tb_sat.vvp \
		$(RTL_FILES) $(TB_DIR)/hp_vpu_tb_modular.sv
	$(VVP) $(SIM_DIR)/tb_sat.vvp | tee $(RESULTS_DIR)/sat_$(VLEN).log | \
		grep -E "PASS:|FAIL:|Test Results:|==="

cmp: pkg tests
	@echo "=== Compare Tests ==="
	$(IVERILOG) $(VFLAGS) -DTEST_CMP -o $(SIM_DIR)/tb_cmp.vvp \
		$(RTL_FILES) $(TB_DIR)/hp_vpu_tb_modular.sv
	$(VVP) $(SIM_DIR)/tb_cmp.vvp | tee $(RESULTS_DIR)/cmp_$(VLEN).log | \
		grep -E "PASS:|FAIL:|Test Results:|==="

red: pkg tests
	@echo "=== Reduction Tests ==="
	$(IVERILOG) $(VFLAGS) -DTEST_RED -o $(SIM_DIR)/tb_red.vvp \
		$(RTL_FILES) $(TB_DIR)/hp_vpu_tb_modular.sv
	$(VVP) $(SIM_DIR)/tb_red.vvp | tee $(RESULTS_DIR)/red_$(VLEN).log | \
		grep -E "PASS:|FAIL:|Test Results:|==="

lut: pkg tests
	@echo "=== LUT Custom Tests ==="
	$(IVERILOG) $(VFLAGS) -DTEST_LUT -o $(SIM_DIR)/tb_lut.vvp \
		$(RTL_FILES) $(TB_DIR)/hp_vpu_tb_modular.sv
	$(VVP) $(SIM_DIR)/tb_lut.vvp | tee $(RESULTS_DIR)/lut_$(VLEN).log | \
		grep -E "PASS:|FAIL:|Test Results:|==="

stress: pkg
	@echo "=== R2A/R2B Stress Tests (VLEN=256, NLANES=4) ==="
	$(IVERILOG) $(VFLAGS) -o $(SIM_DIR)/tb_stress_r2ab.vvp \
		$(RTL_FILES) $(TB_DIR)/test_r2ab_stress.sv
	$(VVP) $(SIM_DIR)/tb_stress_r2ab.vvp | tee $(RESULTS_DIR)/stress_r2ab.log | \
		grep -E "PASS:|FAIL:|Results:|===|TIMEOUT|ERROR"

timing: pkg
	@echo "=== Reduction Timing Tests ==="
	$(IVERILOG) $(VFLAGS) -o $(SIM_DIR)/tb_red_timing.vvp \
		$(RTL_FILES) $(TB_DIR)/test_reduction_timing.sv
	$(VVP) $(SIM_DIR)/tb_red_timing.vvp | tee $(RESULTS_DIR)/timing.log | \
		grep -E "PASS:|FAIL:|Results:|===|TIMEOUT"

#==============================================================================
# Generation targets
#==============================================================================

.PHONY: pkg tests

pkg:
	@mkdir -p $(GEN_DIR) $(SIM_DIR) $(RESULTS_DIR)
	$(PYTHON) scripts/gen_pkg.py $(CONFIG)

tests:
	@mkdir -p $(GEN_DIR)/tests
	$(PYTHON) scripts/gen_modular_tests.py $(GEN_DIR)/tests

#==============================================================================
# Utility targets
#==============================================================================

clean:
	rm -rf $(SIM_DIR)/*.vvp $(SIM_DIR)/*.vcd
	rm -f $(RESULTS_DIR)/*.log

distclean: clean
	rm -rf $(GEN_DIR)/tests
	rm -f $(GEN_DIR)/hp_vpu_pkg.sv

# Show test summary
summary:
	@echo "=== Test Results Summary ==="
	@for f in $(RESULTS_DIR)/*.log; do \
		echo -n "$$(basename $$f .log): "; \
		grep "Test Results:" $$f 2>/dev/null || echo "no results"; \
	done

help:
	@echo "VPU Makefile Targets:"
	@echo "  make quick      - Quick smoke test (default)"
	@echo "  make full       - Full test suite"
	@echo "  make alu        - ALU tests only"
	@echo "  make mul        - MUL tests only"
	@echo "  make mac        - MAC tests only"
	@echo "  make sat        - Saturating tests only"
	@echo "  make cmp        - Compare tests only"
	@echo "  make red        - Reduction tests only"
	@echo "  make lut        - LUT custom tests only"
	@echo "  make stress     - R2A/R2B pipeline stress tests"
	@echo "  make timing     - Reduction timing tests"
	@echo ""
	@echo "Options:"
	@echo "  make VLEN=256   - Use 256-bit config"
	@echo "  make VLEN=64    - Use 64-bit config (default)"
	@echo ""
	@echo "Utility:"
	@echo "  make clean      - Remove simulation files"
	@echo "  make summary    - Show all test results"
	@echo "  make pkg        - Regenerate package"
	@echo "  make tests      - Regenerate test files"
