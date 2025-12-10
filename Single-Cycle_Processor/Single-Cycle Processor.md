# Design of a Single-Cycle RISC-V Processor

## System Overview

![complete architecture](E:\Projects\RISC-V CPU\Single-Cycle Processor\_attachment\complete architecture.png)

![interfaced to ext mem](E:\Projects\RISC-V CPU\Single-Cycle Processor\_attachment\interfaced to ext mem.png)

## Modules

### Processor
The Processor is the main part of the CPU, containing a Controller and Datapath.

#### Interface
- Controller
  - Input
    - Instr [31:0]  -->  Receive instruction from (External) Instruction Memory.

  - Output
    - MemWrite  -->  Control the WE (Write Enable) port of the (External) Data Memory.
      - 0  -->  Read data from memory.
      - 1  -->  Write data to memory.

- Datapath
  - Input
    - CLK
    - Reset
    - Instr [31:0]
    - ReadData [31:0]  -->  Connect to RD port of Data Memory.

  - Output
    - PC [31:0]  -->  Pointer to the address of the instruction, connect to the A(ddress) port of Instruction Memory.
    - ALUResult [31:0]  -->  The address of the data to be read/written from Data Memory.
    - WriteData [31:0]  -->  Data to write to Data Memory.

### Controller

The Controller receives signal zero and parts of the instruction to decide the operation of each module.

#### Interface

- Input
  - zero  -->  Whether the result of ALU is zero, used for conditional branching.
  - Instr [31:0]
- Output
  - PCSrc   -->  Choose next PC between PC+4 and other branch.
  - ImmSrc [1:0]  -->  Encode ImmExt according to the instruction type.
  - ALUSrc  -->  Choose the source between reg and ImmExt before sending to ALU.
  - ResultSrc  -->  Choose the data written to RegFile between ALUResult and data from memory.
  - RegWrite  -->  Whether to write data to RegFile.
  - MemWrite
  - ALUControl [2:0]  -->  Decide the operation of ALU (add, sub, and, or).

### Datapath

Instructions are processed according to the control signals.

#### Interface

- Input
  - CLK
  - Reset
  - Instr [31:0]
  - ReadData [31:0]
  - PCSrc
  - ImmSrc [1:0]
  - ALUSrc
  - ResultSrc
  - RegWrite
  - ALUControl [2:0]
- Output
  - PC [31:0]
  - ALUResult [31:0]
  - WriteData [31:0]
  - zero