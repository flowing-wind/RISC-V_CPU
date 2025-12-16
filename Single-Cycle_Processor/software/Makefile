CROSS_COMPILE = riscv64-unknown-elf-
CC = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

CFLAGS = -march=rv32i -mabi=ilp32 -nostdlib -g

RTL_SRC = $(wildcard ../rtl/*.v) $(wildcard ../tb/*.v)
SIM_DIR = sim

all: run

main.elf: start.S main.c link.ld
		$(CC) $(CFLAGS) -T link.ld start.S main.c -o main.elf

main.bin: main.elf
		$(OBJCOPY) -O binary main.elf main.bin

main.hex: main.elf
		$(OBJCOPY) -O verilog --verilog-data-width=4 main.elf main.hex

main.asm: main.elf
		$(OBJDUMP) -D main.elf > main.asm

run: clean main.bin
	@echo "--- Preparing Simulation Directory ---"
	mkdir -p $(SIM_DIR)
	@echo "--- Compiling RTL ---"
	iverilog -o $(SIM_DIR)/cpu_sim.out $(RTL_SRC)
	@echo "--- Running Simulation ---"

	vvp $(SIM_DIR)/cpu_sim.out

wave:
	gtkwave $(SIM_DIR)/wave.vcd

clean:
		rm -f *.elf *.bin *.asm *.hex
		rm -rf $(SIM_DIR)
		