module ctr_drbg_rsa_pq_generator (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [383:0] entropy_seed,
    input  wire [383:0] personalization,
    output reg  [511:0] p_candidate,
    output reg  [511:0] q_candidate,
    output reg  [127:0] nonce_value,
    output reg          done
);

wire [383:0] nonce_material;
wire [383:0] seed_material;
wire [255:0] seed_key;
wire [127:0] seed_counter;

wire [255:0] drbg_key;
wire [127:0] drbg_counter;

wire [127:0] counter_1;
wire [127:0] counter_2;
wire [127:0] counter_3;
wire [127:0] counter_4;
wire [127:0] counter_5;
wire [127:0] counter_6;
wire [127:0] counter_7;
wire [127:0] counter_8;

wire [127:0] random_1;
wire [127:0] random_2;
wire [127:0] random_3;
wire [127:0] random_4;
wire [127:0] random_5;
wire [127:0] random_6;
wire [127:0] random_7;
wire [127:0] random_8;

wire [511:0] p_raw;
wire [511:0] q_raw;
wire [511:0] p_forced;
wire [511:0] q_forced;

assign nonce_material = {
    nonce_value,
    nonce_value ^ 128'h9e3779b97f4a7c15f39cc0605cedc835,
    nonce_value ^ 128'h3c6ef372fe94f82be73980c0a5db906a
};

assign seed_material = entropy_seed ^ personalization ^ nonce_material;
assign seed_key = seed_material[383:128];
assign seed_counter = seed_material[127:0];

ctr_drbg_update_state instantiate_state (
    .key(seed_key),
    .counter_in(seed_counter),
    .provided_data(seed_material),
    .has_provided_data(1'b1),
    .next_key(drbg_key),
    .next_counter(drbg_counter)
);

ctr_drbg_generate_block generate_1 (
    .key(drbg_key),
    .counter_in(drbg_counter),
    .counter_out(counter_1),
    .random_block(random_1)
);

ctr_drbg_generate_block generate_2 (
    .key(drbg_key),
    .counter_in(counter_1),
    .counter_out(counter_2),
    .random_block(random_2)
);

ctr_drbg_generate_block generate_3 (
    .key(drbg_key),
    .counter_in(counter_2),
    .counter_out(counter_3),
    .random_block(random_3)
);

ctr_drbg_generate_block generate_4 (
    .key(drbg_key),
    .counter_in(counter_3),
    .counter_out(counter_4),
    .random_block(random_4)
);

ctr_drbg_generate_block generate_5 (
    .key(drbg_key),
    .counter_in(counter_4),
    .counter_out(counter_5),
    .random_block(random_5)
);

ctr_drbg_generate_block generate_6 (
    .key(drbg_key),
    .counter_in(counter_5),
    .counter_out(counter_6),
    .random_block(random_6)
);

ctr_drbg_generate_block generate_7 (
    .key(drbg_key),
    .counter_in(counter_6),
    .counter_out(counter_7),
    .random_block(random_7)
);

ctr_drbg_generate_block generate_8 (
    .key(drbg_key),
    .counter_in(counter_7),
    .counter_out(counter_8),
    .random_block(random_8)
);

assign p_raw = {random_1, random_2, random_3, random_4};
assign q_raw = {random_5, random_6, random_7, random_8};

assign p_forced = {1'b1, p_raw[510:1], 1'b1};
assign q_forced = {1'b1, q_raw[510:1], 1'b1};

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_candidate <= 512'd0;
        q_candidate <= 512'd0;
        nonce_value <= 128'd0;
        done <= 1'b0;
    end else begin
        done <= 1'b0;

        if (start) begin
            p_candidate <= p_forced;
            q_candidate <= q_forced;
            nonce_value <= nonce_value + 128'd1;
            done <= 1'b1;
        end
    end
end

endmodule
