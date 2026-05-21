`timescale 1ns / 1ps

module ModExp_tb;

    reg          clk;
    reg          rst_n;
    reg          start;
    reg  [1023:0] base_in;
    reg  [1023:0] exp_in;
    reg  [1023:0] mod_in;
    reg  [1023:0] r2_mod_n;
    wire [1023:0] result;
    wire          done;

    integer pass_count;
    integer fail_count;

    ModExp uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .base_in(base_in),
        .exp_in(exp_in),
        .mod_in(mod_in),
        .r2_mod_n(r2_mod_n),
        .result(result),
        .done(done)
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

    task wait_done;
        begin
            while (!done) begin
                @(posedge clk);
            end
            #1;
        end
    endtask

    task run_case;
        input [1023:0] in_base;
        input [1023:0] in_exp;
        input [1023:0] in_mod;
        input [1023:0] in_r2;
        input [1023:0] expected;
        begin
            base_in = in_base;
            exp_in = in_exp;
            mod_in = in_mod;
            r2_mod_n = in_r2;
            pulse_start();
            wait_done();

            if (result !== expected) begin
                $display("FAIL: %0d^%0d mod %0d got=%0d expected=%0d",
                         in_base, in_exp, in_mod, result, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %0d^%0d mod %0d = %0d", in_base, in_exp, in_mod, result);
                pass_count = pass_count + 1;
            end

            @(posedge clk);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        base_in = 1024'd0;
        exp_in = 1024'd0;
        mod_in = 1024'd0;
        r2_mod_n = 1024'd0;
        pass_count = 0;
        fail_count = 0;

        #50;
        rst_n = 1'b1;
        #20;

        // For modulus 17, R^2 mod 17 = 1 because R = 2^1024 and 1024 is a multiple of 8.
        run_case(1024'd5, 1024'd3, 1024'd17, 1024'd1, 1024'd6);

        $display("=== ModExp_tb: pass=%0d fail=%0d ===", pass_count, fail_count);
        $finish;
    end

endmodule
