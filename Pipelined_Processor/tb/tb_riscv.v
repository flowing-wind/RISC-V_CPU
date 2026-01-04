`timescale 1ns/1ps

module tb_riscv ();

    localparam MS = 1000000;
    localparam US = 1000;

    reg sys_clk;
    reg sys_rst;

    // UART para
    reg uart_rx;
    wire uart_tx;
    parameter BIT_PERIOD = 104167;

    top dut (
        .sys_clk (sys_clk),
        .sys_rst (sys_rst),

        .uart_rx (uart_rx),
        .uart_tx (uart_tx)
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
        sys_rst = 1;
        #20;
        sys_rst = 0;
    end

    task send_uart_char(input [7:0] char);
        integer i;
        begin
            uart_rx = 0;    // start
            #BIT_PERIOD;

            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = char[i];
                #BIT_PERIOD;
            end

            uart_rx = 1;    // stop
            #BIT_PERIOD;

            $display("--- Testbench: Sent character '%c' (0x%h) ---", char, char);
        end
    endtask

    initial begin
        uart_rx = 1;

        #(1 * MS);
        send_uart_char(8'h41);  // 'A'

        #(8 * MS);
        $stop;
    end


    // load testcase
    initial begin
        // vivado sim
        // $readmemh("main.hex", dut.mem.inst.native_mem_mapped_module.blk_mem_gen_v8_4_12_inst.memory);
    end

    // debug
    // wire [31:0] debug_gp = dut.cpu.d_unit.rf.regs[3];
    // wire is_writing_tohost = (|dut.MemWrite_EN) && (dut.MemAddr == 32'h1000);
    // wire [31:0] tohost_data = dut.WriteData;

    // used fot tcl
    // reg [1:0] test_status = 2'd0;

    // always @(*) begin
    //     if (is_writing_tohost) begin
    //         #5;
    //         if (tohost_data == 1) begin
    //             $display("--- Verilog: Test Passed (Write 1 to tohost) ---");
    //             test_status = 2'd1;
    //         end
    //         else begin
    //             $display("--- Verilog: Test Failed (Write %h to tohost) ---", tohost_data);
    //             test_status = 2'd2;
    //         end
            
    //         #2;
    //         $stop;
    //     end
    // end

endmodule
