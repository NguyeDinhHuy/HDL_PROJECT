`timescale 1ns/1ps

module tb_ctr_drbg_update_state;

reg [255:0] key;
reg [127:0] counter_in;
reg [383:0] provided_data;
reg has_provided_data;
wire [255:0] next_key;
wire [127:0] next_counter;
integer errors;

ctr_drbg_update_state dut (
    .key(key),
    .counter_in(counter_in),
    .provided_data(provided_data),
    .has_provided_data(has_provided_data),
    .next_key(next_key),
    .next_counter(next_counter)
);

initial begin
    errors = 0;
    key = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
    counter_in = 128'h00112233445566778899aabbccddeeff;
    provided_data = 384'h0;
    has_provided_data = 1'b0;
    #5;

    if (next_key !== 256'hade7995a7fd71781a24c228168708e836a5c655648b818abf008e39f28b86b55) begin
        $display("FAIL next_key=%064h", next_key);
        errors = errors + 1;
    end

    if (next_counter !== 128'h704f5848470bab9d588e4affa71be3aa) begin
        $display("FAIL next_counter=%032h", next_counter);
        errors = errors + 1;
    end

    has_provided_data = 1'b1;
    provided_data = {384{1'b1}};
    #5;

    if (next_key !== 256'h521866a58028e87e5db3dd7e978f717c95a39aa9b747e7540ff71c60d74794aa) begin
        $display("FAIL provided next_key=%064h", next_key);
        errors = errors + 1;
    end

    if (next_counter !== 128'h8fb0a7b7b8f45462a771b50058e41c55) begin
        $display("FAIL provided next_counter=%032h", next_counter);
        errors = errors + 1;
    end

    if (errors == 0) $display("CTR_DRBG_UPDATE_STATE TEST PASSED");
    else $display("CTR_DRBG_UPDATE_STATE TEST FAILED: %0d errors", errors);
    $finish;
end

endmodule
