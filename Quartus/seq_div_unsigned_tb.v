`timescale 1ns / 1ps

module seq_div_unsigned_tb;

    reg         clk;
    reg         rst_n;
    reg         start;
    reg  [31:0] dividend;
    reg  [31:0] divisor;
    wire [31:0] quotient;
    wire [31:0] remainder;
    wire        done;
    wire        divide_by_zero;

    integer pass_count;
    integer fail_count;
    integer wait_count;

    seq_div_unsigned #(
        .WIDTH(32),
        .COUNT_WIDTH(6)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .dividend(dividend),
        .divisor(divisor),
        .quotient(quotient),
        .remainder(remainder),
        .done(done),
        .divide_by_zero(divide_by_zero)
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
            while (!done && wait_count < 100) begin
                @(posedge clk);
                wait_count = wait_count + 1;
            end
            #1;
        end
    endtask

    task run_case;
        input [31:0] in_dividend;
        input [31:0] in_divisor;
        input [31:0] exp_quotient;
        input [31:0] exp_remainder;
        input        exp_divide_by_zero;
        begin
            dividend = in_dividend;
            divisor  = in_divisor;
            pulse_start();
            wait_done();

            if (!done) begin
                $display("FAIL: timeout dividend=%0d divisor=%0d", in_dividend, in_divisor);
                fail_count = fail_count + 1;
            end else if (divide_by_zero !== exp_divide_by_zero) begin
                $display("FAIL: divide_by_zero dividend=%0d divisor=%0d got=%b expected=%b",
                         in_dividend, in_divisor, divide_by_zero, exp_divide_by_zero);
                fail_count = fail_count + 1;
            end else if (!exp_divide_by_zero &&
                         (quotient !== exp_quotient || remainder !== exp_remainder)) begin
                $display("FAIL: %0d / %0d got q=%0d r=%0d expected q=%0d r=%0d",
                         in_dividend, in_divisor, quotient, remainder, exp_quotient, exp_remainder);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %0d / %0d", in_dividend, in_divisor);
                pass_count = pass_count + 1;
            end

            @(posedge clk);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        dividend = 32'd0;
        divisor = 32'd0;
        pass_count = 0;
        fail_count = 0;

        #50;
        rst_n = 1'b1;
        #20;

        run_case(32'd100, 32'd7, 32'd14, 32'd2, 1'b0);
        run_case(32'd123456789, 32'd1000, 32'd123456, 32'd789, 1'b0);
        run_case(32'd42, 32'd1, 32'd42, 32'd0, 1'b0);
        run_case(32'd42, 32'd0, 32'd0, 32'd0, 1'b1);

        $display("=== seq_div_unsigned_tb: pass=%0d fail=%0d ===", pass_count, fail_count);
        $finish;
    end

endmodule
