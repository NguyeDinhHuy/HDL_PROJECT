`timescale 1ns / 1ps

module seq_div_unsigned #(
    parameter WIDTH = 32,
    parameter COUNT_WIDTH = 6
) (
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 start,
    input  wire [WIDTH-1:0]     dividend,
    input  wire [WIDTH-1:0]     divisor,
    output reg  [WIDTH-1:0]     quotient,
    output reg  [WIDTH-1:0]     remainder,
    output reg                  done,
    output reg                  divide_by_zero
);

    localparam IDLE = 2'd0;
    localparam CALC = 2'd1;
    localparam DONE = 2'd2;
    localparam [COUNT_WIDTH-1:0] LAST_COUNT = WIDTH - 1;

    reg [1:0] state;
    reg [WIDTH-1:0] dividend_reg;
    reg [WIDTH-1:0] divisor_reg;
    reg [WIDTH-1:0] quotient_reg;
    reg [WIDTH:0]   remainder_reg;
    reg [COUNT_WIDTH-1:0] count;

    wire [WIDTH:0] divisor_ext = {1'b0, divisor_reg};
    wire [WIDTH:0] rem_shifted = {remainder_reg[WIDTH-1:0], dividend_reg[WIDTH-1]};
    wire           can_subtract = (rem_shifted >= divisor_ext);
    wire [WIDTH:0] rem_next = can_subtract ? (rem_shifted - divisor_ext) : rem_shifted;
    wire [WIDTH-1:0] quotient_next = {quotient_reg[WIDTH-2:0], can_subtract};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= IDLE;
            dividend_reg   <= {WIDTH{1'b0}};
            divisor_reg    <= {WIDTH{1'b0}};
            quotient_reg   <= {WIDTH{1'b0}};
            remainder_reg  <= {(WIDTH+1){1'b0}};
            count          <= {COUNT_WIDTH{1'b0}};
            quotient       <= {WIDTH{1'b0}};
            remainder      <= {WIDTH{1'b0}};
            done           <= 1'b0;
            divide_by_zero <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        dividend_reg   <= dividend;
                        divisor_reg    <= divisor;
                        quotient_reg   <= {WIDTH{1'b0}};
                        remainder_reg  <= {(WIDTH+1){1'b0}};
                        count          <= {COUNT_WIDTH{1'b0}};
                        divide_by_zero <= (divisor == {WIDTH{1'b0}});
                        state          <= (divisor == {WIDTH{1'b0}}) ? DONE : CALC;
                    end
                end

                CALC: begin
                    remainder_reg <= rem_next;
                    quotient_reg  <= quotient_next;
                    dividend_reg  <= {dividend_reg[WIDTH-2:0], 1'b0};

                    if (count == LAST_COUNT) begin
                        quotient  <= quotient_next;
                        remainder <= rem_next[WIDTH-1:0];
                        state     <= DONE;
                    end else begin
                        count <= count + 1'b1;
                    end
                end

                DONE: begin
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
