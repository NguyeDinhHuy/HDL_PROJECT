module MontgomeryMul(
    input  wire          clk,
    input  wire          rst_n,    // Reset tích c?c m?c th?p (active low)
    input  wire          start,    // Tín hi?u b?t ??u tính toán (xung 1 chu k?)
    input  wire [1023:0] a,        // Toán h?ng A
    input  wire [1023:0] b,        // Toán h?ng B
    input  wire [1023:0] m,        // Module M
    output reg  [1023:0] result,   // K?t qu?: (A * B * R^-1) mod M
    output reg           done      // C? báo hoàn thành (xung 1 chu k?)
);

    // --- Khai báo tr?ng thái (FSM) ---
    localparam STATE_IDLE = 2'b00;
    localparam STATE_CALC = 2'b01;
    localparam STATE_NORM = 2'b10;
    localparam STATE_DONE = 2'b11;

    reg [1:0] state;

    // --- Khai báo thanh ghi (Registers) ---
    reg [1025:0] S;       // Thanh ghi tích l?y (c?n d? 2 bit ?? tránh tràn khi c?ng S+B+M)
    reg [1023:0] A_reg;
    reg [1023:0] B_reg;
    reg [1023:0] M_reg;
    reg [10:0]   count;   // B? ??m 11-bit (?? ??m t? 0 ??n 1024)

    // --- Kh?i t? h?p (Combinational Logic) ---
    wire a_i;
    wire q_i;
    wire [1025:0] add_B;
    wire [1025:0] add_M;
    wire [1025:0] next_S;

    // L?y bit th?p nh?t c?a A hi?n t?i
    assign a_i = A_reg[0];

    // Xác ??nh q_i = (S[0] + a_i * B[0]) mod 2
    // Phép c?ng mod 2 trong nh? phân chính là phép XOR (^)
    assign q_i = S[0] ^ (a_i & B_reg[0]);

    // Ch?n giá tr? ?? c?ng (T?o Multiplexer trên ph?n c?ng)
    assign add_B = a_i ? {2'b00, B_reg} : 1026'd0;
    assign add_M = q_i ? {2'b00, M_reg} : 1026'd0;

    // Công th?c Montgomery: S_next = (S + a_i*B + q_i*M) / 2
    // Phép chia 2 ???c th?c hi?n b?ng cách d?ch logic ph?i (>> 1)
    assign next_S = (S + add_B + add_M) >> 1;

    // --- Kh?i tu?n t? (Sequential Logic) ---
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
                        // L?y m?u (sample) ??u vào ?? tránh d? li?u b? ??i gi?a ch?ng
                        A_reg <= a;
                        B_reg <= b;
                        M_reg <= m;
                        S     <= 1026'd0; // Kh?i t?o t?ng S = 0
                        count <= 11'd0;
                        state <= STATE_CALC;
                    end
                end

                STATE_CALC: begin
                    // L?p 1024 l?n (t??ng ?ng v?i 1024 bit)
                    if (count < 11'd1024) begin
                        S     <= next_S;       // C?p nh?t S
                        A_reg <= A_reg >> 1;   // D?ch ph?i A ?? xét bit ti?p theo
                        count <= count + 1'b1; // T?ng bi?n ??m
                    end else begin
                        state <= STATE_NORM;   // Chuy?n sang b??c chu?n hóa
                    end
                end

                STATE_NORM: begin
                    // Thu?t toán Montgomery yêu c?u: n?u S >= M thì S = S - M
                    if (S >= {2'b00, M_reg}) begin
                        result <= S[1023:0] - M_reg;
                    end else begin
                        result <= S[1023:0];
                    end
                    state <= STATE_DONE;
                end

                STATE_DONE: begin
                    done  <= 1'b1;       // Phát xung Done báo hi?u hoàn thành
                    state <= STATE_IDLE; // Quay v? ch? l?nh start m?i
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule