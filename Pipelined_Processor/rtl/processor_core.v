module processor_core(
    input wire clk, reset,

    // Imem Interface
    output wire [31:0] PC,
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
    wire Stall_F, Stall_D, Flush_D, Flush_E;
    wire [1:0] ForwardA_E, ForwardB_E;
    wire [4:0] Rs1_D_H, Rs2_D_H, Rs1_E_H, Rs2_E_H, Rd_E_H, Rd_M_H, Rd_W_H;
    wire [1:0] PC_Src_E_H;
    wire ResultSrc_E_0_H, ResultSrc_M_0_H, RegWrite_M_H, RegWrite_W_H;


    // ===================================================
    controller c_unit (
        // Control Unit receives Instr_D, not Instr
        .OP (OP),
        .Funct3 (Funct3),
        .Funct7b5 (Funct7b5),

        .RegWrite (RegWrite),
        .MemWrite (MemWrite),
        .Branch (Branch),
        .ALUSrc_b (ALUSrc_b),
        .Jump (Jump),
        .ResultSrc (ResultSrc),
        .ALUSrc_a (ALUSrc_a),
        .ImmSrc (ImmSrc),
        .ALU_Control (ALU_Control)
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
        .Stall_F (Stall_F),
        .Stall_D (Stall_D),
        .Flush_D (Flush_D),
        .Flush_E (Flush_E),
        .ForwardA_E (ForwardA_E),
        .ForwardB_E (ForwardB_E),
        .Rs1_D_H (Rs1_D_H),
        .Rs2_D_H (Rs2_D_H),
        .Rs1_E_H (Rs1_E_H),
        .Rs2_E_H (Rs2_E_H),
        .Rd_E_H (Rd_E_H),
        .Rd_M_H (Rd_M_H),
        .Rd_W_H (Rd_W_H),
        .PC_Src_E_H (PC_Src_E_H),
        .ResultSrc_E_0_H (ResultSrc_E_0_H),
        .ResultSrc_M_0_H (ResultSrc_M_0_H),
        .RegWrite_M_H (RegWrite_M_H),
        .RegWrite_W_H (RegWrite_W_H),

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
        
        .Stall_F (Stall_F),
        .Stall_D (Stall_D),
        .Flush_D (Flush_D),
        .Flush_E (Flush_E),
        .ForwardA_E (ForwardA_E),
        .ForwardB_E (ForwardB_E),
        .Rs1_D_H (Rs1_D_H),
        .Rs2_D_H (Rs2_D_H),
        .Rs1_E_H (Rs1_E_H),
        .Rs2_E_H (Rs2_E_H),
        .Rd_E_H (Rd_E_H),
        .Rd_M_H (Rd_M_H),
        .Rd_W_H (Rd_W_H),
        .PC_Src_E_H (PC_Src_E_H),
        .ResultSrc_E_0_H (ResultSrc_E_0_H),
        .ResultSrc_M_0_H (ResultSrc_M_0_H),
        .RegWrite_M_H (RegWrite_M_H),
        .RegWrite_W_H (RegWrite_W_H)
    );

endmodule

