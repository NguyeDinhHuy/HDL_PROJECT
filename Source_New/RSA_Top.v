`timescale 1ns / 1ps
// =================================================================
// Module RSA Top-Level qu?n lý toàn b? h? th?ng mã hóa/gi?i mã RSA
// =================================================================

module RSA_Top (
    input  wire          clk,          // Clock h? th?ng
    input  wire          rst_n,        // Reset tích c?c m?c th?p
    input  wire          start,        // Tín hi?u b?t ??u toàn quy trình
    input  wire          mode,         // L?a ch?n ch? ?? (0: Mã hóa v?i e=65537, 1: Gi?i mã v?i d)
    input  wire [6:0]    prime_addr,   // ??A CH? G?C CH?N P (Tách bi?t hoàn toàn kh?i message_in)
    input  wire [1023:0] message_in,   // Thông ?i?p g?c ??u vào (Plaintext / Ciphertext)
    
    output reg  [1023:0] message_out,  // K?t qu? ??u ra sau khi x? lý
    output reg           done,         // C? báo toàn h? th?ng hoàn thành
    output reg           error         // C? báo l?i khi phi(N) không h?p l?
);

    // --- ??nh ngh?a các tr?ng thái FSM ---
    localparam STATE_IDLE       = 4'd0,
               STATE_READ_P     = 4'd1,
               STATE_READ_Q     = 4'd2,
               STATE_START_N    = 4'd3,
               STATE_WAIT_N     = 4'd4,
               STATE_START_PHI  = 4'd5,
               STATE_WAIT_PHI   = 4'd6,
               STATE_START_KEYS = 4'd7,
               STATE_WAIT_KEYS  = 4'd10,
               STATE_START_EXP  = 4'd11,
               STATE_WAIT_EXP   = 4'd12,
               STATE_DONE       = 4'd13;

    reg [3:0] current_state;

    // --- Khai báo các thanh ghi l?u tr? giá tr? n?i b? ---
    reg [511:0]  p_val, q_val;
    reg [1023:0] N_reg;
    reg [1023:0] phi_reg;
    reg [1023:0] d_reg;
    reg [1023:0] r2_reg;
    
    reg          r2_ready, keygen_ready;

    // --- Logic tính toán ??a ch? p và q d?a vào c?ng vào ??c l?p `prime_addr` ---
    wire [6:0] addr_p = prime_addr; 
    // ??a ch? q = p + 1. N?u v??t quá 12 (theo yêu c?u), gán b?ng 0
    wire [6:0] addr_q = (addr_p >= 7'd12) ? 7'd0 : (addr_p + 7'd1); 

    // --- K?t n?i tín hi?u v?i Module RAM ---
    reg  [6:0]   ram_addr;
    wire [511:0] ram_data_out;

    prime_ram_512 u_prime_ram (
        .clk(clk),
        .we(1'b0), // Luôn ? ch? ?? ??c c? ??nh
        .addr(ram_addr),
        .data_in(512'd0),
        .data_out(ram_data_out)
    );

    // --- K?t n?i tín hi?u v?i Module Multiplier (Dùng chung cho N và Phi N) ---
    reg          mult_start;
    reg  [511:0] mult_p, mult_q;
    wire [1023:0] mult_n;
    wire          mult_done;

    rsa_512x512_multiplier u_multiplier (
        .clk(clk),
        .rst_n(rst_n),
        .start(mult_start),
        .p(mult_p),
        .q(mult_q),
        .n(mult_n),
        .done(mult_done)
    );

    // --- K?t n?i tín hi?u v?i Module Fast_R2_Mod_N ---
    reg          r2_start;
    wire [1023:0] r2_mod_n;
    wire          r2_done;

    Fast_R2_Mod_N u_fast_r2 (
        .clk(clk),
        .rst_n(rst_n),
        .start(r2_start),
        .n(N_reg),
        .r2_mod_n(r2_mod_n),
        .done(r2_done)
    );

    // --- K?t n?i tín hi?u v?i Module rsa_key_d_generator ---
    reg          keygen_start;
    wire [1023:0] private_d;
    wire          keygen_done;
    wire          phi_invalid;

    rsa_key_d_generator u_key_d_gen (
        .clk(clk),
        .rst_n(rst_n),
        .start(keygen_start),
        .phi(phi_reg),
        .private_d(private_d),
        .done(keygen_done),
        .phi_invalid(phi_invalid)
    );

    // --- K?t n?i tín hi?u v?i Module ModExp (Mã hóa / Gi?i mã) ---
    reg          modexp_start;
    reg  [1023:0] modexp_base;
    reg  [1023:0] modexp_exp;
    wire [1023:0] modexp_result;
    wire          modexp_done;

    ModExp u_mod_exp (
        .clk(clk),
        .rst_n(rst_n),
        .start(modexp_start),
        .base_in(modexp_base),
        .exp_in(modexp_exp),
        .mod_in(N_reg),
        .r2_mod_n(r2_reg),
        .result(modexp_result),
        .done(modexp_done)
    );

    // --- Máy tr?ng thái ?i?u khi?n tu?n t? h? th?ng (FSM Logic) ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_IDLE;
            p_val         <= 512'd0;
            q_val         <= 512'd0;
            N_reg         <= 1024'd0;
            phi_reg       <= 1024'd0;
            d_reg         <= 1024'd0;
            r2_reg        <= 1024'd0;
            mult_start    <= 1'b0;
            mult_p        <= 512'd0;
            mult_q        <= 512'd0;
            r2_start      <= 1'b0;
            keygen_start  <= 1'b0;
            modexp_start  <= 1'b0;
            modexp_base   <= 1024'd0;
            modexp_exp    <= 1024'd0;
            r2_ready      <= 1'b0;
            keygen_ready  <= 1'b0;
            message_out   <= 1024'd0;
            ram_addr      <= 7'd0;
            done          <= 1'b0;
            error         <= 1'b0;
        end else begin
            case (current_state)
                
                STATE_IDLE: begin
                    done  <= 1'b0;
                    error <= 1'b0;
                    if (start) begin
                        ram_addr      <= addr_p; // ??t ??a ch? ??c p t? logic ??c l?p
                        current_state <= STATE_READ_P;
                    end
                end

                STATE_READ_P: begin
                    p_val         <= ram_data_out; // ??c d? li?u p t? RAM sau 1 chu k? clock
                    ram_addr      <= addr_q;       // ??t ??a ch? ??c q
                    current_state <= STATE_READ_Q;
                end

                STATE_READ_Q: begin
                    q_val         <= ram_data_out; // ??c d? li?u q t? RAM
                    current_state <= STATE_START_N;
                end

                STATE_START_N: begin
                    mult_p        <= p_val;
                    mult_q        <= q_val;
                    mult_start    <= 1'b1;         // Kích ho?t b? nhân tính N = p * q
                    current_state <= STATE_WAIT_N;
                end

                STATE_WAIT_N: begin
                    mult_start <= 1'b0;
                    if (mult_done) begin
                        N_reg         <= mult_n;   // L?u k?t qu? N
                        current_state <= STATE_START_PHI;
                    end
                end

                STATE_START_PHI: begin
                    mult_p        <= p_val - 512'd1;
                    mult_q        <= q_val - 512'd1;
                    mult_start    <= 1'b1;         // Kích ho?t tính Phi(N) = (p-1) * (q-1)
                    current_state <= STATE_WAIT_PHI;
                end

                STATE_WAIT_PHI: begin
                    mult_start <= 1'b0;
                    if (mult_done) begin
                        phi_reg       <= mult_n;   // L?u k?t qu? Phi(N)
                        current_state <= STATE_START_KEYS;
                    end
                end

                STATE_START_KEYS: begin
                    r2_start     <= 1'b1;          // Kích ho?t kh?i tính R^2 mod N
                    keygen_start <= 1'b1;          // Kích ho?t kh?i tìm khóa private d
                    r2_ready     <= 1'b0;
                    keygen_ready <= 1'b0;
                    current_state <= STATE_WAIT_KEYS;
                end

                STATE_WAIT_KEYS: begin
                    r2_start     <= 1'b0;
                    keygen_start <= 1'b0;
                    
                    if (r2_done) begin
                        r2_reg   <= r2_mod_n;
                        r2_ready <= 1'b1;
                    end
                    
                    if (keygen_done) begin
                        d_reg        <= private_d;
                        keygen_ready <= 1'b1;
                        if (phi_invalid) begin
                            error <= 1'b1;         // Báo l?i n?u h? th?ng sinh khóa th?t b?i
                        end
                    end

                    // ??i c? hai b? tính toán khóa song song hoàn thành
                    if ((r2_ready || r2_done) && (keygen_ready || keygen_done)) begin
                        if (error || (phi_invalid && keygen_done))
                            current_state <= STATE_DONE;
                        else
                            current_state <= STATE_START_EXP;
                    end
                end

                STATE_START_EXP: begin
                    modexp_base <= message_in;
                    if (mode == 1'b0) begin
                        modexp_exp <= 1024'd65537; // Ch? ?? mã hóa (S? d?ng khóa công khai e)
                    end else begin
                        modexp_exp <= d_reg;       // Ch? ?? gi?i mã (S? d?ng khóa riêng t? d)
                    end
                    modexp_start  <= 1'b1;
                    current_state <= STATE_WAIT_EXP;
                end

                STATE_WAIT_EXP: begin
                    modexp_start <= 1'b0;
                    if (modexp_done) begin
                        message_out   <= modexp_result; // Xu?t k?t qu? sau tính toán
                        current_state <= STATE_DONE;
                    end
                end

                STATE_DONE: begin
                    done          <= 1'b1;
                    current_state <= STATE_IDLE;
                end

                default: current_state <= STATE_IDLE;
            endcase
        end
    end

endmodule