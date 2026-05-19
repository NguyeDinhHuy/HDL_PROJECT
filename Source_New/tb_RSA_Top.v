`timescale 1ns / 1ps

module tb_RSA_Top;

    // Cac tin hieu ket noi voi Module can kiem thu (DUT)
    reg          clk;
    reg          rst_n;
    reg          start;
    reg          mode;
    reg [6:0]    prime_addr;   // Cong vao doc lap chon dia chi so nguyen to
    reg [1023:0] message_in;

    wire [1023:0] message_out;
    wire          done;
    wire          error;

    // Khoi tao khoi DUT (Device Under Test)
    RSA_Top uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .mode(mode),
        .prime_addr(prime_addr), 
        .message_in(message_in),
        .message_out(message_out),
        .done(done),
        .error(error)
    );

    // Tao xung Clock he thong (Chu ky 20ns tuong duong tan so 50MHz)
    always #10 clk = ~clk;

    // Thanh ghi trung gian luu tru du lieu mo phong
    reg [1023:0] plaintext;
    reg [1023:0] ciphertext;
    reg [1023:0] decryptedtext;

    initial begin
        // Khoi tao trang thai ban dau cua cac tin hieu
        clk        = 1'b0;
        rst_n      = 1'b0;
        start      = 1'b0;
        mode       = 1'b0;
        message_in = 1024'd0;
        
        // Cau hinh doc lap dia chi so nguyen to co dinh cho toan bo bai test
        // So 23520624 co 7-bit cuoi la 48, nen ta chon thang o nho so 48
        prime_addr = 7'd48; 
        
        // Cau hinh thong diep kiem thu theo yeu cau
        plaintext  = 1024'd23520624; 

        // Cho 100ns cho qua trinh khoi tao he thong on dinh
        #100;
        rst_n = 1'b1; // Giai phong tin hieu Reset
        #40;

        $display("[MO PHONG] Bat dau qua trinh Ma hoa (Mode = 0)...");
        
        message_in = plaintext;       // Nap thong diep goc (Plaintext) vao duong du lieu
        mode       = 1'b0;            // Chon che do Ma hoa (Su dung e = 65537)
        start      = 1'b1;            // Kich hoat xung Start
        #20;
        start      = 1'b0;            // Tat xung Start sau 1 chu ky clock

        // Doi co done tu he thong bao hieu hoan thanh ma hoa
        @(posedge done);
        #10;
        ciphertext = message_out;     // Luu lai ban ma sau khi ma hoa thanh cong
        
        $display("[KET QUA MA HOA]");
        $display(" -> Plaintext (Goc)  : %d (Hex: 0x%h)", plaintext, plaintext);
        $display(" -> Ciphertext (Ma)  : %d (Hex: 0x%h)", ciphertext, ciphertext);
        $display(" -> prime_addr dau vao doc lap: %d", prime_addr);
        
        #200; // Khoang nghi an toan giua 2 qua trinh

        $display("[MO PHONG] Bat dau qua trinh Giai ma (Mode = 1)...");
        
        message_in = ciphertext;      // Nap ban ma (Ciphertext) vao duong du lieu
        mode       = 1'b1;            // Chon che do Giai ma (Su dung khoa rieng tu d)
        
        // Luu y: prime_addr van giu nguyen la 7'd48 nhu da gan o dau bai test,
        // khong bi phu thuoc hay thay doi boi gia tri cua ciphertext.
        
        start      = 1'b1;            // Kich hoat xung Start
        #20;
        start      = 1'b0;            // Tat xung Start sau 1 chu ky clock

        // Doi co done tu he thong bao hieu hoan thanh giai ma
        @(posedge done);
        #10;
        decryptedtext = message_out;  // Luu lai thong diep sau giai ma
        
        $display("[KET QUA GIAI MA]");
        $display(" -> Ciphertext nap vao : %d", ciphertext);
        $display(" -> Decrypted (Giai ma): %d (Hex: 0x%h)", decryptedtext, decryptedtext);

        // Kiem tra tinh dung dan tuyet doi cua chu trinh RSA
        if (decryptedtext == plaintext) begin
            $display("[DANH GIA] >>> THANH CONG: Thong diep giai ma trung khop hoan toan voi thong diep goc! <<<");
        end else begin
            $display("[DANH GIA] >>> THAT BAI: Qua trinh giai ma co loi, hay kiem tra lai ket noi FSM. <<<");
        end

        #100;
        $finish; // Ket thuc mo phong
    end

endmodule