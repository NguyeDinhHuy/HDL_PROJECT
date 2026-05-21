`timescale 1ns / 1ps

module rsa_pkcs1_v15_wrapper_tb;

    reg          clk;
    reg          rst_n;
    reg          start;
    reg          mode;
    reg  [935:0] message_in_936;
    reg  [1023:0] decrypted_msg_1024;

    wire [935:0]  message_out_936;
    wire [1023:0] padded_msg_1024;
    wire          ready;
    wire          padding_error;

    rsa_pkcs1_v15_wrapper uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .mode(mode),
        .message_in_936(message_in_936),
        .message_out_936(message_out_936),
        .padded_msg_1024(padded_msg_1024),
        .decrypted_msg_1024(decrypted_msg_1024),
        .ready(ready),
        .padding_error(padding_error)
    );

    always #10 clk = ~clk;

    task pulse_start;
        begin
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    task wait_ready;
        begin
            @(posedge ready);
            #1;
        end
    endtask

    initial begin
        clk                = 1'b0;
        rst_n              = 1'b0;
        start              = 1'b0;
        mode               = 1'b0;
        message_in_936     = 936'd0;
        decrypted_msg_1024 = 1024'd0;

        #50;
        rst_n = 1'b1;
        #20;

        $display("=== TEST 1: Padding mode ===");
        message_in_936 = 936'h1234_5678_9ABC_DEF0;
        mode = 1'b0;
        pulse_start();
        wait_ready();

        $display("padded_msg_1024 = 0x%h", padded_msg_1024);

        if (padding_error != 1'b0) begin
            $display("FAIL: padding_error must be 0 in padding mode.");
        end else if (padded_msg_1024[1023:1016] != 8'h00) begin
            $display("FAIL: first byte is not 0x00.");
        end else if (padded_msg_1024[1015:1008] != 8'h02) begin
            $display("FAIL: block type is not 0x02.");
        end else if (padded_msg_1024[943:936] != 8'h00) begin
            $display("FAIL: separator byte is not 0x00.");
        end else if (padded_msg_1024[935:0] != message_in_936) begin
            $display("FAIL: message field does not match input.");
        end else if (padded_msg_1024[1007:944] == 64'd0) begin
            $display("FAIL: random padding block must not be all zero.");
        end else begin
            $display("PASS: padding block format is correct.");
        end

        #80;

        $display("=== TEST 2: Unpadding valid block ===");
        decrypted_msg_1024 = padded_msg_1024;
        mode = 1'b1;
        pulse_start();
        wait_ready();

        if (padding_error != 1'b0) begin
            $display("FAIL: valid block raised padding_error.");
        end else if (message_out_936 != message_in_936) begin
            $display("FAIL: unpadded message does not match original.");
        end else begin
            $display("PASS: valid block unpadded correctly.");
        end

        #80;

        $display("=== TEST 3: Unpadding invalid header ===");
        decrypted_msg_1024 = padded_msg_1024;
        decrypted_msg_1024[1015:1008] = 8'h01;
        mode = 1'b1;
        pulse_start();
        wait_ready();

        if (padding_error != 1'b1) begin
            $display("FAIL: invalid header did not raise padding_error.");
        end else if (message_out_936 != 936'd0) begin
            $display("FAIL: invalid block should clear message_out_936.");
        end else begin
            $display("PASS: invalid header detected.");
        end

        #80;

        $display("=== TEST 4: Unpadding invalid separator ===");
        decrypted_msg_1024 = padded_msg_1024;
        decrypted_msg_1024[943:936] = 8'h55;
        mode = 1'b1;
        pulse_start();
        wait_ready();

        if (padding_error != 1'b1) begin
            $display("FAIL: invalid separator did not raise padding_error.");
        end else begin
            $display("PASS: invalid separator detected.");
        end

        #100;
        $display("=== rsa_pkcs1_v15_wrapper_tb finished ===");
        $finish;
    end

endmodule
