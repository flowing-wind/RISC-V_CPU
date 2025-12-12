module reg_file (
    input wire clk, reset,
    input wire we3,
    input wire [31:0] wd3,
    input wire [4:0] a1, a2, a3,
    
    output wire [31:0] rd1, rd2
);

    // Define register file
    reg [31:0] regs [31:0];

    // Read RefFile
    assign rd1 = (|a1) ? regs[a1] : 32'b0;
    assign rd2 = (|a2) ? regs[a2] : 32'b0;

    // Write Reg
    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i=0; i<32; i=i+1) begin
                regs[i] <= 32'b0;
            end
        end
        else if (we3 && (|a3))
            regs[a3] <= wd3;
    end

endmodule
