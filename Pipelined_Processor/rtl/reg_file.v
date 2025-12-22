module reg_file (
    input wire clk, reset,
    
    input wire WE3,
    input wire [31:0] WD3,
    input wire [4:0] A1, A2, A3,
    
    output wire [31:0] RD1, RD2
);

    // Define register file
    reg [31:0] regs [31:0];

    // Read RefFile
    assign RD1 = (WE3 && (A1 == A3) && (|A1)) ? WD3 : ((|A1) ? regs[A1] : 32'b0);
    assign RD2 = (WE3 && (A2 == A3) && (|A2)) ? WD3 : ((|A2) ? regs[A2] : 32'b0);

    // Write Reg
    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i=0; i<32; i=i+1) begin
                regs[i] <= 32'b0;
            end
        end
        else if (WE3 && (|A3))
            regs[A3] <= WD3;
    end

endmodule
