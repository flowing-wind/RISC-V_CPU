`timescale 1ns/1ps

module tb_riscv ();

    localparam MS = 1000000;
    localparam US = 1000;

    reg sys_clk;
    reg sys_rst;
    reg uart_rx;
    wire uart_tx;
    
    parameter BIT_PERIOD = 104167;

    top dut (
        .sys_clk      (sys_clk),
        .sys_rst      (sys_rst),     
        .isp_uart_rx  (uart_rx),
        .isp_uart_tx  (uart_tx),
        .user_uart_rx (1'b1),
        .user_uart_tx ()
    );

    initial begin
        sys_clk = 0;
        forever #10 sys_clk = ~sys_clk;
    end

    initial begin
        sys_rst = 1;
        #100;
        sys_rst = 0;
    end

    task send_uart_char(input [7:0] char);
        integer i;
        begin
            uart_rx = 0;
            #BIT_PERIOD;
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = char[i];
                #BIT_PERIOD;
            end
            uart_rx = 1;
            #BIT_PERIOD;
        end
    endtask

    task wait_uart_char(output [7:0] char);
        integer i;
        begin
            @(negedge uart_tx);
            #(BIT_PERIOD / 2);
            for (i = 0; i < 8; i = i + 1) begin
                #(BIT_PERIOD);
                char[i] = uart_tx;
            end
            #(BIT_PERIOD);
        end
    endtask

    integer file_ptr;
    integer file_size;
    integer i;
    reg [7:0] bin_buffer [0:16383];
    reg [7:0] rx_byte;

    initial begin
        uart_rx = 1;
        
        file_ptr = $fopen("main.bin", "rb");
        if (file_ptr == 0) begin
            $display("--- TB: Error: Could not open main.bin! ---");
            $finish;
        end
        file_size = 0;
        while (!$feof(file_ptr)) begin
            bin_buffer[file_size] = $fgetc(file_ptr);
            file_size = file_size + 1;
        end
        file_size = file_size - 1;
        $fclose(file_ptr);
        $display("--- TB: Loaded main.bin, size: %0d bytes ---", file_size);

        $display("--- TB: Waiting for CMD_READY (0x5A)... ---");
        wait_uart_char(rx_byte);
        if (rx_byte == 8'h5A) 
            $display("--- TB: Received 0x5A (Ready)! ---");
        else 
            $display("--- TB: Warning: Received unexpected byte: %h ---", rx_byte);

        #(100 * US);
        $display("--- TB: Sending Handshake (0x8A 0xBF)... ---");
        send_uart_char(8'h8A);
        send_uart_char(8'hBF);

        wait_uart_char(rx_byte);
        wait_uart_char(rx_byte);
        $display("--- TB: Handshake ACK received! ---");

        $display("--- TB: Sending program size: %0d ---", file_size);
        send_uart_char(file_size[7:0]);
        send_uart_char(file_size[15:8]);
        send_uart_char(file_size[23:16]);
        send_uart_char(file_size[31:24]);

        $display("--- TB: Sending program data... ---");
        for (i = 0; i < file_size; i = i + 1) begin
            send_uart_char(bin_buffer[i]);
            if (i % 512 == 0) $display("--- TB: Sent %0d bytes ---", i);
        end

        $display("--- TB: Update Done. Waiting for jump... ---");
        #(10 * MS);
        $stop;
    end

endmodule
