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
        #100;
        sys_rst_n = 1;

        #200000;
        $stop;
    end

endmodule
