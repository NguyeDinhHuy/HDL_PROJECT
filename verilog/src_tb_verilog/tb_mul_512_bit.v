`timescale 1ns / 1ps

module tb_mul_512_bit();

    // 1. Khai báo các tín hi?u k?t n?i v?i module
    reg clk;
    reg rst;
    reg start;
    reg  [511:0] a;
    reg  [511:0] b;
    
    wire [1023:0] result;
    wire done;

    // 2. Kh?i t?o module c?n test (Device Under Test - DUT)
    mul_512_bit uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(a),
        .b(b),
        .result(result),
        .done(done)
    );

    // 3. T?o xung nh?p (Clock) chu k? 10ns (T?n s? 100MHz)
    always #5 clk = ~clk;

    // 4. Task t? ??ng hóa quy trình ??y d? li?u và ch? k?t qu?
    task test_multiply;
        input [511:0] test_a;
        input [511:0] test_b;
        begin
            // ??ng b? v?i s??n âm c?a clock ?? d? li?u ?n ??nh khi s??n d??ng t?i
            @(negedge clk);
            a     = test_a;
            b     = test_b;
            start = 1'b1;
            
            @(negedge clk);
            start = 1'b0; // H? tín hi?u start xu?ng sau 1 chu k?
            
            // Ch? h? th?ng tính toán xong (ch? ??n khi c? done = 1)
            wait(done == 1'b1);
            
            // In k?t qu? ra màn hình Console (Transcript)
            $display("---------------------------------------------------");
            $display("Thoi gian: %0t ns", $time);
            $display("A        = %h", a);
            $display("B        = %h", b);
            $display("Ket qua  = %h", result);
            
            // Trình mô ph?ng (ModelSim/Vivado) có th? t? nhân s? l?n trong TB
            // Ta dùng nó ?? ??i chi?u xem logic ph?n c?ng ch?y ?úng không
            if (result == (test_a * test_b))
                $display("=> KET LUAN: PASS (Chinh xac!)");
            else
                $display("=> KET LUAN: FAIL! Ky vong: %h", (test_a * test_b));
                
            #50; // Ch? m?t chút tr??c khi ch?y ca test ti?p theo
        end
    endtask

    // 5. Quá trình ch?y mô ph?ng chính
    initial begin
        // Kh?i t?o giá tr? ban ??u
        clk   = 0;
        start = 0;
        a     = 0;
        b     = 0;
        
        // Reset h? th?ng
        rst = 0;
        #20;
        rst = 1; // B?t ??u ho?t ??ng
        #20;
        
        $display("=== BAT DAU MO PHONG BO NHAN 512-BIT RADIX-4 ===");

        // Test Case 1: Phép nhân c? b?n các s? nh?
        // 15 * 10 = 150
        test_multiply(512'd15, 512'd10);
        
        // Test Case 2: M?t trong hai s? b?ng 0 (Zero case)
        test_multiply(512'd0, 512'd9999);
        
        // Test Case 3: Nhân v?i 1
        test_multiply(512'hFFFF_FFFF, 512'd1);

        // Test Case 4: Tràn 32-bit, chuy?n sang s? l?n h?n
        // 0xFFFFFFFF * 0x2 = 0x1FFFFFFFE
        test_multiply(512'hFFFF_FFFF, 512'h2);

        // Test Case 5: Phép nhân các s? 512-bit kh?ng l? (D?ng Hex)
        test_multiply(
            512'h1234567890ABCDEF1234567890ABCDEF, 
            512'hFEDCBA0987654321FEDCBA0987654321
        );

        $display("---------------------------------------------------");
        $display("=== KET THUC MO PHONG ===");
        
        // D?ng mô ph?ng
        $finish;
    end

endmodule