`timescale 1ns / 1ps

module RSA_Top (
    input  wire          clk,
    input  wire          rst_n,

    input  wire          keygen_start,
    input  wire [383:0]  entropy_seed,
    input  wire [383:0]  personalization,

    output wire [511:0]  p,
    output wire [511:0]  q,
    output wire [1023:0] n,
    output wire [1023:0] phi,
    output wire [1023:0] public_e,
    output wire [1023:0] private_d,
    output wire          key_valid,
    output reg           keygen_busy,
    output reg           keygen_done,

    input  wire          rsa_start,
    input  wire          rsa_decrypt,
    input  wire [1023:0] rsa_data_in,

    output wire [1023:0] rsa_data_out,
    output wire          rsa_done,

    input  wire          send_start,
    input  wire [1023:0] message_in,
    output reg  [1023:0] ciphertext_out,
    output reg           send_busy,
    output reg           send_done,

    input  wire          receive_start,
    input  wire [1023:0] ciphertext_in,
    input  wire [1023:0] security_key_in,
    output reg  [1023:0] message_out,
    output reg           receive_busy,
    output reg           receive_done,
    output reg           security_key_ok,
    output reg           security_error
);

    localparam [1023:0] RSA_E = 1024'd65537;
    localparam [2:0] KEY_IDLE     = 3'd0;
    localparam [2:0] KEY_START_PQ = 3'd1;
    localparam [2:0] KEY_WAIT_PQ  = 3'd2;
    localparam [2:0] KEY_CAPTURE  = 3'd3;
    localparam [2:0] KEY_R2_START = 3'd4;
    localparam [2:0] KEY_R2_WAIT  = 3'd5;
    localparam [2:0] KEY_DONE     = 3'd6;
    localparam [2:0] MSG_IDLE     = 3'd0;
    localparam [2:0] MSG_START    = 3'd1;
    localparam [2:0] MSG_WAIT     = 3'd2;
    localparam [2:0] MSG_DONE     = 3'd3;
    localparam [2:0] MSG_BAD_KEY  = 3'd4;

    reg [2:0] key_state;
    reg [2:0] msg_state;
    reg       pq_start;
    reg [511:0] p_reg;
    reg [511:0] q_reg;
    reg       msg_modexp_start;
    reg       msg_is_decrypt;
    reg [1023:0] msg_base;
    reg [1023:0] msg_exp;
    reg       r2_start;
    reg       r2_valid;
    reg [1023:0] r2_mod_n_reg;

    wire [511:0] pq_p;
    wire [511:0] pq_q;
    wire [127:0] pq_nonce;
    wire         pq_done;

    ctr_drbg_rsa_pq_generator u_pq_generator (
        .clk(clk),
        .rst_n(rst_n),
        .start(pq_start),
        .entropy_seed(entropy_seed),
        .personalization(personalization),
        .p_candidate(pq_p),
        .q_candidate(pq_q),
        .nonce_value(pq_nonce),
        .done(pq_done)
    );

    wire [1023:0] generated_r2_mod_n;
    wire          r2_done;

    Fast_R2_Mod_N u_r2_mod_n (
        .clk(clk),
        .rst_n(rst_n),
        .start(r2_start),
        .n(n),
        .r2_mod_n(generated_r2_mod_n),
        .done(r2_done)
    );

    assign p = p_reg;
    assign q = q_reg;
    assign n = p_reg * q_reg;
    assign phi = (p_reg - 512'd1) * (q_reg - 512'd1);
    assign public_e = RSA_E;

    wire [16:0] phi_mod_e;
    wire [16:0] phi_mod_e_inv;
    wire [16:0] key_k;
    wire [1040:0] d_numerator;

    assign phi_mod_e = mod_65537(phi);
    assign phi_mod_e_inv = inv_mod_65537(phi_mod_e);
    assign key_k = (phi_mod_e_inv == 17'd0) ? 17'd0 :
                   (17'd65537 - phi_mod_e_inv);
    assign d_numerator = ({17'd0, phi} * key_k) + 1041'd1;
    assign private_d = d_numerator / 17'd65537;
    assign key_valid = (p_reg != 512'd0) &&
                       (q_reg != 512'd0) &&
                       (p_reg != q_reg) &&
                       (phi_mod_e != 17'd0);

    wire modexp_start;
    wire [1023:0] rsa_exp;

    assign modexp_start = rsa_start && key_valid && r2_valid;
    assign rsa_exp = rsa_decrypt ? private_d : public_e;

    ModExp u_rsa_modexp (
        .clk(clk),
        .rst_n(rst_n),
        .start(modexp_start),
        .base_in(rsa_data_in),
        .exp_in(rsa_exp),
        .mod_in(n),
        .r2_mod_n(r2_mod_n_reg),
        .result(rsa_data_out),
        .done(rsa_done)
    );

    wire [1023:0] msg_modexp_result;
    wire          msg_modexp_done;

    ModExp u_message_modexp (
        .clk(clk),
        .rst_n(rst_n),
        .start(msg_modexp_start),
        .base_in(msg_base),
        .exp_in(msg_exp),
        .mod_in(n),
        .r2_mod_n(r2_mod_n_reg),
        .result(msg_modexp_result),
        .done(msg_modexp_done)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_state   <= KEY_IDLE;
            pq_start    <= 1'b0;
            p_reg       <= 512'd0;
            q_reg       <= 512'd0;
            keygen_busy <= 1'b0;
            keygen_done <= 1'b0;
            msg_state   <= MSG_IDLE;
            msg_modexp_start <= 1'b0;
            msg_is_decrypt <= 1'b0;
            msg_base <= 1024'd0;
            msg_exp <= 1024'd0;
            r2_start <= 1'b0;
            r2_valid <= 1'b0;
            r2_mod_n_reg <= 1024'd0;
            ciphertext_out <= 1024'd0;
            message_out <= 1024'd0;
            send_busy <= 1'b0;
            send_done <= 1'b0;
            receive_busy <= 1'b0;
            receive_done <= 1'b0;
            security_key_ok <= 1'b0;
            security_error <= 1'b0;
        end else begin
            keygen_done <= 1'b0;
            pq_start    <= 1'b0;
            r2_start    <= 1'b0;
            msg_modexp_start <= 1'b0;
            send_done <= 1'b0;
            receive_done <= 1'b0;
            security_error <= 1'b0;

            case (key_state)
                KEY_IDLE: begin
                    keygen_busy <= 1'b0;
                    if (keygen_start) begin
                        keygen_busy <= 1'b1;
                        r2_valid <= 1'b0;
                        key_state   <= KEY_START_PQ;
                    end
                end

                KEY_START_PQ: begin
                    pq_start  <= 1'b1;
                    key_state <= KEY_WAIT_PQ;
                end

                KEY_WAIT_PQ: begin
                    key_state <= KEY_CAPTURE;
                end

                KEY_CAPTURE: begin
                    p_reg     <= pq_p;
                    q_reg     <= pq_q;
                    key_state <= KEY_R2_START;
                end

                KEY_R2_START: begin
                    r2_start <= 1'b1;
                    key_state <= KEY_R2_WAIT;
                end

                KEY_R2_WAIT: begin
                    if (r2_done) begin
                        r2_mod_n_reg <= generated_r2_mod_n;
                        r2_valid <= 1'b1;
                        key_state <= KEY_DONE;
                    end
                end

                KEY_DONE: begin
                    keygen_busy <= 1'b0;
                    keygen_done <= 1'b1;
                    key_state   <= KEY_IDLE;
                end

                default: begin
                    key_state <= KEY_IDLE;
                end
            endcase

            case (msg_state)
                MSG_IDLE: begin
                    send_busy <= 1'b0;
                    receive_busy <= 1'b0;

                    if (send_start && key_valid && r2_valid) begin
                        msg_base <= message_in;
                        msg_exp <= public_e;
                        msg_is_decrypt <= 1'b0;
                        send_busy <= 1'b1;
                        msg_state <= MSG_START;
                    end else if (receive_start && key_valid && r2_valid) begin
                        if (security_key_in == private_d) begin
                            security_key_ok <= 1'b1;
                            msg_base <= ciphertext_in;
                            msg_exp <= private_d;
                            msg_is_decrypt <= 1'b1;
                            receive_busy <= 1'b1;
                            msg_state <= MSG_START;
                        end else begin
                            security_key_ok <= 1'b0;
                            msg_state <= MSG_BAD_KEY;
                        end
                    end
                end

                MSG_START: begin
                    msg_modexp_start <= 1'b1;
                    msg_state <= MSG_WAIT;
                end

                MSG_WAIT: begin
                    if (msg_modexp_done) begin
                        if (msg_is_decrypt) begin
                            message_out <= msg_modexp_result;
                            receive_busy <= 1'b0;
                        end else begin
                            ciphertext_out <= msg_modexp_result;
                            send_busy <= 1'b0;
                        end
                        msg_state <= MSG_DONE;
                    end
                end

                MSG_DONE: begin
                    if (msg_is_decrypt) begin
                        receive_done <= 1'b1;
                    end else begin
                        send_done <= 1'b1;
                    end
                    msg_state <= MSG_IDLE;
                end

                MSG_BAD_KEY: begin
                    security_error <= 1'b1;
                    receive_done <= 1'b1;
                    msg_state <= MSG_IDLE;
                end

                default: begin
                    msg_state <= MSG_IDLE;
                end
            endcase
        end
    end

    function [16:0] mod_65537;
        input [1023:0] value;
        integer i;
        reg [17:0] rem;
        begin
            rem = 18'd0;
            for (i = 1023; i >= 0; i = i - 1) begin
                rem = {rem[16:0], value[i]};
                if (rem >= 18'd65537) begin
                    rem = rem - 18'd65537;
                end
            end
            mod_65537 = rem[16:0];
        end
    endfunction

    function [16:0] inv_mod_65537;
        input [16:0] value;
        integer t;
        integer new_t;
        integer r;
        integer new_r;
        integer quotient;
        integer temp;
        integer i;
        begin
            if (value == 17'd0) begin
                inv_mod_65537 = 17'd0;
            end else begin
                t = 0;
                new_t = 1;
                r = 65537;
                new_r = value;

                for (i = 0; i < 40; i = i + 1) begin
                    if (new_r != 0) begin
                        quotient = r / new_r;

                        temp = t - quotient * new_t;
                        t = new_t;
                        new_t = temp;

                        temp = r - quotient * new_r;
                        r = new_r;
                        new_r = temp;
                    end
                end

                if (r > 1) begin
                    inv_mod_65537 = 17'd0;
                end else begin
                    if (t < 0) begin
                        t = t + 65537;
                    end
                    inv_mod_65537 = t[16:0];
                end
            end
        end
    endfunction

endmodule
