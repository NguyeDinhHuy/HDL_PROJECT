`timescale 1ns / 1ps

module rsa_512x512_multiplier_tb;

    reg          clk;               // Xung nhip he thong tao bang clock
    reg          rst_n;             // Reset thap chu dong toan mach
    reg          start;             // Tin hieu kich hoat luong nhan Pipeline
    reg [511:0]  p;                 // Thanh ghi luu so hang nhan p 512 bit
    reg [511:0]  q;                 // Thanh ghi luu so hang nhan q 512 bit

    wire [1023:0] n;                // Duong truyen nhan ket qua tich 1024 bit
    wire          done;             // Co bao nhi phan da hoan thanh tinh toan

    // --- Goi khoi mach can kiem tra ---
    rsa_512x512_multiplier uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .p(p),
        .q(q),
        .n(n),
        .done(done)
    );

    // --- Trinh tao xung nhip tuan hoan chu ky 20ns ---
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

        // =============================================================
        // TEST CASE 1: Kiem tra voi cac so hang nhan nho
        // =============================================================
        $display("=== TEST CASE 1 ===");
        p = 512'd5;
        q = 512'd10;
        start = 1'b1;
        #20;
        start = 1'b0;

        while (!done) begin
            @(posedge clk);
        end

        $display("Ket qua ma tran n thu duoc = %d", n);
        if (n == 1024'd50) begin
            $display("=> SUCCESS: Tich so nho chinh xac!");
        end else begin
            $display("=> FAIL: Tich so nho bi sai!");
        end
        #100;

        // =============================================================
        // TEST CASE 2: Kiem tra voi gia tri so nguyen lon hon
        // =============================================================
        $display("=== TEST CASE 2 ===");
        p = 512'd123456789;
        q = 512'd987654321;
        start = 1'b1;
        #20;
        start = 1'b0;

        while (!done) begin
            @(posedge clk);
        end

        $display("Ket qua ma tran n thu duoc = %d", n);
        if (n == (1024'd123456789 * 1024'd987654321)) begin
            $display("=> SUCCESS: Tich so lon chinh xac!");
        end else begin
            $display("=> FAIL: Tich so lon bi sai!");
        end

        #100;
        $finish;
    end

endmodule