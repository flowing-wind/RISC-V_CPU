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
    wire is_writing_tohost = (|dut.MemWrite_EN) && (dut.MemAddr == 32'h1000);
    wire [31:0] tohost_data = dut.WriteData;

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
    end

    // used fot tcl
    reg [1:0] test_status = 2'd0;

    always @(*) begin
        if (is_writing_tohost) begin
            #5;
            if (tohost_data == 1) begin
                $display("--- Verilog: Test Passed (Write 1 to tohost) ---");
                test_status = 2'd1;
            end
            else begin
                $display("--- Verilog: Test Failed (Write %h to tohost) ---", tohost_data);
                test_status = 2'd2;
            end
            
            #2;
            $stop;
        end
    end

    // load testcase
    initial begin
        // vivado sim
        $readmemh("rv32ui-p-ld_st.hex", dut.imem.inst.native_mem_mapped_module.blk_mem_gen_v8_4_12_inst.memory);
        // tmp for test of dmem
        $readmemh("rv32ui-p-ld_st.hex", dut.dmem.inst.native_mem_mapped_module.blk_mem_gen_v8_4_12_inst.memory);


        // iverilog sim
        // $readmemh("current_test.hex", dut.imem.ram);
        // $readmemh("current_test.hex", dut.dmem.ram);
        // $dumpfile("sim/sim.vcd");
        // $dumpvars(0, tb_riscv);
    end

endmodule
