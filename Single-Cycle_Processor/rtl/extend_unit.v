//   | imm_src |  Type  |
//   | :-----: | :----: |
//   | 3'b000  | I-Type |
//   | 3'b001  | S-Type |
//   | 3'b010  | B-Type |
//   | 3'b011  | U-Type |
//   | 3'b100  | J-Type |


module extend_unit (
    input wire [31:0] instr,
    input wire [2:0] imm_src,

    output reg [31:0] imm_ext
);

    always @(*) begin
        // default
        imm_ext = 32'b0;

        case (imm_src)
            3'b000: imm_ext = {{20{instr[31]}}, instr[31:20]};  // I-Type
            3'b001: imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // S-Type
            3'b010: imm_ext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; // B-Type
            3'b011: imm_ext = {instr[31:12], 12'b0}; // U-Type
            3'b100: imm_ext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; // J-Type
 
            default: imm_ext = 32'b0;
        endcase
    end

endmodule

