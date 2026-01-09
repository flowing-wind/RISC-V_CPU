# Design and Implementation of a simple 

# 7-Stage Pipelined RISC-V Processor

## Introduction
This article presents the development of a 7-stage pipelined RISC-V processor. We outline the architectural evolution from a basic single-cycle core to a full RV32I-compliant processor. By transitioning to a 7-stage pipeline, we significantly optimized the system's instruction throughput. Finally, the design was integrated with a UART peripheral and deployed on an FPGA, where it successfully executed C-based applications, proving its reliability in a real hardware environment.

## Single-Cycle Processor

This microarchitecture executes instructions in a single cycle. Figure 1.1 shows a basic structure of a single-cycle processor.

<figure>
  <img src="E:\Projects\RISC-V_CPU\_attachment\Figure_1_1.png" />
  <figcaption style="text-align: center; color: gray;">
      Figure 1.1: Basic Single-Cycle Processor
  </figcaption>
</figure>

However, this structure supports only a few RV32I instructions, changes must be made to handle every RV32I instruction.

### 1. 