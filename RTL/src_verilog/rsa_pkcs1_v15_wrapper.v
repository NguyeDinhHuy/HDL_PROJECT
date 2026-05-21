`timescale 1ns / 1ps

module rsa_pkcs1_v15_wrapper (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          start,           // Xung kich hoat tien trinh (1 chu ky clock)
    input  wire          mode,            // 0: Chieu Padding (Ma hoa), 1: Chieu Unpadding (Giai ma)
    
    // Giao tiep phia thong diep goc (Toi da 936 bit = 117 byte de chua phan dem)
    input  wire [935:0]  message_in_936,  // Thong diep goc nap vao de ma hoa
    output reg  [935:0]  message_out_936, // Thong diep goc thu lai sau khi giai ma
    
    // Giao tiep phia khoi ModExp / RSA_top (1024 bit)
    output reg  [1023:0] padded_msg_1024, // Noi vao duong message_in cua khoi ModExp
    input  wire [1023:0] decrypted_msg_1024,// Don du lieu message_out tu khoi ModExp ve
    
    output reg           ready,           // Co bao hieu da hoan thanh xu ly chuoi
    output reg           padding_error    // Co bao loi neu ban giai ma co dinh dang padding sai
);

    localparam STATE_IDLE = 2'b00;
    localparam STATE_EXEC = 2'b01;
    localparam STATE_DONE = 2'b10;

    reg [1:0]  state;
    reg [63:0] lfsr; // Su dung LFSR 64-bit de tao nhanh 8 byte ngau nhien cung mot luc

    // Cong thuc phan hoi logic cho LFSR 64-bit (Polynomial: x^64 + x^63 + x^61 + x^60 + 1)
    wire lfsr_tap = lfsr[63] ^ lfsr[62] ^ lfsr[60] ^ lfsr[59];
    wire [63:0] next_lfsr = {lfsr[62:0], lfsr_tap};

    // Loc bo cac byte co gia tri 0x00 va thay bang 0x01 de dung quy dinh cua chuan PKCS v1.5
    wire [7:0] rand7 = (lfsr[63:56] == 8'h00) ? 8'h01 : lfsr[63:56];
    wire [7:0] rand6 = (lfsr[55:48] == 8'h00) ? 8'h01 : lfsr[55:48];
    wire [7:0] rand5 = (lfsr[47:40] == 8'h00) ? 8'h01 : lfsr[47:40];
    wire [7:0] rand4 = (lfsr[39:32] == 8'h00) ? 8'h01 : lfsr[39:32];
    wire [7:0] rand3 = (lfsr[31:24] == 8'h00) ? 8'h01 : lfsr[31:24];
    wire [7:0] rand2 = (lfsr[23:16] == 8'h00) ? 8'h01 : lfsr[23:16];
    wire [7:0] rand1 = (lfsr[15:8]  == 8'h00) ? 8'h01 : lfsr[15:8];
    wire [7:0] rand0 = (lfsr[7:0]   == 8'h00) ? 8'h01 : lfsr[7:0];

    // Gop thanh khoi mang 64-bit ngau nhien an toan (Padding String)
    wire [63:0] rand_block = {rand7, rand6, rand5, rand4, rand3, rand2, rand1, rand0};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= STATE_IDLE;
            lfsr            <= 64'hA1B2C3D4E5F6A7B8; // Nap gia tri seed nen ban dau cho LFSR
            padded_msg_1024 <= 1024'd0;
            message_out_936 <= 936'd0;
            ready           <= 1'b0;
            padding_error   <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    ready         <= 1'b0;
                    padding_error <= 1'b0;
                    if (start) begin
                        lfsr  <= next_lfsr; // Cap nhat trang thai LFSR moi de lay s? ngau nhien
                        state <= STATE_EXEC;
                    end
                end

                STATE_EXEC: begin
                    if (mode == 1'b0) begin
                        // CHIEU PADDING (MA HOA): Ghep khoi 1024 bit bat buoc tu chuoi 936 bit dau vao
                        // Cau truc: 0x00 (1 byte) + 0x02 (1 byte) + Ngau nhien (8 byte) + 0x00 (1 byte) + Data (117 byte)
                        padded_msg_1024 <= {8'h00, 8'h02, rand_block, 8'h00, message_in_936};
                        padding_error   <= 1'b0;
                    end else begin
                        // CHIEU UNPADDING (GIAI MA): Kiem tra tinh hop le cua cac vi tri byte danh dau co dinh
                        if (decrypted_msg_1024[1023:1016] == 8'h00 &&
                            decrypted_msg_1024[1015:1008] == 8'h02 &&
                            decrypted_msg_1024[943:936]   == 8'h00) begin
                            
                            message_out_936 <= decrypted_msg_1024[935:0]; // Cat lay dung 936 bit thong diep goc ban dau
                            padding_error   <= 1'b0;
                        end else begin
                            message_out_936 <= 936'd0;
                            padding_error   <= 1'b1; // Bat co loi neu khoi giai ma bi sai cau truc PKCS v1.5
                        end
                    end
                    state <= STATE_DONE;
                end

                STATE_DONE: begin
                    ready <= 1'b1; // Bao hieu cho khoi dieu khien ben ngoai don nhan ket qua
                    state <= STATE_IDLE;
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule