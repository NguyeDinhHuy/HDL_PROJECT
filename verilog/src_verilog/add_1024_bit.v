module add_1024_bit(
    input  wire clk,
    input  wire rst,
    input  wire start,             // Tín hiệu bắt đầu tính toán
    input  wire [1023:0] a,
    input  wire [1023:0] b,
    output reg  [1024:0] result,
    output reg  done               // Tín hiệu báo đã cộng xong
);

    reg [1023:0] reg_a;
    reg [1023:0] reg_b;
    reg [5:0]    count;            // Đếm từ 0 đến 31 
    reg          carry;
    

    wire [32:0] sum_32 = reg_a[31:0] + reg_b[31:0] + carry;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            result <= 1025'b0;
            done   <= 1'b0;
            carry  <= 1'b0;
            count  <= 6'd0;
            reg_a  <= 1024'b0;
            reg_b  <= 1024'b0;
        end 
        else begin
            if (start) begin
                // Khởi tạo giá trị khi có lệnh start
                reg_a  <= a;
                reg_b  <= b;
                carry  <= 1'b0;
                count  <= 6'd0;
                done   <= 1'b0;
                result <= 1025'b0;
            end 
            else if (!done && count < 6'd32) begin
                // Lưu kết quả 32-bit vào đúng vị trí tương ứng
                result[count * 32 +: 32] <= sum_32[31:0];
                
                // bit 33 = carry
                carry <= sum_32[32];
                
                // Dich 32 bit lay phan tiêp theo
                reg_a <= reg_a >> 32;
                reg_b <= reg_b >> 32;
                
                count <= count + 1'b1;
            end 
            else if (count == 6'd32) begin
                // Lưu bit carry cuối cùng vào bit thứ 1024
                result[1024] <= carry;
                done <= 1'b1;
            end
        end
    end

endmodule