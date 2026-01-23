# Single-Cycle RISC-V Processor

A complete, from-scratch implementation of a **Single-Cycle RISC-V Processor** supporting the **RV32I** Base Integer Instruction Set. This project includes the hardware description (Verilog), a custom Python-based assembler, a C software execution environment, and a comprehensive automated verification framework using Cocotb and a Python Golden Model.

## ✨ Key Features

- **RV32I ISA Support:** Implements all major instruction types: R, I, S, B, U, and J.
- **Single-Cycle Architecture:** Executing one instruction per clock cycle.
- **Full Software Stack:**
  - **C Environment:** Supports C programming with a custom linker script and startup assembly.
  - **Custom Assembler:** A Python script to convert RISC-V assembly into machine code binaries.
- **Advanced Verification:**
  - **Cocotb Testbench:** Integration of Python-based hardware verification.
  - **Golden Model:** A cycle-accurate Python CPU simulator to verify RTL results.
- **FPGA Ready:** Includes a top-level wrapper with **Memory-Mapped I/O (MMIO)** to control hardware peripherals like LEDs.

## 📂 Project Structure

```
Single-Cycle_Processor/
├── rtl/                # Hardware Description Language (Verilog)
├── asm/                # Custom Assembler
├── software/           # C Program and Toolchain scripts
├── dv/                 # Automated Verification (Cocotb & Python Model)
└── tb/                 # Verilog Testbench
```

## 🛠️ Instruction Set Support

The processor core and assembler support the following RV32I instructions:

- **Arithmetic:** `add`, `sub`, `addi`, `lui`, `auipc`
- **Logical:** `and`, `or`, `xor`, `andi`, `ori`, `xori`
- **Shift:** `sll`, `srl`, `sra`, `slli`, `srli`, `srai`
- **Compare:** `slt`, `sltu`, `slti`, `sltiu`
- **Branch:** `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`
- **Jump:** `jal`, `jalr`
- **Memory:** `lw`, `lh`, `lb`, `lhu`, `lbu`, `sw`, `sh`, `sb`

## 🚀 Getting Started

### 1. Prerequisites

- **Icarus Verilog:** For RTL simulation.
- **Python 3.x:** For the assembler and verification.
- **Cocotb:** `pip install cocotb cocotb-test`.
- **RISC-V Toolchain:** `riscv64-unknown-elf-gcc` (for C compilation).

### 2. Running Verification

To run the automated test suite which compares the RTL against the Python Golden Model:

```bash
cd dv
uv run make run_test
```

The system will:

1. Run the `cpu_model.py` to generate expected register and memory states.
2. Compile the `main.asm` using the custom assembler.
3. Execute the RTL simulation and report any mismatches.

### 3. Compiling C Software

To compile the provided C demo (LED blinking):

```bash
cd software
uv run make all
```

This generates `main.bin`, which can be loaded into the instruction memory (`imem.v`).

## 🔌 Memory Mapping (MMIO)

The processor uses a simple address decoding scheme for peripherals:

- **Data Memory:** `0x00002000` to `0x00002FFF` (4KB).
- **LED Peripheral:** `0x80000000`. Writing `1` turns the LED ON; `0` turns it OFF.