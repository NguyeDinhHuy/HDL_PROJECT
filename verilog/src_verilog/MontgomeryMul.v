module MontgomeryMul(
    input  wire          clk,
    input  wire          rst_n,    // Reset tích cực mức thấp (active low)
    input  wire          start,    // Tín hiệu bắt đầu tính toán (xung 1 chu kỳ)
    input  wire [1023:0] a,        // Toán hạng A
    input  wire [1023:0] b,        // Toán hạng B
    input  wire [1023:0] m,        // Module M
    output reg  [1023:0] result,   // Kết quả: (A * B * R^-1) mod M
    output reg           done      // Cờ báo hoàn thành (xung 1 chu kỳ)
);

    // --- Khai báo trạng thái (FSM) ---
    localparam STATE_IDLE = 2'b00;
    localparam STATE_CALC = 2'b01;
    localparam STATE_NORM = 2'b10;
    localparam STATE_DONE = 2'b11;

    reg [1:0] state;

    // --- Khai báo thanh ghi (Registers) ---
    reg [1025:0] S;       // Thanh ghi tích lũy (cần dư 2 bit để tránh tràn khi cộng S+B+M)
    reg [1023:0] A_reg;
    reg [1023:0] B_reg;
    reg [1023:0] M_reg;
    reg [10:0]   count;   // Bộ đếm 11-bit (để đếm từ 0 đến 1024)

    // --- Khối tổ hợp (Combinational Logic) ---
    wire a_i;
    wire q_i;
    wire [1025:0] add_B;
    wire [1025:0] add_M;
    wire [1025:0] next_S;

    // Lấy bit thấp nhất của A hiện tại
    assign a_i = A_reg[0];

    // Xác định q_i = (S[0] + a_i * B[0]) mod 2
    // Phép cộng mod 2 trong nhị phân chính là phép XOR (^)
    assign q_i = S[0] ^ (a_i & B_reg[0]);

    // Chọn giá trị để cộng (Tạo Multiplexer trên phần cứng)
    assign add_B = a_i ? {2'b00, B_reg} : 1026'd0;
    assign add_M = q_i ? {2'b00, M_reg} : 1026'd0;

    // Công thức Montgomery: S_next = (S + a_i*B + q_i*M) / 2
    // Phép chia 2 được thực hiện bằng cách dịch logic phải (>> 1)
    assign next_S = (S + add_B + add_M) >> 1;

    // --- Khối tuần tự (Sequential Logic) ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= STATE_IDLE;
            S       <= 1026'd0;
            A_reg   <= 1024'd0;
            B_reg   <= 1024'd0;
            M_reg   <= 1024'd0;
            count   <= 11'd0;
            result  <= 1024'd0;
            done    <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        // Lấy mẫu (sample) đầu vào để tránh dữ liệu bị đổi giữa chừng
                        A_reg <= a;
                        B_reg <= b;
                        M_reg <= m;
                        S     <= 1026'd0; // Khởi tạo tổng S = 0
                        count <= 11'd0;
                        state <= STATE_CALC;
                    end
                end

                STATE_CALC: begin
                    // Lặp 1024 lần (tương ứng với 1024 bit)
                    if (count < 11'd1024) begin
                        S     <= next_S;       // Cập nhật S
                        A_reg <= A_reg >> 1;   // Dịch phải A để xét bit tiếp theo
                        count <= count + 1'b1; // Tăng biến đếm
                    end else begin
                        state <= STATE_NORM;   // Chuyển sang bước chuẩn hóa
                    end
                end

                STATE_NORM: begin
                    // Thuật toán Montgomery yêu cầu: nếu S >= M thì S = S - M
                    if (S >= {2'b00, M_reg}) begin
                        result <= S[1023:0] - M_reg;
                    end else begin
                        result <= S[1023:0];
                    end
                    state <= STATE_DONE;
                end

                STATE_DONE: begin
                    done  <= 1'b1;       // Phát xung Done báo hiệu hoàn thành
                    state <= STATE_IDLE; // Quay về chờ lệnh start mới
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule