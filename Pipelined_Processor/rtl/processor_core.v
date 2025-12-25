module processor_core(
    input wire clk, reset,

    // Interrupt Interface
    input wire Ext_Int, Sw_Int, Timer_Int,

    // Imem Interface
    output wire [31:0] PC,
    output wire Stall,
    input wire [31:0] Instr,

    // Dmem Interface
    output wire [3:0] MemWrite_EN,  // The MemWrite_EN is MemWrite_M(expanded), not MemWrite
    output wire [31:0] MemAddr,     // Data address in dmem
    output wire [31:0] WriteData,   // Data written to dmem
    input wire [31:0] ReadData      // Data read from dmem
);

    // Control Unit Interface
    wire [31:0] Instr_D;
    wire [6:0] OP = Instr_D[6:0];
    wire [2:0] Funct3 = Instr_D[14:12];
    wire Funct7b5 = Instr_D[30];

    wire RegWrite, MemWrite, Branch, ALUSrc_b;
    wire [1:0] Jump, ResultSrc, ALUSrc_a;
    wire [2:0] ImmSrc;
    wire [3:0] ALU_Control;

    // Hazard Unit Interface
    wire Stall_F1, Stall_F2, Stall_D, Flush_F2, Flush_D, Flush_E, Flush_M1, Flush_M2;
    wire EX_Flush;
    wire [1:0] ForwardA_E, ForwardB_E;
    wire [4:0] Rs1_D_H, Rs2_D_H, Rs1_E_H, Rs2_E_H, Rd_E_H, Rd_M1_H, Rd_M2_H, Rd_W_H;
    wire [1:0] PC_Src_E_H;
    wire ResultSrc_E_0_H, ResultSrc_M1_0_H, ResultSrc_M2_0_H, RegWrite_M1_H, RegWrite_M2_H, RegWrite_W_H;

    assign Stall = Stall_F1;

    // CSR Related
    wire CSRWrite, Is_MRET, Is_ECALL, Illegal_Instr;


    // ===================================================
    controller c_unit (
        // Control Unit receives Instr_D, not Instr
        .OP (OP),
        .Funct3 (Funct3),
        .Funct7b5 (Funct7b5),

        .Instr_In_D (Instr_D),
        .RegWrite (RegWrite),
        .MemWrite (MemWrite),
        .Branch (Branch),
        .ALUSrc_b (ALUSrc_b),
        .Jump (Jump),
        .ResultSrc (ResultSrc),
        .ALUSrc_a (ALUSrc_a),
        .ImmSrc (ImmSrc),
        .ALU_Control (ALU_Control),

        // CSR
        .CSRWrite (CSRWrite),
        .Is_MRET (Is_MRET),
        .Is_ECALL (Is_ECALL),
        .Illegal_Instr (Illegal_Instr)
    );

    datapath d_unit (
        .clk (clk),
        .reset (reset),

        // Control Unit Interface
        .RegWrite (RegWrite),
        .MemWrite (MemWrite),
        .Branch (Branch),
        .ALUSrc_b (ALUSrc_b),
        .Jump (Jump),
        .ResultSrc (ResultSrc),
        .ALUSrc_a (ALUSrc_a),
        .ImmSrc (ImmSrc),
        .ALU_Control (ALU_Control),
        .Instr_D_out (Instr_D),

        // Hazard Unit Interface
        .Stall_F1 (Stall_F1),
        .Stall_F2 (Stall_F2),
        .Stall_D (Stall_D),
        .Flush_F2 (Flush_F2),
        .Flush_D (Flush_D),
        .Flush_E (Flush_E),
        .Flush_M1 (Flush_M1),
        .Flush_M2 (Flush_M2),
        .EX_Flush_H (EX_Flush),
        .ForwardA_E (ForwardA_E),
        .ForwardB_E (ForwardB_E),
        .Rs1_D_H (Rs1_D_H),
        .Rs2_D_H (Rs2_D_H),
        .Rs1_E_H (Rs1_E_H),
        .Rs2_E_H (Rs2_E_H),
        .Rd_E_H (Rd_E_H),
        .Rd_M1_H (Rd_M1_H),
        .Rd_M2_H (Rd_M2_H),
        .Rd_W_H (Rd_W_H),
        .PC_Src_E_H (PC_Src_E_H),
        .ResultSrc_E_0_H (ResultSrc_E_0_H),
        .ResultSrc_M1_0_H (ResultSrc_M1_0_H),
        .ResultSrc_M2_0_H (ResultSrc_M2_0_H),
        .RegWrite_M1_H (RegWrite_M1_H),
        .RegWrite_M2_H (RegWrite_M2_H),
        .RegWrite_W_H (RegWrite_W_H),

        // CSR
        .CSRWrite (CSRWrite),
        .Is_ECALL (Is_ECALL),
        .Is_MRET (Is_MRET),
        .Illegal_Instr (Illegal_Instr),

        .Ext_Int (Ext_Int),
        .Sw_Int (Sw_Int),
        .Timer_Int (Timer_Int),

        // Imem Interface
        .PC (PC),
        .Instr (Instr),

        // Dmem Interface
        .MemWrite_EN (MemWrite_EN),
        .MemAddr (MemAddr),
        .WriteData (WriteData),
        .ReadData (ReadData)
    );

    hazard_unit h_unit (
        .clk (clk),
        .reset (reset),
        
        .Stall_F1 (Stall_F1),
        .Stall_F2 (Stall_F2),
        .Stall_D (Stall_D),
        .Flush_F2 (Flush_F2),
        .Flush_D (Flush_D),
        .Flush_E (Flush_E),
        .Flush_M1 (Flush_M1),
        .Flush_M2 (Flush_M2),
        .EX_Flush_H (EX_Flush),
        .ForwardA_E (ForwardA_E),
        .ForwardB_E (ForwardB_E),
        .Rs1_D_H (Rs1_D_H),
        .Rs2_D_H (Rs2_D_H),
        .Rs1_E_H (Rs1_E_H),
        .Rs2_E_H (Rs2_E_H),
        .Rd_E_H (Rd_E_H),
        .Rd_M1_H (Rd_M1_H),
        .Rd_M2_H (Rd_M2_H),
        .Rd_W_H (Rd_W_H),
        .PC_Src_E_H (PC_Src_E_H),
        .ResultSrc_E_0_H (ResultSrc_E_0_H),
        .ResultSrc_M1_0_H (ResultSrc_M1_0_H),
        .ResultSrc_M2_0_H (ResultSrc_M2_0_H),
        .RegWrite_M1_H (RegWrite_M1_H),
        .RegWrite_M2_H (RegWrite_M2_H),
        .RegWrite_W_H (RegWrite_W_H)
    );

endmodule

