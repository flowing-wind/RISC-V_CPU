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
arm_src		= $(asm_dir)/assembly.asm
target		= $(sim_dir)/riscv_sim
hex_file	= $(sim_dir)/testinstr.txt
wave_file 	= $(sim_dir)/wave.vcd
srcs		= $(wildcard $(rtl_dir)/*.v) $(wildcard $(tb_dir)/*.v)

# --------------------------------------------- #

# default run all
all: run

# 1. create sim dir
$(sim_dir):
	mkdir -p $(sim_dir)

# 2. assemble .asm file
$(hex_file): $(arm_src) | $(sim_dir)
	@echo "[ASM] Assembling code..."
	cd $(asm_dir) && $(python) asm.py
	mv $(asm_dir)/testinstr.txt $(hex_file)

# 3. compile verilog
$(target): $(srcs) $(hex_file)
	@echo "[IVERILOG] Compiling Verilog..."
	$(iverilog) -o $(target) $(srcs)

# 4. Run simulation
$(wave_file): $(target)
	@echo "[SIM] Running Simulation..."
	cd $(sim_dir) && $(vvp) riscv_sim

# --------------------------------------------- #

run: $(wave_file)

wave: run
	@echo "[WAVE] Opening GTKWave..."
	gtkwave $(wave_file)

clean:
	@echo "[CLEAN] Removing sim files..."
	$(rm) $(sim_dir)

.PHONY: all run wave clean
