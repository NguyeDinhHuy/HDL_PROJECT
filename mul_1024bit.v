module mul_1024bit(
    input [1023:0] a,
    input [1023:0] b,
    output [2047:0] result
)
reg [31:0] temp [31:0];
integer i, j;


 ì 