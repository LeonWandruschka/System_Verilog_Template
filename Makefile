# Makefile
# Project: System Verilog Template | Simulation & Synthesis

.DEFAULT_GOAL := help

include config.mk

################################################################################
# Verilator Options
################################################################################

EXTRA_ARGS += --trace --trace-structs
EXTRA_ARGS += -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -O0 
EXTRA_ARGS += --coverage

################################################################################
# Include Cocotb Makefiles
################################################################################

COCOTB_MAKEFILE := $(shell cocotb-config --makefiles)/Makefile.sim
include $(COCOTB_MAKEFILE)

################################################################################
# Test Template
################################################################################

ALL_TESTS :=

define TEST_template
$(1):
	@echo ""
	@echo -e "\033[1;32m>>> Running Cocotb testbench: $(1)<<<\033[0m"
	@echo ""
	@echo "TOPLEVEL=$(2)" > .last_test.meta
	@echo "VERILOG_SOURCES=$(3)" >> .last_test.meta
	@echo "SIM_BUILD=sim_build/$(1)" >> .last_test.meta
	$(MAKE) -f $(COCOTB_MAKEFILE) \
		SIM=$(SIM) TOPLEVEL_LANG=$(TOPLEVEL_LANG) \
		TOPLEVEL=$(2) MODULE=tb.$(1) \
		VERILOG_SOURCES="$(3)" \
		SIM_BUILD=sim_build/$(1) \
		EXTRA_ARGS="$(EXTRA_ARGS)"
ALL_TESTS += $(1)
endef

################################################################################
# Synthesis Template
################################################################################

define SYNTH_template
synth_$(1):
	@mkdir -p $(SYNTHDIR)
	$(eval SYNTH_SRCS := $(foreach f,$(3),$(VERILOG_SRC_DIR)/$(f)))
	sv2v --incdir $(VERILOG_SRC_DIR) -E logic $(SYNTH_SRCS) -w $(SYNTHDIR)/$(1).v
	$(YOSYS) -p "read_verilog -sv $(SYNTHDIR)/$(1).v; synth; write_verilog $(SYNTHDIR)/$(1)_synth.v"
endef

################################################################################
# Evaluate Test Definitions
################################################################################

# Parse space-separated entries with semicolon-delimited file list in 3rd field

define PARSE_TEST_ENTRY
$(eval NAME := $(word $(1),$(TEST_DEFS)))
$(eval TOP  := $(word $(shell echo $$(($(1)+1))),$(TEST_DEFS)))
$(eval FILES_RAW := $(word $(shell echo $$(($(1)+2))),$(TEST_DEFS)))
$(eval FILES := $(subst ;, ,$(FILES_RAW)))
$(eval SRCS := $(foreach f,$(FILES),$(VERILOG_SRC_DIR)/$(f)))
$(eval $(call TEST_template,$(NAME),$(TOP),$(SRCS)))
$(eval $(call SYNTH_template,$(NAME),$(TOP),$(FILES)))
endef

NUM_WORDS := $(words $(TEST_DEFS))
NUM_TESTS := $(shell echo $$(( $(NUM_WORDS) / 3 )))

$(foreach i,$(shell seq 0 $(shell echo $$(( $(NUM_TESTS) - 1 )))), \
  $(eval OFFSET := $(shell echo $$(( $(i) * 3 + 1 )))) \
  $(eval $(call PARSE_TEST_ENTRY,$(OFFSET))) \
)

test_all: $(ALL_TESTS)

################################################################################
# RTL View (RTLBrowse + GTKWave)
################################################################################

JSON2STEMS_BIN := json2stems/json2stems

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
	gtkwave -t $(PROJECT_NAME).stems $(PWD)/dump.fst --save=$(PROJECT_NAME).gtkw --rcfile gtkwave.rc -g --dark -d

################################################################################
# Default Synthesis Target = First Test
################################################################################

SYNTH_TEST := $(word 1,$(TEST_DEFS))
synth: synth_$(SYNTH_TEST)

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
	@echo "  make <name>           Run a testbench (e.g. make counter_tb)"
	@echo "  make test_all         Run all tests"
	@echo "  make synth_<name>     Synthesize a testbench"
	@echo "  make synth            Synthesize the first test"
	@echo "  make json / stems     Generate structural netlists and view"
	@echo "  make view             Open GTKWave with stems and FST"
	@echo "  make coverage         Generate Verilator coverage report"
	@echo "  make clean-all        Remove all generated files"

################################################################################
# Clean
################################################################################

clean::
	rm -r -f $(SIM_BUILD) obj_dir
	rm -r -f $(SYNTHDIR)
	rm -r -f coverage_html
	rm -f dump.vcd dump.fst
	rm -f results.xml *.stems *.dat *.info .last_test.meta

################################################################################
# Phony Targets
################################################################################

.PHONY: help view synth coverage open-coverage clean test_all $(ALL_TESTS)

