module dmem (
    input wire clk, we,
    input wire [31:0] addr, wd,
    input wire [2:0] funct3,

    output wire [31:0] rd
);
    
    reg [31:0] RAM [63:0];

    // init
    integer i;
    initial begin
        for (i=0; i<64; i=i+1) begin
            RAM[i] <= 32'b0;
        end
    end

    // Read mem
    assign rd = RAM[addr[31:2]];    // addr[1:0] points to byte, but we need a 32 bit word.
    
    // Write mem
    always @(posedge clk) begin
        if (we) begin
            case (funct3)
                // sw
                3'b010: RAM[addr[31:2]] <= wd;

                // sh
                3'b001: begin
                    if (addr[1] == 0)   // low
                        RAM[addr[31:2]][15:0] <= wd[15:0];
                    else
                        RAM[addr[31:2]][31:16] <= wd[15:0];
                end

                // sb
                3'b000: begin
                    case (addr[1:0])
                        2'b00: RAM[addr[31:2]][7:0]     <= wd[7:0];
                        2'b01: RAM[addr[31:2]][15:8]    <= wd[7:0];
                        2'b10: RAM[addr[31:2]][23:16]   <= wd[7:0];
                        2'b11: RAM[addr[31:2]][31:24]   <= wd[7:0];
                    endcase
                end

                default: RAM[addr[31:2]] <= wd;  
            endcase
        end
    end

endmodule

