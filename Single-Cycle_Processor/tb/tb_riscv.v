`timescale 1ns/1ps

module tb_riscv ();

    reg clk;
    reg reset;
    wire [31:0] read_data, write_data, data_addr;
    wire [31:0] pc, instr;
    wire mem_write;

    // RISC-V Core
    riscv_processor dut (   // DUT: Device Under Test
        .clk (clk),
        .reset (reset),
        .instr (instr),
        .read_data (read_data),

        .mem_write (mem_write),
        .pc (pc),
        .alu_result (data_addr),
        .write_data (write_data)
    );

    // Instruction Memory
    imem imem_unit (
        .addr (pc[31:2]),    // 32 bits at a time

        .rd (instr)
    );

    // Data Memory
    dmem dmem_unit (
        .clk (clk),
        .we (mem_write),
        .addr (data_addr),
        .wd (write_data),
        .funct3 (instr[14:12]),

        .rd (read_data)
    );

    // Generate clk
    always begin
        #5 clk = ~clk;  // T = 10ns
    end

    integer log_file;
    integer i;

    // Test process
    initial begin
        $dumpfile("sim/wave.vcd");
        $dumpvars(0, tb_riscv);

        log_file = $fopen("sim/result.log", "w");
        if (log_file == 0) begin
            $display("Error: Could not open sim/result.log.");
            $finish;
        end
        
        // init
        clk = 0;
        reset = 1;
        #20 reset = 0;

        #50000;

        $fdisplay(log_file, "================ FINAL REGISTER STATE ================");
        for (i = 0; i < 32; i = i + 1) begin
            $fdisplay(log_file, "x%0d  = %h (%0d)", i, dut.d_unit.rf.regs[i], $signed(dut.d_unit.rf.regs[i]));
        end

        $fdisplay(log_file, "\n================ FINAL MEMORY STATE (0x2000) ================");
        for (i = 0; i < 10; i = i + 1) begin
            $fdisplay(log_file, "Mem[%0d] = %h", i, dmem_unit.RAM[i]);
        end

        $fclose(log_file);
        $display("Simulation finished. Results saved to sim/result.log and sim/wave.vcd");
        $finish;

    end

    always @(negedge clk ) begin
        if (mem_write)
             $display("Write data %h to dmem address %h.", write_data, data_addr);
    end
    
endmodule

