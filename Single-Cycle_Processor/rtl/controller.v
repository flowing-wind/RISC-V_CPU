module controller(
    input wire [6:0] op,
    input wire [2:0] funct3,
    input wire funct7b5,
    input wire zero,
    input wire [31:0] alu_result,

    output reg [2:0] imm_src,
    output reg [1:0] pc_src,
    output reg [1:0] alu_src_a,
    output reg alu_src_b,
    output reg [1:0] result_src,
    output reg reg_write, mem_write,
    output reg [3:0] alu_control
);

    reg [1:0] alu_op;   // whether to check funct3
    reg branch, is_jal, is_jalr;
    wire alu_lsb = alu_result[0];

    // Main Decoder
    always @(*) begin
        // default
        reg_write = 0;
        imm_src = 2'b00;
        alu_src_a = 0;
        alu_src_b = 0;
        mem_write = 0;
        result_src = 2'b00;
        branch = 0;
        is_jal = 0;
        is_jalr = 0;
        alu_op = 2'b00;

        // | alu_op |       operation        |
        // | :----: | :--------------------: |
        // | 2'b00  |          add           |
        // | 2'b01  |  B-Type, check funct3  |
        // | 2'b10  | I/R-Type, check funct3 |


        case (op)
            // R-Type
            7'b0110011: begin   // add, sub, and, or, xor, slt, sll ,srl, sra
                reg_write = 1;
                imm_src = 3'bxxx;
                alu_src_a = 2'b00;
                alu_src_b = 0;
                mem_write = 0;
                result_src = 2'b00;
                branch = 0;
                alu_op = 2'b10; // depends on funct3
            end

            // I-Type (3)
            7'b0000011: begin   // lw, lb, lh, lbu, lhu
                reg_write = 1;
                imm_src = 3'b000;
                alu_src_a = 2'b00;
                alu_src_b = 1;
                mem_write = 0;
                result_src = 2'b01;
                branch = 0;
                alu_op = 2'b00; // add 
            end

            7'b0010011: begin   // R-Type + i
                reg_write = 1;
                imm_src = 3'b000;
                alu_src_a = 2'b00;
                alu_src_b = 1;
                mem_write = 0;
                result_src = 2'b00;
                branch = 0;
                alu_op = 2'b10; // depends
            end
            
            7'b1100111: begin   // jalr
                reg_write = 1;
                imm_src = 3'b000;
                alu_src_a = 2'b00;
                alu_src_b = 1;
                mem_write = 0;
                result_src = 2'b10; // pc + 4
                branch = 0;
                alu_op = 2'b00; // add
                is_jalr = 1;
            end

            // S-Type
            7'b0100011: begin   // sw
                reg_write = 0;
                imm_src = 3'b001;
                alu_src_a = 2'b00;
                alu_src_b = 1;
                mem_write = 1;
                result_src = 2'bxx;
                branch = 0;
                alu_op = 2'b00; // add
            end

            // B-Type
            7'b1100011: begin   // branch
                reg_write = 0;
                imm_src = 3'b010;
                alu_src_a = 2'b00;
                alu_src_b = 0;
                mem_write = 0;
                result_src = 2'bxx;
                branch = 1;
                alu_op = 2'b01;
            end

            // U-Type
            7'b0010111: begin   // auipc
                reg_write = 1;
                imm_src = 3'b011;
                alu_src_a = 2'b01;  // from pc
                alu_src_b = 1;  // from imm
                mem_write = 0;
                result_src = 2'b00;
                branch = 0;
                alu_op = 2'b00; // add
            end

            7'b0110111: begin   // lui
                reg_write = 1;
                imm_src = 3'b011;
                alu_src_a = 2'b10;  // always 1'b0
                alu_src_b = 1;
                mem_write = 0;
                result_src = 2'b00;
                branch = 0;
                alu_op = 2'b00; // add
            end

            // J-Type
            7'b1101111: begin
                reg_write = 1;
                imm_src = 3'b100;
                alu_src_a = 2'b01;  // from pc
                alu_src_b = 1;  // from imm
                mem_write = 0;
                result_src = 2'b10; // pc + 4
                branch = 0;
                alu_op = 2'b00;
                is_jal = 1;
            end

        endcase
    end

    always @(*) begin
        case (alu_op)
            2'b00: alu_control = 4'b0000;    // add
            // check funct3
            2'b01: begin
                case (funct3)
                    3'b000: alu_control = 4'b0001;  // beq  -->  sub
                    3'b001: alu_control = 4'b0001;  // bne  -->  sub
                    3'b100: alu_control = 4'b0101;  // blt  -->  slt <
                    3'b101: alu_control = 4'b0101;  // bge  -->  slt >=
                    3'b110: alu_control = 4'b0110;  // bltu  -->  sltu <
                    3'b111: alu_control = 4'b0110;  // bgeu  -->  sltu >=

                    default: alu_control = 4'b0001;
                endcase
            end
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        if (op == 7'b0110011 && funct7b5)
                            alu_control = 4'b0001;   // sub
                        else alu_control = 4'b0000;  // add, addi
                    end
                    3'b001: alu_control = 4'b0111;   // sll, slli
                    3'b010: alu_control = 4'b0101;   // slt, slti
                    3'b011: alu_control = 4'b0110;   // sltu, sltiu
                    3'b100: alu_control = 4'b0100;   // xor, xori
                    3'b101: begin
                        if (funct7b5)
                            alu_control = 4'b1001;   // sra, srai
                        else alu_control = 4'b1000;  // srl, srli
                    end
                    3'b110: alu_control = 4'b0011;   // or, ori
                    3'b111: alu_control = 4'b0010;   // and, andi

                    default: alu_control = 4'b0000;  // add
                endcase
            end
            
            default: alu_control = 4'b0000;
        endcase
    end

    // pc_src choose
    reg branch_taken;

    always @( *) begin
        case (funct3)
            3'b000: branch_taken = zero;
            3'b001: branch_taken = ~zero;
            3'b100: branch_taken = (alu_lsb != 0);
            3'b101: branch_taken = (alu_lsb == 0);
            3'b110: branch_taken = (alu_lsb != 0);
            3'b111: branch_taken = (alu_lsb == 0);

            default: branch_taken = 0;
        endcase
    end
    always @( *) begin
        if (is_jalr)
            pc_src = 2'b10; // from alu
        else if (is_jal || (branch && branch_taken))
            pc_src = 2'b01;
        else
            pc_src = 2'b00;
    end

endmodule

