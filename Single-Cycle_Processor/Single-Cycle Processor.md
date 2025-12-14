# Design of a Single-Cycle RISC-V Processor

## System Overview

![complete architecture](E:\Projects\RISC-V_CPU\Single-Cycle_Processor\_attachment\complete architecture.png)

![interfaced to ext mem](E:\Projects\RISC-V_CPU\Single-Cycle_Processor\_attachment\interfaced to ext mem.png)

## History
12.14 update:

1. Extend alu_control to support more alu operations:

   | Operation | alu_control |       ex. instr        |           verilog           |
   | :-------: | :---------: | :--------------------: | :-------------------------: |
   |    ADD    |   4'b0000   | add, addi, lw, sw, jal |            A + B            |
   |    SUB    |   4'b0001   |     sub, beq, bne      |            A - B            |
   |    AND    |   4'b0010   |       and, andi        |            A & B            |
   |    OR     |   4'b0011   |        or, ori         |           A \| B            |
   |    XOR    |   4'b0100   |       xor, xori        |            A ^ B            |
   |    SLT    |   4'b0101   |       slt, slti        | `($signed(A) < $signed(B))` |
   |   SLTU    |   4'b0110   |      sltu, sltiu       |           (A < B)           |
   |    SLL    |   4'b0111   |       sll, slli        |           A << B            |
   |    SRL    |   4'b1000   |       srl, srli        |           A >> B            |
   |    SRA    |   4'b1001   |       sra, srai        |           A >>> B           |

2. Add I-Type, U-Type, J-Type logic

3. Extend imm_src to support U-Type and J-Type Instruction.

  | imm_src |  Type  |
  | :-----: | :----: |
  | 3'b000  | I-Type |
  | 3'b001  | S-Type |
  | 3'b010  | B-Type |
  | 3'b011  | U-Type |
  | 3'b100  | J-Type |

4. Add support for auipc
   - add a mux to src_a, choose between RegFile and pc
   - rename alu_src to alu_src_b, add new control signal alu_src_a

5. Add support for lui

   -  alu_src_a add new source 1'b0, for lui only
   -  alu_src [1:0]

6. Add support for jalr

   - extend pc mux, add source alu_result
   - mux result_src add source pc + 4 (write back to rd)

7. Add support for jal

   - same as beq, jump to pc + Imm(label), which is PC Target

