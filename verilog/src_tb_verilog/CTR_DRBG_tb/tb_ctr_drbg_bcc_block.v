`timescale 1ns/1ps

module tb_ctr_drbg_bcc_block;

reg [255:0] key;
reg [127:0] chaining_value;
reg [127:0] data_block;
wire [127:0] next_chaining_value;
integer errors;

ctr_drbg_bcc_block dut (
    .key(key),
    .chaining_value(chaining_value),
    .data_block(data_block),
    .next_chaining_value(next_chaining_value)
);

initial begin
    errors = 0;
    key = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
    chaining_value = 128'h00000000000000000000000000000000;
    data_block = 128'h00112233445566778899aabbccddeeff;
    #5;

    if (next_chaining_value !== 128'h8ea2b7ca516745bfeafc49904b496089) begin
        $display("FAIL next_chaining_value=%032h", next_chaining_value);
        errors = errors + 1;
    end

    chaining_value = 128'hffffffffffffffffffffffffffffffff;
    data_block = 128'hffeeddccbbaa99887766554433221100;
    #5;

    if (next_chaining_value !== 128'h8ea2b7ca516745bfeafc49904b496089) begin
        $display("FAIL xor chaining next_chaining_value=%032h", next_chaining_value);
        errors = errors + 1;
    end

    if (errors == 0) $display("CTR_DRBG_BCC_BLOCK TEST PASSED");
    else $display("CTR_DRBG_BCC_BLOCK TEST FAILED: %0d errors", errors);
    $finish;
end

endmodule
