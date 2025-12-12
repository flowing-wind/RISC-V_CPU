module imem (
    input wire [29:0] addr,
    output wire [31:0] rd
);

    // Define the RAM
    reg [31:0] RAM [0:1023];

    // init
    initial begin
        $readmemh("instr.txt", RAM);
    end

    assign rd = RAM[addr];
    
endmodule

