`timescale 1ns/1ps

module tb_aes256_encrypt_block;

reg [127:0] block_in;
reg [255:0] key;
wire [127:0] block_out;
integer errors;

aes256_encrypt_block dut (
    .block_in(block_in),
    .key(key),
    .block_out(block_out)
);

initial begin
    errors = 0;
    key = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
    block_in = 128'h00112233445566778899aabbccddeeff;
    #5;

    if (block_out !== 128'h8ea2b7ca516745bfeafc49904b496089) begin
        $display("FAIL block_out=%032h expected=8ea2b7ca516745bfeafc49904b496089", block_out);
        errors = errors + 1;
    end else begin
        $display("PASS block_out=%032h", block_out);
    end

    if (errors == 0) $display("AES256_ENCRYPT_BLOCK TEST PASSED");
    else $display("AES256_ENCRYPT_BLOCK TEST FAILED: %0d errors", errors);
    $finish;
end

endmodule
