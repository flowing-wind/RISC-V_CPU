module datapath (
    input wire clk, reset,

    // Control Unit Interface
    input wire RegWrite, MemWrite, Branch, ALUSrc_b,    // MemWrite comes from Control Unit
    input wire [1:0] Jump, ResultSrc, ALUSrc_a,
    input wire [2:0] ImmSrc,
    input wire [3:0] ALU_Control,
    output wire [31:0] Instr_D_out,

    // Hazard Unit Interface
    input wire Stall_F1, Stall_F2, Stall_D, Flush_F2, Flush_D, Flush_E,
    input wire [1:0] ForwardA_E, ForwardB_E,
    output wire [4:0] Rs1_D_H, Rs2_D_H, Rs1_E_H, Rs2_E_H, Rd_E_H, Rd_M1_H, Rd_M2_H, Rd_W_H,
    output wire [1:0] PC_Src_E_H,
    output wire ResultSrc_E_0_H, ResultSrc_M1_0_H, ResultSrc_M2_0_H, RegWrite_M1_H, RegWrite_M2_H, RegWrite_W_H,

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
    // F1
    reg [31:0] PC_F1, PC_Next_F1;
    wire [31:0] PC_Plus4_F1, PC_Target_E, ALU_Result_E;

    // F2
    reg F2_Valid;
    reg [31:0] PC_F2, PC_Plus4_F2;

    // D
    reg valid_D;    // used to control Reg and Mem write
    wire RegWrite_D, MemWrite_D, Branch_D, ALUSrc_b_D;
    wire [1:0] Jump_D, ResultSrc_D, ALUSrc_a_D;
    wire [3:0] ALU_Control_D;

    reg [31:0] Instr_D, PC_D, PC_Plus4_D;
    wire [2:0] ImmSrc_D, Funct3_D;
    wire [4:0] Rs1_D, Rs2_D, Rd_D;
    wire [31:0] RD1_D, RD2_D, ImmExt_D;

    // E
    reg valid_E;
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
    reg [31:0] ImmExt_E, SrcA_E, WriteData_E, ALU_Result_M1;
    wire [31:0] SrcB_E;

    // M1
    reg valid_M1;
    reg RegWrite_M1, MemWrite_M1;
    reg [1:0] ResultSrc_M1;
    reg [2:0] Funct3_M1;
    reg [4:0] Rd_M1;
    reg [31:0] WriteData_M1, PC_Plus4_M1, Result_M1;
    reg [31:0] WriteData_Aligned_M1;
    reg [3:0] Byte_Enable_M1;
    wire [1:0] Addr_Offset_M1 = ALU_Result_M1[1:0];

    // M2
    reg valid_M2;
    reg RegWrite_M2;
    reg [1:0] ResultSrc_M2;
    reg [2:0] Funct3_M2;
    reg [4:0] Rd_M2;
    reg [31:0] ALU_Result_M2, PC_Plus4_M2, Result_M2, ReadData_Processed_M2;
    wire [1:0] Byte_Offset_M2 = ALU_Result_M2[1:0];
    wire [31:0] ReadData_M2;

    // W
    reg valid_W;
    reg RegWrite_W;
    reg [1:0] ResultSrc_W;
    reg [4:0] Rd_W;
    reg [31:0] ALU_Result_W, PC_Plus4_W, Result_W;
    reg [31:0] ReadData_Processed_W;
    wire [31:0] ReadData_W;


    // ================================================
    // Control Unit Interface
    // ================================================
    assign RegWrite_D = RegWrite;
    assign MemWrite_D = MemWrite;
    assign Branch_D = Branch;
    assign ALUSrc_b_D = ALUSrc_b;
    assign Jump_D = Jump;
    assign ResultSrc_D = ResultSrc;
    assign ALUSrc_a_D = ALUSrc_a;
    assign ALU_Control_D = ALU_Control;
    assign ImmSrc_D = ImmSrc;
    assign Instr_D_out = Instr_D;


    // ================================================
    // Hazard Unit Interface
    // ================================================
    assign Rs1_D_H = Rs1_D;
    assign Rs2_D_H = Rs2_D;
    assign Rs1_E_H = Rs1_E;
    assign Rs2_E_H = Rs2_E;
    assign Rd_E_H = Rd_E;
    assign Rd_M1_H = Rd_M1;
    assign Rd_M2_H = Rd_M2;
    assign Rd_W_H = Rd_W;
    assign PC_Src_E_H = PC_Src_E;
    assign ResultSrc_E_0_H = ResultSrc_E[0];
    assign ResultSrc_M1_0_H = ResultSrc_M1[0];
    assign ResultSrc_M2_0_H = ResultSrc_M2[0];
    assign RegWrite_M1_H = RegWrite_M1;
    assign RegWrite_M2_H = RegWrite_M2;
    assign RegWrite_W_H = RegWrite_W;


    // ================================================
    // 1.1 Fetch Stage 1 (F1)  -->  give PC to IMEM
    // ================================================
    // Imem Interface
    assign PC = PC_F1;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC_F1 <= 32'b0;
        end
        else if (!Stall_F1) begin
            PC_F1 <= PC_Next_F1;
        end
    end

    assign PC_Plus4_F1 = PC_F1 + 32'd4;

    // PC MUX
    always @( *) begin
        case (PC_Src_E)
            2'b00: PC_Next_F1 = PC_Plus4_F1;
            2'b01: PC_Next_F1 = PC_Target_E;
            2'b10: PC_Next_F1 = ALU_Result_E;

            default: PC_Next_F1 = PC_Plus4_F1;
        endcase
    end


    // ================================================
    // IF1/IF2 Pipeline Register
    // ================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC_F2 <= 32'b0;
            PC_Plus4_F2 <= 32'b0;
            F2_Valid <= 1'b0;
        end
        else if (Flush_F2) begin
            F2_Valid <= 1'b0;   // Instr_D do not use Instr
        end
        else if (!Stall_F2) begin
            PC_F2 <= PC_F1;
            PC_Plus4_F2 <= PC_Plus4_F1;
            F2_Valid <= 1'b1;
        end
    end


    // ================================================
    // 1.2 Fetch Stage 2 (F2)  -->  receive Instr
    // ================================================


    // ================================================
    // IF2/ID Pipeline Register
    // ================================================
    // reset > flush > stall
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            Instr_D <= 32'b0;
            PC_D <= 32'b0;
            PC_Plus4_D <= 32'b0;
            valid_D <= 1'b0;
        end
        else if (Flush_D) begin
            Instr_D <= 32'h00000013;    // NOP
            valid_D <= 1'b0;
        end
        else if (!Stall_D) begin
            if (F2_Valid) begin
                Instr_D <= Instr;
                valid_D <= 1'b1;
            end
            else begin
                Instr_D <= 32'h00000013;
                valid_D <= 1'b0;
            end
            PC_D <= PC_F2;
            PC_Plus4_D <= PC_Plus4_F2;
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

        .WE3 (RegWrite_W & valid_W),
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
            valid_E <= 1'b0;
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
        else if (!Stall_D) begin
            valid_E <= valid_D;
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
            2'b10: RD1_FD_E = Result_M1;
            2'b11: RD1_FD_E = Result_M2;

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
            2'b10: WriteData_E = Result_M1;
            2'b11: WriteData_E = Result_M2;

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
            valid_M1 <= 1'b0;
            RegWrite_M1 <= 1'b0;
            ResultSrc_M1 <= 2'b0;
            MemWrite_M1 <= 1'b0;
            Funct3_M1 <= 3'b0;

            ALU_Result_M1 <= 32'b0;
            WriteData_M1 <= 32'b0;
            Rd_M1 <= 5'b0;
            PC_Plus4_M1 <= 32'b0;
        end
        else begin
            valid_M1 <= valid_E;
            RegWrite_M1 <= RegWrite_E;
            ResultSrc_M1 <= ResultSrc_E;
            MemWrite_M1 <= MemWrite_E;
            Funct3_M1 <= Funct3_E;

            ALU_Result_M1 <= ALU_Result_E;
            WriteData_M1 <= WriteData_E;
            Rd_M1 <= Rd_E;
            PC_Plus4_M1 <= PC_Plus4_E;
        end
    end


    // ================================================
    // 4.1 Memory Stage 1 (M1)  --> give addr
    // ================================================
    // Dmem Interface
    always @( *) begin
        case (Funct3_M1)
            3'b000: begin   // sb
                case (Addr_Offset_M1)
                    2'b00: begin
                        WriteData_Aligned_M1 = {24'b0, WriteData_M1[7:0]};
                        Byte_Enable_M1 = 4'b0001;
                    end
                    2'b01: begin
                        WriteData_Aligned_M1 = {16'b0, WriteData_M1[7:0], 8'b0};
                        Byte_Enable_M1 = 4'b0010;
                    end
                    2'b10: begin
                        WriteData_Aligned_M1 = {8'b0, WriteData_M1[7:0], 16'b0};
                        Byte_Enable_M1 = 4'b0100;
                    end
                    2'b11: begin
                        WriteData_Aligned_M1 = {WriteData_M1[7:0], 24'b0};
                        Byte_Enable_M1 = 4'b1000;
                    end
                endcase
            end
            3'b001: begin   // sh
                if (Addr_Offset_M1[1] == 0) begin
                    WriteData_Aligned_M1 = {16'b0, WriteData_M1[15:0]};
                    Byte_Enable_M1 = 4'b0011;
                end
                else begin
                    WriteData_Aligned_M1 = {WriteData_M1[15:0], 16'b0};
                    Byte_Enable_M1 = 4'b1100;
                end
            end
            3'b010: begin   // sw
                WriteData_Aligned_M1 = WriteData_M1;
                Byte_Enable_M1 = 4'b1111;
            end

            default: begin
                WriteData_Aligned_M1 = WriteData_M1;
                Byte_Enable_M1 = 4'b0000;
            end     
        endcase
    end

    // Drive DMEM
    assign MemWrite_EN = (MemWrite_M1 & valid_M1) ? Byte_Enable_M1 : 4'b0000;
    assign MemAddr = ALU_Result_M1;
    assign WriteData = WriteData_Aligned_M1;

    always @( *) begin
        case (ResultSrc_M1)
            2'b00: Result_M1 = ALU_Result_M1;
            2'b10: Result_M1 = PC_Plus4_M1;

            default: Result_M1 = ALU_Result_M1;
        endcase
    end


    // ================================================
    // MEM1/MEM2 Pipeline Register
    // ================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            valid_M2 <= 1'b0;
            RegWrite_M2 <= 1'b0;
            ResultSrc_M2 <= 2'b0;
            Funct3_M2 <= 3'b0;

            ALU_Result_M2 <= 32'b0;
            Rd_M2 <= 5'b0;
            PC_Plus4_M2 <= 32'b0;
        end
        else begin
            valid_M2 <= valid_M1;
            RegWrite_M2 <= RegWrite_M1;
            ResultSrc_M2 <= ResultSrc_M1;
            Funct3_M2 <= Funct3_M1;

            ALU_Result_M2 <= ALU_Result_M1;
            Rd_M2 <= Rd_M1;
            PC_Plus4_M2 <= PC_Plus4_M1;
        end
    end


    // ================================================
    // 4.2 Memory Stage 2 (M2)  --> receive data
    // ================================================
    // Load data logic
    assign ReadData_M2 = ReadData;
    always @( *) begin
        case (Funct3_M2)
            // lw
            3'b010: ReadData_Processed_M2  = ReadData_M2;

            // lb
            3'b000: begin
                case (Byte_Offset_M2)
                    2'b00: ReadData_Processed_M2 = {{24{ReadData_M2[7]}}, ReadData_M2[7:0]};
                    2'b01: ReadData_Processed_M2 = {{24{ReadData_M2[15]}}, ReadData_M2[15:8]};
                    2'b10: ReadData_Processed_M2 = {{24{ReadData_M2[23]}}, ReadData_M2[23:16]};
                    2'b11: ReadData_Processed_M2 = {{24{ReadData_M2[31]}}, ReadData_M2[31:24]};
                endcase
            end

            // lbu
            3'b100: begin
                case (Byte_Offset_M2)
                    2'b00: ReadData_Processed_M2 = {24'b0, ReadData_M2[7:0]};
                    2'b01: ReadData_Processed_M2 = {24'b0, ReadData_M2[15:8]};
                    2'b10: ReadData_Processed_M2 = {24'b0, ReadData_M2[23:16]};
                    2'b11: ReadData_Processed_M2 = {24'b0, ReadData_M2[31:24]};
                endcase
            end

            // lh
            3'b001: begin
                if (Byte_Offset_M2[1] == 0)    // low
                    ReadData_Processed_M2 = {{16{ReadData_M2[15]}}, ReadData_M2[15:0]};
                else
                    ReadData_Processed_M2 = {{16{ReadData_M2[31]}}, ReadData_M2[31:16]};
            end

            // lhu
            3'b101: begin
                if (Byte_Offset_M2[1] == 0)    // low
                    ReadData_Processed_M2 = {16'b0, ReadData_M2[15:0]};
                else
                    ReadData_Processed_M2 = {16'b0, ReadData_M2[31:16]};
            end

            default: ReadData_Processed_M2  = ReadData_M2;      
        endcase
    end

    always @( *) begin
        case (ResultSrc_M2)
            2'b00: Result_M2 = ALU_Result_M2;
            2'b01: Result_M2 = ReadData_Processed_M2;
            2'b10: Result_M2 = PC_Plus4_M2;

            default: Result_M2 = ALU_Result_M2;
        endcase
    end


    // ================================================
    // MEM2/WB Pipeline Register
    // ================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            valid_W <= 1'b0;
            RegWrite_W <= 1'b0;
            ResultSrc_W <= 2'b0;

            ALU_Result_W <= 32'b0;
            ReadData_Processed_W <= 32'b0;
            Rd_W <= 5'b0;
            PC_Plus4_W <= 32'b0;
        end
        else begin
            valid_W <= valid_M2;
            RegWrite_W <= RegWrite_M2;
            ResultSrc_W <= ResultSrc_M2;

            ALU_Result_W <= ALU_Result_M2;
            ReadData_Processed_W <= ReadData_Processed_M2;
            Rd_W <= Rd_M2;
            PC_Plus4_W <= PC_Plus4_M2;
        end
    end


    // ================================================
    // 5. Writeback Stage (W)
    // ================================================
    // Choose Result Source
    always @( *) begin
        case (ResultSrc_W)
            2'b00: Result_W = ALU_Result_W;
            2'b01: Result_W = ReadData_Processed_W;
            2'b10: Result_W = PC_Plus4_W;

            default: Result_W = ALU_Result_W;
        endcase
    end

endmodule
