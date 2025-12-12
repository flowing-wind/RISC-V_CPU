SIM ?= icarus
TOPLEVEL_LANG ?= verilog

PROJ_DIR = ../..

VERILOG_SOURCES += $(wildcard $(PROJ_DIR)/rtl/*.v) $(wildcard $(PROJ_DIR)/tb/*.v)

TOPLEVEL = tb_riscv
MODULE = test_top   

ASM_SRC = instr.asm
HEX_DST = instr.txt
EXP_JSON = expected_regs.json
ASM_DIR = $(PROJ_DIR)/asm

.PHONY: run_test gen compile_hex cleanup

run_test: cleanup gen compile_hex
	$(MAKE) sim; \
	RET=$$?; \
	rm -f $(ASM_DIR)/$(ASM_SRC) $(ASM_DIR)/$(HEX_DST); \
	exit $$RET

gen:
	@echo "[Gen] Generating Random Assembly..."
	python cpu_model.py

compile_hex:
	@echo "[CC] Compiling Assembly to Hex"
	cp $(ASM_SRC) $(ASM_DIR)/$(ASM_SRC)
	$(MAKE) -C $(PROJ_DIR) asm
	cp $(ASM_DIR)/$(HEX_DST) .

cleanup:
	@echo "[Clean] Cleaning up previous run..."
	rm -f $(ASM_SRC) $(HEX_DST) $(EXP_JSON) results.xml wave.vcd
	rm -f $(ASM_DIR)/$(ASM_SRC)


include $(shell cocotb-config --makefiles)/Makefile.sim
