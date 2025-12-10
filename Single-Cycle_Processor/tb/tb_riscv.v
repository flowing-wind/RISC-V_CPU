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
        .addr (pc[7:2]),    // 32 bits at a time

        .rd (instr)
    );

    // Data Memory
    dmem dmem_unit (
        .clk (clk),
        .we (mem_write),
        .addr (data_addr),
        .wd (write_data),

        .rd (read_data)
    );

    // Generate clk
    always begin
        #5 clk = ~clk;  // T = 10ns
    end

    // Test process
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_riscv);
        
        // init
        clk = 0;
        reset = 1;
        #20 reset = 0;

        #500;
        $finish;
    end

    always @(negedge clk ) begin
        if (mem_write)
            $display("Write data %h to dmem address %h.", write_data, data_addr);
        // $display("PC=%h | x1=%h, x2=%h, x3=%h, x4=%h",
        //         dut.pc,
        //         dut.d_unit.rf.rf[1],
        //         dut.d_unit.rf.rf[2],
        //         dut.d_unit.rf.rf[3],
        //         dut.d_unit.rf.rf[4]);
    end
    
endmodule

