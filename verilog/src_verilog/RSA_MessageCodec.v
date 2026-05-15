`timescale 1ns / 1ps

module RSA_MessageCodec (
    input  wire          clk,
    input  wire          rst_n,

    input  wire          encrypt_start,
    input  wire [1023:0] message_in,
    input  wire [1023:0] public_exponent,
    input  wire [1023:0] public_modulus,

    output reg  [1023:0] ciphertext_out,
    output reg           encrypt_busy,
    output reg           encrypt_done,

    input  wire          decrypt_start,
    input  wire [1023:0] security_key,

    output reg  [1023:0] message_out,
    output reg           decrypt_busy,
    output reg           decrypt_done,
    output reg           decrypt_match,
    output reg           input_error
);

    localparam [3:0] STATE_IDLE       = 4'd0;
    localparam [3:0] STATE_R2_INIT    = 4'd1;
    localparam [3:0] STATE_R2_STEP    = 4'd2;
    localparam [3:0] STATE_ENC_START  = 4'd3;
    localparam [3:0] STATE_ENC_WAIT   = 4'd4;
    localparam [3:0] STATE_DEC_START  = 4'd5;
    localparam [3:0] STATE_DEC_WAIT   = 4'd6;
    localparam [3:0] STATE_ERROR      = 4'd7;

    reg [3:0] state;

    reg          modexp_start;
    reg [1023:0] modexp_base;
    reg [1023:0] modexp_exp;
    reg [1023:0] modexp_mod;
    reg [1023:0] modexp_r2_mod_n;
    reg [1023:0] original_message;
    reg          pending_decrypt;
    reg [11:0]   r2_count;
    reg [1024:0] r2_remainder;

    wire [1023:0] modexp_result;
    wire          modexp_done;
    wire [1024:0] r2_modulus_wide;
    wire [1024:0] r2_doubled;
    wire [1024:0] r2_next;

    assign r2_modulus_wide = {1'b0, modexp_mod};
    assign r2_doubled = r2_remainder << 1;
    assign r2_next = (r2_doubled >= r2_modulus_wide) ?
                     (r2_doubled - r2_modulus_wide) :
                     r2_doubled;

    ModExp u_modexp (
        .clk(clk),
        .rst_n(rst_n),
        .start(modexp_start),
        .base_in(modexp_base),
        .exp_in(modexp_exp),
        .mod_in(modexp_mod),
        .r2_mod_n(modexp_r2_mod_n),
        .result(modexp_result),
        .done(modexp_done)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            modexp_start <= 1'b0;
            modexp_base <= 1024'd0;
            modexp_exp <= 1024'd0;
            modexp_mod <= 1024'd0;
            modexp_r2_mod_n <= 1024'd0;
            original_message <= 1024'd0;
            pending_decrypt <= 1'b0;
            r2_count <= 12'd0;
            r2_remainder <= 1025'd0;
            ciphertext_out <= 1024'd0;
            message_out <= 1024'd0;
            encrypt_busy <= 1'b0;
            encrypt_done <= 1'b0;
            decrypt_busy <= 1'b0;
            decrypt_done <= 1'b0;
            decrypt_match <= 1'b0;
            input_error <= 1'b0;
        end else begin
            modexp_start <= 1'b0;
            encrypt_done <= 1'b0;
            decrypt_done <= 1'b0;
            input_error <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    encrypt_busy <= 1'b0;
                    decrypt_busy <= 1'b0;

                    if (encrypt_start) begin
                        if ((public_modulus <= 1024'd1) ||
                            (public_exponent == 1024'd0) ||
                            (message_in >= public_modulus)) begin
                            state <= STATE_ERROR;
                        end else begin
                            original_message <= message_in;
                            modexp_base <= message_in;
                            modexp_exp <= public_exponent;
                            modexp_mod <= public_modulus;
                            pending_decrypt <= 1'b0;
                            encrypt_busy <= 1'b1;
                            state <= STATE_R2_INIT;
                        end
                    end else if (decrypt_start) begin
                        if (public_modulus <= 1024'd1) begin
                            state <= STATE_ERROR;
                        end else begin
                            modexp_base <= ciphertext_out;
                            modexp_exp <= security_key;
                            modexp_mod <= public_modulus;
                            pending_decrypt <= 1'b1;
                            decrypt_busy <= 1'b1;
                            state <= STATE_R2_INIT;
                        end
                    end
                end

                STATE_R2_INIT: begin
                    r2_remainder <= 1025'd1;
                    r2_count <= 12'd0;
                    state <= STATE_R2_STEP;
                end

                STATE_R2_STEP: begin
                    r2_remainder <= r2_next;

                    if (r2_count == 12'd2047) begin
                        modexp_r2_mod_n <= r2_next[1023:0];
                        state <= pending_decrypt ? STATE_DEC_START : STATE_ENC_START;
                    end else begin
                        r2_count <= r2_count + 1'b1;
                    end
                end

                STATE_ENC_START: begin
                    modexp_start <= 1'b1;
                    state <= STATE_ENC_WAIT;
                end

                STATE_ENC_WAIT: begin
                    if (modexp_done) begin
                        ciphertext_out <= modexp_result;
                        encrypt_busy <= 1'b0;
                        encrypt_done <= 1'b1;
                        state <= STATE_IDLE;
                    end
                end

                STATE_DEC_START: begin
                    modexp_start <= 1'b1;
                    state <= STATE_DEC_WAIT;
                end

                STATE_DEC_WAIT: begin
                    if (modexp_done) begin
                        message_out <= modexp_result;
                        decrypt_match <= (modexp_result == original_message);
                        decrypt_busy <= 1'b0;
                        decrypt_done <= 1'b1;
                        state <= STATE_IDLE;
                    end
                end

                STATE_ERROR: begin
                    input_error <= 1'b1;
                    encrypt_busy <= 1'b0;
                    decrypt_busy <= 1'b0;
                    state <= STATE_IDLE;
                end

                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
