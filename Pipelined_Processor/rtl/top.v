module top(
    input sys_clk,
    input sys_rst_n
    );

    // Generate reset signal
    wire locked;
    wire async_reset_n = sys_rst_n && locked;
    reg [1:0] rst_sync_n;

    always @(posedge clk_core or negedge async_reset_n) begin
        if (!async_reset_n) begin
            rst_sync_n <= 2'b00;
        end
        else begin
            rst_sync_n <= {rst_sync_n[0], 1'b1};
        end
    end

    assign reset = ~rst_sync_n[1];  // eff at 1

    
    // ===========================================================
    wire [31:0] PC, Instr, MemAddr, WriteData, ReadData;
    wire [3:0] MemWrite_EN;

    processor_core cpu (
        .clk (clk_core),
        .reset (reset),

        .PC (PC),
        .Instr (Instr),

        .MemWrite_EN (MemWrite_EN),
        .MemAddr (MemAddr),
        .WriteData (WriteData),
        .ReadData (ReadData)
    );

    clk_wiz_0 clk_wiz (
        .clk_in1 (sys_clk),
        .reset (~sys_rst_n),
        .locked (locked),
        .clk_out1 (clk_core)
    );

    INSTR_MEM imem (
        .clka (clk_core),
        .ena (rst_sync_n[0]),
        .wea (1'b0),    // instr read only
        .addra (PC),
        .dina (32'b0),
        .douta (Instr)
    );

    // DMEM
    DATA_MEM dmem (
        .clka (clk_core),
        .ena (rst_sync_n[0]),
        .wea (MemWrite_EN),
        .addra (MemAddr),
        .dina (WriteData),
        .douta (ReadData)
    );

endmodule
