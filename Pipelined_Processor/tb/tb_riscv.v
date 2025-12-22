`timescale 1ns/1ps

module tb_riscv ();

    reg sys_clk;
    reg sys_rst_n;

    top dut (
        .sys_clk (sys_clk),
        .sys_rst_n (sys_rst_n)
    );

    // debug for gtkwave
    wire [31:0] debug_gp = dut.cpu.d_unit.rf.regs[3];
    wire [31:0] debug_a1 = dut.cpu.d_unit.rf.regs[11];
    wire [31:0] debug_a2 = dut.cpu.d_unit.rf.regs[12];
    wire [31:0] debug_a4 = dut.cpu.d_unit.rf.regs[14];
    wire [31:0] debug_t2 = dut.cpu.d_unit.rf.regs[7];

    // Generate clock, T = 20ns
    initial begin
        sys_clk = 0;
        forever begin
            #10;
            sys_clk = ~sys_clk;
        end
    end

    // Reset
    initial begin
        sys_rst_n = 0;
        #20;
        sys_rst_n = 1;

        #10000;
        $finish;
    end

    // load testcase
    initial begin
        // vivado sim
        $readmemh("rv32ui-p-lb.hex", dut.imem.inst.native_mem_mapped_module.blk_mem_gen_v8_4_12_inst.memory);
        // tmp for test of dmem
        $readmemh("rv32ui-p-lb.hex", dut.dmem.inst.native_mem_mapped_module.blk_mem_gen_v8_4_12_inst.memory);

        // iverilog sim
        // $readmemh("rv32ui-p-tests/hex/rv32ui-p-add.hex", dut.imem.ram);

        // $dumpfile("sim/sim.vcd");
        // $dumpvars(0, tb_riscv);
    end

endmodule
