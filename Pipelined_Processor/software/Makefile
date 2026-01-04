CC      = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy
OBJDUMP = riscv64-unknown-elf-objdump
PYTHON  = python

ARCH_FLAGS = -march=rv32i_zicsr -mabi=ilp32
CFLAGS     = $(ARCH_FLAGS) -g -nostartfiles -I.
LDFLAGS    = -T link.ld

TARGET = main
ELF    = $(TARGET).elf
BIN    = $(TARGET).bin
HEX    = $(TARGET).hex
DIS    = $(TARGET).dis
COE    = $(TARGET).coe


all: $(ELF) $(BIN) $(HEX) $(DIS) $(COE)

$(ELF): start.S main.c link.ld
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(ELF) start.S main.c uart.c

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $(ELF) $(BIN)

$(HEX): $(ELF)
	$(OBJCOPY) -j .text -j .data -j .rodata -O verilog --verilog-data-width=4 $(ELF) $(HEX)

$(DIS): $(ELF)
	$(OBJDUMP) -D -S $(ELF) > $(DIS)

$(COE): $(HEX)
	$(PYTHON) hex2coe.py


elf: $(ELF)
bin: $(BIN)
hex: $(HEX)
dis: $(DIS)
coe: $(COE)

clean:
	rm -f $(ELF) $(BIN) $(HEX) $(DIS) $(COE)

.PHONY: all clean elf bin hex dis coe