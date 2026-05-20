`timescale 1ns / 1ps

module RSA_Top (
    input  wire          clk,          // Clock he thong
    input  wire          rst_n,        // Reset tich cuc muc thap
    input  wire          start,        // Tin hieu bat dau toan quy trinh
    input  wire          mode,         // Luyen chon che do (0: Ma hoa, 1: Giai ma)
    input  wire [6:0]    prime_addr,   // Dia chi goc chon so nguyen to trong RAM
    
    // Phan tac cac cong giao tiep theo dung do rong chuan PKCS #1 v1.5
    input  wire [935:0]  plaintext_in, // Ban ro nap vao de ma hoa (Dung khi mode = 0)
    input  wire [1023:0] ciphertext_in,// Ban ma nap vao de giai ma (Dung khi mode = 1)
    output reg  [1023:0] ciphertext_out,// Ban ma xuat ra sau ma hoa (Co khi mode = 0)
    output reg  [935:0]  plaintext_out,// Ban ro khoi phuc sau giai ma (Co khi mode = 1)
    
    output reg           done,         // Co bao toan he thong hoan thanh chu ky
    output reg           error         // Co bao loi (Bao gom loi sinh khoa va loi chuoi padding)
);

    // --- Dinh nghia cac trang thai FSM mo rong de quan ly Wrapper ---
    localparam STATE_IDLE        = 5'd0,
               STATE_WAIT_P_RAM  = 5'd1,
               STATE_READ_P      = 5'd2,
               STATE_WAIT_Q_RAM  = 5'd3,
               STATE_READ_Q      = 5'd4,
               STATE_START_N     = 5'd5,
               STATE_WAIT_N      = 5'd6,
               STATE_DEC_P       = 5'd7,
               STATE_DEC_Q       = 5'd8,
               STATE_START_PHI   = 5'd9,
               STATE_WAIT_PHI    = 5'd10,
               STATE_START_KEYS  = 5'd11,
               STATE_WAIT_KEYS   = 5'd12,
               STATE_START_PAD   = 5'd13, // Trang thai kich hoat chen dem padding
               STATE_WAIT_PAD    = 5'd14, // Trang thai doi chen dem padding xong
               STATE_START_EXP   = 5'd15,
               STATE_WAIT_EXP    = 5'd16,
               STATE_START_UNPAD = 5'd17, // Trang thai kich hoat boc go padding
               STATE_WAIT_UNPAD  = 5'd18, // Trang thai doi boc go padding xong
               STATE_DONE        = 5'd19;

    reg [4:0] current_state;

    // --- Thanh ghi luu tru tham so noi bo ---
    reg [511:0]  p_val, q_val;
    reg [511:0]  p_minus_one, q_minus_one;
    reg [1023:0] N_reg;
    reg [1023:0] phi_reg;
    reg [1023:0] d_reg;
    reg [1023:0] r2_reg;
    reg [1023:0] pad_out_reg;
    reg          r2_ready, keygen_ready;
    reg [4:0]    dec_word_idx;
    reg          dec_borrow;

    wire [31:0] dec_source_word = (current_state == STATE_DEC_Q) ?
                                  q_val[dec_word_idx * 32 +: 32] :
                                  p_val[dec_word_idx * 32 +: 32];
    wire [32:0] dec_sub_result  = {1'b0, dec_source_word} - {32'd0, dec_borrow};

    // --- Tinh toan dia chi tu prime_addr doc lap ---
    wire [6:0] addr_p = prime_addr; 
    wire [6:0] addr_q = (addr_p >= 7'd12) ? 7'd0 : (addr_p + 7'd1); 

    // --- Ket noi Module RAM ---
    reg  [6:0]   ram_addr;
    wire [511:0] ram_data_out;

    prime_ram_512 u_prime_ram (
        .clk(clk), .we(1'b0), .addr(ram_addr), .data_in(512'd0), .data_out(ram_data_out)
    );

    // --- Ket noi Module Multiplier ---
    reg          mult_start;
    reg  [511:0] mult_p, mult_q;
    wire [1023:0] mult_n;
    wire          mult_done;

    serial_multiplier #(
        .WIDTH(512),
        .CHUNK_WIDTH(32)
    ) u_multiplier (
        .clk(clk),
        .rst_n(rst_n),
        .start(mult_start),
        .multiplicand_in(mult_p),
        .multiplier_in(mult_q),
        .product_out(mult_n),
        .done(mult_done)
    );

    // --- Ket noi Module Fast_R2_Mod_N ---
    reg          r2_start;
    wire [1023:0] r2_mod_n;
    wire          r2_done;

    Fast_R2_Mod_N u_fast_r2 (
        .clk(clk), .rst_n(rst_n), .start(r2_start), .n(N_reg), .r2_mod_n(r2_mod_n), .done(r2_done)
    );

    // --- Ket noi Module rsa_key_d_generator ---
    reg          keygen_start;
    wire [1023:0] private_d;
    wire          keygen_done;
    wire          phi_invalid;

    rsa_key_d_generator u_key_d_gen (
        .clk(clk), .rst_n(rst_n), .start(keygen_start), .phi(phi_reg), .private_d(private_d), .done(keygen_done), .phi_invalid(phi_invalid)
    );

    // --- Ket noi Module ModExp ---
    reg          modexp_start;
    reg  [1023:0] modexp_base;
    reg  [1023:0] modexp_exp;
    wire [1023:0] modexp_result;
    wire          modexp_done;

    ModExp u_mod_exp (
        .clk(clk), .rst_n(rst_n), .start(modexp_start), .base_in(modexp_base), .exp_in(modexp_exp), .mod_in(N_reg), .r2_mod_n(r2_reg), .result(modexp_result), .done(modexp_done)
    );

    // --- TICH HOP: Goi Module rsa_pkcs1_v15_wrapper vao mang FSM ---
    reg           wrapper_start;
    wire          wrapper_ready;
    wire          wrapper_padding_error;
    wire [1023:0] wrapper_padded_msg;
    wire [935:0]  wrapper_plaintext_out;

    rsa_pkcs1_v15_wrapper u_padding_wrapper (
        .clk(clk),
        .rst_n(rst_n),
        .start(wrapper_start),
        .mode(mode),                        // Chay chung phuong thuc cau hinh voi FSM Top
        .message_in_936(plaintext_in),
        .message_out_936(wrapper_plaintext_out),
        .padded_msg_1024(wrapper_padded_msg),
        .decrypted_msg_1024(modexp_result), // Lay truc tiep ket qua giai ma tu khoi ModExp de quet
        .ready(wrapper_ready),
        .padding_error(wrapper_padding_error)
    );

    // --- May trang thai dieu khien lien ket toan he thong ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state   <= STATE_IDLE;
            p_val           <= 512'd0;
            q_val           <= 512'd0;
            p_minus_one     <= 512'd0;
            q_minus_one     <= 512'd0;
            N_reg           <= 1024'd0;
            phi_reg         <= 1024'd0;
            d_reg           <= 1024'd0;
            r2_reg          <= 1024'd0;
            pad_out_reg     <= 1024'd0;
            mult_start      <= 1'b0;
            mult_p          <= 512'd0;
            mult_q          <= 512'd0;
            r2_start        <= 1'b0;
            keygen_start    <= 1'b0;
            modexp_start    <= 1'b0;
            modexp_base     <= 1024'd0;
            modexp_exp      <= 1024'd0;
            r2_ready        <= 1'b0;
            keygen_ready    <= 1'b0;
            dec_word_idx    <= 5'd0;
            dec_borrow      <= 1'b0;
            wrapper_start   <= 1'b0;
            ciphertext_out  <= 1024'd0;
            plaintext_out   <= 936'd0;
            ram_addr        <= 7'd0;
            done            <= 1'b0;
            error           <= 1'b0;
        end else begin
            case (current_state)
                
                STATE_IDLE: begin
                    done  <= 1'b0;
                    error <= 1'b0;
                    if (start) begin
                        ram_addr      <= addr_p;
                        current_state <= STATE_WAIT_P_RAM;
                    end
                end

                STATE_WAIT_P_RAM: begin
                    current_state <= STATE_READ_P;
                end

                STATE_READ_P: begin
                    p_val         <= ram_data_out;
                    ram_addr      <= addr_q;
                    current_state <= STATE_WAIT_Q_RAM;
                end

                STATE_WAIT_Q_RAM: begin
                    current_state <= STATE_READ_Q;
                end

                STATE_READ_Q: begin
                    q_val         <= ram_data_out;
                    current_state <= STATE_START_N;
                end

                STATE_START_N: begin
                    mult_p        <= p_val;
                    mult_q        <= q_val;
                    mult_start    <= 1'b1;
                    current_state <= STATE_WAIT_N;
                end

                STATE_WAIT_N: begin
                    mult_start <= 1'b0;
                    if (mult_done) begin
                        N_reg         <= mult_n;
                        dec_word_idx  <= 5'd0;
                        dec_borrow    <= 1'b1;
                        current_state <= STATE_DEC_P;
                    end
                end

                STATE_DEC_P: begin
                    p_minus_one[dec_word_idx * 32 +: 32] <= dec_sub_result[31:0];
                    if (dec_word_idx == 5'd15) begin
                        dec_word_idx  <= 5'd0;
                        dec_borrow    <= 1'b1;
                        current_state <= STATE_DEC_Q;
                    end else begin
                        dec_word_idx  <= dec_word_idx + 5'd1;
                        dec_borrow    <= dec_sub_result[32];
                    end
                end

                STATE_DEC_Q: begin
                    q_minus_one[dec_word_idx * 32 +: 32] <= dec_sub_result[31:0];
                    if (dec_word_idx == 5'd15) begin
                        dec_word_idx  <= 5'd0;
                        dec_borrow    <= 1'b0;
                        current_state <= STATE_START_PHI;
                    end else begin
                        dec_word_idx  <= dec_word_idx + 5'd1;
                        dec_borrow    <= dec_sub_result[32];
                    end
                end

                STATE_START_PHI: begin
                    mult_p        <= p_minus_one;
                    mult_q        <= q_minus_one;
                    mult_start    <= 1'b1;
                    current_state <= STATE_WAIT_PHI;
                end

                STATE_WAIT_PHI: begin
                    mult_start <= 1'b0;
                    if (mult_done) begin
                        phi_reg       <= mult_n;
                        current_state <= STATE_START_KEYS;
                    end
                end

                STATE_START_KEYS: begin
                    r2_start     <= 1'b1;
                    keygen_start <= 1'b1;
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
                            error <= 1'b1;
                        end
                    end

                    if ((r2_ready || r2_done) && (keygen_ready || keygen_done)) begin
                        if (error || (phi_invalid && keygen_done))
                            current_state <= STATE_DONE;
                        else begin
                            // Neu la che do Ma hoa (mode=0), phai di qua khoi chen dem truoc
                            if (mode == 1'b0)
                                current_state <= STATE_START_PAD;
                            else
                                current_state <= STATE_START_EXP; // Giai ma thi vao thang luon
                        end
                    end
                end

                // --- TIEN XU LY: Kich hoat va doi Wrapper tron chuoi ngau nhien ---
                STATE_START_PAD: begin
                    wrapper_start <= 1'b1;
                    current_state <= STATE_WAIT_PAD;
                end

                STATE_WAIT_PAD: begin
                    wrapper_start <= 1'b0;
                    if (wrapper_ready) begin
                        pad_out_reg   <= wrapper_padded_msg; // Nhan khoi vector 1024-bit sach sau khi pad
                        current_state <= STATE_START_EXP;
                    end
                end

                STATE_START_EXP: begin
                    if (mode == 1'b0) begin
                        modexp_base <= pad_out_reg;     // Ma hoa chuoi da duoc chen dem bao mat
                        modexp_exp  <= 1024'd65537;
                    end else begin
                        modexp_base <= ciphertext_in;   // Giai ma ban ma 1024-bit truyen tu ngoai vao
                        modexp_exp  <= d_reg;
                    end
                    modexp_start  <= 1'b1;
                    current_state <= STATE_WAIT_EXP;
                end

                STATE_WAIT_EXP: begin
                    modexp_start <= 1'b0;
                    if (modexp_done) begin
                        if (mode == 1'b0) begin
                            ciphertext_out <= modexp_result; // Xuat thang ban ma 1024-bit ra ngoai
                            current_state  <= STATE_DONE;
                        end else begin
                            current_state  <= STATE_START_UNPAD; // Giai ma xong phai tien hanh unpad
                        end
                    end
                end

                // --- HAU XU LY: Kich hoat bo xoa dem de phuc hoi dung 936 bit tin nhan goc ---
                STATE_START_UNPAD: begin
                    wrapper_start <= 1'b1;
                    current_state <= STATE_WAIT_UNPAD;
                end

                STATE_WAIT_UNPAD: begin
                    wrapper_start <= 1'b0;
                    if (wrapper_ready) begin
                        plaintext_out <= wrapper_plaintext_out; // Tra lai dung so 936-bit ban dau
                        error         <= wrapper_padding_error; // Bat co loi neu chuoi ma hoa co doan dem sai qui cach
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
