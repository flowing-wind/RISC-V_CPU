# tools
iverilog = iverilog
vvp      = vvp
python   = python
rm       = rm -rf

# path
rtl_dir = rtl
tb_dir = tb
asm_dir = asm
sim_dir = sim

# file
asm_src		= $(asm_dir)/instr.asm
hex_file	= $(asm_dir)/instr.txt
hex_sim		= $(sim_dir)/instr.txt
wave_file 	= $(sim_dir)/wave.vcd
target		= $(sim_dir)/riscv_sim
srcs		= $(wildcard $(rtl_dir)/*.v) $(wildcard $(tb_dir)/*.v)

# --------------------------------------------- #

# default run all
all: run

# 1. create sim dir
$(sim_dir):
	mkdir -p $(sim_dir)

# 2. assemble .asm file
$(hex_file): $(asm_src)
	@echo "[ASM] Assembling code..."
	cd $(asm_dir) && $(python) asm.py

$(hex_sim): $(hex_file) | $(sim_dir)
	@echo "[Copy] Copying hex file to sim dir..."
	mv $(hex_file) $(hex_sim)

# 3. compile verilog
$(target): $(srcs) $(hex_sim)
	@echo "[IVERILOG] Compiling Verilog..."
	$(iverilog) -o $(target) $(srcs)

# 4. Run simulation
$(wave_file): $(target)
	@echo "[SIM] Running Simulation..."
	cd $(sim_dir) && $(vvp) riscv_sim

# --------------------------------------------- #

run: $(wave_file)

asm: $(hex_file)

wave: run
	@echo "[WAVE] Opening GTKWave..."
	gtkwave $(wave_file)

clean:
	@echo "[CLEAN] Removing sim files..."
	$(rm) $(sim_dir)

.PHONY: all run asm wave clean
