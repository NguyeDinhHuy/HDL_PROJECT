`timescale 1ns/1ps

module tb_ctr_drbg_increment_counter;

reg [127:0] counter_in;
wire [127:0] counter_out;
integer errors;

ctr_drbg_increment_counter dut (
    .counter_in(counter_in),
    .counter_out(counter_out)
);

initial begin
    errors = 0;

    counter_in = 128'h00000000000000000000000000000000;
    #5;
    if (counter_out !== 128'h00000000000000000000000000000001) begin
        $display("FAIL zero increment: %032h", counter_out);
        errors = errors + 1;
    end

    counter_in = 128'h00112233445566778899aabbccddeeff;
    #5;
    if (counter_out !== 128'h00112233445566778899aabbccddef00) begin
        $display("FAIL normal increment: %032h", counter_out);
        errors = errors + 1;
    end

    counter_in = 128'hffffffffffffffffffffffffffffffff;
    #5;
    if (counter_out !== 128'h00000000000000000000000000000000) begin
        $display("FAIL wrap increment: %032h", counter_out);
        errors = errors + 1;
    end

    if (errors == 0) $display("CTR_DRBG_INCREMENT_COUNTER TEST PASSED");
    else $display("CTR_DRBG_INCREMENT_COUNTER TEST FAILED: %0d errors", errors);
    $finish;
end

endmodule
