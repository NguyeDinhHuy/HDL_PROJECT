module ctr_drbg_generate_block (
    input  wire [255:0] key,
    input  wire [127:0] counter_in,
    output wire [127:0] counter_out,
    output wire [127:0] random_block
);

ctr_drbg_increment_counter increment_counter_inst (
    .counter_in(counter_in),
    .counter_out(counter_out)
);

aes256_encrypt_block encrypt_counter_inst (
    .block_in(counter_out),
    .key(key),
    .block_out(random_block)
);

endmodule
