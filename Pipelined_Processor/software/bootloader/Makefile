CC      = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy
OBJDUMP = riscv64-unknown-elf-objdump
PYTHON  = python

ARCH_FLAGS = -march=rv32i -mabi=ilp32
CFLAGS     = $(ARCH_FLAGS) -g -nostartfiles -I.
LDFLAGS    = -T bootloader.ld

TARGET = bootloader
ELF    = $(TARGET).elf
HEX    = $(TARGET).hex
DIS    = $(TARGET).dis
COE    = $(TARGET).coe


all: $(ELF) $(HEX) $(DIS) $(COE)

$(ELF): start.S bootloader.c bootloader.ld
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(ELF) start.S bootloader.c uart.c

$(HEX): $(ELF)
	$(OBJCOPY) -j .text -j .data -j .rodata -O verilog --verilog-data-width=4 $(ELF) $(HEX)

$(DIS): $(ELF)
	$(OBJDUMP) -D -S $(ELF) > $(DIS)

$(COE): $(HEX)
	$(PYTHON) hex2coe.py

elf: $(ELF)
hex: $(HEX)
dis: $(DIS)
coe: $(COE)

clean:
	rm -f $(ELF) $(HEX) $(DIS) $(COE)

.PHONY: all clean elf hex dis coe