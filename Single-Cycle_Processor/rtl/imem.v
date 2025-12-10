module imem (
    input wire [5:0] addr,
    output wire [31:0] rd
);

    // Define the RAM
    reg [31:0] RAM [63:0];

    // init
    initial begin
        $readmemh("testinstr.txt", RAM);
    end

    assign rd = RAM[addr];
    
endmodule

