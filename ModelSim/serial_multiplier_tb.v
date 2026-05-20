`timescale 1ns / 1ps

module serial_multiplier_tb;

    reg          clk;
    reg          rst_n;
    reg          start;
    reg [511:0]  p;
    reg [511:0]  q;

    wire [1023:0] n;
    wire          done;

    serial_multiplier #(
        .WIDTH(512),
        .CHUNK_WIDTH(32)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .multiplicand_in(p),
        .multiplier_in(q),
        .product_out(n),
        .done(done)
    );

    always #10 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        p = 512'd0;
        q = 512'd0;

        #40;
        rst_n = 1'b1;
        #20;

        $display("=== TEST CASE 1 ===");
        p = 512'd5;
        q = 512'd10;
        start = 1'b1;
        #20;
        start = 1'b0;

        while (!done) begin
            @(posedge clk);
        end

        $display("Ket qua n = %d", n);
        if (n == 1024'd50) begin
            $display("=> SUCCESS: Tich so nho chinh xac!");
        end else begin
            $display("=> FAIL: Tich so nho bi sai!");
        end
        #100;

        $display("=== TEST CASE 2 ===");
        p = 512'd123456789;
        q = 512'd987654321;
        start = 1'b1;
        #20;
        start = 1'b0;

        while (!done) begin
            @(posedge clk);
        end

        $display("Ket qua n = %d", n);
        if (n == (1024'd123456789 * 1024'd987654321)) begin
            $display("=> SUCCESS: Tich so lon chinh xac!");
        end else begin
            $display("=> FAIL: Tich so lon bi sai!");
        end

        #100;
        $finish;
    end

endmodule
