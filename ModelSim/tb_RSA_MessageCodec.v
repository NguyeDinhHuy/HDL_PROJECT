`timescale 1ns / 1ps

module tb_RSA_MessageCodec;
    reg clk;
    reg rst_n;
    reg encrypt_start;
    reg decrypt_start;
    reg [1023:0] message_in;
    reg [1023:0] public_exponent;
    reg [1023:0] public_modulus;
    reg [1023:0] security_key;

    wire [1023:0] ciphertext_out;
    wire encrypt_busy;
    wire encrypt_done;
    wire [1023:0] message_out;
    wire decrypt_busy;
    wire decrypt_done;
    wire decrypt_match;
    wire input_error;

    localparam [1023:0] TEST_N = 1024'h7a5488ef6dca272efef17f340fc7a8ec345092bb3c305d7e07de6dc36ea442cb59143a3ad04406adcab59941666e4822f07cdaa192a67ef916e3bdbe9c726d7e76133c2fb8b072b9a575f1089729e44c52ffa2fd3ecbb4ab5bec430f9dad752a55765b9c94d6d70ebdf13e2e60e75e1cef973e3b5cab2cfa5ddd6f44f1cdae8d;
    localparam [1023:0] TEST_E = 1024'h10001;
    localparam [1023:0] TEST_D = 1024'h353f7cc7b3a38e00cfea70f34977205988c015ceb8795908d60605034fb2e27c3f4f25b59a18324c0df3943d3a8800906cdbfc12de91e8ad264085c465b70d5f9f9a663ebe03cb596d430e3f9b665925645923e9001bf912a34818232f31626a8a1cee59856ee2a8065ff3a94186f126cc72d12b82f0a2a8a0b385506fab3e25;
    localparam [1023:0] TEST_BAD_D = 1024'd123;
    localparam [1023:0] TEST_MESSAGE = 1024'd65;
    localparam integer OP_TIMEOUT_CYCLES = 300000000;

    RSA_MessageCodec dut (
        .clk(clk),
        .rst_n(rst_n),
        .encrypt_start(encrypt_start),
        .message_in(message_in),
        .public_exponent(public_exponent),
        .public_modulus(public_modulus),
        .ciphertext_out(ciphertext_out),
        .encrypt_busy(encrypt_busy),
        .encrypt_done(encrypt_done),
        .decrypt_start(decrypt_start),
        .security_key(security_key),
        .message_out(message_out),
        .decrypt_busy(decrypt_busy),
        .decrypt_done(decrypt_done),
        .decrypt_match(decrypt_match),
        .input_error(input_error)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        encrypt_start = 1'b0;
        decrypt_start = 1'b0;
        message_in = TEST_MESSAGE;
        public_exponent = TEST_E;
        public_modulus = TEST_N;
        security_key = 1024'd0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        encrypt_message();
        decrypt_with_key(TEST_D, 1'b1);
        decrypt_with_key(TEST_BAD_D, 1'b0);
        reject_message_greater_than_modulus();

        $display("PASS: RSA_MessageCodec encrypt/decrypt test completed");
        $finish;
    end

    task encrypt_message;
        begin
            encrypt_start = 1'b1;
            @(posedge clk);
            encrypt_start = 1'b0;

            wait_for_encrypt_done();

            if (input_error) begin
                $display("FAIL: encrypt raised input_error");
                $finish;
            end

            if (ciphertext_out >= TEST_N) begin
                $display("FAIL: ciphertext >= modulus");
                $display("      ciphertext = 0x%0h", ciphertext_out);
                $display("      modulus    = 0x%0h", TEST_N);
                $finish;
            end

            $display("PASS: encrypt message %0d", TEST_MESSAGE);
            $display("      ciphertext = %0d (0x%0h)", ciphertext_out, ciphertext_out);
        end
    endtask

    task decrypt_with_key;
        input [1023:0] key_value;
        input          expect_match;
        begin
            security_key = key_value;
            decrypt_start = 1'b1;
            @(posedge clk);
            decrypt_start = 1'b0;

            wait_for_decrypt_done();

            if (input_error) begin
                $display("FAIL: decrypt raised input_error");
                $finish;
            end

            if (decrypt_match !== expect_match) begin
                $display("FAIL: decrypt_match mismatch, got %0d expected %0d", decrypt_match, expect_match);
                $finish;
            end

            if (expect_match && (message_out != TEST_MESSAGE)) begin
                $display("FAIL: correct key output mismatch, got %0d expected %0d", message_out, TEST_MESSAGE);
                $finish;
            end

            if (!expect_match && (message_out == TEST_MESSAGE)) begin
                $display("FAIL: wrong key unexpectedly recovered original message");
                $finish;
            end

            if (expect_match) begin
                $display("PASS: decrypt with CORRECT key");
                $display("      key = %0d", key_value);
                $display("      decrypted message = %0d (0x%0h)", message_out, message_out);
                $display("      match original = %0d", decrypt_match);
            end else begin
                $display("PASS: decrypt with WRONG key");
                $display("      key = %0d", key_value);
                $display("      decrypted message = %0d (0x%0h)", message_out, message_out);
                $display("      match original = %0d", decrypt_match);
            end
        end
    endtask

    task reject_message_greater_than_modulus;
        begin
            message_in = TEST_N;
            encrypt_start = 1'b1;
            @(posedge clk);
            encrypt_start = 1'b0;
            @(posedge clk);
            #1;

            if (!input_error) begin
                $display("FAIL: message >= modulus was not rejected");
                $finish;
            end

            message_in = TEST_MESSAGE;
            $display("PASS: message >= modulus rejected");
        end
    endtask

    task wait_for_encrypt_done;
        integer cycles;
        begin
            cycles = 0;
            while (!encrypt_done && cycles < OP_TIMEOUT_CYCLES) begin
                @(posedge clk);
                cycles = cycles + 1;
            end

            if (!encrypt_done) begin
                $display("FAIL: timeout waiting for encrypt_done");
                $finish;
            end
        end
    endtask

    task wait_for_decrypt_done;
        integer cycles;
        begin
            cycles = 0;
            while (!decrypt_done && cycles < OP_TIMEOUT_CYCLES) begin
                @(posedge clk);
                cycles = cycles + 1;
            end

            if (!decrypt_done) begin
                $display("FAIL: timeout waiting for decrypt_done");
                $finish;
            end
        end
    endtask
endmodule
