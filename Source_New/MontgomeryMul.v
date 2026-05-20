`timescale 1ns / 1ps

module MontgomeryMul(
    input  wire          clk,       // Clock he thong dong bo
    input  wire          rst_n,     // Reset tich cuc muc thap
    input  wire          start,     // Xung kich hoat bat dau tinh (1 chu ky clock)
    input  wire [1023:0] a,         // Thua so a (1024-bit)
    input  wire [1023:0] b,         // Thua so b (1024-bit)
    input  wire [1023:0] m,         // Modulus m (1024-bit)
    
    output reg  [1023:0] result,    // Ket qua tinh toan Montgomery (1024-bit)
    output reg           done       // Co bao hieu da nhan xong va ket qua san sang
);

    localparam STATE_IDLE  = 2'b00;
    localparam STATE_LOOP  = 2'b01;
    localparam STATE_FINAL = 2'b10;

    reg [1:0]    state;
    reg [10:0]   count;     // Bo dem vong lap tu 0 den 1023 (du 1024 bit)
    reg [1025:0] S;         // Thanh ghi tich luy noi bo (rong 1026-bit de chong tran)
    reg [1023:0] A_reg;     // Thanh ghi dich phai luu giu gia tri a
    reg [1023:0] B_reg;     // Thanh ghi giu nguyen gia tri b
    reg [1023:0] M_reg;     // Thanh ghi giu nguyen gia tri m

    // Logic xac dinh he so quy doi q_i tai moi chu ky clock
    // Cong thuc: q_i = (S[0] + A_reg[0]*B_reg[0]) mod 2
    wire q = S[0] ^ (A_reg[0] & B_reg[0]);
    
    // Phep cong song song 1024-bit tren toan vao va dich phai 1 bit noi bo (/2)
    // Quartus se tu dong map lenh cong nay vao cac khoi Carry Chain phan cung cuc nhanh
    wire [1025:0] next_S = (S + (A_reg[0] ? B_reg : 1024'd0) + (q ? M_reg : 1024'd0)) >> 1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= STATE_IDLE;
            S         <= 1026'd0;
            A_reg     <= 1024'd0;
            B_reg     <= 1024'd0;
            M_reg     <= 1024'd0;
            count     <= 11'd0;
            result    <= 1024'd0;
            done      <= 1'b0;
        end else begin
            case (state)
                
                STATE_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        A_reg <= a;
                        B_reg <= b;
                        M_reg <= m;
                        S     <= 1026'd0; // Xoa thanh ghi tich luy cu
                        count <= 11'd0;   // Reset bo dem vong lap
                        state <= STATE_LOOP;
                    end
                end

                STATE_LOOP: begin
                    S     <= next_S;       // Cap nhat S bang ket qua cong va dich cua chu ky nay
                    A_reg <= A_reg >> 1;   // Dich phai A de xet bit tiep theo o chu ky sau
                    count <= count + 1'b1; // Tang bo dem chu ky len 1
                    
                    // Kiem tra neu da quet qua du 1024 bit cua rsa_core
                    if (count == 11'd1023) begin
                        state <= STATE_FINAL;
                    end
                end

                STATE_FINAL: begin
                    // Buoc chuan hoa cuoi cung theo thuat toan Montgomery: Neu S >= M thi tru bot M
                    if (S >= M_reg) begin
                        result <= S - M_reg;
                    end else begin
                        result <= S[1023:0];
                    end
                    done  <= 1'b1;         // Bat co bao xong dung 1 chu ky clock
                    state <= STATE_IDLE;   // Quay tro ve trang thai cho
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule