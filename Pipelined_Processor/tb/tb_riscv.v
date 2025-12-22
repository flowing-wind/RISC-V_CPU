`timescale 1ns/1ps

module tb_riscv ();

    reg sys_clk;
    reg sys_rst_n;

    top dut (
        .sys_clk (sys_clk),
        .sys_rst_n (sys_rst_n)
    );

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
        // $readmemh("add.hex", dut.imem.inst.native_mem_module.blk_mem_gen_v8_4_12_inst.memory);
        $readmemh("rv32ui-p-tests/hex/rv32ui-p-add.hex", dut.imem.ram);

        $dumpfile("sim/sim.vcd");
        $dumpvars(0, tb_riscv);
    end

endmodule
