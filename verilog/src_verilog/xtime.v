module xtime
(
 input      [7 : 0] iData,
 output reg [7 : 0] shifted
);

always @(*)
begin
  shifted = iData << 1;
  if(iData & 8'h80 != 0)
    begin
      shifted = shifted ^ 8'h1B;
    end
end

endmodule
