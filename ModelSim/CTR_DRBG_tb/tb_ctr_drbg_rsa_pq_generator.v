`timescale 1ns/1ps

module tb_ctr_drbg_rsa_pq_generator;

reg clk;
reg rst_n;
reg start;
reg [383:0] entropy_seed;
reg [383:0] personalization;
wire [511:0] p_candidate;
wire [511:0] q_candidate;
wire [127:0] nonce_value;
wire done;

reg [511:0] first_p;
reg [511:0] first_q;
integer errors;

ctr_drbg_rsa_pq_generator dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .entropy_seed(entropy_seed),
    .personalization(personalization),
    .p_candidate(p_candidate),
    .q_candidate(q_candidate),
    .nonce_value(nonce_value),
    .done(done)
);

always #5 clk = ~clk;

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    start = 1'b0;
    errors = 0;

    entropy_seed = 384'h00112233445566778899aabbccddeeff102132435465768798a9babbdcfd0e0f0123456789abcdeffedcba9876543210;
    personalization = 384'h444f414e5f48444c5f4354525f445242475f5253415f50515f47454e00000000000000000000000000000000;

    #20;
    rst_n = 1'b1;
    #10;

    start = 1'b1;
    #10;
    start = 1'b0;

    if (done !== 1'b1) begin
        $display("FAIL done was not asserted after first start");
        errors = errors + 1;
    end

    if (nonce_value !== 128'd1) begin
        $display("FAIL nonce after first start=%032h", nonce_value);
        errors = errors + 1;
    end

    if (p_candidate[511] !== 1'b1 || p_candidate[0] !== 1'b1) begin
        $display("FAIL p_candidate is not forced to odd 512-bit value");
        errors = errors + 1;
    end

    if (q_candidate[511] !== 1'b1 || q_candidate[0] !== 1'b1) begin
        $display("FAIL q_candidate is not forced to odd 512-bit value");
        errors = errors + 1;
    end

    if (p_candidate === q_candidate) begin
        $display("FAIL p_candidate and q_candidate should differ");
        errors = errors + 1;
    end

    first_p = p_candidate;
    first_q = q_candidate;

    #10;
    start = 1'b1;
    #10;
    start = 1'b0;

    if (nonce_value !== 128'd2) begin
        $display("FAIL nonce after second start=%032h", nonce_value);
        errors = errors + 1;
    end

    if (p_candidate === first_p && q_candidate === first_q) begin
        $display("FAIL second key generation reused the same p/q candidates");
        errors = errors + 1;
    end

    if (errors == 0) $display("CTR_DRBG_RSA_PQ_GENERATOR TEST PASSED");
    else $display("CTR_DRBG_RSA_PQ_GENERATOR TEST FAILED: %0d errors", errors);
    $finish;
end

endmodule
