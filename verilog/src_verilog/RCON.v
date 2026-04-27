module RCON (
    input  wire [3:0] in,
    output reg  [7:0] out
);

always @(*) begin
    case (in)
        4'h0: out = 8'h00;
        4'h1: out = 8'h01;
        4'h2: out = 8'h02;
        4'h3: out = 8'h04;
        4'h4: out = 8'h08;
        4'h5: out = 8'h10;
        4'h6: out = 8'h20;
        4'h7: out = 8'h40;
        4'h8: out = 8'h80;
        4'h9: out = 8'h1B;
        4'hA: out = 8'h36;
        4'hB: out = 8'h6C;
        4'hC: out = 8'hD8;
        4'hD: out = 8'hAB;
        4'hE: out = 8'h4D;

        default: out = 8'h00;
    endcase
end

endmodule