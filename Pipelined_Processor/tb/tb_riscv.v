`timescale 1ns/1ps

module tb_riscv ();

    localparam MS = 1000000;
    localparam US = 1000;

    reg sys_clk;
    reg sys_rst_n;

    // UART para
    reg uart_rx;
    wire uart_tx;
    parameter BIT_PERIOD = 104167;

    top dut (
        .sys_clk (sys_clk),
        .sys_rst_n (sys_rst_n),

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
        sys_rst_n = 0;
        #20;
        sys_rst_n = 1;
    end

    // load testcase
    initial begin
        // vivado sim
        // $readmemh("main.hex", dut.mem.inst.native_mem_mapped_module.blk_mem_gen_v8_4_12_inst.memory);
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
        end
    endtask

    // initial begin
    //     uart_rx = 1;

    //     #(15 * MS);
    //     send_uart_char(8'h41);  // 'A'

    //     #(8 * MS);
    //     $stop;
    // end


    // 定义文件处理相关的变量
    integer file_ptr;
    integer file_size;
    integer i;
    reg [7:0] bin_buffer [0:16383]; // 准备一个 16KB 的缓冲区存储 main.bin

    initial begin
        uart_rx = 1; // 初始状态为高电平 (空闲) [cite: 301]

        // ---------------------------------------------------------
        // 1. 读取 main.bin 文件到缓冲区
        // ---------------------------------------------------------
        file_ptr = $fopen("main.bin", "rb"); // 以二进制只读方式打开
        if (file_ptr == 0) begin
            $display("--- Error: Could not open main.bin! ---");
            $finish;
        end
        
        file_size = 0;
        // 循环读取直到文件结束
        while (!$feof(file_ptr)) begin
            bin_buffer[file_size] = $fgetc(file_ptr);
            file_size = file_size + 1;
        end
        file_size = file_size - 1; // 减去最后的 EOF
        $fclose(file_ptr);
        $display("--- TB: Loaded main.bin, size: %0d bytes ---", file_size);

        // ---------------------------------------------------------
        // 2. 等待硬件复位和 Bootloader 启动
        // ---------------------------------------------------------
        #(200 * US); // 等待一段时间，确保 Bootloader 已经运行并发送了 'R' [cite: 294]
        
        // ---------------------------------------------------------
        // 3. 发送 4 字节的程序长度 (prog_size)
        // ---------------------------------------------------------
        // Bootloader 使用小端序读取 4 字节
        $display("--- TB: Sending program size: %0d ---", file_size);
        send_uart_char(file_size[7:0]);
        send_uart_char(file_size[15:8]);
        send_uart_char(file_size[23:16]);
        send_uart_char(file_size[31:24]);

        // ---------------------------------------------------------
        // 4. 发送程序内容
        // ---------------------------------------------------------
        $display("--- TB: Sending program data... ---");
        for (i = 0; i < file_size; i = i + 1) begin
            send_uart_char(bin_buffer[i]);
            if (i % 128 == 0) $display("--- TB: Sent %0d bytes ---", i);
        end

        // ---------------------------------------------------------
        // 5. 等待运行结果
        // ---------------------------------------------------------
        $display("--- TB: Transfer complete. Waiting for app to run... ---");
        #(10 * MS); // 给程序运行时间，观察仿真波形中的 uart_tx
        $stop;
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
