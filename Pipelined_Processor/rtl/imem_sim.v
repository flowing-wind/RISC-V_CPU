module INSTR_MEM (
    input  wire clka,
    input  wire ena,
    input  wire [0:0] wea,
    input  wire [31:0] addra,
    input  wire [31:0] dina,
    output reg  [31:0] douta
);
    reg [31:0] ram [0:2047]; // 8KB 深度
    
    always @(posedge clka) begin
        if (ena) douta <= ram[addra];
    end
endmodule
