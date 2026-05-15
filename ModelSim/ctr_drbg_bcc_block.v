module ctr_drbg_bcc_block (
    input  wire [255:0] key,
    input  wire [127:0] chaining_value,
    input  wire [127:0] data_block,
    output wire [127:0] next_chaining_value
);

aes256_encrypt_block encrypt_bcc_block (
    .block_in(data_block ^ chaining_value),
    .key(key),
    .block_out(next_chaining_value)
);

endmodule
