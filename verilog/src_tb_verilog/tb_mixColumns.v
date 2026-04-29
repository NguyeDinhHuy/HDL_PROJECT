`timescale 1ns/1ps

module tb_mixColumns;

reg clk;
reg rst_n;
reg start;
reg [7:0] iData;

wire [7:0] oData;
wire done;
wire we;
wire [3:0] r_address;
wire [3:0] w_address;

reg [7:0] mem_in  [0:15];
reg [7:0] mem_out [0:15];
reg [7:0] expected[0:15];

integer i;
integer error_count;

mixColumns dut (
    .start(start),
    .rst_n(rst_n),
    .clk(clk),
    .iData(iData),
    .oData(oData),
    .done(done),
    .we(we),
    .r_address(r_address),
    .w_address(w_address)
);

// clock 10ns
always #5 clk = ~clk;

// BRAM read sync: data ra sau 1 clock
always @(posedge clk) begin
    iData <= mem_in[r_address];
end

// BRAM write sync
always @(posedge clk) begin
    if (we) begin
        mem_out[w_address] <= oData;
        $display("WRITE: addr=%0d data=%02h time=%0t", w_address, oData, $time);
    end
end

function [7:0] xtime_func;
    input [7:0] x;
    begin
        if (x[7])
            xtime_func = (x << 1) ^ 8'h1B;
        else
            xtime_func = (x << 1);
    end
endfunction

function [7:0] mul2;
    input [7:0] x;
    begin
        mul2 = xtime_func(x);
    end
endfunction

function [7:0] mul3;
    input [7:0] x;
    begin
        mul3 = xtime_func(x) ^ x;
    end
endfunction

task calc_expected;
    reg [7:0] s0, s1, s2, s3;
    integer col;
    integer index;
    begin
        for (col = 0; col < 4; col = col + 1) begin
            index = col * 4;

            s0 = mem_in[index];
            s1 = mem_in[index + 1];
            s2 = mem_in[index + 2];
            s3 = mem_in[index + 3];

            expected[index]     = mul2(s0) ^ mul3(s1) ^ s2      ^ s3;
            expected[index + 1] = s0      ^ mul2(s1) ^ mul3(s2) ^ s3;
            expected[index + 2] = s0      ^ s1      ^ mul2(s2) ^ mul3(s3);
            expected[index + 3] = mul3(s0) ^ s1     ^ s2      ^ mul2(s3);
        end
    end
endtask

initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    iData = 0;
    error_count = 0;

    for (i = 0; i < 16; i = i + 1) begin
        mem_in[i] = 0;
        mem_out[i] = 0;
        expected[i] = 0;
    end

    // AES MixColumns test vector, l?u theo t?ng c?t
    mem_in[0]  = 8'hd4;
    mem_in[1]  = 8'hbf;
    mem_in[2]  = 8'h5d;
    mem_in[3]  = 8'h30;

    mem_in[4]  = 8'he0;
    mem_in[5]  = 8'hb4;
    mem_in[6]  = 8'h52;
    mem_in[7]  = 8'hae;

    mem_in[8]  = 8'hb8;
    mem_in[9]  = 8'h41;
    mem_in[10] = 8'h11;
    mem_in[11] = 8'hf1;

    mem_in[12] = 8'h1e;
    mem_in[13] = 8'h27;
    mem_in[14] = 8'h98;
    mem_in[15] = 8'he5;

    calc_expected();

    #20;
    rst_n = 1;
    #20;

    start = 1;
    #10;
    start = 0;

    wait(done == 1);

    #30;

    $display("\n===== CHECK RESULT =====");

    for (i = 0; i < 16; i = i + 1) begin
        if (mem_out[i] !== expected[i]) begin
            $display("FAIL addr=%0d out=%02h expected=%02h", i, mem_out[i], expected[i]);
            error_count = error_count + 1;
        end
        else begin
            $display("PASS addr=%0d out=%02h", i, mem_out[i]);
        end
    end

    if (error_count == 0)
        $display("\nMIXCOLUMNS TEST PASSED");
    else
        $display("\nMIXCOLUMNS TEST FAILED: %0d errors", error_count);

    #20;
    $stop;
end

// timeout ch?ng treo
initial begin
    #5000;
    $display("TIMEOUT: done khong len");
    $stop;
end

endmodule