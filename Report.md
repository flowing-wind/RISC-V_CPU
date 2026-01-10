# Design and Implementation of a simple 

# 7-Stage Pipelined RISC-V Processor

## Introduction
This article presents the development of a 7-stage pipelined RISC-V processor. We outline the architectural evolution from a basic single-cycle core to a full RV32I-compliant processor. By transitioning to a 7-stage pipeline, we significantly optimized the system's instruction throughput. Finally, the design was integrated with a UART peripheral and deployed on an FPGA, where it successfully executed C-based applications, proving its reliability in a real hardware environment.

## Single-Cycle Processor

### Design
This microarchitecture executes instructions in a single cycle. Figure 1.1 shows a basic structure of a single-cycle processor.

<figure>
  <img src="E:\Projects\RISC-V_CPU\_attachment\Figure_1_1.png" />
  <figcaption style="text-align: center; color: gray;">
      Figure 1.1: Basic Single-Cycle Processor
  </figcaption>
</figure>

However, this structure supports only a few RV32I instructions, changes must be made to handle every RV32I instruction.

#### 1. Control Flow and Jump Support (JAL, JALR)

The basic structure in Figure 1.1 typically handles simple branches (B-Type), but full RV32I compliance requires unconditional jumps (J-Type and I-Type). To support `jal` (Jump And Link) and `jalr` (Jump And Link Register), we modified the Next PC logic and the Write-Back logic:

- **Next PC Selection:** The `jalr` instruction requires jumping to an address calculated by the ALU (register + immediate), rather than the PC-relative target used by branches. We expanded the `PCNext` multiplexer logic to select between `PC + 4`, `PCTarget` (branch/jal), and `ALUResult` (jalr).
	
	```verilog
	always @( *) begin
		case (pc_src)
			2'b00: pc_next = pc_plus4;
			2'b01: pc_next = pc_target;
			2'b10: pc_next = alu_result;
			default: pc_next = pc_plus4;
		endcase
	end
	```
	
- **Return Address Storage:** Both `jal` and `jalr` need to store the return address (`PC + 4`) into the register file. We added a result selection multiplexer (`ResultSrc`) to allow writing `PC + 4` directly to the destination register, alongside `ALUResult` and `ReadData`.
	
	```verilog
	always @( *) begin
		case (result_src)
			2'b00: result = alu_result;
			2'b01: result = mem_data_processed;
			2'b10: result = pc_plus4;
			default: result = alu_result;
		endcase
	end
	```

#### 2. Upper Immediate Instructions (LUI, AUIPC)

To support `lui` (Load Upper Immediate) and `auipc` (Add Upper Immediate to PC), we modified the ALU input multiplexers:

- **ALU Source A:** Standard instructions use the register file output `RD1`. However, `auipc` requires the current `PC` as an operand. For `lui`, the controller selects `0` for Source A and the immediate value for Source B, effectively passing the immediate through the ALU. We implemented a multiplexer for `SrcA` to select between `RD1`, `PC`, or `0`.
	
	```verilog
	always @( *) begin
		case (alu_src_a)
			2'b00: src_a = rf_rd1;
			2'b01: src_a = pc;
			2'b10: src_a = 32'b0;
			default: src_a = rf_rd1;
		endcase
	end
	```

#### 3. Sub-Word Memory Access (Load/Store)

The basic architecture assumes 32-bit word alignment. To fully support RV32I, we implemented logic for byte and half-word operations (`lb`, `lh`, `lbu`, `lhu`, `sb`, `sh`):

- **Load Logic:** We introduced a post-processing block for the data memory output. Based on the `funct3` field and the byte offset (from `ALUResult`), this logic handles sign-extension or zero-extension for bytes and half-words before writing to the register file.
	
	```verilog
	// take lb, lbu as an example
	always @( *) begin
		case (funct3)
			// lb
			3'b000: begin
				case (byte_offset)
					2'b00: mem_data_processed = {{24{read_data[7]}}, read_data[7:0]};
					2'b01: mem_data_processed = {{24{read_data[15]}}, read_data[15:8]};
					2'b10: mem_data_processed = {{24{read_data[23]}}, read_data[23:16]};
					2'b11: mem_data_processed = {{24{read_data[31]}}, read_data[31:24]};
				endcase
			end
	
			// lbu
			3'b100: begin
				case (byte_offset)
					2'b00: mem_data_processed = {24'b0, read_data[7:0]};
					2'b01: mem_data_processed = {24'b0, read_data[15:8]};
					2'b10: mem_data_processed = {24'b0, read_data[23:16]};
					2'b11: mem_data_processed = {24'b0, read_data[31:24]};
				endcase
			end
		endcase
	end
	```


- **Store Logic:** The Data Memory (`dmem`) module was updated to handle write-enable signals for specific byte lanes, allowing the processor to modify only 8 or 16 bits of a 32-bit word in memory.
	```verilog
	always @(posedge clk) begin
		if (we) begin
			case (funct3)
				// sw
				3'b010: RAM[addr[11:2]] <= wd;
				// sh
				3'b001: begin
					if (addr[1] == 0)   // low
						RAM[addr[11:2]][15:0] <= wd[15:0];
					else
						RAM[addr[11:2]][31:16] <= wd[15:0];
				end
				// sb
				3'b000: begin
					case (addr[1:0])
						2'b00: RAM[addr[11:2]][7:0]     <= wd[7:0];
						2'b01: RAM[addr[11:2]][15:8]    <= wd[7:0];
						2'b10: RAM[addr[11:2]][23:16]   <= wd[7:0];
						2'b11: RAM[addr[11:2]][31:24]   <= wd[7:0];
					endcase
				end
				default: RAM[addr[11:2]] <= wd;  
			endcase
		end
	end
	```


#### 4. ALU Functionality Expansion

The basic ALU was upgraded to handle the complete set of arithmetic and logical operations required by RV32I:

- **Comparison:** We added logic for both signed (`slt`, `blt`, `bge`) and unsigned (`sltu`, `bltu`, `bgeu`) comparisons.
- **Shifts:** The ALU was expanded to support logical shifts (`sll`, `srl`) and arithmetic right shifts (`sra`).

	| Operation | alu_control |       ex. instr        |
	| :-------: | :---------: | :--------------------: |
	|    ADD    |   4'b0000   | add, addi, lw, sw, jal |
	|    SUB    |   4'b0001   |     sub, beq, bne      |
	|    AND    |   4'b0010   |       and, andi        |
	|    OR     |   4'b0011   |        or, ori         |
	|    XOR    |   4'b0100   |       xor, xori        |
	|    SLT    |   4'b0101   |       slt, slti        |
	|   SLTU    |   4'b0110   |      sltu, sltiu       |
	|    SLL    |   4'b0111   |       sll, slli        |
	|    SRL    |   4'b1000   |       srl, srli        |
	|    SRA    |   4'b1001   |       sra, srai        |

#### 5. Control Unit Integration

Finally, the control unit was implemented to decode the 7-bit opcode, `funct3`, and `funct7` fields. It generates the expanded control signals—such as `ImmSrc`, `ALUSrcA`, `ALUSrcB`, and `PCSrc`—to coordinate the datapath modifications described above.

### Verification

For the Single-Cycle Processor, we implemented a preliminary verification framework to ensure the correctness of the core architecture before moving to the more complex pipelined design. The verification process consists of two parts: automated co-simulation for architectural compliance and a C-based on-board test for peripheral interaction.

> Note: A more comprehensive verification suite covering data hazards and advanced control flows will be detailed in the Pipelined Processor section of this report.

#### 1. Automated Co-Simulation with Cocotb
To verify the execution of standard RV32I instructions, we developed an automated testbench using Cocotb. This environment compares the state of the RTL design against a Python-based Golden Model.

- **Reference Model:**
	We built a CPU model that behaves as an instruction-set simulator. It parses the assembly code and calculates the expected state of the Register File and Data Memory for every instruction.

- **Assembly Test Case:**
	A custom assembly program (`main.asm`) was written to cover various instruction types, including R-Type arithmetic, I-Type immediate operations, Load/Store memory access, and Branch/Jump control flows.

- **Result Checking:**
	The testbench executes the assembly code on the RTL and, upon completion, dumps the values of all 32 general-purpose registers and the relevant data memory regions. These values are automatically compared against the Golden Model's output.
	
	- Regfile and Dmem will be checked like this:
	```python
	# Check regs
	rf_handle = dut.dut.d_unit.rf.regs
	mismatch =  False
	for i in range(0, 32):
		rtl_val = int(rf_handle[i].value)
		exp_val = expected_regs[i]
		if rtl_val != exp_val:
			cocotb.log.error(f"Mismatch at x{i}! Expected: {hex(exp_val)}, Got: {hex(rtl_val)}")
			mismatch = True
	if not mismatch:
		cocotb.log.info("PASS: All registers match model!")
	else:
		raise Exception("FAIL: Register mismatch detected!")
	```
	- If test passed, cocotb will return the result:
	```
	500000.00ns INFO     cocotb.regression		test_top.verify passed
	500000.00ns INFO     cocotb.regression                  **************************************************************************************
  ** TEST                          STATUS  SIM TIME (ns)  REAL TIME (s)  RATIO (ns/s) **
  **************************************************************************************
  ** test_top.verify                PASS      500000.00           0.14    3467857.26  **
  **************************************************************************************
  ** TESTS=1 PASS=1 FAIL=0 SKIP=0             500000.00           0.15    3437807.57  **                                        **************************************************************************************
  ```

#### 2. FPGA On-Board Verification
In addition to simulation, we validated the processor's capability to execute high-level compiled code on actual hardware. We wrote a simple C language program to control the LEDs on the FPGA board.

The program (`main.c`) utilizes Memory-Mapped I/O (MMIO) to toggle an LED connected to a specific address (0x80000000). It implements a delay loop to create a blinking effect. This test verifies the entire toolchain—from C compilation to instruction fetching and MMIO store operations. The processor successfully executed the program, resulting in the LED blinking as expected on the FPGA.

## Pipelined Processor
<figure>
  <img src="E:\Projects\RISC-V_CPU\_attachment\Figure_2_1.png" />
  <figcaption style="text-align: center; color: gray;">
      Figure 2.1: Pipelined processor with full hazard handling
  </figcaption>
</figure>

### Architecture Overview
To achieve higher operating frequencies and better compatibility with FPGA hardware resources (specifically Block RAMs), we evolved the single-cycle architecture into a 7-stage pipelined processor. Standard 5-stage pipelines assume asynchronous memory access (data available in the same cycle), but modern FPGA memory blocks are synchronous, requiring at least one clock cycle to fetch data.

Our 7-stage design splits the Instruction Fetch (IF) and Memory Access (MEM) stages to accommodate this latency without reducing the clock speed. The stages are defined as follows:

- **IF1 (Fetch 1):**
	The Program Counter (PC) is updated, and the address is sent to Instruction Memory.

- **IF2 (Fetch 2):**
	The instruction data is received from Memory and latched into the pipeline register.

- **ID (Decode):**
	Instruction decoding, register file reading, and immediate extension.

- **EX (Execute):**
	ALU operations and branch resolution.

- **M1 (Memory 1):**
	The ALU result is used as an address for Data Memory access.

- **M2 (Memory 2):**
	Read data is received from Data Memory and processed (byte/half-word alignment).

- **WB (Writeback):**
	Results are written back to the Register File or CSRs.

### Hazard Management
Pipelining introduces dependencies between instructions that must be resolved to ensure correct execution. We implemented a dedicated Hazard Unit (`hazard_unit.v`) to handle Data Hazards, Control Hazards, and Structural/Load-Use Hazards.

#### 1. Data Hazards and Forwarding
Since the Writeback stage (WB) is several cycles after the Execute stage (EX), an instruction needing a result from a previous instruction would typically have to wait. To minimize stalls, we implemented Forwarding logic.

The Hazard Unit monitors the source registers (Rs1, Rs2) in the Decode/Execute stages and compares them with the destination registers (Rd) in the M1, M2, and WB stages. If a match is found (and RegWrite is enabled), the latest data is forwarded directly to the ALU inputs.

##### Forwarding Paths
Data can be forwarded to the EX stage from:

- **M1 Stage:** The ALU result of the immediately preceding instruction.

- **M2 Stage:** The result from two cycles ago.

- **WB Stage:** The result from three cycles ago.
```verilog
// take SrcB as an example
// hazard_unit.v
always @( *) begin
	if (((Rs2_E_H == Rd_M1_H) && RegWrite_M1_H) && (Rs2_E_H != 0))
		ForwardB_E_r = 2'b10;
	else if (((Rs2_E_H == Rd_M2_H) && RegWrite_M2_H) && (Rs2_E_H != 0))
		ForwardB_E_r = 2'b11;
	else if (((Rs2_E_H == Rd_W_H) && RegWrite_W_H) && (Rs2_E_H != 0))
		ForwardB_E_r = 2'b01;
	else
		ForwardB_E_r = 2'b00;
    end
// datapath.v
always @( *) begin
	case (ForwardB_E)
		2'b00: WriteData_E = RD2_E;
		2'b01: WriteData_E = Result_W;
		2'b10: WriteData_E = Result_M1;
		2'b11: WriteData_E = Result_M2;
		default: WriteData_E = RD2_E;
	endcase
end
assign SrcB_E = (ALUSrc_b_E) ? ImmExt_E : WriteData_E;
```

#### 2. Load-Use Hazards and Multi-Cycle Stalls
Unlike ALU operations where the result is available immediately after the Execute stage, memory load instructions (lw, lb, etc.) incur significant latency. In our 7-stage architecture, data from memory is not available until the end of the M2 stage. This creates a hazard window of three cycles where Forwarding is impossible because the data has not yet arrived from the memory subsystem.

To handle this, we implemented a robust stall logic in the Hazard Unit that monitors the three pipeline stages ahead of the Decode stage.

##### Hazard Detection Logic
The logic identifies a hazard by checking if a Load instruction exists in the EX, M1, or M2 stages and if its destination register (Rd) matches the source registers (Rs1/Rs2) of the instruction currently in the ID stage.

The detection code utilizes the LSB of the ResultSrc signal (`ResultSrc[0]`), which is set to 1 specifically for Load instructions (where ResultSrc = 2'b01 or 2'b11 for CSR):
```verilog
always @( *) begin
	case (ResultSrc_W)
		2'b00: Result_W = ALU_Result_W;
		2'b01: Result_W = ReadData_Processed_W;
		2'b10: Result_W = PC_Plus4_W;
		2'b11: Result_W = CSR_ReadData;
		default: Result_W = ALU_Result_W;
	endcase
end
```
When a stall is asserted to freeze the fetch and decode stages (`Stall_F`, `Stall_D`), the pipeline must ensure that the Execute stage does not process invalid or duplicate instructions in the next cycle.

To achieve this, the lwStall signal also triggers Flush_E. This clears the ID/EX pipeline registers, effectively inserting a "Bubble" (NOP) into the Execute stage. This bubble propagates through the back-end stages (M1, M2, WB), ensuring no state changes occur while the dependent instruction waits in the Decode stage for the memory data to become available.
```verilog
assign lwStall = 
	// Case 1: Load in EX stage vs Instruction in ID
	(ResultSrc_E_0_H  && (Rd_E_H != 5'b0)  && ((Rs1_D_H == Rd_E_H) || (Rs2_D_H == Rd_E_H))) ||
	// Case 2: Load in M1 stage vs Instruction in ID
	(ResultSrc_M1_0_H && (Rd_M1_H != 5'b0) && ((Rs1_D_H == Rd_M1_H) || (Rs2_D_H == Rd_M1_H))) ||
	// Case 3: Load in M2 stage vs Instruction in ID
	(ResultSrc_M2_0_H && (Rd_M2_H != 5'b0) && ((Rs1_D_H == Rd_M2_H) || (Rs2_D_H == Rd_M2_H)));
	
assign Flush_E = (lwStall || (|PC_Src_E_H)) || EX_Flush_H;
```

#### 3. Control Hazards (Branching)
Branch decisions are resolved in the EX stage. We employ a "Predict Not Taken" strategy. The processor continues fetching instructions sequentially (PC+4).

If the branch is not taken, execution continues normally.

If the branch is taken, the instructions currently in the F1, F2, and ID stages are invalid. The Hazard Unit asserts Flush signals (Flush_F2, Flush_D, Flush_E) to clear these pipeline registers, and the PC is updated to the correct branch target.

### Exceptions and Interrupts
To support a realistic operating system environment and handle asynchronous events, we implemented a complete Machine-Mode CSR (Control and Status Register) unit defined in `csr_file.v`.

#### 1. CSR Architecture
We implemented the essential Machine-Mode CSRs required for a basic RISC-V trap handler. These registers are mapped to their standard 12-bit addresses:

- **mstatus (0x300):** Machine Status Register.
	It tracks the global interrupt enable (MIE) bit and the previous interrupt enable (MPIE) bit.
	
- **mie (0x304) / mip (0x344):** Machine Interrupt Enable / Pending Registers.
	Used to mask and track interrupt sources (External, Timer, Software).

- **mtvec (0x305):** Machine Trap-Vector Base-Address.
	Stores the address where the PC jumps to when a trap occurs.

- **mepc (0x341):** Machine Exception PC.
	Stores the PC of the instruction that caused the exception (or the interrupted instruction).

- **mcause (0x342):** Machine Cause.
	Stores an ID indicating the reason for the trap (e.g. interrupt or illegal instruction).

- **mtval (0x343):** Machine Trap Value.
	Stores additional information (e.g. the faulting address in a Load/Store fault).

#### 2. Interrupt Request Logic
The processor supports three types of interrupts: External (MEIP), Timer (MTIP), and Software (MSIP). The logic in csr_file.v continuously monitors external interrupt signals and updates the mip register:
```verilog
mip[11] <= ext_int; 	// MEIP
mip[7]  <= timer_int; 	// MTIP
mip[3]  <= sw_int;  	// MSIP
```
To decide if an interrupt should be serviced, the CSR unit performs a bitwise AND between pending interrupts (`mip`) and enabled interrupts (`mie`). The result is combined with the global interrupt enable (`mstatus[3]`, i.e. MIE) in the main controller to assert the interrupt_pending signal:
```verilog
assign global_int_en = mstatus[3];  	// mstatus.MIE
assign pending_interrupts = mip & mie;  // if != 1, interrupt exists
assign interrupt_pending = |pending_interrupts;
```

#### 3. Trap Entry Mechanism
When the writeback stage asserts `trap_en` (indicating an exception or interrupt is taken), the CSR file automatically updates the architectural state to preserve context and prepare for the handler. This is critical for correct execution.

- **Save PC:**
	The current PC (or the next PC for interrupts) is saved to mepc.
	```verilog
	mepc <= trap_pc;
	```

- **Record Cause:**
	The reason for the trap is written to mcause.
	```verilog
	mcause <= trap_cause;
	```

- **Update Status (mstatus):**
	The processor must disable interrupts to prevent nested traps from overwriting mepc before software can save it. We implemented a hardware stack for the interrupt enable bit:
	- Save the current MIE (bit 3) to MPIE (bit 7).
	- Set MIE (bit 3) to 0 to globally disable interrupts.
	```verilog
	mstatus[7] <= mstatus[3];   // MPIE --> store old state
	mstatus[3] <= 1'b0;    		// MIE  --> disbale interrupt
	```

#### 4. Trap Return Mechanism (MRET)
The `mret` instruction is used to return from a trap handler. When the `is_mret` signal is asserted, the CSR file reverses the operations performed during trap entry:

- **Restore Status:**
	The logic restores the global interrupt enable state from MPIE back to MIE.
	```verilog
	mstatus[3] <= mstatus[7];
	```

- **Set MPIE to 1:**
	To avoid errors in Interrupt Nesting, MPIE is reset to 1.
	```verilog
	mstatus[7] <= 1'b1; 
	```

### Design Trade-offs and Performance Analysis
Transiting from a single-cycle to a 7-stage pipeline introduces a trade-off between clock frequency and Instruction Per Cycle (IPC).

- **Frequency Improvement:**
	By breaking down critical paths (especially the memory access paths into F1/F2 and M1/M2), the logic depth per stage is reduced, allowing for a significantly higher operating frequency on the FPGA.

- **IPC Cost:**
	While the ideal IPC is 1, hazards introduce penalties.
	- **Branch Misprediction:**
		A taken branch incurs a 3-cycle penalty (flushing F1, F2, ID).

	- **Load-Use Hazard:**
		A load instruction followed immediately by a dependent instruction incurs a latency stall.

	- **Memory Latency:**
		The 2-cycle memory access is hidden by the pipeline for independent instructions but contributes to the branch/load penalties.

- **Conclusion:**
	Despite the lower IPC compared to a single-cycle machine, the substantial increase in clock speed results in a net performance gain for typical workloads. 

### Verification
