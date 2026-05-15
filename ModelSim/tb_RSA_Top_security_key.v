`timescale 1ns / 1ps

module tb_RSA_Top_security_key;
    reg clk;
    reg rst_n;
    reg keygen_start;
    reg receive_start;
    reg [383:0] entropy_seed;
    reg [383:0] personalization;

    wire [511:0] p;
    wire [511:0] q;
    wire [1023:0] n;
    wire [1023:0] phi;
    wire [1023:0] public_e;
    wire [1023:0] private_d;
    wire key_valid;
    wire keygen_busy;
    wire keygen_done;
    wire [1023:0] rsa_data_out;
    wire rsa_done;
    wire [1023:0] ciphertext_out;
    wire send_busy;
    wire send_done;
    wire [1023:0] message_out;
    wire receive_busy;
    wire receive_done;
    wire security_key_ok;
    wire security_error;

    RSA_Top dut (
        .clk(clk),
        .rst_n(rst_n),
        .keygen_start(keygen_start),
        .entropy_seed(entropy_seed),
        .personalization(personalization),
        .p(p),
        .q(q),
        .n(n),
        .phi(phi),
        .public_e(public_e),
        .private_d(private_d),
        .key_valid(key_valid),
        .keygen_busy(keygen_busy),
        .keygen_done(keygen_done),
        .rsa_start(1'b0),
        .rsa_decrypt(1'b0),
        .rsa_data_in(1024'd0),
        .r2_mod_n(1024'd0),
        .rsa_data_out(rsa_data_out),
        .rsa_done(rsa_done),
        .send_start(1'b0),
        .message_in(1024'd0),
        .ciphertext_out(ciphertext_out),
        .send_busy(send_busy),
        .send_done(send_done),
        .receive_start(receive_start),
        .ciphertext_in(1024'h1234),
        .security_key_in(private_d ^ 1024'd1),
        .message_out(message_out),
        .receive_busy(receive_busy),
        .receive_done(receive_done),
        .security_key_ok(security_key_ok),
        .security_error(security_error)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        keygen_start = 1'b0;
        receive_start = 1'b0;
        entropy_seed = 384'h00112233445566778899aabbccddeeff102132435465768798a9babbdcedfe0f0102030405060708090a0b0c0d0e0f;
        personalization = 384'hf0e0d0c0b0a090807060504030201000ffeeddccbbaa9988776655443322110ffeeddccbbaa99887766554433221100;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        keygen_start = 1'b1;
        @(posedge clk);
        keygen_start = 1'b0;

        wait (keygen_done);
        repeat (2) @(posedge clk);

        receive_start = 1'b1;
        @(posedge clk);
        receive_start = 1'b0;

        wait (receive_done);
        #1;

        if (!security_error || security_key_ok || receive_busy) begin
            $display("FAIL: wrong security key was not rejected");
            $finish;
        end

        $display("PASS: wrong security key rejected");
        $finish;
    end
endmodule
