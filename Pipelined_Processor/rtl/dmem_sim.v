module DATA_MEM (
    input  wire clka,
    input  wire ena,
    input  wire [3:0] wea, // 字节写使能
    input  wire [9:0] addra,
    input  wire [31:0] dina,
    output reg  [31:0] douta
);
    reg [31:0] ram [0:2047];
    
    always @(posedge clka) begin
        if (ena) begin
            if (wea[0]) ram[addra][7:0]   <= dina[7:0];
            if (wea[1]) ram[addra][15:8]  <= dina[15:8];
            if (wea[2]) ram[addra][23:16] <= dina[23:16];
            if (wea[3]) ram[addra][31:24] <= dina[31:24];
            douta <= ram[addra];
        end
    end
endmodule
