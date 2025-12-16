CROSS_COMPILE = riscv64-unknown-elf-
CC = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

CFLAGS = -march=rv32i -mabi=ilp32 -nostdlib -g

all: main.bin main.asm

main.elf: start.S main.c link.ld
		$(CC) $(CFLAGS) -T link.ld start.S main.c -o main.elf

main.bin: main.elf
		$(OBJCOPY) -O binary main.elf main.bin

main.asm: main.elf
		$(OBJDUMP) -D main.elf > main.asm

clean:
		rm -f *.elf *.bin *.asm
		