module datapath (
    input wire [31:0] instr,
    input wire clk, reset,
    input wire [31:0] read_data,
    input wire [2:0] imm_src,
    input wire [1:0] pc_src,
    input wire [1:0] alu_src_a,
    input wire alu_src_b,
    input [1:0] result_src,
    input wire reg_write,
    input wire [3:0] alu_control,

    output reg [31:0] pc,
    output wire zero,
    output wire [31:0] alu_result,
    output wire [31:0] write_data
);
    reg [31:0] pc_next;
    wire [31:0] pc_plus4, pc_target;
    wire [31:0] imm_ext;
    reg [31:0] src_a;
    wire [31:0] src_b;
    wire [31:0] rf_rd1;
    reg [31:0] result;
    reg [31:0] mem_data_processed;  // for lb, lh, lbu, lhu
    wire [2:0] funct3 = instr[14:12];
    wire [1:0] byte_offset = alu_result[1:0];

    // Load data logic
    always @( *) begin
        case (funct3)
            // lw
            3'b010: mem_data_processed = read_data;

            // lb
            3'b000: begin
                case (byte_offset)
                    2'b00: mem_data_processed = {{24{read_data[7]}}, read_data[7:0]};
                    2'b01: mem_data_processed = {{24{read_data[15]}}, read_data[15:8]};
                    2'b10: mem_data_processed = {{24{read_data[23]}}, read_data[23:16]};
                    2'b11: mem_data_processed = {{24{read_data[31]}}, read_data[31:24]};
                endcase
            end

            // lbu
            3'b100: begin
                case (byte_offset)
                    2'b00: mem_data_processed = {24'b0, read_data[7:0]};
                    2'b01: mem_data_processed = {24'b0, read_data[15:8]};
                    2'b10: mem_data_processed = {24'b0, read_data[23:16]};
                    2'b11: mem_data_processed = {24'b0, read_data[31:24]};
                endcase
            end

            // lh
            3'b001: begin
                if (byte_offset[1] == 0)    // low
                    mem_data_processed = {{16{read_data[15]}}, read_data[15:0]};
                else
                    mem_data_processed = {{16{read_data[31]}}, read_data[31:16]};
            end

            // lhu
            3'b101: begin
                if (byte_offset[1] == 0)    // low
                    mem_data_processed = {16'b0, read_data[15:0]};
                else
                    mem_data_processed = {16'b0, read_data[31:16]};
            end
        endcase
    end

    // PC Logic
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 32'b0;
        else
            pc <= pc_next;
    end

    // Decide next pc
    assign pc_plus4 = pc + 32'd4;
    assign pc_target = pc + imm_ext;

    always @( *) begin
        case (pc_src)
            2'b00: pc_next = pc_plus4;
            2'b01: pc_next = pc_target;
            2'b10: pc_next = alu_result;

            default: pc_next = pc_plus4;
        endcase
    end

    // Choose src_a
    always @( *) begin
        case (alu_src_a)
            2'b00: src_a = rf_rd1;
            2'b01: src_a = pc;
            2'b10: src_a = 32'b0;

            default: src_a = rf_rd1;
        endcase
    end

    // Choose src_b
    assign src_b = (alu_src_b) ? imm_ext : write_data;

    // Choose result
    always @( *) begin
        case (result_src)
            2'b00: result = alu_result;
            2'b01: result = mem_data_processed;
            2'b10: result = pc_plus4;
            
            default: result = alu_result;
        endcase
    end

    // Register File
    reg_file rf (
        .clk (clk),
        .reset (reset),
        .we3 (reg_write),
        .wd3 (result),
        .a1 (instr[19:15]),
        .a2 (instr[24:20]),
        .a3 (instr[11:7]),

        .rd1 (rf_rd1),
        .rd2 (write_data)
    );

    // Extend Imm
    extend_unit ext (
        .instr(instr),
        .imm_src (imm_src),

        .imm_ext (imm_ext)
    );

    // ALU
    alu alu_core (
        .src_a (src_a),
        .src_b (src_b),
        .alu_control (alu_control),

        .zero (zero),
        .alu_result (alu_result)
    );

endmodule

