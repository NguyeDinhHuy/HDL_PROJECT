module bram
#(
  parameter quantity_of_mem = 1,
  parameter width_data      = 1,
  parameter width_address   = (quantity_of_mem <= 1) ? 1 : $clog2(quantity_of_mem),
  parameter init_file       = ""
)
(
  input  [width_data-1:0]    iData,
  input  [width_address-1:0] r_address,
  input  [width_address-1:0] w_address,
  input                      clk,
  input                      we,
  output reg [width_data-1:0] oData
);

(* ram_style = "block" *) reg [width_data-1:0] mem [quantity_of_mem-1 : 0];

initial begin
    if (init_file != "")
        $readmemh(init_file, mem);
end

always @(posedge clk) begin
    if (we)
        mem[w_address] <= iData;

    oData <= mem[r_address];
end

endmodule