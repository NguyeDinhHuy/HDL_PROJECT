module ctr_drbg_update_state (
    input  wire [255:0] key,
    input  wire [127:0] counter_in,
    input  wire [383:0] provided_data,
    input  wire         has_provided_data,
    output wire [255:0] next_key,
    output wire [127:0] next_counter
);

wire [127:0] counter_1;
wire [127:0] counter_2;
wire [127:0] counter_3;
wire [127:0] encrypted_1;
wire [127:0] encrypted_2;
wire [127:0] encrypted_3;
wire [383:0] temp;
wire [383:0] mixed_temp;

ctr_drbg_increment_counter increment_1 (
    .counter_in(counter_in),
    .counter_out(counter_1)
);

ctr_drbg_increment_counter increment_2 (
    .counter_in(counter_1),
    .counter_out(counter_2)
);

ctr_drbg_increment_counter increment_3 (
    .counter_in(counter_2),
    .counter_out(counter_3)
);

aes256_encrypt_block encrypt_1 (
    .block_in(counter_1),
    .key(key),
    .block_out(encrypted_1)
);

aes256_encrypt_block encrypt_2 (
    .block_in(counter_2),
    .key(key),
    .block_out(encrypted_2)
);

aes256_encrypt_block encrypt_3 (
    .block_in(counter_3),
    .key(key),
    .block_out(encrypted_3)
);

assign temp = {encrypted_1, encrypted_2, encrypted_3};
assign mixed_temp = has_provided_data ? (temp ^ provided_data) : temp;
assign next_key = mixed_temp[383:128];
assign next_counter = mixed_temp[127:0];

endmodule
