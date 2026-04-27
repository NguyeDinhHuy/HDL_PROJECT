`timescale 1ns/1ps

module tb_shiftRows;

reg clk;
reg rst_n;
reg start;

reg  [7:0] iData;
wire [3:0] r_address;
wire [3:0] w_address;
wire       done;
wire       we;
wire [7:0] oData;

reg [7:0] input_mem  [0:15];
reg [7:0] output_mem [0:15];
reg [7:0] expected   [0:15];

integer i;
integer write_count;
integer timeout;

shiftRows dut (
    .clk       (clk),
    .start     (start),
    .rst_n     (rst_n),
    .iData     (iData),
    .r_address (r_address),
    .w_address (w_address),
    .done      (done),
    .we        (we),
    .oData     (oData)
);

// clock
always #5 clk = ~clk;

// mô ph?ng BRAM ??c tr? 1 clock
always @(posedge clk) begin
    iData <= input_mem[r_address];
end

// mô ph?ng BRAM ghi
always @(posedge clk) begin
    if (we) begin
        output_mem[w_address] <= oData;
        write_count <= write_count + 1;

        $display("T=%0t | WRITE output_mem[%0d] <= %02h",
                 $time, w_address, oData);
    end
end

initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    iData = 0;
    write_count = 0;
    timeout = 0;

    // input m?u: 00 01 02 ... 0F
    for (i = 0; i < 16; i = i + 1) begin
        input_mem[i]  = i[7:0];
        output_mem[i] = 8'hxx;
        expected[i]   = 8'h00;
    end

    // expected theo code C++
    expected[0]  = input_mem[0];
    expected[1]  = input_mem[5];
    expected[2]  = input_mem[10];
    expected[3]  = input_mem[15];

    expected[4]  = input_mem[4];
    expected[5]  = input_mem[9];
    expected[6]  = input_mem[14];
    expected[7]  = input_mem[3];

    expected[8]  = input_mem[8];
    expected[9]  = input_mem[13];
    expected[10] = input_mem[2];
    expected[11] = input_mem[7];

    expected[12] = input_mem[12];
    expected[13] = input_mem[1];
    expected[14] = input_mem[6];
    expected[15] = input_mem[11];

    // reset
    #20;
    rst_n = 1;

    // start pulse 1 clock
    @(posedge clk);
    start = 1;

    @(posedge clk);
    start = 0;

    // b?t done theo c?nh clock
    while (done !== 1'b1 && timeout < 100) begin
        @(posedge clk);
        timeout = timeout + 1;
    end

    if (timeout >= 100) begin
        $display("ERROR: Timeout, done not detected");
        $stop;
    end

    $display("\nDONE detected at T=%0t", $time);

    // ch? thêm 1 clock cho write cu?i ?n ??nh n?u có
    @(posedge clk);

    $display("\n==============================");
    $display("CHECK WRITE COUNT");
    $display("==============================");

    if (write_count != 16) begin
        $display("ERROR: write_count = %0d, expected = 16", write_count);
        $stop;
    end
    else begin
        $display("PASS: write_count = 16");
    end

    $display("\n==============================");
    $display("CHECK OUTPUT");
    $display("==============================");

    for (i = 0; i < 16; i = i + 1) begin
        $display("output_mem[%0d] = %02h | expected = %02h",
                 i, output_mem[i], expected[i]);

        if (output_mem[i] !== expected[i]) begin
            $display("ERROR at index %0d", i);
            $stop;
        end
    end

    $display("\n==============================");
    $display("SHIFTROWS PASS");
    $display("==============================");

    $finish;
end

endmodule