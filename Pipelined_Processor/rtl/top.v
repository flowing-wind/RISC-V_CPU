module top(
    input sys_clk,
    input sys_rst_n
    );

    // Generate reset signal
    wire locked;
    wire async_reset_n = sys_rst_n && locked;
    wire reset, clk_core;
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
    wire Stall;

    processor_core cpu (
        .clk (clk_core),
        .reset (reset),

        // Interrupt Interface
        // not used for now
        .Ext_Int (1'b0), 
        .Sw_Int (1'b0), 
        .Timer_Int (1'b0),

        .PC (PC),
        .Stall (Stall),
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

    // IMEM & DMEM
    RAM mem (
        // IMEM
        .clka (clk_core),
        .ena (rst_sync_n[0] & ~Stall),
        .wea (4'b0000),    // instr read only
        .addra (PC),
        .dina (32'b0),
        .douta (Instr),

        // DMEM
        .clkb (clk_core),
        .enb (rst_sync_n[0]),
        .web (MemWrite_EN),
        .addrb (MemAddr),
        .dinb (WriteData),
        .doutb (ReadData)
    );

endmodule
