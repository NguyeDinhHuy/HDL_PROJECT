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

    localparam IDLE     = 4'd0;
    localparam PREP     = 4'd1;
    localparam CMP_INIT = 4'd2;
    localparam CMP      = 4'd3;
    localparam SUB_INIT = 4'd4;
    localparam SUB      = 4'd5;
    localparam CALC     = 4'd6;
    localparam DONE     = 4'd7;

    localparam [COUNT_WIDTH-1:0] LAST_COUNT = WIDTH - 1;
    localparam EXT_WIDTH = WIDTH + 1;
    localparam CHUNK_COUNT = (EXT_WIDTH + 31) / 32;
    localparam PAD_WIDTH = CHUNK_COUNT * 32;
    localparam PAD_ZERO = PAD_WIDTH - EXT_WIDTH;
    localparam [5:0] LAST_CHUNK = CHUNK_COUNT - 1;

    reg [3:0] state;
    reg [WIDTH-1:0] dividend_reg;
    reg [WIDTH-1:0] divisor_reg;
    reg [WIDTH-1:0] quotient_reg;
    reg [WIDTH:0]   remainder_reg;
    reg [COUNT_WIDTH-1:0] count;

    reg [PAD_WIDTH-1:0] rem_shifted_pad;
    reg [PAD_WIDTH-1:0] divisor_pad;
    reg [PAD_WIDTH-1:0] rem_sub_pad;
    reg                 can_subtract_reg;
    reg                 sub_borrow;
    reg [5:0]           chunk_idx;
    reg [5:0]           cmp_idx;

    wire [WIDTH-1:0] quotient_next = {quotient_reg[WIDTH-2:0], can_subtract_reg};

    wire [31:0] cmp_rem_chunk = rem_shifted_pad[cmp_idx * 32 +: 32];
    wire [31:0] cmp_div_chunk = divisor_pad[cmp_idx * 32 +: 32];

    wire [32:0] sub_diff =
        {1'b0, rem_shifted_pad[chunk_idx * 32 +: 32]} -
        {1'b0, divisor_pad[chunk_idx * 32 +: 32]} -
        sub_borrow;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= IDLE;
            dividend_reg     <= {WIDTH{1'b0}};
            divisor_reg      <= {WIDTH{1'b0}};
            quotient_reg     <= {WIDTH{1'b0}};
            remainder_reg    <= {(WIDTH+1){1'b0}};
            count            <= {COUNT_WIDTH{1'b0}};
            rem_shifted_pad  <= {PAD_WIDTH{1'b0}};
            divisor_pad      <= {PAD_WIDTH{1'b0}};
            rem_sub_pad      <= {PAD_WIDTH{1'b0}};
            can_subtract_reg <= 1'b0;
            sub_borrow       <= 1'b0;
            chunk_idx        <= 6'd0;
            cmp_idx          <= 6'd0;
            quotient         <= {WIDTH{1'b0}};
            remainder        <= {WIDTH{1'b0}};
            done             <= 1'b0;
            divide_by_zero   <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        dividend_reg     <= dividend;
                        divisor_reg      <= divisor;
                        quotient_reg     <= {WIDTH{1'b0}};
                        remainder_reg    <= {(WIDTH+1){1'b0}};
                        rem_shifted_pad  <= {PAD_WIDTH{1'b0}};
                        divisor_pad      <= {{PAD_ZERO{1'b0}}, 1'b0, divisor};
                        rem_sub_pad      <= {PAD_WIDTH{1'b0}};
                        can_subtract_reg <= 1'b0;
                        sub_borrow       <= 1'b0;
                        count            <= {COUNT_WIDTH{1'b0}};
                        divide_by_zero   <= (divisor == {WIDTH{1'b0}});
                        state            <= (divisor == {WIDTH{1'b0}}) ? DONE : PREP;
                    end
                end

                PREP: begin
                    rem_shifted_pad <= {{PAD_ZERO{1'b0}}, remainder_reg[WIDTH-1:0], dividend_reg[WIDTH-1]};
                    state           <= CMP_INIT;
                end

                CMP_INIT: begin
                    cmp_idx          <= LAST_CHUNK;
                    can_subtract_reg <= 1'b0;
                    state            <= CMP;
                end

                CMP: begin
                    if (cmp_rem_chunk > cmp_div_chunk) begin
                        can_subtract_reg <= 1'b1;
                        state            <= SUB_INIT;
                    end else if (cmp_rem_chunk < cmp_div_chunk) begin
                        can_subtract_reg <= 1'b0;
                        rem_sub_pad      <= rem_shifted_pad;
                        state            <= CALC;
                    end else if (cmp_idx == 6'd0) begin
                        can_subtract_reg <= 1'b1;
                        state            <= SUB_INIT;
                    end else begin
                        cmp_idx <= cmp_idx - 6'd1;
                    end
                end

                SUB_INIT: begin
                    chunk_idx  <= 6'd0;
                    sub_borrow <= 1'b0;
                    state      <= SUB;
                end

                SUB: begin
                    rem_sub_pad[chunk_idx * 32 +: 32] <= sub_diff[31:0];
                    sub_borrow <= sub_diff[32];
                    if (chunk_idx == LAST_CHUNK) begin
                        state <= CALC;
                    end else begin
                        chunk_idx <= chunk_idx + 6'd1;
                    end
                end

                CALC: begin
                    remainder_reg <= rem_sub_pad[WIDTH:0];
                    quotient_reg  <= quotient_next;
                    dividend_reg  <= {dividend_reg[WIDTH-2:0], 1'b0};

                    if (count == LAST_COUNT) begin
                        quotient  <= quotient_next;
                        remainder <= rem_sub_pad[WIDTH-1:0];
                        state     <= DONE;
                    end else begin
                        count <= count + 1'b1;
                        state <= PREP;
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
