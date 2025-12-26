module controller(
    input wire [6:0] OP,
    input wire [2:0] Funct3,
    input wire Funct7b5,
    
    // Datapath
    input wire [31:0] Instr_In_D,
    output wire RegWrite, MemWrite, Branch, ALUSrc_b,
    output wire [1:0] Jump, ResultSrc, ALUSrc_a,
    output wire [2:0] ImmSrc,
    output wire [3:0] ALU_Control,

    // CSR
    output wire CSRWrite,   // Write CSR
    output wire Is_MRET,    // MRET
    output wire Is_ECALL,   // ECALL
    output wire Illegal_Instr   // Illegal Instruction
);

    reg RegWrite_r, MemWrite_r, Branch_r, ALUSrc_b_r;
    reg [1:0] Jump_r, ResultSrc_r, ALUSrc_a_r;
    reg [2:0] ImmSrc_r;
    reg [3:0] ALU_Control_r;


    // ================================================
    // Datapath Interface
    // ================================================
    assign RegWrite = RegWrite_r;
    assign MemWrite = MemWrite_r;
    assign Branch = Branch_r;
    assign ALUSrc_b = ALUSrc_b_r;
    assign Jump = Jump_r;
    assign ResultSrc = ResultSrc_r;
    assign ALUSrc_a = ALUSrc_a_r;
    assign ImmSrc = ImmSrc_r;
    assign ALU_Control = ALU_Control_r;


    // ================================================
    // Main Decoder
    // ================================================
    reg [1:0] ALU_OP;   // whether to check funct3
    reg is_jal, is_jalr;
    reg CSRWrite_r, Is_MRET_r, Is_ECALL_r, Illegal_Instr_r;
    assign CSRWrite = CSRWrite_r;
    assign Is_MRET = Is_MRET_r;
    assign Is_ECALL = Is_ECALL_r;
    assign Illegal_Instr = Illegal_Instr_r;

    always @(*) begin
        // default
        RegWrite_r = 0;
        ImmSrc_r = 3'b000;
        ALUSrc_a_r = 0;
        ALUSrc_b_r = 0;
        MemWrite_r = 0;
        ResultSrc_r = 2'b00;
        Branch_r = 0;
        is_jal = 0;
        is_jalr = 0;
        CSRWrite_r = 0;
        Is_MRET_r = 0;
        Is_ECALL_r = 0;
        Illegal_Instr_r = 0;
        ALU_OP = 2'b00;

        // | ALU_OP |       operation        |
        // | :----: | :--------------------: |
        // | 2'b00  |          add           |
        // | 2'b01  |  B-Type, check funct3  |
        // | 2'b10  | I/R-Type, check funct3 |
        // | 2'b11  |  System, check funct3  |

        case (OP)
            // Treat fence as NOP
            7'b0001111: begin
                RegWrite_r = 0;
                ImmSrc_r = 3'b000;
                MemWrite_r = 0;
                Branch_r = 0;
                ResultSrc_r = 2'b00;
                ALUSrc_a_r = 2'b00;
                ALUSrc_b_r = 0;
                ALU_OP = 2'b00;
            end
            
            // System
            7'b1110011: begin
                ALUSrc_b_r = 1;     // use Imm for CSRRWI, CSRRSI, CSRRCI
                MemWrite_r = 0;
                ResultSrc_r = 2'b11;
                Branch_r = 0;
                ALU_OP = 2'b11;
                case (Funct3)
                    3'b000: begin   // ECALL / EBREAK and MRET
                        RegWrite_r = 0;
                        CSRWrite_r = 0;
                        ImmSrc_r = 3'b000;  // not cared
                        if (Instr_In_D[31:20] == 12'h000) Is_ECALL_r = 1;
                        else if (Instr_In_D[31:20] == 12'h302) Is_MRET_r = 1;
                        else Illegal_Instr_r = 1;
                    end
                    3'b001, 3'b010, 3'b011: begin
                        RegWrite_r = 1;
                        ImmSrc_r = 3'b000;  // not cared
                        ALUSrc_a_r = 2'b00; // use rs1
                        CSRWrite_r = (Funct3 == 3'b001) || (Instr_In_D[19:15] != 5'b0); // CSRRW and rs1 != x0
                    end
                    3'b101, 3'b110, 3'b111: begin
                        RegWrite_r = 1;
                        ImmSrc_r = 3'b101;
                        ALUSrc_a_r = 2'b10; // use 32'b0, add to SrcB
                        CSRWrite_r = (Funct3 == 3'b101) || (Instr_In_D[19:15] != 5'b0);
                    end

                    default: Illegal_Instr_r = 1;
                endcase
            end

            // R-Type
            7'b0110011: begin   // add, sub, and, or, xor, slt, sll ,srl, sra
                RegWrite_r = 1;
                ImmSrc_r = 3'b000;  // not cared
                ALUSrc_a_r = 2'b00;
                ALUSrc_b_r = 0;
                MemWrite_r = 0;
                ResultSrc_r = 2'b00;
                Branch_r = 0;
                ALU_OP = 2'b10; // depends on funct3
            end

            // I-Type (3)
            7'b0000011: begin   // lw, lb, lh, lbu, lhu
                RegWrite_r = 1;
                ImmSrc_r = 3'b000;
                ALUSrc_a_r = 2'b00;
                ALUSrc_b_r = 1;
                MemWrite_r = 0;
                ResultSrc_r = 2'b01;
                Branch_r = 0;
                ALU_OP = 2'b00; // add 
            end

            7'b0010011: begin   // R-Type + i
                RegWrite_r = 1;
                ImmSrc_r = 3'b000;
                ALUSrc_a_r = 2'b00;
                ALUSrc_b_r = 1;
                MemWrite_r = 0;
                ResultSrc_r = 2'b00;
                Branch_r = 0;
                ALU_OP = 2'b10; // depends
            end
            
            7'b1100111: begin   // jalr
                RegWrite_r = 1;
                ImmSrc_r = 3'b000;
                ALUSrc_a_r = 2'b00;
                ALUSrc_b_r = 1;
                MemWrite_r = 0;
                ResultSrc_r = 2'b10; // pc + 4
                Branch_r = 0;
                ALU_OP = 2'b00; // add
                is_jalr = 1;
            end

            // S-Type
            7'b0100011: begin   // sw
                RegWrite_r = 0;
                ImmSrc_r = 3'b001;
                ALUSrc_a_r = 2'b00;
                ALUSrc_b_r = 1;
                MemWrite_r = 1;
                ResultSrc_r = 2'b00;    // not cared
                Branch_r = 0;
                ALU_OP = 2'b00; // add
            end

            // B-Type
            7'b1100011: begin   // Branch_r
                RegWrite_r = 0;
                ImmSrc_r = 3'b010;
                ALUSrc_a_r = 2'b00;
                ALUSrc_b_r = 0;
                MemWrite_r = 0;
                ResultSrc_r = 2'b00;    // not cared
                Branch_r = 1;
                ALU_OP = 2'b01;
            end

            // U-Type
            7'b0010111: begin   // auipc
                RegWrite_r = 1;
                ImmSrc_r = 3'b011;
                ALUSrc_a_r = 2'b01;  // from pc
                ALUSrc_b_r = 1;  // from imm
                MemWrite_r = 0;
                ResultSrc_r = 2'b00;
                Branch_r = 0;
                ALU_OP = 2'b00; // add
            end

            7'b0110111: begin   // lui
                RegWrite_r = 1;
                ImmSrc_r = 3'b011;
                ALUSrc_a_r = 2'b10;  // always 1'b0
                ALUSrc_b_r = 1;
                MemWrite_r = 0;
                ResultSrc_r = 2'b00;
                Branch_r = 0;
                ALU_OP = 2'b00; // add
            end

            // J-Type
            7'b1101111: begin
                RegWrite_r = 1;
                ImmSrc_r = 3'b100;
                ALUSrc_a_r = 2'b01;  // from pc
                ALUSrc_b_r = 1;  // from imm
                MemWrite_r = 0;
                ResultSrc_r = 2'b10; // pc + 4
                Branch_r = 0;
                ALU_OP = 2'b00;
                is_jal = 1;
            end

            default: Illegal_Instr_r = 1;
        endcase

        // Decode Jump_r
        if (is_jalr == 1)
            Jump_r = 2'b10;
        else if (is_jal == 1)
            Jump_r = 2'b01;
        else
            Jump_r = 2'b00;
    end

    // Decode ALU_Control_r
    always @(*) begin
        case (ALU_OP)
            2'b00: ALU_Control_r = 4'b0000;    // add
            // check Funct3
            2'b01: begin
                case (Funct3)
                    3'b000: ALU_Control_r = 4'b0001;  // beq  -->  sub
                    3'b001: ALU_Control_r = 4'b0001;  // bne  -->  sub
                    3'b100: ALU_Control_r = 4'b0101;  // blt  -->  slt <
                    3'b101: ALU_Control_r = 4'b0101;  // bge  -->  slt >=
                    3'b110: ALU_Control_r = 4'b0110;  // bltu  -->  sltu <
                    3'b111: ALU_Control_r = 4'b0110;  // bgeu  -->  sltu >=

                    default: ALU_Control_r = 4'b0001;
                endcase
            end
            2'b10: begin
                case (Funct3)
                    3'b000: begin
                        if (OP == 7'b0110011 && Funct7b5)
                            ALU_Control_r = 4'b0001;   // sub
                        else ALU_Control_r = 4'b0000;  // add, addi
                    end
                    3'b001: ALU_Control_r = 4'b0111;   // sll, slli
                    3'b010: ALU_Control_r = 4'b0101;   // slt, slti
                    3'b011: ALU_Control_r = 4'b0110;   // sltu, sltiu
                    3'b100: ALU_Control_r = 4'b0100;   // xor, xori
                    3'b101: begin
                        if (Funct7b5)
                            ALU_Control_r = 4'b1001;   // sra, srai
                        else ALU_Control_r = 4'b1000;  // srl, srli
                    end
                    3'b110: ALU_Control_r = 4'b0011;   // or, ori
                    3'b111: ALU_Control_r = 4'b0010;   // and, andi

                    default: ALU_Control_r = 4'b0000;  // add
                endcase
            end
            2'b11: begin
                case (Funct3)
                    3'b000: begin   // ECALL / EBREAK and MRET
                        ALU_Control_r = 4'b0000;  // no ALU op needed
                    end
                    3'b001, 3'b010, 3'b011: begin
                        ALU_Control_r = 4'b1111;    // Directly give SrcA (rs1)
                    end
                    3'b101, 3'b110, 3'b111: begin
                        ALU_Control_r = 4'b0000;    // 0 + SrcB
                    end
                endcase
            end
            
            default: ALU_Control_r = 4'b0000;
        endcase
    end

endmodule

