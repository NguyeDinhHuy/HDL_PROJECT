`timescale 1ns / 1ps

module rsa_key_d_generator_tb;

    // --- Cac tin hieu ket noi vao khoi can test ---
    reg          clk;
    reg          rst_n;
    reg          start;
    reg [1023:0] phi;

    wire [1023:0] private_d;
    wire          done;
    wire          phi_invalid;

    // --- Goi khoi uut de tien hanh kiem tra ---
    rsa_key_d_generator uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .phi(phi),
        .private_d(private_d),
        .done(done),
        .phi_invalid(phi_invalid)
    );

    // --- Trinh tao xung nhiplay chu ky 20ns tuong duong f=50MHz ---
    always #10 clk = ~clk;

    initial begin
        // --- Khoi tao gia tri ban dau cho cac thanh ghi ---
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        phi = 1024'd0;

        // --- Cap xung reset he thong ---
        #40;
        rst_n = 1'b1;
        #20;

        // =============================================================
        // TEST CASE 1: Chay thu voi so nho p=257, q=263 -> phi=67072
        // Ket qua mong doi: private_d = 63489, phi_invalid = 0
        // =============================================================
        $display("=== TEST CASE 1: Chay voi phi = 67072 ===");
        phi = 1024'd67072;
        start = 1'b1;
        #20;
        start = 1'b0;

        // --- Vong lap cho den khi mach bao tinh toan xong ---
        while (!done) begin
            @(posedge clk);
        end

        // --- Kiem tra va in ket qua cua test case 1 ---
        if (phi_invalid) begin
            $display("ERROR: May bao loi phi khong hop le tai Test Case 1!");
        end else begin
            $display("Gia tri private_d thu duoc = %d", private_d);
            if (private_d == 1024'd63489) begin
                $display("=> SUCCESS: Ket qua tinh d chinh xac tuyet doi!");
            end else begin
                $display("=> FAIL: Ket qua bi tinh sai!");
            end
        end
        #100;

        // =============================================================
        // TEST CASE 2: Chay voi gia tri loi, phi chia het cho e (phi = 65537)
        // Ket qua mong doi: phi_invalid = 1, private_d = 0
        // =============================================================
        $display("=== TEST CASE 2: Chay voi phi loi = 65537 ===");
        phi = 1024'd65537;
        start = 1'b1;
        #20;
        start = 1'b0;

        // --- Vong lap cho den khi mach bao tinh toan xong ---
        while (!done) begin
            @(posedge clk);
        end

        // --- Kiem tra va in ket qua cua test case 2 ---
        if (phi_invalid) begin
            $display("=> SUCCESS: Mach da phat hien loi phi_invalid chinh xac!");
        end else begin
            $display("=> FAIL: Mach khong phat hien ra loi chia het! private_d = %d", private_d);
        end

        // --- Ket thuc qua trinh mo phong ---
        #100;
        $display("=== KET THUC QUA TRINH MO PHONG ===");
        $finish;
    end

endmodule