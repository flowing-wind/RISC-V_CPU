module top(
    input sys_clk,
    input sys_rst,

    // isp UART
    input isp_uart_rx,
    output isp_uart_tx,

    // user UART
    input user_uart_rx,
    output user_uart_tx
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
    wire [31:0] PC, Instr, Boot_Instr, RAM_Instr, MemAddr, WriteData, ReadData;
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
    // ROM:  0x0000_0000 ~ 0x0000_0FFF  (BOOT)
    // RAM:  0x0000_1000 ~ 0x0000_4FFF
    // ISP UART :  0x1000_0000 ~ 0x1FFF_FFFF;
    // USER UART:  0x2000_0000 ~ 0x2FFF_FFFF;
    wire is_rom_addr    = (MemAddr[31:12] == 20'h00000);
    wire is_ram_addr    = (MemAddr[31:12] >= 20'h00001 && MemAddr[31:12] <= 20'h00004);

    wire is_isp_uart_addr   = (MemAddr[31:28] == 4'h1);
    wire is_user_uart_addr  = (MemAddr[31:28] == 4'h2);

    reg  is_rom_addr_M2, is_isp_uart_addr_M2, is_user_uart_addr_M2;    // addr should be kept, otherwise ReadData will change unexpectly

    wire isp_stall, user_stall;

    assign Instr = (PC[31:12] == 20'h00000) ? Boot_Instr : RAM_Instr;
    
    always @(posedge clk_core or posedge reset) begin
        if (reset) begin
            is_rom_addr_M2       <= 1'b0;
            is_isp_uart_addr_M2  <= 1'b0;
            is_user_uart_addr_M2 <= 1'b0;
        end
        else begin
            is_rom_addr_M2 <= is_rom_addr;

            if (isp_stall)
                is_isp_uart_addr_M2  <= is_isp_uart_addr_M2;
            else
                is_isp_uart_addr_M2  <= is_isp_uart_addr;

            if (user_stall)
                is_user_uart_addr_M2 <= is_user_uart_addr_M2;
            else
                is_user_uart_addr_M2 <= is_user_uart_addr;
        end
    end


    // ===========================================================
    // ISP UART AXI Bridge
    // ===========================================================
    // AXI-Lite interface
    wire [31:0] m_axi_isp_awaddr, m_axi_isp_wdata, m_axi_isp_araddr, m_axi_isp_rdata;
    wire [3:0]  m_axi_isp_wstrb;
    wire        m_axi_isp_awvalid, m_axi_isp_awready, m_axi_isp_wvalid, m_axi_isp_wready;
    wire [1:0]  m_axi_isp_bresp, m_axi_isp_rresp;
    wire        m_axi_isp_bvalid, m_axi_isp_bready, m_axi_isp_arvalid, m_axi_isp_arready;
    wire        m_axi_isp_rvalid, m_axi_isp_rready;

    wire [31:0] isp_rdata;

    // AXI_Bridge
    axi_bridge bridge_isp (
        .clk (clk_core),
        .rstn (~reset),

        .cpu_addr (MemAddr),
        .cpu_wdata (WriteData),
        .cpu_we (MemWrite_EN),
        .cpu_req (is_isp_uart_addr && MemReq),
        
        .cpu_rdata (isp_rdata),
        .cpu_stall (isp_stall),

        // AXI
        .m_axi_awaddr(m_axi_isp_awaddr), .m_axi_awvalid(m_axi_isp_awvalid), .m_axi_awready(m_axi_isp_awready),
        .m_axi_wdata(m_axi_isp_wdata), .m_axi_wstrb(m_axi_isp_wstrb), .m_axi_wvalid(m_axi_isp_wvalid), .m_axi_wready(m_axi_isp_wready),
        .m_axi_bresp(m_axi_isp_bresp), .m_axi_bvalid(m_axi_isp_bvalid), .m_axi_bready(m_axi_isp_bready),
        .m_axi_araddr(m_axi_isp_araddr), .m_axi_arvalid(m_axi_isp_arvalid), .m_axi_arready(m_axi_isp_arready),
        .m_axi_rdata(m_axi_isp_rdata), .m_axi_rresp(m_axi_isp_rresp), .m_axi_rvalid(m_axi_isp_rvalid), .m_axi_rready(m_axi_isp_rready)
    );

    axi_uartlite_isp uart_isp (
        .s_axi_aclk    (clk_core),
        .s_axi_aresetn (~reset),
        // .interrupt     (),   // isp donot need interrupt
        
        .s_axi_awaddr  (m_axi_isp_awaddr[3:0]),
        .s_axi_awvalid (m_axi_isp_awvalid),
        .s_axi_awready (m_axi_isp_awready),
        .s_axi_wdata   (m_axi_isp_wdata),
        .s_axi_wstrb   (m_axi_isp_wstrb),
        .s_axi_wvalid  (m_axi_isp_wvalid),
        .s_axi_wready  (m_axi_isp_wready),
        .s_axi_bresp   (m_axi_isp_bresp),
        .s_axi_bvalid  (m_axi_isp_bvalid),
        .s_axi_bready  (m_axi_isp_bready),
        .s_axi_araddr  (m_axi_isp_araddr[3:0]),
        .s_axi_arvalid (m_axi_isp_arvalid),
        .s_axi_arready (m_axi_isp_arready),
        .s_axi_rdata   (m_axi_isp_rdata),
        .s_axi_rresp   (m_axi_isp_rresp),
        .s_axi_rvalid  (m_axi_isp_rvalid),
        .s_axi_rready  (m_axi_isp_rready),
        
        .rx (isp_uart_rx),
        .tx (isp_uart_tx)
    );


    // ===========================================================
    // USER UART AXI Bridge
    // ===========================================================
    // AXI-Lite interface
    wire [31:0] m_axi_user_awaddr, m_axi_user_wdata, m_axi_user_araddr, m_axi_user_rdata;
    wire [3:0]  m_axi_user_wstrb;
    wire        m_axi_user_awvalid, m_axi_user_awready, m_axi_user_wvalid, m_axi_user_wready;
    wire [1:0]  m_axi_user_bresp, m_axi_user_rresp;
    wire        m_axi_user_bvalid, m_axi_user_bready, m_axi_user_arvalid, m_axi_user_arready;
    wire        m_axi_user_rvalid, m_axi_user_rready;

    wire [31:0] user_rdata;

    // AXI_Bridge
    axi_bridge bridge_user (
        .clk (clk_core),
        .rstn (~reset),

        .cpu_addr (MemAddr),
        .cpu_wdata (WriteData),
        .cpu_we (MemWrite_EN),
        .cpu_req (is_user_uart_addr && MemReq),
        
        .cpu_rdata (user_rdata),
        .cpu_stall (user_stall),

        // AXI
        .m_axi_awaddr(m_axi_user_awaddr), .m_axi_awvalid(m_axi_user_awvalid), .m_axi_awready(m_axi_user_awready),
        .m_axi_wdata(m_axi_user_wdata), .m_axi_wstrb(m_axi_user_wstrb), .m_axi_wvalid(m_axi_user_wvalid), .m_axi_wready(m_axi_user_wready),
        .m_axi_bresp(m_axi_user_bresp), .m_axi_bvalid(m_axi_user_bvalid), .m_axi_bready(m_axi_user_bready),
        .m_axi_araddr(m_axi_user_araddr), .m_axi_arvalid(m_axi_user_arvalid), .m_axi_arready(m_axi_user_arready),
        .m_axi_rdata(m_axi_user_rdata), .m_axi_rresp(m_axi_user_rresp), .m_axi_rvalid(m_axi_user_rvalid), .m_axi_rready(m_axi_user_rready)
    );

    axi_uartlite_user uart_user (
        .s_axi_aclk    (clk_core),
        .s_axi_aresetn (~reset),
        .interrupt     (UART_Irq),
        
        .s_axi_awaddr  (m_axi_user_awaddr[3:0]),
        .s_axi_awvalid (m_axi_user_awvalid),
        .s_axi_awready (m_axi_user_awready),
        .s_axi_wdata   (m_axi_user_wdata),
        .s_axi_wstrb   (m_axi_user_wstrb),
        .s_axi_wvalid  (m_axi_user_wvalid),
        .s_axi_wready  (m_axi_user_wready),
        .s_axi_bresp   (m_axi_user_bresp),
        .s_axi_bvalid  (m_axi_user_bvalid),
        .s_axi_bready  (m_axi_user_bready),
        .s_axi_araddr  (m_axi_user_araddr[3:0]),
        .s_axi_arvalid (m_axi_user_arvalid),
        .s_axi_arready (m_axi_user_arready),
        .s_axi_rdata   (m_axi_user_rdata),
        .s_axi_rresp   (m_axi_user_rresp),
        .s_axi_rvalid  (m_axi_user_rvalid),
        .s_axi_rready  (m_axi_user_rready),
        
        .rx (user_uart_rx),
        .tx (user_uart_tx)
    );

    assign AXI_Stall = isp_stall || user_stall;

    
    // ===========================================================
    // BRAM
    // ===========================================================
    Boot_ROM rom (
        // BootInstr
        .clka (clk_core),
        .ena (rst_sync_n[0] & ~IMEM_Stall),
        .wea (4'b0000),
        .addra (PC),
        .dina (32'b0),
        .douta (Boot_Instr),

        // BootData
        .clkb (clk_core),
        .enb (rst_sync_n[0] & is_rom_addr),
        .web (MemWrite_EN),
        .addrb (MemAddr),
        .dinb (WriteData),
        .doutb (rom_rdata)
    );

    // IMEM & DMEM
    RAM mem (
        // IMEM
        .clka (clk_core),
        .ena (rst_sync_n[0] & ~IMEM_Stall),
        .wea (4'b0000),    // instr read only
        .addra (PC),
        .dina (32'b0),
        .douta (RAM_Instr),

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
    assign ReadData = is_isp_uart_addr_M2 ? isp_rdata : 
                      (is_user_uart_addr_M2 ? user_rdata : 
                      (is_rom_addr_M2 ? rom_rdata : ram_rdata));

endmodule
