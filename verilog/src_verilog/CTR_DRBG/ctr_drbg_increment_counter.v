module ctr_drbg_increment_counter (
    input  wire [127:0] counter_in,
    output wire [127:0] counter_out
);

assign counter_out = counter_in + 128'd1;

endmodule
