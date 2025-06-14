################################################################################
# Project: System Verilog Template | Simulation & Synthesis
# Simulator: Verilator
# Testbench: Cocotb (Python)
#
# File: config.mk 
#
# Author: Leon Wandruschka
################################################################################


################################################################################
# Simulator & Language Settings
################################################################################

PROJECT_NAME 	:= counter

TOPLEVEL_LANG 	?= verilog

SIM 					?= verilator

SIM_BUILD 		?= sim_build
YOSYS 				?= yosys
SYNTHDIR 			?= synth_out

# 1 = RTL view on | 0 = RTL view off
VIEW_RTL      := 1

################################################################################
# Source Directory
################################################################################

VERILOG_SRC_DIR := $(PWD)/src


################################################################################
# Define all tests
################################################################################

# Define test list (name, topmodule, files...)
# Format: testname|topmodule|file1 file2 ...
# config.mk
TEST_DEFS := \
	counter_tb counter counter.sv \
	top_tb     top     main/top.sv;counter.sv


