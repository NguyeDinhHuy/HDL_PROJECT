`timescale 1ns / 1ps

module prime_ram_512_tb;

    reg          clk;
    reg          we;
    reg  [6:0]   addr;
    reg  [511:0] data_in;
    wire [511:0] data_out;

    prime_ram_512 uut (
        .clk(clk),
        .we(we),
        .addr(addr),
        .data_in(data_in),
        .data_out(data_out)
    );

    always #10 clk = ~clk;

    initial begin
        clk = 1'b0;
        we = 1'b0;
        addr = 7'd0;
        data_in = 512'd0;

        @(posedge clk);
        addr = 7'd0;
        @(posedge clk);
        #1;
        if (data_out == 512'h87d497f50f3f72428ae190d314bc2513ea2e6f532b93142b2ff76ea84e525878f9c46a3b8d7cb9c4ceb6afd4c07c7945f5ec4dc03279ac6bf45bc458d26d42e9)
            $display("PASS: read initial prime at addr 0");
        else
            $display("FAIL: addr 0 data mismatch: 0x%h", data_out);

        addr = 7'd5;
        @(posedge clk);
        #1;
        if (data_out == 512'h82b30e39dc17dc84369aae8aca84def5abb4ad51e88c0e7c2f44b3345e5553f43ecc8ba82d7649a99790173261e638616eed49aad112da56267f7104e06245ab)
            $display("PASS: read initial prime at addr 5");
        else
            $display("FAIL: addr 5 data mismatch: 0x%h", data_out);

        data_in = 512'h1234;
        addr = 7'd3;
        we = 1'b1;
        @(posedge clk);
        we = 1'b0;
        @(posedge clk);
        #1;
        if (data_out == 512'h1234)
            $display("PASS: write/read works at addr 3");
        else
            $display("FAIL: write/read mismatch: 0x%h", data_out);

        #100;
        $finish;
    end

endmodule
