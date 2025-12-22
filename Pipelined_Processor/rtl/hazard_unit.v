module hazard_unit (
    input wire clk, reset,
    input wire [4:0] Rs1_D_H, Rs2_D_H, Rs1_E_H, Rs2_E_H, Rd_E_H, Rd_M_H, Rd_W_H,
    input wire [1:0] PC_Src_E_H,
    input wire ResultSrc_E_0_H, RegWrite_M_H,  RegWrite_W_H,

    output wire Stall_F, Stall_D, Flush_D, Flush_E,
    output wire [1:0] ForwardA_E, ForwardB_E
);

    reg [1:0] ForwardA_E_r, ForwardB_E_r;
    assign ForwardA_E = ForwardA_E_r;
    assign ForwardB_E = ForwardB_E_r;

    wire lwStall;

    // ForwardA_E  -->  Data Hazard
    always @( *) begin
        if (((Rs1_E_H == Rd_M_H) && RegWrite_M_H) && (Rs1_E_H != 0))
            ForwardA_E_r = 2'b10;
        else if (((Rs1_E_H == Rd_W_H) && RegWrite_W_H) && (Rs1_E_H != 0))
            ForwardA_E_r = 2'b01;
        else
            ForwardA_E_r = 2'b00;
    end

    // ForwardB_E
    always @( *) begin
        if (((Rs2_E_H == Rd_M_H) && RegWrite_M_H) && (Rs2_E_H != 0))
            ForwardB_E_r = 2'b10;
        else if (((Rs2_E_H == Rd_W_H) && RegWrite_W_H) && (Rs2_E_H != 0))
            ForwardB_E_r = 2'b01;
        else
            ForwardB_E_r = 2'b00;
    end

    // Stall  -->  Load Hazard
    assign lwStall = (ResultSrc_E_0_H && ((Rs1_D_H == Rd_E_H) || (Rs2_D_H == Rd_E_H)));
    assign Stall_F = lwStall;
    assign Stall_D = lwStall;

    // Flush  -->  Branch Taken
    reg flush_delay;    // Due to BRAM, we need to flush D again when branch taken
    always @(posedge clk or posedge reset) begin
        if (reset)
            flush_delay <= 1'b0;
        else
            flush_delay <= (|PC_Src_E_H);
    end

    assign Flush_D = (|PC_Src_E_H) || flush_delay;
    assign Flush_E = (lwStall || (|PC_Src_E_H));

endmodule
