`timescale 1ns/1ps

module tb_aes256_key_expansion;

reg [255:0] key;
wire [1919:0] round_keys;
integer errors;

aes256_key_expansion dut (
    .key(key),
    .round_keys(round_keys)
);

initial begin
    errors = 0;
    key = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
    #1;

    if (round_keys[1919 - (0 * 8) -: 256] !== key) begin
        $display("FAIL original key copy=%064h", round_keys[1919 - (0 * 8) -: 256]);
        errors = errors + 1;
    end else begin
        $display("PASS original key copy");
    end

    if (round_keys[1919 - (32 * 8) -: 128] !== 128'ha573c29fa176c498a97fce93a572c09c) begin
        $display("FAIL round key bytes 32..47=%032h", round_keys[1919 - (32 * 8) -: 128]);
        errors = errors + 1;
    end else begin
        $display("PASS round key bytes 32..47");
    end

    if (round_keys[1919 - (48 * 8) -: 128] !== 128'h1651a8cd0244beda1a5da4c10640bade) begin
        $display("FAIL round key bytes 48..63=%032h", round_keys[1919 - (48 * 8) -: 128]);
        errors = errors + 1;
    end else begin
        $display("PASS round key bytes 48..63");
    end

    if (errors == 0) $display("AES256_KEY_EXPANSION TEST PASSED");
    else $display("AES256_KEY_EXPANSION TEST FAILED: %0d errors", errors);
    $finish;
end

endmodule
