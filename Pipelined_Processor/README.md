# Pipelined RISC-V Processor

A high-performance **7-stage pipelined** RISC-V processor implementation supporting the **RV32I** Base Integer Instruction Set and **Zicsr** extension. This project features a robust hazard detection unit, exception/interrupt handling, and an AXI-Lite bridge for peripheral communication.

## 🚀 Architectural Features

- **7-Stage Pipeline:** Optimized stages including `F1` (PC generation), `F2` (Instruction Fetch), `D` (Decode), `E` (Execute), `M1` (Address generation), `M2` (Memory Access), and `W` (Writeback).
- **Hazard Unit:**
  - **Data Forwarding:** Resolves RAW hazards across multiple stages.
  - **Stall & Flush:** Handles Load-use hazards and control hazards (Branch/Jump/Exceptions).
- **CSR & Exceptions:** Full support for `ECALL`, `MRET`, and Illegal Instructions. Implements key CSRs like `mstatus`, `mie`, `mtvec`, `mepc`, and `mcause`.
- **Memory System:**
  - **Tightly Coupled Memory:** BRAM-based Instruction and Data memory.
  - **AXI-Lite Bridge:** Connects the CPU core to AXI-compliant peripherals such as UART.
- **MMIO:** Memory-mapped UART access at `0x1000_0000`.

## 📂 Directory Structure

```
Pipelined_Processor/
├── rtl/                # Verilog source files
│   ├── processor_core.v # CPU Core top
│   ├── hazard_unit.v    # Forwarding and Stall logic
│   ├── axi_bridge.v     # CPU-to-AXI-Lite Master bridge
│   └── ...              # Datapath, Controller, CSR file, etc.
├── rv32ui-p-tests/      # Official RISC-V Architecture Tests
│   ├── hex/             # Memory images for simulation
│   └── dump/            # Disassembled files for debugging
├── software/           # Embedded software development kit
│   ├── demo/            # Sample C programs (Bubble Sort, Fibonacci, etc.)
│   ├── start.S          # Assembly startup and ISR vector
│   ├── link.ld          # Linker script for memory mapping
│   └── Makefile         # Software build system
├── tcl/                # Vivado automation scripts
└── tb/                 # Testbench (Supports TCL regression & C software)
```

## 🛠️ Toolchain Prerequisites

- **Vivado Design Suite:** For FPGA synthesis and simulation.
- **RISC-V GNU Toolchain:** `riscv64-unknown-elf-` (compiled for `rv32i`).
- **Python 3:** For memory image conversion.

## 🧪 Verification & Testing
   ### 1. Official ISA Regression (Automated)

   This flow uses the official RISC-V test suite to verify the architectural correctness of every instruction. The process is automated via a Vivado Tcl script that runs all cases in batch.

   - **Command (Batch Mode):**

     ```bash
     vivado -mode batch -source <path to run_tests.tcl>
     ```

   - **Command (Vivado Tcl Console):**

     ```bash
     source <path to run_tests.tcl>
     ```

   The script copies individual `.hex` files from `rv32ui-p-tests/hex/` to `tcl/current_test.hex` for the testbench to read, then monitors the `test_status` signal for PASS (1) or FAIL (2).

   ### 2. Custom Software Execution (C Demos)

   You can compile and run custom C programs to test complex workloads or MMIO peripherals.

   1. **Select a Demo:** Navigate to `software/demo/` and copy your target (e.g. `bubble_sort.c`) to the `software/` root.

      ```bash
      cp software/demo/bubble_sort.c software/main.c
      ```

   2. **Compile:** Run the Makefile to generate binaries and COE files.

      ```bash
      cd software
      uv run make all
      ```

      - The `make all` command generates `main.bin`, `main.hex`, and uses `hex2coe.py` to create a `.coe` file.

   3. **Simulate:** Load the generated `.hex` into the simulation environment or update the BRAM IP with the `.coe` file for FPGA deployment.

## 🔌 Peripheral Access (MMIO)

- **BRAM (Main Memory):** `0x0000_0000` ~ `0x0FFF_FFFF`.
- **UART Controller:** `0x1000_0000` ~ `0x1FFF_FFFF`.
