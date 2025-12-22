module clk_wiz_0 (
    input  wire clk_in1,
    input  wire reset,
    output wire clk_out1,
    output reg  locked
);
    assign clk_out1 = clk_in1; // 仿真中直接透传时钟
    
    initial locked = 0;
    always @(posedge clk_in1 or posedge reset) begin
        if (reset) locked <= 0;
        else    locked <= 1; // 模拟 PLL 锁定延迟
    end
endmodule
