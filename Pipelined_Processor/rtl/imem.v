module imem (
    input wire [29:0] addr,
    output wire [31:0] rd
);

    // Define the RAM
    reg [31:0] RAM [0:1023];
    // tmp cache
    reg [7:0] bin_cache [0:4095];
    integer fd, i, count;

    // init
    initial begin
        fd = $fopen("main.bin", "rb");
        if (fd==0) begin
            $display("Error: Could not open main.bin");
            $finish;
        end

        count = $fread(bin_cache, fd);
        $display("Loaded %d bytes from main.bin", count);

        for (i=0; i<1024; i=i+1) begin
            RAM[i] = {bin_cache[i*4+3], bin_cache[i*4+2], bin_cache[i*4+1], bin_cache[i*4]};
        end

        $fclose(fd);
    end

    assign rd = RAM[addr];
    
endmodule

