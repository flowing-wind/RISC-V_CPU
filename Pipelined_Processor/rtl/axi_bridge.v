module axi_bridge (
    input wire clk, rstn,

    // processor core
    input wire [31:0] cpu_addr,
    input wire [31:0] cpu_wdata,
    input wire [3:0] cpu_we,
    input wire cpu_req,     // available when using UART
    output reg [31:0] cpu_rdata,
    output wire cpu_stall,

    // AXI-Lite Master
    output reg  [31:0] m_axi_awaddr,
    output reg         m_axi_awvalid,
    input  wire        m_axi_awready,
    
    output reg  [31:0] m_axi_wdata,
    output reg  [3:0]  m_axi_wstrb,
    output reg         m_axi_wvalid,
    input  wire        m_axi_wready,
    
    input  wire [1:0]  m_axi_bresp,
    input  wire        m_axi_bvalid,
    output reg         m_axi_bready,
    
    output reg  [31:0] m_axi_araddr,
    output reg         m_axi_arvalid,
    input  wire        m_axi_arready,
    
    input  wire [31:0] m_axi_rdata,
    input  wire [1:0]  m_axi_rresp,
    input  wire        m_axi_rvalid,
    output reg         m_axi_rready
);

    localparam IDLE = 3'd0;
    localparam WR_ADDR_DATA = 3'd1;
    localparam WR_RESP = 3'd2;
    localparam RD_ADDR = 3'd3;
    localparam RD_DATA = 3'd4;

    reg [2:0] state;
    wire is_write = |cpu_we;

    assign cpu_stall =  (state != IDLE);

    always @(posedge clk or negedge rstn) begin 
        if (!rstn) begin
            state <= IDLE;
            m_axi_awvalid <= 0; m_axi_wvalid <= 0; m_axi_bready <= 0;
            m_axi_arvalid <= 0; m_axi_rready<= 0;
            cpu_rdata <= 32'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (cpu_req) begin
                        if (is_write) begin // write data
                            state <= WR_ADDR_DATA;
                            m_axi_awaddr <= cpu_addr;
                            m_axi_awvalid <= 1;
                            m_axi_wdata <= cpu_wdata;
                            m_axi_wstrb <= cpu_we;
                            m_axi_wvalid <= 1;
                            m_axi_bready <= 1;  // ready to response in advance
                        end
                        else begin
                            //  read data
                            state <= RD_ADDR;
                            m_axi_araddr <= cpu_addr;
                            m_axi_arvalid <= 1;
                            m_axi_rready <= 1;
                        end
                    end
                end
                
                // Write
                WR_ADDR_DATA: begin
                    if (m_axi_awready) m_axi_awvalid <= 0;
                    if (m_axi_wready) m_axi_wvalid <= 0;

                    if (m_axi_bvalid) begin
                        m_axi_awvalid <= 0;
                        m_axi_wvalid <= 0;
                        m_axi_bready <= 0;
                        state <= IDLE;
                    end
                    else if (!m_axi_awvalid && !m_axi_wvalid) state <= WR_RESP;
                end

                WR_RESP: begin
                    if (m_axi_bvalid) begin
                        state <= IDLE;
                    end
                end

                // Read
                RD_ADDR: begin
                    if (m_axi_arready) begin
                        m_axi_arvalid <= 0;
                        state <= RD_DATA;
                    end
                end
                RD_DATA: begin
                    if (m_axi_rvalid) begin
                        if (m_axi_rresp == 2'b10)
                            cpu_rdata <= 32'b0;
                        else
                            cpu_rdata <= m_axi_rdata;

                        m_axi_rready <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
