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
    input wire [31:0] SrcA, SrcB,
    input wire [3:0] ALU_Control,

    output wire Zero,
    output reg [31:0] ALU_Result
);

    always @(*) begin
        // default
        ALU_Result = 32'b0;

        case (ALU_Control)
            4'b0000: ALU_Result = SrcA + SrcB;  // add
            4'b0001: ALU_Result = SrcA - SrcB;  // sub
            4'b0010: ALU_Result = SrcA & SrcB;  // and
            4'b0011: ALU_Result = SrcA | SrcB;  // or
            4'b0100: ALU_Result = SrcA ^ SrcB;  // xor
            4'b0101: ALU_Result = ($signed(SrcA) < $signed(SrcB)) ? 32'b1 : 32'b0;   // slt
            4'b0110: ALU_Result = (SrcA < SrcB) ? 32'b1 : 32'b0;  // sltu, unsigned
            4'b0111: ALU_Result = SrcA << SrcB[4:0];  // sll
            4'b1000: ALU_Result = SrcA >> SrcB[4:0];  // srl
            4'b1001: ALU_Result = $signed(SrcA) >>> SrcB[4:0];    // sra

            4'b1111: ALU_Result = SrcA;     // Directly give SrcA, used in CSR Instr

            default: ALU_Result = 32'b0;
        endcase
    end

    // If the result is 0, zero = 1
    assign Zero = ~(|ALU_Result);

endmodule
