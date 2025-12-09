module alu (
    input wire [31:0] src_a, src_b,
    input wire [2:0] alu_control,

    output wire zero,
    output reg [31:0] alu_result
);

    always @(*) begin
        // default
        alu_result = 32'b0;

        case (alu_control)
            3'b000: alu_result = src_a + src_b;  // add
            3'b001: alu_result = src_a - src_b;  // sub
            3'b010: alu_result = src_a & src_b;  // and
            3'b011: alu_result = src_a | src_b;  // or
            3'b101: begin   // slt
                if ($signed(src_a) < $signed(src_b))
                    alu_result = 32'b1;
                else
                    alu_result = 32'b0;
            end
        endcase
    end

    // If the result is 0, zero = 1
    assign zero = ~(|alu_result);

endmodule
