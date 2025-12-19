module datapath (
    input wire clk, reset,

    // Control Unit Interface
    input wire RegWrite, MemWrite, Branch, ALUSrc_b,    // MemWrite comes from Control Unit
    input wire [1:0] Jump, ResultSrc, ALUSrc_a,
    input wire [2:0] ImmSrc,
    input wire [3:0] ALU_Control,
    output wire [31:0] Instr_D_out,

    // Hazard Unit Interface
    input wire Stall_F, Stall_D, Flush_D, Flush_E,
    input wire [1:0] ForwardA_E, ForwardB_E,
    output wire [4:0] Rs1_D_H, Rs2_D_H, Rs1_E_H, Rs2_E_H, Rd_E_H, Rd_M_H, Rd_W_H,
    output wire [1:0] PC_Src_E_H,
    output wire ResultSrc_E_0_H, RegWrite_M_H,  RegWrite_W_H,

    // Imem Interface
    output wire [31:0] PC,
    input wire [31:0] Instr,

    // Dmem Interface
    output wire [3:0] MemWrite_EN,  // The MemWrite_EN is MemWrite_M(expanded), not MemWrite
    output wire [31:0] MemAddr,     // Data address in dmem
    output wire [31:0] WriteData,   // Data written to dmem
    input wire [31:0] ReadData      // Data read from dmem
);

    // ================================================
    // Wires and Regs
    // ================================================
    // F
    reg [31:0] PC_F, PC_Next_F;
    wire [31:0] PC_Plus4_F, PC_Target_E, ALU_Result_E;
    wire [31:0] Instr_F;

    // D
    wire RegWrite_D, MemWrite_D, Branch_D, ALUSrc_b_D;
    wire [1:0] Jump_D, ResultSrc_D, ALUSrc_a_D;
    wire [3:0] ALU_Control_D;

    reg [31:0] Instr_D, PC_D, PC_Plus4_D;
    wire [2:0] ImmSrc_D, Funct3_D;
    wire [4:0] Rs1_D, Rs2_D, Rd_D;
    wire [31:0] RD1_D, RD2_D, ImmExt_D;

    // E
    wire Zero_E;
    reg [1:0] PC_Src_E;
    reg Branch_taken_E;
    wire ALU_LSB = ALU_Result_E[0];

    reg RegWrite_E, MemWrite_E, Branch_E, ALUSrc_b_E;
    reg [1:0] Jump_E, ResultSrc_E, ALUSrc_a_E;
    reg [2:0] Funct3_E;
    reg [3:0] ALU_Control_E;

    reg [4:0] Rs1_E, Rs2_E, Rd_E;
    reg [31:0] RD1_FD_E, RD1_E, RD2_E, PC_E, PC_Plus4_E;
    reg [31:0] ImmExt_E, SrcA_E, WriteData_E, ALU_Result_M;
    wire [31:0] SrcB_E;

    // M
    reg RegWrite_M, MemWrite_M;
    reg [1:0] ResultSrc_M;
    reg [2:0] Funct3_M;
    reg [4:0] Rd_M;
    reg [31:0] WriteData_M, PC_Plus4_M;
    reg [31:0] WriteData_Aligned_M;
    reg [3:0] Byte_Enable;
    wire [1:0] Addr_Offset = ALU_Result_M[1:0];

    // W
    reg RegWrite_W;
    reg [1:0] ResultSrc_W;
    reg [2:0] Funct3_W;
    reg [4:0] Rd_W;
    reg [31:0] ALU_Result_W, PC_Plus4_W, Result_W;
    reg [31:0] ReadData_Processed_W;
    wire [31:0] ReadData_W;
    wire [1:0] Byte_Offset_W = ALU_Result_W[1:0];


    // ================================================
    // Control Unit Interface
    // ================================================
    assign RegWrite = RegWrite_D;
    assign MemWrite = MemWrite_D;
    assign Branch = Branch_D;
    assign ALUSrc_b = ALUSrc_b_D;
    assign Jump = Jump_D;
    assign ResultSrc = ResultSrc_D;
    assign ALUSrc_a = ALUSrc_a_D;
    assign ALU_Control = ALU_Control_D;
    assign ImmSrc = ImmSrc_D;
    assign Instr_D_out = Instr_D;


    // ================================================
    // Hazard Unit Interface
    // ================================================
    assign Rs1_D_H = Rs1_D;
    assign Rs2_D_H = Rs2_D;
    assign Rs1_E_H = Rs1_E;
    assign Rs2_E_H = Rs2_E;
    assign Rd_E_H = Rd_E;
    assign Rd_M_H = Rd_M;
    assign Rd_W_H = Rd_W;
    assign PC_Src_E_H = PC_Src_E;
    assign ResultSrc_E_0_H = ResultSrc_E[0];
    assign RegWrite_M_H = RegWrite_M;
    assign RegWrite_W_H = RegWrite_W;


    // ================================================
    // 1. Fetch Stage (F)
    // ================================================
    // Imem Interface
    assign PC = PC_F;
    assign Instr_F = Instr;

    always @(posedge clk or posedge reset) begin
        if (reset)
            PC_F <= 32'b0;
        else if (!Stall_F)
            PC_F <= PC_Next_F;
    end

    assign PC_Plus4_F = PC_F + 32'd4;

    // PC MUX
    always @( *) begin
        case (PC_Src_E)
            2'b00: PC_Next_F = PC_Plus4_F;
            2'b01: PC_Next_F = PC_Target_E;
            2'b10: PC_Next_F = ALU_Result_E;

            default: PC_Next_F = PC_Plus4_F;
        endcase
    end


    // ================================================
    // IF/ID Pipeline Register
    // ================================================
    // reset > flush > stall
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            Instr_D <= 32'b0;
            PC_D <= 32'b0;
            PC_Plus4_D <= 32'b0;
        end
        else if (Flush_D) begin
            // no need to clear PC
            Instr_D <= 32'b0;
        end
        else if (!Stall_D) begin
            Instr_D <= Instr_F;
            PC_D <= PC_F;
            PC_Plus4_D <= PC_Plus4_F;
        end
    end


    // ================================================
    // 2. Decode Stage (D)
    // ================================================
    assign Funct3_D = Instr_D[14:12];

    assign Rs1_D = Instr_D[19:15];
    assign Rs2_D = Instr_D[24:20];
    assign Rd_D = Instr_D[11:7];

    // Register File
    reg_file rf (
        .clk (clk),
        .reset (reset),

        .WE3 (RegWrite_W),
        .WD3 (Result_W),
        .A1 (Instr_D[19:15]),
        .A2 (Instr_D[24:20]),
        .A3 (Rd_W),

        .RD1 (RD1_D),
        .RD2 (RD2_D)
    );

    // Extend Imm
    extend_unit ext (
        .Instr(Instr_D),
        .ImmSrc (ImmSrc_D),

        .ImmExt (ImmExt_D)
    );


    // ================================================
    // ID/EX Pipeline Register
    // ================================================
    always @(posedge clk or posedge reset) begin
        if (reset || Flush_E) begin
            RegWrite_E <= 1'b0;
            ResultSrc_E <= 2'b0;
            MemWrite_E <= 1'b0;
            Jump_E <= 2'b0;
            Branch_E <= 1'b0;
            ALU_Control_E <= 4'b0;
            ALUSrc_a_E <= 2'b0;
            ALUSrc_b_E <= 1'b0;
            Funct3_E <= 3'b0;

            RD1_E <= 32'b0;
            RD2_E <= 32'b0;

            PC_E <= 32'b0;
            Rs1_E <= 5'b0;
            Rs2_E <= 5'b0;
            Rd_E <= 5'b0;
            ImmExt_E <= 32'b0;
            PC_Plus4_E <= 32'b0;
        end
        else begin
            RegWrite_E <= RegWrite_D;
            ResultSrc_E <= ResultSrc_D;
            MemWrite_E <= MemWrite_D;
            Jump_E <= Jump_D;
            Branch_E <= Branch_D;
            ALU_Control_E <= ALU_Control_D;
            ALUSrc_a_E <= ALUSrc_a_D;
            ALUSrc_b_E <= ALUSrc_b_D;
            Funct3_E <= Funct3_D;

            RD1_E <= RD1_D;
            RD2_E <= RD2_D;

            PC_E <= PC_D;
            Rs1_E <= Rs1_D;
            Rs2_E <= Rs2_D;
            Rd_E <= Rd_D;
            ImmExt_E <= ImmExt_D;
            PC_Plus4_E <= PC_Plus4_D;
        end
    end


    // ================================================
    // 3. Execute Stage (E)
    // ================================================
    // Update PC_Src_E
    // Decide whether Branch takes effect
    always @( *) begin
        case (Funct3_E)
            3'b000: Branch_taken_E = Zero_E;
            3'b001: Branch_taken_E = ~Zero_E;
            3'b100: Branch_taken_E = (ALU_LSB != 0);
            3'b101: Branch_taken_E = (ALU_LSB == 0);
            3'b110: Branch_taken_E = (ALU_LSB != 0);
            3'b111: Branch_taken_E = (ALU_LSB == 0);

            default: Branch_taken_E = 0;
        endcase
    end

    // Jump_E:
    // 2'b00: no jal/jalr
    // 2'b01: is jal
    // 2'b10: is jalr
    always @( *) begin
        if (Jump_E == 2'b10)
            PC_Src_E = 2'b10;
        else if (Jump_E == 2'b01 || (Branch_E && Branch_taken_E))
            PC_Src_E = 2'b01;
        else
            PC_Src_E = 2'b00;
    end

    // Calculate PC_Target_E
    assign PC_Target_E = PC_E + ImmExt_E;

    // Choose SrcA_E
    always @( *) begin
        case (ForwardA_E)
            2'b00: RD1_FD_E = RD1_E;
            2'b01: RD1_FD_E = Result_W;
            2'b10: RD1_FD_E = ALU_Result_M;

            default: RD1_FD_E = RD1_E;     
        endcase

        case (ALUSrc_a_E)
            2'b00: SrcA_E = RD1_FD_E;
            2'b01: SrcA_E = PC_E;
            2'b10: SrcA_E = 32'b0;

            default: SrcA_E = RD1_FD_E;
        endcase
    end

    // Choose SrcB_E
    always @( *) begin
        case (ForwardB_E)
            2'b00: WriteData_E = RD2_E;
            2'b01: WriteData_E = Result_W;
            2'b10: WriteData_E = ALU_Result_M;

            default: WriteData_E = RD2_E;
        endcase
    end

    assign SrcB_E = (ALUSrc_b_E) ? ImmExt_E : WriteData_E;

    // ALU
    alu alu_core (
        .SrcA (SrcA_E),
        .SrcB (SrcB_E),
        .ALU_Control (ALU_Control_E),

        .Zero (Zero_E),
        .ALU_Result (ALU_Result_E)
    );


    // ================================================
    // EX/MEM Pipeline Register
    // ================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            RegWrite_M <= 1'b0;
            ResultSrc_M <= 2'b0;
            MemWrite_M <= 1'b0;
            Funct3_M <= 3'b0;

            ALU_Result_M <= 32'b0;
            WriteData_M <= 32'b0;
            Rd_M <= 5'b0;
            PC_Plus4_M <= 32'b0;
        end
        else begin
            RegWrite_M <= RegWrite_E;
            ResultSrc_M <= ResultSrc_E;
            MemWrite_M <= MemWrite_E;
            Funct3_M <= Funct3_E;

            ALU_Result_M <= ALU_Result_E;
            WriteData_M <= WriteData_E;
            Rd_M <= Rd_E;
            PC_Plus4_M <= PC_Plus4_E;
        end
    end


    // ================================================
    // 4. Memory Stage (M)
    // ================================================
    // Dmem Interface
    always @( *) begin
        case (Funct3_M)
            3'b000: begin   // sb
                case (Addr_Offset)
                    2'b00: begin
                        WriteData_Aligned_M = {24'b0, WriteData_M[7:0]};
                        Byte_Enable = 4'b0001;
                    end
                    2'b01: begin
                        WriteData_Aligned_M = {16'b0, WriteData_M[7:0], 8'b0};
                        Byte_Enable = 4'b0010;
                    end
                    2'b10: begin
                        WriteData_Aligned_M = {8'b0, WriteData_M[7:0], 16'b0};
                        Byte_Enable = 4'b0100;
                    end
                    2'b11: begin
                        WriteData_Aligned_M = {WriteData_M[7:0], 24'b0};
                        Byte_Enable = 4'b1000;
                    end
                endcase
            end
            3'b001: begin   // sh
                if (Addr_Offset[1] == 0) begin
                    WriteData_Aligned_M = {16'b0, WriteData_M[15:0]};
                    Byte_Enable = 4'b0011;
                end
                else begin
                    WriteData_Aligned_M = {WriteData_M[15:0], 16'b0};
                    Byte_Enable = 4'b1100;
                end
            end
            3'b010: begin   // sw
                WriteData_Aligned_M = WriteData_M;
                Byte_Enable = 4'b1111;
            end

            default: begin
                WriteData_Aligned_M = WriteData_M;
                Byte_Enable = 4'b0000;
            end     
        endcase
    end

    assign MemWrite_EN = (MemWrite_M) ? Byte_Enable : 4'b0000;
    assign MemAddr = ALU_Result_M;
    assign WriteData = WriteData_Aligned_M;


    // ================================================
    // MEM/WB Pipeline Register
    // ================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            RegWrite_W <= 1'b0;
            ResultSrc_W <= 2'b0;
            Funct3_W <= 3'b0;

            ALU_Result_W <= 32'b0;
            Rd_W <= 5'b0;
            PC_Plus4_W <= 32'b0;
        end
        else begin
            RegWrite_W <= RegWrite_M;
            ResultSrc_W <= ResultSrc_M;
            Funct3_W <= Funct3_M;

            ALU_Result_W <= ALU_Result_M;
            Rd_W <= Rd_M;
            PC_Plus4_W <= PC_Plus4_M;
        end
    end


    // ================================================
    // 5. Writeback Stage (W)
    // ================================================
    // Load data logic
    // BRAM is sync, should be processed in WB Stage
    assign ReadData_W = ReadData;

    always @( *) begin
        case (Funct3_W)
            // lw
            3'b010: ReadData_Processed_W  = ReadData_W;

            // lb
            3'b000: begin
                case (Byte_Offset_W)
                    2'b00: ReadData_Processed_W = {{24{ReadData_W[7]}}, ReadData_W[7:0]};
                    2'b01: ReadData_Processed_W = {{24{ReadData_W[15]}}, ReadData_W[15:8]};
                    2'b10: ReadData_Processed_W = {{24{ReadData_W[23]}}, ReadData_W[23:16]};
                    2'b11: ReadData_Processed_W = {{24{ReadData_W[31]}}, ReadData_W[31:24]};
                endcase
            end

            // lbu
            3'b100: begin
                case (Byte_Offset_W)
                    2'b00: ReadData_Processed_W = {24'b0, ReadData_W[7:0]};
                    2'b01: ReadData_Processed_W = {24'b0, ReadData_W[15:8]};
                    2'b10: ReadData_Processed_W = {24'b0, ReadData_W[23:16]};
                    2'b11: ReadData_Processed_W = {24'b0, ReadData_W[31:24]};
                endcase
            end

            // lh
            3'b001: begin
                if (Byte_Offset_W[1] == 0)    // low
                    ReadData_Processed_W = {{16{ReadData_W[15]}}, ReadData_W[15:0]};
                else
                    ReadData_Processed_W = {{16{ReadData_W[31]}}, ReadData_W[31:16]};
            end

            // lhu
            3'b101: begin
                if (Byte_Offset_W[1] == 0)    // low
                    ReadData_Processed_W = {16'b0, ReadData_W[15:0]};
                else
                    ReadData_Processed_W = {16'b0, ReadData_W[31:16]};
            end

            default: ReadData_Processed_W  = ReadData_W;      
        endcase
    end

    always @( *) begin
        case (ResultSrc_W)
            2'b00: Result_W = ALU_Result_W;
            2'b01: Result_W = ReadData_Processed_W;
            2'b10: Result_W = PC_Plus4_W;

            default: Result_W = ALU_Result_W;
        endcase
    end

endmodule

