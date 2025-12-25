module csr_file (
    input wire clk, reset,

    // Read/Write reg
    input wire [11:0] csr_addr,
    input wire csr_we,      // csr write enable
    input wire [31:0] csr_wdata,    // write data
    output wire [31:0] csr_rdata,    // read data

    // Trap interface (from W)
    input wire trap_en,
    input wire [31:0] trap_pc,  // pc --> into mepc
    input wire [31:0] trap_cause,   // cause --> into mcause
    input wire [31:0] trap_val,     // trap info --> mtval

    // Return? (from W)
    input wire is_mret,

    // Interrupt input
    input wire ext_int,     // External interrupt
    input wire sw_int,      // Software interrupt
    input wire timer_int,   // Timer interrupt

    // Control signals
    output wire [31:0] mepc_out,    // return addr
    output wire [31:0] mtvec_out,   // trap, jump to addr
    output wire global_int_en,  // MIE, interrupt enable
    output wire interrupt_pending   // pending interrupt
);

    // CSRs
    reg [31:0] mtvec;
    reg [31:0] mepc;
    reg [31:0] mcause;
    reg [31:0] mstatus;
    reg [31:0] mtval;
    reg [31:0] mip;
    reg [31:0] mie;

    // map address
    localparam CSR_MSTATUS  = 12'h300;
    localparam CSR_MIE      = 12'h304;
    localparam CSR_MTVEC    = 12'h305;
    localparam CSR_MEPC     = 12'h341;
    localparam CSR_MCAUSE   = 12'h342;
    localparam CSR_MTVAL    = 12'h343;
    localparam CSR_MIP      = 12'h344;
    // Fake CSRs, not needed in this case
    localparam CSR_MHARTID  = 12'hF14;
    localparam CSR_MISA     = 12'h301;
    localparam CSR_MEDELEG  = 12'h302;
    localparam CSR_MIDELEG  = 12'h303;
    localparam CSR_SATP     = 12'h180;
    localparam CSR_PMPCFG0  = 12'h3A0;
    localparam CSR_PMPADDR0 = 12'h3B0;

    // Read
    assign csr_rdata = (csr_addr == CSR_MSTATUS) ? mstatus :
                       (csr_addr == CSR_MIE)     ? mie     :
                       (csr_addr == CSR_MTVEC)   ? mtvec   :
                       (csr_addr == CSR_MEPC)    ? mepc    :
                       (csr_addr == CSR_MCAUSE)  ? mcause  :
                       (csr_addr == CSR_MTVAL)   ? mtval   :
                       (csr_addr == CSR_MIP)     ? mip     : 
                        // Fake Read Logic
                       (csr_addr == CSR_MHARTID) ? 32'b0   : 
                       (csr_addr == CSR_MISA)    ? 32'h40001100 : // RV32I
                       (csr_addr == CSR_SATP)    ? 32'b0   :
                       (csr_addr == CSR_MEDELEG) ? 32'b0   :
                       (csr_addr == CSR_MIDELEG) ? 32'b0   : 32'b0;
    
    assign mepc_out = mepc;
    assign mtvec_out = mtvec;
    assign global_int_en = mstatus[3];  // mstatus.MIE

    wire [31:0] pending_interrupts;
    assign pending_interrupts = mip & mie;  // if != 1, interrupt exists
    assign interrupt_pending = |pending_interrupts;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mtvec   <= 32'b0;
            mepc    <= 32'b0;
            mcause  <= 32'b0;
            mstatus <= 32'h1800;    // MPP = 2'b11  -->  machine
            mtval   <= 32'b0;
            mip     <= 32'b0;
            mie     <= 32'b0;
        end
        else begin
            mip [11] <= ext_int;    // MEIP
            mip [7]  <= timer_int;  // MTIP
            mip [3]  <= sw_int;     // MSIP

            if (trap_en) begin
                mepc    <= trap_pc;
                mcause  <= trap_cause;
                mtval   <= trap_val;
                // mstatus
                mstatus[7] <= mstatus[3];   // MPIE --> store old state
                mstatus[3] <= 1'b0;     // MIE --> disbale interrupt
                // Machine mode only, do not update MPP
            end
            // MRET return
            else if (is_mret) begin
                mstatus[3] <= mstatus[7];
                mstatus[7] <= 1'b1;     // set to 1 --> avoid errors in Interrupt Nesting
            end
            // Write CSR
            else if (csr_we) begin
                case (csr_addr)
                    CSR_MSTATUS:    mstatus <= csr_wdata;
                    CSR_MIE:        mie     <= csr_wdata;
                    CSR_MTVEC:      mtvec   <= csr_wdata;
                    CSR_MEPC:       mepc    <= csr_wdata;
                    CSR_MCAUSE:     mcause  <= csr_wdata;
                    CSR_MTVAL:      mtval   <= csr_wdata;
                    CSR_MIP:        mip     <= csr_wdata;
                endcase
            end
        end
    end

endmodule
