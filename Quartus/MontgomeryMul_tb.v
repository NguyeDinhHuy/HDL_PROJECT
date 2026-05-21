`timescale 1ns / 1ps

module MontgomeryMul_tb;

    reg          clk;
    reg          rst_n;
    reg          start;
    reg  [1023:0] a;
    reg  [1023:0] b;
    reg  [1023:0] m;
    wire [1023:0] result;
    wire          done;

    integer pass_count;
    integer fail_count;
    integer wait_count;

    MontgomeryMul uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .a(a),
        .b(b),
        .m(m),
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
            wait_count = 0;
            while (!done && wait_count < 50000) begin
                @(posedge clk);
                wait_count = wait_count + 1;
            end
            #1;
        end
    endtask

    task run_case;
        input [1023:0] in_a;
        input [1023:0] in_b;
        input [1023:0] in_m;
        input [1023:0] expected;
        begin
            a = in_a;
            b = in_b;
            m = in_m;
            pulse_start();
            wait_done();

            if (!done) begin
                $display("FAIL: timeout a=%0d b=%0d m=%0d", in_a, in_b, in_m);
                fail_count = fail_count + 1;
            end else if (result !== expected) begin
                $display("FAIL: Mont(%0d,%0d) mod %0d got=%0d expected=%0d",
                         in_a, in_b, in_m, result, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: Mont(%0d,%0d) mod %0d = %0d", in_a, in_b, in_m, result);
                pass_count = pass_count + 1;
            end

            @(posedge clk);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        a = 1024'd0;
        b = 1024'd0;
        m = 1024'd0;
        pass_count = 0;
        fail_count = 0;

        #50;
        rst_n = 1'b1;
        #20;

        // With m = 5 or 17, 2^1024 mod m = 1, so Montgomery result equals a*b mod m.
        run_case(1024'd2, 1024'd3, 1024'd5, 1024'd1);
        run_case(1024'd4, 1024'd4, 1024'd5, 1024'd1);
        run_case(1024'd5, 1024'd7, 1024'd17, 1024'd1);

        $display("=== MontgomeryMul_tb: pass=%0d fail=%0d ===", pass_count, fail_count);
        $finish;
    end

endmodule
