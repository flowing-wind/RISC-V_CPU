//    | Operation | alu_control |       ex. instr        |
//    | :-------: | :---------: | :--------------------: |
//    |    ADD    |   4'b0000   | add, addi, lw, sw, jal |
//    |    SUB    |   4'b0001   |     sub, beq, bne      |
//    |    AND    |   4'b0010   |       and, andi        |
//    |    OR     |   4'b0011   |        or, ori         |
//    |    XOR    |   4'b0100   |       xor, xori        |
//    |    SLT    |   4'b0101   |       slt, slti        |
//    |   SLTU    |   4'b0110   |      sltu, sltiu       |
//    |    SLL    |   4'b0111   |       sll, slli        |
//    |    SRL    |   4'b1000   |       srl, srli        |
//    |    SRA    |   4'b1001   |       sra, srai        |


module alu (
    input wire [31:0] src_a, src_b,
    input wire [3:0] alu_control,

    output wire zero,
    output reg [31:0] alu_result
);

    always @(*) begin
        // default
        alu_result = 32'b0;

        case (alu_control)
            4'b0000: alu_result = src_a + src_b;  // add
            4'b0001: alu_result = src_a - src_b;  // sub
            4'b0010: alu_result = src_a & src_b;  // and
            4'b0011: alu_result = src_a | src_b;  // or
            4'b0100: alu_result = src_a ^ src_b;  // xor
            4'b0101: alu_result = ($signed(src_a) < $signed(src_b)) ? 32'b1 : 32'b0;   // slt
            4'b0110: alu_result = (src_a < src_b) ? 32'b1 : 32'b0;  // sltu, unsigned
            4'b0111: alu_result = src_a << src_b[4:0];  // sll
            4'b1000: alu_result = src_a >> src_b[4:0];  // srl
            4'b1001: alu_result = $signed(src_a) >>> src_b[4:0];    // sra

            default: alu_result = 32'b0;
                
        endcase
    end

    // If the result is 0, zero = 1
    assign zero = ~(|alu_result);

endmodule
