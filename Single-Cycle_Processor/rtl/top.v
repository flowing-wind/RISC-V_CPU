module riscv_processor(
    input wire clk, reset,
    input wire [31:0] instr,
    input wire [31:0] read_data,

    output wire mem_write,
    output wire [31:0] pc,
    output wire [31:0] alu_result,
    output wire [31:0] write_data
);
    wire [6:0] op = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire funct7b5 = instr[30];
    wire zero, pc_src, result_src, alu_src, reg_write;
    wire [1:0] imm_src;
    wire [2:0] alu_control;

    controller c_unit (
        .op (op),
        .funct3 (funct3),
        .funct7b5 (funct7b5),
        .zero (zero),

        .imm_src (imm_src),
        .pc_src (pc_src), 
        .alu_src (alu_src), 
        .result_src (result_src),
        .reg_write (reg_write), 
        .mem_write (mem_write),
        .alu_control (alu_control)
    );

    datapath d_unit (
        .instr (instr),
        .clk (clk),
        .reset (reset),
        .read_data (read_data),
        .imm_src (imm_src),
        .pc_src (pc_src), 
        .alu_src (alu_src), 
        .result_src (result_src),
        .reg_write (reg_write),
        .alu_control (alu_control),

        .pc (pc),
        .zero (zero),
        .alu_result (alu_result),
        .write_data (write_data)
    );

endmodule

