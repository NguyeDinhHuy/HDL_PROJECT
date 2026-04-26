`timescale 1ns / 1ps

module tb_add_1024bit();

    // 1. Khai báo các tín hiệu kết nối với mạch
    reg clk;
    reg rst;
    reg start;
    reg  [1023:0] a;
    reg  [1023:0] b;
    
    wire [1024:0] result;
    wire done;

    add_1024_bit  test (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(a),
        .b(b),
        .result(result),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        // Khởi tạo trạng thái ban đầu
        clk = 0;
        rst = 0;
        start = 0;
        a = 1024'd0;
        b = 1024'd0;

        $display("=== BAT DAU MO PHONG ===");

        // Reset hệ thống để dọn dẹp các thanh ghi
        rst = 0;
        #20; // Giữ reset trong 2 chu kỳ clock
        rst = 1;
        #10;

        // ----------------------------------------------------
        // TEST CASE 1: Cộng hai số nhỏ bình thường
        // ----------------------------------------------------
        a = 1024'd150;
        b = 1024'd250;
        start = 1;      // Kích hoạt lệnh bắt đầu cộng
        #10;
        start = 0;      // Kéo start xuống (chỉ cần tạo 1 xung)

        $display("Dang tinh toan Test 1...");
        
        // Chờ cho đến khi mạch báo done
        wait(done == 1'b1);
        #10; // Đợi thêm 1 nhịp clock cho tín hiệu ổn định trên Waveform
        
        if (result == 1025'd400)
            $display("[PASS] Test 1: 150 + 250 = %d", result);
        else
            $display("[FAIL] Test 1: Ket qua sai, result = %d", result);

        #50; // Nghỉ một chút trước khi chạy test tiếp theo

        // ----------------------------------------------------
        // TEST CASE 2: Kiểm tra tràn số (Carry Out) ở bit 1024
        // ----------------------------------------------------
        // Đặt a = Tất cả 1024 bit đều là 1 (Giá trị Max)
        a = {1024{1'b1}}; 
        // Đặt b = 1
        b = 1024'd1; 
        // Khi cộng lại, kết quả sẽ tràn 1 bit lên vị trí 1024, các bit còn lại bằng 0
        
        start = 1;
        #10;
        start = 0;

        $display("Dang tinh toan Test 2...");

        wait(done == 1'b1);
        #10;

        // Kiểm tra xem bit 1024 có bật lên 1 không và 1024 bit thấp có về 0 hết không
        if (result[1024] == 1'b1 && result[1023:0] == 1024'd0)
            $display("[PASS] Test 2: Xu ly Carry Out thanh cong!");
        else
            $display("[FAIL] Test 2: Xu ly Carry Out bi loi!");

        // Kết thúc mô phỏng
        #50;
        $display("=== KET THUC MO PHONG ===");
        $finish;
    end

endmodule