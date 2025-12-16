# dv/Makefile

SIM ?= icarus
TOPLEVEL_LANG ?= verilog

PROJ_DIR = ..
RTL_DIR = $(PROJ_DIR)/rtl
ASM_SCRIPT = $(PROJ_DIR)/asm/asm.py

VERILOG_SOURCES += $(wildcard $(RTL_DIR)/*.v) $(wildcard $(PROJ_DIR)/tb/*.v)

TOPLEVEL = tb_riscv
COCOTB_TEST_MODULES = test_top   

ASM_SRC = instr.asm
BIN_FILE = main.bin
EXP_REGS = expected_regs.json
EXP_DMEM = expected_dmem.json

.PHONY: run_test gen compile_asm cleanup

run_test: cleanup gen compile_asm
	$(MAKE) sim

gen:
	@echo "[Model] Running Python Golden Model..."
	python cpu_model.py

compile_asm:
	@echo "[ASM] Compiling Assembly to Binary..."
	python $(ASM_SCRIPT) $(ASM_SRC) $(BIN_FILE)

cleanup:
	@echo "[Clean] Removing temporary files..."
	rm -f $(BIN_FILE) $(EXP_REGS) $(EXP_DMEM) results.xml wave.vcd
	rm -rf sim_build/
	rm -rf __pycache__


include $(shell cocotb-config --makefiles)/Makefile.sim

