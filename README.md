# RISC-V CPU

This repository contains two complete RISC-V processor implementations, tracing the evolution from a foundational single-cycle design to a high-performance, 7-stage pipelined architecture. Both cores are designed around the **RV32I** Base Integer Instruction Set.

## 🌟 Project Overview

### 1. Single-Cycle Processor

A classic architectural starting point where every instruction completes in exactly one clock cycle.

- **Key Features**:
	- Custom Python assembler
	- MMIO LED control
	- Cocotb-based verification against a Python Golden Model

### 2. Pipelined Processor

An advanced 7-stage implementation designed to maximize clock frequency and instruction throughput.

- **Key Features**:
	- Hazard detection (Forwarding/Stalling)
	- **Zicsr** extension support
	- AXI-Lite bus integration
	- Automated ISA regression testing

------

## 📊 Comparison at a Glance

|        **Feature**         | **Single-Cycle Core** |         **Pipelined Core**         |
| :------------------------: | :-------------------: | :--------------------------------: |
|     **Pipeline Depth**     |        1 Stage        | 7 Stages (F1, F2, D, E, M1, M2, W) |
| **CPI (Cycles Per Instr)** |      1.0 (Fixed)      |    ~1.2 - 1.5 (Due to hazards)     |
|    **Instruction Set**     |         RV32I         |           RV32I + Zicsr            |
|    **Hazard Handling**     |          N/A          |      Forwarding & Stall Unit       |
|     **Bus Interface**      |   Simple SRAM-like    |          AXI-Lite Bridge           |
|      **Verification**      | Python Model & Cocotb | Official `riscv-tests` Regression  |

## ⚖️ License

This project is licensed under the **Apache License 2.0** - see the [LICENSE](LICENSE) file for details.