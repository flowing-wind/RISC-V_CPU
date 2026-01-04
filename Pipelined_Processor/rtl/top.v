module top(
    input sys_clk,
    input sys_rst,

    // user UART
    input uart_rx,
    output uart_tx
    );

    // Generate reset signal
    wire locked;
    wire sys_rst_n = ~sys_rst;
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
    // Clock and Core
    // ===========================================================
    wire [31:0] PC, Instr, MemAddr, WriteData, ReadData;
    wire [3:0] MemWrite_EN;
    wire MemReq;
    wire IMEM_Stall; // Stall F1 for IMEM
    wire AXI_Stall;
    wire UART_Irq;
    wire [31:0] ram_rdata, rom_rdata;

    clk_wiz_0 clk_wiz (
        .clk_in1 (sys_clk),
        .reset (~sys_rst_n),
        .locked (locked),
        .clk_out1 (clk_core)
    );

    processor_core cpu (
        .clk (clk_core),
        .reset (reset),

        // Interrupt Interface
        .Ext_Int (UART_Irq), 
        .Sw_Int (1'b0), 
        .Timer_Int (1'b0),
        .EX_Stall (AXI_Stall),

        .PC (PC),
        .Stall (IMEM_Stall),
        .Instr (Instr),

        .MemReq (MemReq),
        .MemWrite_EN (MemWrite_EN),
        .MemAddr (MemAddr),
        .WriteData (WriteData),
        .ReadData (ReadData)
    );


    // ===========================================================
    // Address Decode
    // ===========================================================
    // RAM:  0x0000_0000
    // USER UART:  0x1000_0000 ~ 0x2FFF_FFFF;
    wire is_ram_addr   = (MemAddr[31:28] == 4'h0);
    wire is_uart_addr  = (MemAddr[31:28] == 4'h1);
    reg  is_uart_addr_M2;    // addr should be kept, otherwise ReadData will change unexpectly
    
    always @(posedge clk_core or posedge reset) begin
        if (reset) begin
            is_uart_addr_M2 <= 1'b0;
        end
        else begin
            if (AXI_Stall)
                is_uart_addr_M2 <= is_uart_addr_M2;
            else
                is_uart_addr_M2 <= is_uart_addr;
        end
    end


    // ===========================================================
    // USER UART AXI Bridge
    // ===========================================================
    // AXI-Lite interface
    wire [31:0] m_axi_awaddr, m_axi_wdata, m_axi_araddr, m_axi_rdata;
    wire [3:0]  m_axi_wstrb;
    wire        m_axi_awvalid, m_axi_awready, m_axi_wvalid, m_axi_wready;
    wire [1:0]  m_axi_bresp, m_axi_rresp;
    wire        m_axi_bvalid, m_axi_bready, m_axi_arvalid, m_axi_arready;
    wire        m_axi_rvalid, m_axi_rready;

    wire [31:0] uart_rdata;

    // AXI_Bridge
    axi_bridge bridge (
        .clk (clk_core),
        .rstn (~reset),

        .cpu_addr (MemAddr),
        .cpu_wdata (WriteData),
        .cpu_we (MemWrite_EN),
        .cpu_req (is_uart_addr && MemReq),
        
        .cpu_rdata (uart_rdata),
        .cpu_stall (AXI_Stall),

        // AXI
        .m_axi_awaddr(m_axi_awaddr), .m_axi_awvalid(m_axi_awvalid), .m_axi_awready(m_axi_awready),
        .m_axi_wdata(m_axi_wdata), .m_axi_wstrb(m_axi_wstrb), .m_axi_wvalid(m_axi_wvalid), .m_axi_wready(m_axi_wready),
        .m_axi_bresp(m_axi_bresp), .m_axi_bvalid(m_axi_bvalid), .m_axi_bready(m_axi_bready),
        .m_axi_araddr(m_axi_araddr), .m_axi_arvalid(m_axi_arvalid), .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata), .m_axi_rresp(m_axi_rresp), .m_axi_rvalid(m_axi_rvalid), .m_axi_rready(m_axi_rready)
    );

    axi_uartlite_0 uart (
        .s_axi_aclk    (clk_core),
        .s_axi_aresetn (~reset),
        .interrupt     (UART_Irq),
        
        .s_axi_awaddr  (m_axi_awaddr[3:0]),
        .s_axi_awvalid (m_axi_awvalid),
        .s_axi_awready (m_axi_awready),
        .s_axi_wdata   (m_axi_wdata),
        .s_axi_wstrb   (m_axi_wstrb),
        .s_axi_wvalid  (m_axi_wvalid),
        .s_axi_wready  (m_axi_wready),
        .s_axi_bresp   (m_axi_bresp),
        .s_axi_bvalid  (m_axi_bvalid),
        .s_axi_bready  (m_axi_bready),
        .s_axi_araddr  (m_axi_araddr[3:0]),
        .s_axi_arvalid (m_axi_arvalid),
        .s_axi_arready (m_axi_arready),
        .s_axi_rdata   (m_axi_rdata),
        .s_axi_rresp   (m_axi_rresp),
        .s_axi_rvalid  (m_axi_rvalid),
        .s_axi_rready  (m_axi_rready),
        
        .rx (uart_rx),
        .tx (uart_tx)
    );


    
    // ===========================================================
    // BRAM
    // ===========================================================
    // IMEM & DMEM
    RAM mem (
        // IMEM
        .clka (clk_core),
        .ena (rst_sync_n[0] & ~IMEM_Stall),
        .wea (4'b0000),    // instr read only
        .addra (PC),
        .dina (32'b0),
        .douta (Instr),

        // DMEM
        .clkb (clk_core),
        .enb (rst_sync_n[0] & is_ram_addr),
        .web (MemWrite_EN),
        .addrb (MemAddr),
        .dinb (WriteData),
        .doutb (ram_rdata)
    );


    // ===========================================================
    // ReadData MUX
    // ===========================================================
    assign ReadData = is_uart_addr_M2 ? uart_rdata : ram_rdata;

endmodule
