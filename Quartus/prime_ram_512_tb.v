`timescale 1ns / 1ps

module prime_ram_512_tb;

    reg          clk;
    reg          we;
    reg  [6:0]   addr;
    reg  [511:0] data_in;
    wire [511:0] data_out;

    integer pass_count;
    integer fail_count;

    prime_ram_512 uut (
        .clk(clk),
        .we(we),
        .addr(addr),
        .data_in(data_in),
        .data_out(data_out)
    );

    always #10 clk = ~clk;

    task check_read;
        input [6:0] in_addr;
        input [511:0] expected;
        begin
            @(negedge clk);
            we = 1'b0;
            addr = in_addr;
            @(posedge clk);
            #1;
            if (data_out !== expected) begin
                $display("FAIL: addr=%0d got=0x%h expected=0x%h", in_addr, data_out, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: read addr=%0d", in_addr);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task write_word;
        input [6:0] in_addr;
        input [511:0] value;
        begin
            @(negedge clk);
            we = 1'b1;
            addr = in_addr;
            data_in = value;
            @(posedge clk);
            #1;
            we = 1'b0;
        end
    endtask

    initial begin
        clk = 1'b0;
        we = 1'b0;
        addr = 7'd0;
        data_in = 512'd0;
        pass_count = 0;
        fail_count = 0;

        #30;

        check_read(7'd0, 512'h87d497f50f3f72428ae190d314bc2513ea2e6f532b93142b2ff76ea84e525878f9c46a3b8d7cb9c4ceb6afd4c07c7945f5ec4dc03279ac6bf45bc458d26d42e9);
        check_read(7'd1, 512'hd25259edda95cf65d6ecb0e3d4e6d8385dd11e8b36e3ffb3cdfcfc043359ea0909da10a8fb314fd6cc1de78169bbb1250cce24d0dee13cf8187c25ec930484df);

        write_word(7'd5, 512'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef);
        check_read(7'd5, 512'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef);

        $display("=== prime_ram_512_tb: pass=%0d fail=%0d ===", pass_count, fail_count);
        $finish;
    end

endmodule
