`timescale 1ns / 1ps

module tb_RSA_top;

    reg          clk;
    reg          rst_n;
    reg          start;
    reg          mode;
    reg [6:0]    prime_addr;
    reg [935:0]  plaintext_in;
    reg [1023:0] ciphertext_in;

    wire [1023:0] ciphertext_out;
    wire [935:0]  plaintext_out;
    wire          done;
    wire          error;

    RSA_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .mode(mode),
        .prime_addr(prime_addr), 
        .plaintext_in(plaintext_in),
        .ciphertext_in(ciphertext_in),
        .ciphertext_out(ciphertext_out),
        .plaintext_out(plaintext_out),
        .done(done),
        .error(error)
    );

    always #10 clk = ~clk;

    reg [935:0]  tb_plaintext;
    reg [1023:0] tb_ciphertext;
    
    // Khai bao cac bien ghi lai thoi gian bat dau de tinh khoang thoi gian chenh lech
    real t_enc_start;
    real t_dec_start;

    initial begin
        clk           = 1'b0;
        rst_n         = 1'b0;
        start         = 1'b0;
        mode          = 1'b0;
        plaintext_in  = 936'd0;
        ciphertext_in = 1024'd0;
        prime_addr    = 7'd48; 
        tb_plaintext  = 936'd23520624; 

        #100;
        rst_n = 1'b1; 
        #40;

        $display("[MO PHONG] Nguoi dung nhap message_in thong diep goc: %d", tb_plaintext);
        $display("[MO PHONG] Bat dau giai doan 1: Ma hoa (Mode = 0)...");
        
        t_enc_start  = $realtime; // Ghi lai thoi diem bat dau phat xung start ma hoa
        plaintext_in = tb_plaintext;
        mode         = 1'b0;
        start        = 1'b1;
        #20;
        start        = 1'b0;

        @(posedge uut.keygen_ready);
        #1;
        $display("--------------------------------------------------");
        $display("[KHOI SINH KHOA AN TOAN]");
        $display(" -> So nguyen to p: 0x%h", uut.p_val);
        $display(" -> So nguyen to q: 0x%h", uut.q_val);
        $display(" -> Modulus N     : 0x%h", uut.N_reg);
        $display(" -> Phi N         : 0x%h", uut.phi_reg);
        $display(" -> Khoa cong khai e: %d", 1024'd65537);
        $display(" -> Khoa rieng tu d : 0x%h", uut.d_reg);
        $display(" -> Hang so R^2   : 0x%h", uut.r2_reg);
        $display("--------------------------------------------------");

        @(posedge uut.u_padding_wrapper.ready);
        @(posedge clk); 
        if (mode == 1'b0) begin
            #1;
            $display("[GIAI DOAN MA HOA - TIEN XU LY]");
            $display(" -> Du lieu thong diep goc: 0x%h", uut.u_padding_wrapper.message_in_936);
            $display(" -> Ket qua chen bit PKCS v1.5 (1024-bit): 0x%h", uut.pad_out_reg);
        end

        // Doi toan bo chu trinh ma hoa xong han
        @(posedge done);
        #10;
        tb_ciphertext = ciphertext_out;
        
        $display("[KET QUA CUOI CUNG CUA MA HOA]");
        $display(" -> Thoi diem bat dau ma hoa    : %0f ns", t_enc_start);
        $display(" -> Thoi diem hoan thanh ma hoa : %0f ns", $realtime);
        $display(" -> Tong thoi gian tinh ma hoa  : %0f ns (tuong duong %0d chu ky)", ($realtime - t_enc_start), ($realtime - t_enc_start)/20);
        $display(" -> Ciphertext_out (Ban ma 1024-bit): 0x%h", tb_ciphertext);
        $display("--------------------------------------------------");
        
        #200; 

        $display("[MO PHONG] Bat dau giai doan 2: Giai ma (Mode = 1)...");
        
        t_dec_start   = $realtime; // Ghi lai thoi diem bat dau phat xung start giai ma
        ciphertext_in = tb_ciphertext; 
        mode          = 1'b1;
        start         = 1'b1;
        #20;
        start         = 1'b0;

        @(posedge uut.modexp_done);
        if (mode == 1'b1) begin
            #1;
            $display("[GIAI DOAN GIAI MA - TOAN HOC]");
            $display(" -> Ban ma can giai ma nap vao: 0x%h", uut.modexp_base);
            $display(" -> Dau ra khoi luy thua ModExp (Chua unpad): 0x%h", uut.modexp_result);
        end

        // Doi den khi unpad han va thong bao ket qua cuoi
        @(posedge done);
        #10;
        
        $display("[GIAI DOAN GIAI MA - HAU XU LY]");
        $display(" -> Thoi diem bat dau giai ma   : %0f ns", t_dec_start);
        $display(" -> Thoi diem hoan thanh giai ma: %0f ns", $realtime);
        $display(" -> Tong thoi gian tinh giai ma : %0f ns (tuong duong %0d chu ky)", ($realtime - t_dec_start), ($realtime - t_dec_start)/20);
        if (error == 1'b0) begin
            $display(" -> Trang thai: Khoi phuc thanh cong, khong co loi padding.");
            $display(" -> Ket qua sau khi unpad (Thong diep goc): %d (Hex: 0x%h)", plaintext_out, plaintext_out);
        end else begin
            $display(" -> Trang thai: That bai, dinh dang chuoi padding sai quy cach.");
        end
        $display("--------------------------------------------------");

        if (plaintext_out == tb_plaintext && error == 1'b0) begin
            $display("[DANH GIA CHUNG] KET LUAN: CHU TRINH CHAY DUNG TUYET DOI!");
        end else begin
            $display("[DANH GIA CHUNG] KET LUAN: CHU TRINH CHAY CO LOI SAI.");
        end

        #100;
        $finish;
    end

endmodule