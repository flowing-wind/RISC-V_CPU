module hazard_unit (
    input wire clk, reset,
    input wire [4:0] Rs1_D_H, Rs2_D_H, Rs1_E_H, Rs2_E_H, Rd_E_H, Rd_M1_H, Rd_M2_H, Rd_W_H,
    input wire [1:0] PC_Src_E_H,
    input wire ResultSrc_E_0_H, ResultSrc_M1_0_H, ResultSrc_M2_0_H, RegWrite_M1_H, RegWrite_M2_H, RegWrite_W_H,

    output wire Stall_F1, Stall_F2, Stall_D, Flush_F2, Flush_D, Flush_E,
    output wire [1:0] ForwardA_E, ForwardB_E
);

    reg [1:0] ForwardA_E_r, ForwardB_E_r;
    assign ForwardA_E = ForwardA_E_r;
    assign ForwardB_E = ForwardB_E_r;

    wire lwStall;

    // ForwardA_E  -->  Data Hazard
    always @( *) begin
        if (((Rs1_E_H == Rd_M1_H) && RegWrite_M1_H) && (Rs1_E_H != 0))
            ForwardA_E_r = 2'b10;
        else if (((Rs1_E_H == Rd_M2_H) && RegWrite_M2_H) && (Rs1_E_H != 0))
            ForwardA_E_r = 2'b11;
        else if (((Rs1_E_H == Rd_W_H) && RegWrite_W_H) && (Rs1_E_H != 0))
            ForwardA_E_r = 2'b01;
        else
            ForwardA_E_r = 2'b00;
    end

    // ForwardB_E
    always @( *) begin
        if (((Rs2_E_H == Rd_M1_H) && RegWrite_M1_H) && (Rs2_E_H != 0))
            ForwardB_E_r = 2'b10;
        else if (((Rs2_E_H == Rd_M2_H) && RegWrite_M2_H) && (Rs2_E_H != 0))
            ForwardB_E_r = 2'b11;
        else if (((Rs2_E_H == Rd_W_H) && RegWrite_W_H) && (Rs2_E_H != 0))
            ForwardB_E_r = 2'b01;
        else
            ForwardB_E_r = 2'b00;
    end

    // Stall  -->  Load Hazard
    assign lwStall = (ResultSrc_E_0_H && (Rd_E_H != 5'b0) && ((Rs1_D_H == Rd_E_H) || (Rs2_D_H == Rd_E_H))) ||
                     (ResultSrc_M1_0_H && (Rd_M1_H != 0) && ((Rs1_D_H == Rd_M1_H) || (Rs2_D_H == Rd_M1_H)));
    assign Stall_F1 = lwStall;
    assign Stall_F2 = lwStall;
    assign Stall_D = lwStall;

    assign Flush_F2 = (|PC_Src_E_H);
    assign Flush_D = (|PC_Src_E_H);
    assign Flush_E = (lwStall || (|PC_Src_E_H));

endmodule
