`timescale 1ns / 1ps

module Fast_R2_Mod_N_tb;

    reg          clk;
    reg          rst_n;
    reg          start;
    reg  [1023:0] n;
    wire [1023:0] r2_mod_n;
    wire          done;

    integer pass_count;
    integer fail_count;
    integer wait_count;

    Fast_R2_Mod_N uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .n(n),
        .r2_mod_n(r2_mod_n),
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
            while (!done && wait_count < 500000) begin
                @(posedge clk);
                wait_count = wait_count + 1;
            end
            #1;
        end
    endtask

    task run_case;
        input [1023:0] in_n;
        input [1023:0] expected;
        begin
            n = in_n;
            pulse_start();
            wait_done();

            if (!done) begin
                $display("FAIL: timeout n=%0d", in_n);
                fail_count = fail_count + 1;
            end else if (r2_mod_n !== expected) begin
                $display("FAIL: n=%0d got=%0d expected=%0d", in_n, r2_mod_n, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: R^2 mod %0d = %0d", in_n, r2_mod_n);
                pass_count = pass_count + 1;
            end

            @(posedge clk);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        n = 1024'd0;
        pass_count = 0;
        fail_count = 0;

        #50;
        rst_n = 1'b1;
        #20;

        run_case(1024'd3, 1024'd1);
        run_case(1024'd5, 1024'd1);
        run_case(1024'd17, 1024'd1);

        $display("=== Fast_R2_Mod_N_tb: pass=%0d fail=%0d ===", pass_count, fail_count);
        $finish;
    end

endmodule
