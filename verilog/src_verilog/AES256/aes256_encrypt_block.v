module aes256_encrypt_block (
    input  wire [127:0] block_in,
    input  wire [255:0] key,
    output reg  [127:0] block_out
);

`include "aes256_common.vh"

wire [1919:0] round_keys;
integer round;

aes256_key_expansion key_expansion_inst (
    .key(key),
    .round_keys(round_keys)
);

function [127:0] sub_bytes_state;
    input [127:0] state;
    integer i;
    begin
        for (i = 0; i < 16; i = i + 1) begin
            sub_bytes_state[127 - (i * 8) -: 8] =
                aes256_sbox_value(state[127 - (i * 8) -: 8]);
        end
    end
endfunction

function [127:0] shift_rows_state;
    input [127:0] state;
    reg [7:0] s [0:15];
    integer i;
    begin
        for (i = 0; i < 16; i = i + 1) begin
            s[i] = state[127 - (i * 8) -: 8];
        end
        shift_rows_state[127 - (0 * 8) -: 8]  = s[0];
        shift_rows_state[127 - (1 * 8) -: 8]  = s[5];
        shift_rows_state[127 - (2 * 8) -: 8]  = s[10];
        shift_rows_state[127 - (3 * 8) -: 8]  = s[15];
        shift_rows_state[127 - (4 * 8) -: 8]  = s[4];
        shift_rows_state[127 - (5 * 8) -: 8]  = s[9];
        shift_rows_state[127 - (6 * 8) -: 8]  = s[14];
        shift_rows_state[127 - (7 * 8) -: 8]  = s[3];
        shift_rows_state[127 - (8 * 8) -: 8]  = s[8];
        shift_rows_state[127 - (9 * 8) -: 8]  = s[13];
        shift_rows_state[127 - (10 * 8) -: 8] = s[2];
        shift_rows_state[127 - (11 * 8) -: 8] = s[7];
        shift_rows_state[127 - (12 * 8) -: 8] = s[12];
        shift_rows_state[127 - (13 * 8) -: 8] = s[1];
        shift_rows_state[127 - (14 * 8) -: 8] = s[6];
        shift_rows_state[127 - (15 * 8) -: 8] = s[11];
    end
endfunction

function [127:0] mix_columns_state;
    input [127:0] state;
    integer col;
    integer index;
    reg [7:0] s0;
    reg [7:0] s1;
    reg [7:0] s2;
    reg [7:0] s3;
    begin
        mix_columns_state = 128'h0;
        for (col = 0; col < 4; col = col + 1) begin
            index = col * 4;
            s0 = state[127 - (index * 8) -: 8];
            s1 = state[127 - ((index + 1) * 8) -: 8];
            s2 = state[127 - ((index + 2) * 8) -: 8];
            s3 = state[127 - ((index + 3) * 8) -: 8];
            mix_columns_state[127 - (index * 8) -: 8] =
                aes256_multiply_value(s0, 8'h02) ^ aes256_multiply_value(s1, 8'h03) ^ s2 ^ s3;
            mix_columns_state[127 - ((index + 1) * 8) -: 8] =
                s0 ^ aes256_multiply_value(s1, 8'h02) ^ aes256_multiply_value(s2, 8'h03) ^ s3;
            mix_columns_state[127 - ((index + 2) * 8) -: 8] =
                s0 ^ s1 ^ aes256_multiply_value(s2, 8'h02) ^ aes256_multiply_value(s3, 8'h03);
            mix_columns_state[127 - ((index + 3) * 8) -: 8] =
                aes256_multiply_value(s0, 8'h03) ^ s1 ^ s2 ^ aes256_multiply_value(s3, 8'h02);
        end
    end
endfunction

function [127:0] add_round_key_state;
    input [127:0] state;
    input [3:0] round_id;
    integer i;
    integer offset;
    begin
        offset = round_id * 16;
        for (i = 0; i < 16; i = i + 1) begin
            add_round_key_state[127 - (i * 8) -: 8] =
                state[127 - (i * 8) -: 8] ^ round_keys[1919 - ((offset + i) * 8) -: 8];
        end
    end
endfunction

always @(*) begin
    block_out = add_round_key_state(block_in, 4'd0);
    for (round = 1; round < 14; round = round + 1) begin
        block_out = sub_bytes_state(block_out);
        block_out = shift_rows_state(block_out);
        block_out = mix_columns_state(block_out);
        block_out = add_round_key_state(block_out, round[3:0]);
    end
    block_out = sub_bytes_state(block_out);
    block_out = shift_rows_state(block_out);
    block_out = add_round_key_state(block_out, 4'd14);
end

endmodule
