//   | imm_src |  Type  |
//   | :-----: | :----: |
//   | 3'b000  | I-Type |
//   | 3'b001  | S-Type |
//   | 3'b010  | B-Type |
//   | 3'b011  | U-Type |
//   | 3'b100  | J-Type |


module extend_unit (
    input wire [31:0] Instr,
    input wire [2:0] ImmSrc,

    output reg [31:0] ImmExt
);

    always @(*) begin
        case (ImmSrc)
            3'b000: ImmExt = {{20{Instr[31]}}, Instr[31:20]};  // I-Type
            3'b001: ImmExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]}; // S-Type
            3'b010: ImmExt = {{20{Instr[31]}}, Instr[7], Instr[30:25], Instr[11:8], 1'b0}; // B-Type
            3'b011: ImmExt = {Instr[31:12], 12'b0}; // U-Type
            3'b100: ImmExt = {{12{Instr[31]}}, Instr[19:12], Instr[20], Instr[30:21], 1'b0}; // J-Type
            3'b101: ImmExt = {27'b0, Instr[19:15]};     // System
 
            default: ImmExt = 32'b0;
        endcase
    end

endmodule

