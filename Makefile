################################################################################
# Project: Photon Permutation Simulation & Synthesis
# Simulator: Verilator
# Testbench: Cocotb (Python)
# Author: Leon Wandruschka
################################################################################

.DEFAULT_GOAL := help

################################################################################
# Simulator & Language Settings
################################################################################

PROJECT_NAME := counter
SIM ?= verilator
TOPLEVEL_LANG ?= verilog
TOPLEVEL ?= top
MODULE ?= tb.top_tb
SIM_BUILD ?= sim_build

################################################################################
# Source Directory
################################################################################

VERILOG_SRC_DIR := $(PWD)/src

################################################################################
# Verilator Options
################################################################################

EXTRA_ARGS += --trace --trace-structs
EXTRA_ARGS += -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -O0 
EXTRA_ARGS += --coverage

################################################################################
# Include Cocotb Makefiles
################################################################################

include $(shell cocotb-config --makefiles)/Makefile.sim

################################################################################
# Individual Test Targets (Cocotb)
################################################################################

COCOTB_MAKEFILE := $(shell cocotb-config --makefiles)/Makefile.sim
ALL_TESTS :=

define TEST_template
test_$(1):
	@echo ">>> Running Cocotb testbench: $(1)"
	@echo "TOPLEVEL=$(2)" > .last_test.meta
	@echo "VERILOG_SOURCES=$(foreach f,$(3),$(VERILOG_SRC_DIR)/$(f))" >> .last_test.meta
	@echo "SIM_BUILD=sim_build/$(1)" >> .last_test.meta
	$(MAKE) -f $(COCOTB_MAKEFILE) \
		SIM=$(SIM) TOPLEVEL_LANG=$(TOPLEVEL_LANG) \
		TOPLEVEL=$(2) MODULE=tb.$(1) \
		VERILOG_SOURCES="$(foreach f,$(3),$(VERILOG_SRC_DIR)/$(f))" \
		SIM_BUILD=sim_build/$(1) \
		EXTRA_ARGS="$(EXTRA_ARGS)"
ALL_TESTS += test_$(1)
endef

$(eval $(call TEST_template,counter_tb,counter,counter.sv))
$(eval $(call TEST_template,top_tb,top,top.sv counter.sv))

test_all: $(ALL_TESTS)

################################################################################
# RTL View (RTLBrowse + GTKWave)
################################################################################

JSON2STEMS_BIN := json2stems/json2stems
RTL_VIEW := 1

$(JSON2STEMS_BIN):
	@if [ ! -x "$@" ]; then \
		$(MAKE) -C json2stems; \
	fi

json: $(JSON2STEMS_BIN)
	@test -f .last_test.meta || (echo "Error: No previous test run. Run a test first." && exit 1)
	@TOPLEVEL=$$(grep ^TOPLEVEL= .last_test.meta | cut -d= -f2-) && \
	SRCS=$$(grep ^VERILOG_SOURCES= .last_test.meta | cut -d= -f2-) && \
	SIM_BUILD=$$(grep ^SIM_BUILD= .last_test.meta | cut -d= -f2-) && \
	echo ">>> Generating Verilator JSON for top=$$TOPLEVEL ..." && \
	verilator -cc -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC --json-only \
		--top-module $$TOPLEVEL \
		--prefix Vtop \
		-Mdir $$SIM_BUILD \
		$$SRCS

stems: json
	@test -f .last_test.meta || (echo "Error: No previous test run. Run a test first." && exit 1)
	@SIM_BUILD=$$(grep ^SIM_BUILD= .last_test.meta | cut -d= -f2-) && \
	$(JSON2STEMS_BIN) $$SIM_BUILD/Vtop.tree.json $$SIM_BUILD/Vtop.tree.meta.json $(PROJECT_NAME).stems

vcd2fst:
	vcd2fst dump.vcd dump.fst

view: stems vcd2fst
	gtkwave -t $(PROJECT_NAME).stems $(PWD)/dump.fst --save=$(PROJECT_NAME).gtkw --rcfile gtkwave.rc -g --dark

################################################################################
# Synthesis Flow (sv2v + Yosys)
################################################################################

YOSYS ?= yosys
SYNTHDIR ?= synth_out

synth:
	@mkdir -p $(SYNTHDIR)
	sv2v --incdir $(VERILOG_SRC_DIR) -E logic $(foreach f,counter.sv top.sv,$(VERILOG_SRC_DIR)/$(f)) -w $(SYNTHDIR)/photon_permutation.v
	$(YOSYS) -p "read_verilog -sv $(SYNTHDIR)/photon_permutation.v; synth; write_verilog $(SYNTHDIR)/photon_permutation_synth.v"

################################################################################
# Coverage
################################################################################

coverage:
	@echo "-- COVERAGE HTML GENERATION ----------------"
	verilator_coverage --write-info coverage.info coverage.dat
	genhtml coverage.info --output-directory coverage_html
	@echo "Coverage HTML generated in ./coverage_html"

open-coverage:
	@echo "-- OPENING COVERAGE HTML -------------------"
	open coverage_html/index.html

################################################################################
# Help
################################################################################

help:
	@echo "Usage:"
	@echo "  make test_<name>      Run a specific testbench (e.g. test_counter_tb)"
	@echo "  make test_all         Run all tests"
	@echo "  make json / stems     Generate structural netlists and view"
	@echo "  make view             Open GTKWave with stems and FST"
	@echo "  make synth            Run synthesis with sv2v and Yosys"
	@echo "  make coverage         Generate Verilator coverage report"
	@echo "  make clean-all        Remove all generated files"

################################################################################
# Clean
################################################################################

clean-all:
	@echo ">>> Cleaning simulation and intermediate build files..."
	rm -rf sim_build obj_dir $(SYNTHDIR) coverage_html
	rm -f dump.vcd dump.fst results.xml *.stems *.dat *.info .last_test.meta

################################################################################
# Phony Targets
################################################################################

.PHONY: help view synth coverage open-coverage clean-all test_all $(ALL_TESTS)

