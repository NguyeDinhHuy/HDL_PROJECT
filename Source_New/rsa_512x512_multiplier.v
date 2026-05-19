`timescale 1ns / 1ps

module rsa_512x512_multiplier (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          start,
    input  wire [511:0]  p,
    input  wire [511:0]  q,
    
    output reg  [1023:0] n,
    output reg           done
);

    localparam IDLE = 2'd0;
    localparam CALC = 2'd1;
    localparam DONE = 2'd2;

    reg [1:0]   state;              // Thanh ghi luu tru trang thai FSM
    reg [3:0]   count;              // Bo dem chu ky quan ly luong pipeline
    reg [511:0] p_reg;              // Thanh ghi luu p de co dinh cho bo nhan
    reg [511:0] q_reg;              // Thanh ghi luu q de quet dich thap xuong
    reg [575:0] part_prod;          // Thanh ghi dem luu san pham tung phan 512x64 bit
    reg [512:0] accum;              // Thanh ghi tich luy phan cao cua phep cong
    reg [511:0] result_lower;       // Thanh ghi dich luu phan thap cua ket qua

    wire [576:0] sum = accum + part_prod;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            p_reg        <= 512'd0;
            q_reg        <= 512'd0;
            part_prod    <= 576'd0;
            accum        <= 513'd0;
            result_lower <= 512'd0;
            count        <= 4'd0;
            done         <= 1'b0;
            n            <= 1024'd0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        p_reg        <= p;
                        q_reg        <= q;
                        accum        <= 513'd0;
                        result_lower <= 512'd0;
                        count        <= 4'd0;
                        state        <= CALC;
                    end
                end

                CALC: begin
                    count     <= count + 4'd1;
                    part_prod <= p_reg * q_reg[63:0];
                    q_reg     <= q_reg >> 64;

                    if (count > 4'd0) begin
                        result_lower <= {sum[63:0], result_lower[511:64]};
                        accum        <= sum[576:64];
                    end

                    if (count == 4'd8) begin
                        state <= DONE;
                    end
                end

                DONE: begin
                    n     <= {accum[511:0], result_lower};
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule