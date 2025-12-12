module datapath (
    input wire [31:0] instr,
    input wire clk, reset,
    input wire [31:0] read_data,
    input wire [1:0] imm_src,
    input wire pc_src, alu_src, result_src,
    input wire reg_write,
    input wire [2:0] alu_control,

    output reg [31:0] pc,
    output wire zero,
    output wire [31:0] alu_result,
    output wire [31:0] write_data
);
    wire [31:0] pc_next, pc_plus4, pc_target;
    wire [31:0] imm_ext;
    wire [31:0] src_a, src_b;
    wire [31:0] result;

    // PC Logic
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 32'b0;
        else
            pc <= pc_next;
    end

    // Decide next pc
    assign pc_plus4 = pc + 32'd4;
    assign pc_target = pc + imm_ext;
    assign pc_next = (pc_src) ? pc_target : pc_plus4;

    // Choose src_b
    assign src_b = (alu_src) ? imm_ext : write_data;

    // Choose result
    assign result = (result_src) ? read_data : alu_result;

    // Register File
    reg_file rf (
        .clk (clk),
        .reset (reset),
        .we3 (reg_write),
        .wd3 (result),
        .a1 (instr[19:15]),
        .a2 (instr[24:20]),
        .a3 (instr[11:7]),

        .rd1 (src_a),
        .rd2 (write_data)
    );

    // Extend Imm
    extend_unit ext (
        .instr(instr),
        .imm_src (imm_src),

        .imm_ext (imm_ext)
    );

    // ALU
    alu alu_core (
        .src_a (src_a),
        .src_b (src_b),
        .alu_control (alu_control),

        .zero (zero),
        .alu_result (alu_result)
    );

endmodule

