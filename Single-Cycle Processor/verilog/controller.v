module controller(
    input wire [6:0] op,
    input wire [2:0] funct3,
    input wire funct7b5,
    input wire zero,

    output reg [1:0] imm_src,
    output reg pc_src, alu_src, result_src,
    output reg reg_write, mem_write,
    output reg [2:0] alu_control
);

    reg [1:0] alu_op;   // whether to check funct3
    reg branch;

    assign pc_src = branch & zero;

    // Main Decoder
    always @(*) begin
        // default
        reg_write = 0;
        imm_src = 2'b00;
        alu_src = 0;
        mem_write = 0;
        result_src = 0;
        branch = 0;
        alu_op = 2'b00;

        case (op)
            // R-Type
            7'b0110011: begin   // add, sub, and, or
                reg_write = 1;
                imm_src = 2'bxx;
                alu_src = 0;
                mem_write = 0;
                result_src = 0;
                branch = 0;
                alu_op = 2'b10;
            end

            // I-Type
            7'b0000011: begin   // lw
                reg_write = 1;
                imm_src = 2'b00;
                alu_src = 1;
                mem_write = 0;
                result_src = 1;
                branch = 0;
                alu_op = 2'b00;
            end

            7'b0010011: begin   // addi
                reg_write = 1;
                imm_src = 2'b00;
                alu_src = 1;
                mem_write = 0;
                result_src = 0;
                branch = 0;
                alu_op = 2'b10;
            end

            // S-Type
            7'b0100011: begin   // sw
                reg_write = 0;
                imm_src = 2'b01;
                alu_src = 1;
                mem_write = 1;
                result_src = 1'bx;
                branch = 0;
                alu_op = 2'b00;
            end

            // B-Type
            7'b1100011: begin   // branch
                reg_write = 0;
                imm_src = 2'b10;
                alu_src = 0;
                mem_write = 0;
                result_src = 1'bx;
                branch = 1;
                alu_op = 2'b01;
            end
            
        endcase
    end

    always @(*) begin
        case (alu_op)
            2'b00: alu_control = 3'b000;    // add
            2'b01: alu_control = 3'b001;    // beq  -->  sub
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        if (op == 7'b0110011 && funct7b5)
                            alu_control = 3'b001;   // sub
                        else alu_control = 3'b000;
                    end
                    3'b010: alu_control = 3'b101;   // slt
                    3'b110: alu_control = 3'b011;   // or
                    3'b111: alu_control = 3'b010;   // and
                    default: alu_control = 3'b000;  // add
                endcase
            end
            default: alu_control = 3'b000;
        endcase
    end

endmodule

