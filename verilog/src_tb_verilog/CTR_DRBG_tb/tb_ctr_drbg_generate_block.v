`timescale 1ns/1ps

module tb_ctr_drbg_generate_block;

reg [255:0] key;
reg [127:0] counter_in;
wire [127:0] counter_out;
wire [127:0] random_block;
integer errors;

ctr_drbg_generate_block dut (
    .key(key),
    .counter_in(counter_in),
    .counter_out(counter_out),
    .random_block(random_block)
);

initial begin
    errors = 0;
    key = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
    counter_in = 128'h00112233445566778899aabbccddeeff;
    #5;

    if (counter_out !== 128'h00112233445566778899aabbccddef00) begin
        $display("FAIL counter_out=%032h", counter_out);
        errors = errors + 1;
    end

    if (random_block !== 128'hade7995a7fd71781a24c228168708e83) begin
        $display("FAIL random_block=%032h", random_block);
        errors = errors + 1;
    end

    if (errors == 0) $display("CTR_DRBG_GENERATE_BLOCK TEST PASSED");
    else $display("CTR_DRBG_GENERATE_BLOCK TEST FAILED: %0d errors", errors);
    $finish;
end

endmodule
