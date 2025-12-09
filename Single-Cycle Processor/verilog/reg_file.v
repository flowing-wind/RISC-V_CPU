module reg_file (
    input wire clk,
    input wire we3,
    input wire [31:0] wd3,
    input wire [4:0] a1, a2, a3,
    
    output wire [31:0] rd1, rd2
);

    // Define register file
    reg [31:0] rf [31:0];

    // Read RefFile
    assign rd1 = (|a1) ? rf[a1] : 32'b0;
    assign rd2 = (|a2) ? rf[a2] : 32'b0;

    // Write Reg
    always @(posedge clk) begin
        if (we3 && (|a3))
            rf[a3] <= wd3;
    end

endmodule

