module dmem (
    input wire clk, we,
    input wire [31:0] addr, wd,

    output wire [31:0] rd
);
    
    reg [31:0] RAM [63:0];

    // Read mem
    assign rd = RAM[addr[31:2]];    // addr[1:0] points to byte, but we need a 32 bit word.
    
    // Write mem
    always @(posedge clk) begin
        if (we)
            RAM[addr[31:2]] <= wd;
    end

endmodule

