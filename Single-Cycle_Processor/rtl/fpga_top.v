`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/16 17:43:17
// Design Name: 
// Module Name: fpga_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fpga_top(
    input sys_clk,
    input sys_rst_n,
    output led
    );

    // clock
    reg [24:0] clk_div;
    always @(posedge sys_clk) begin
        clk_div <= clk_div + 1;
    end

    wire clk_core = clk_div[1];

    wire reset = ~sys_rst_n;

    wire [31:0] pc, instr, read_data, alu_result, write_data;
    wire mem_write;

    riscv_processor cpu (
        .clk (clk_core),
        .reset (reset),
        .instr (instr),
        .read_data (read_data),

        .mem_write (mem_write),
        .pc (pc),
        .alu_result (alu_result),
        .write_data (write_data)
    );

    imem imem_inst (
        .addr (pc[31:2]),

        .rd (instr)
    );

    // Address Decoding
    wire is_mmio_addr = (alu_result == 32'h8000_0000);
    wire is_dmem_addr = (alu_result < 32'h0000_3000);

    wire dmem_we = mem_write && is_dmem_addr;

    // DMEM
    wire [31:0] dmem_out;
    dmem dmem_inst (
        .clk (clk_core),
        .we (dmem_we),
        .addr (alu_result),
        .wd (write_data),
        .funct3 (instr[14:12]),

        .rd (dmem_out)
    );

    // MMIO LED
    reg led_reg;
    always @(posedge clk_core) begin
        if (reset) begin
            led_reg <= 1'b0;
        end
        else if (mem_write && is_mmio_addr) begin
            led_reg <= write_data[0];
        end
    end

    assign read_data = (is_mmio_addr) ? {31'b0, led_reg} : dmem_out;

    assign led = led_reg;

endmodule
