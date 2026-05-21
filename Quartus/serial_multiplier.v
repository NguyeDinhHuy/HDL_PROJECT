`timescale 1ns / 1ps

module serial_multiplier #(
    parameter WIDTH = 512,
    parameter CHUNK_WIDTH = 32
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     start,
    input  wire [WIDTH-1:0]         multiplicand_in,
    input  wire [WIDTH-1:0]         multiplier_in,

    output reg  [(2*WIDTH)-1:0]     product_out,
    output reg                      done
);

    localparam PRODUCT_WIDTH   = 2 * WIDTH;
    localparam CHUNK_COUNT     = PRODUCT_WIDTH / CHUNK_WIDTH;
    localparam INPUT_CHUNKS    = WIDTH / CHUNK_WIDTH;
    localparam COUNT_WIDTH     = (WIDTH <= 1)    ? 1  :
                                 (WIDTH <= 3)    ? 2  :
                                 (WIDTH <= 7)    ? 3  :
                                 (WIDTH <= 15)   ? 4  :
                                 (WIDTH <= 31)   ? 5  :
                                 (WIDTH <= 63)   ? 6  :
                                 (WIDTH <= 127)  ? 7  :
                                 (WIDTH <= 255)  ? 8  :
                                 (WIDTH <= 511)  ? 9  :
                                 (WIDTH <= 1023) ? 10 :
                                 (WIDTH <= 2047) ? 11 : 12;
    localparam CHUNK_IDX_WIDTH = (CHUNK_COUNT <= 2)   ? 1  :
                                 (CHUNK_COUNT <= 4)   ? 2  :
                                 (CHUNK_COUNT <= 8)   ? 3  :
                                 (CHUNK_COUNT <= 16)  ? 4  :
                                 (CHUNK_COUNT <= 32)  ? 5  :
                                 (CHUNK_COUNT <= 64)  ? 6  :
                                 (CHUNK_COUNT <= 128) ? 7  :
                                 (CHUNK_COUNT <= 256) ? 8  : 9;
    localparam [COUNT_WIDTH-1:0]     LAST_BIT_COUNT = WIDTH;
    localparam [CHUNK_IDX_WIDTH-1:0] LAST_CHUNK_IDX = CHUNK_COUNT - 1;

    localparam IDLE        = 4'd0;
    localparam INIT_WORDS  = 4'd1;
    localparam CHECK       = 4'd2;
    localparam ADD_READ    = 4'd3;
    localparam ADD_WRITE   = 4'd4;
    localparam SHIFT       = 4'd5;
    localparam SHIFT_WRITE = 4'd6;
    localparam PACK        = 4'd7;
    localparam DONE        = 4'd8;

    reg [3:0]                         state;
    reg [COUNT_WIDTH-1:0]             bit_count;
    reg [WIDTH-1:0]                   multiplier_reg;
    reg                               add_carry;
    reg                               shift_carry;
    reg [CHUNK_IDX_WIDTH-1:0]         chunk_idx;
    reg [CHUNK_WIDTH-1:0]             product_read;
    reg [CHUNK_WIDTH-1:0]             multiplicand_read;

    reg [CHUNK_WIDTH-1:0]             product_words [0:CHUNK_COUNT-1];
    reg [CHUNK_WIDTH-1:0]             multiplicand_words [0:CHUNK_COUNT-1];

    wire [CHUNK_WIDTH:0] chunk_sum =
        {1'b0, product_read} + {1'b0, multiplicand_read} + add_carry;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state             <= IDLE;
            bit_count         <= {COUNT_WIDTH{1'b0}};
            multiplier_reg    <= {WIDTH{1'b0}};
            add_carry         <= 1'b0;
            shift_carry       <= 1'b0;
            chunk_idx         <= {CHUNK_IDX_WIDTH{1'b0}};
            product_read      <= {CHUNK_WIDTH{1'b0}};
            multiplicand_read <= {CHUNK_WIDTH{1'b0}};
            product_out       <= {PRODUCT_WIDTH{1'b0}};
            done              <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        bit_count      <= {COUNT_WIDTH{1'b0}};
                        multiplier_reg <= multiplier_in;
                        add_carry      <= 1'b0;
                        shift_carry    <= 1'b0;
                        chunk_idx      <= {CHUNK_IDX_WIDTH{1'b0}};
                        product_out    <= {PRODUCT_WIDTH{1'b0}};
                        state          <= INIT_WORDS;
                    end
                end

                INIT_WORDS: begin
                    product_words[chunk_idx] <= {CHUNK_WIDTH{1'b0}};
                    if (chunk_idx < INPUT_CHUNKS) begin
                        multiplicand_words[chunk_idx] <= multiplicand_in[chunk_idx * CHUNK_WIDTH +: CHUNK_WIDTH];
                    end else begin
                        multiplicand_words[chunk_idx] <= {CHUNK_WIDTH{1'b0}};
                    end

                    if (chunk_idx == LAST_CHUNK_IDX) begin
                        chunk_idx <= {CHUNK_IDX_WIDTH{1'b0}};
                        state     <= CHECK;
                    end else begin
                        chunk_idx <= chunk_idx + 1'b1;
                    end
                end

                CHECK: begin
                    if (bit_count == LAST_BIT_COUNT) begin
                        chunk_idx <= {CHUNK_IDX_WIDTH{1'b0}};
                        state     <= PACK;
                    end else if (multiplier_reg[0]) begin
                        add_carry <= 1'b0;
                        chunk_idx <= {CHUNK_IDX_WIDTH{1'b0}};
                        state     <= ADD_READ;
                    end else begin
                        state <= SHIFT;
                    end
                end

                ADD_READ: begin
                    product_read      <= product_words[chunk_idx];
                    multiplicand_read <= multiplicand_words[chunk_idx];
                    state             <= ADD_WRITE;
                end

                ADD_WRITE: begin
                    product_words[chunk_idx] <= chunk_sum[CHUNK_WIDTH-1:0];
                    add_carry <= chunk_sum[CHUNK_WIDTH];

                    if (chunk_idx == LAST_CHUNK_IDX) begin
                        state <= SHIFT;
                    end else begin
                        chunk_idx <= chunk_idx + 1'b1;
                        state     <= ADD_READ;
                    end
                end

                SHIFT: begin
                    chunk_idx   <= {CHUNK_IDX_WIDTH{1'b0}};
                    shift_carry <= 1'b0;
                    state       <= SHIFT_WRITE;
                end

                SHIFT_WRITE: begin
                    multiplicand_words[chunk_idx] <= {
                        multiplicand_words[chunk_idx][CHUNK_WIDTH-2:0],
                        shift_carry
                    };
                    shift_carry <= multiplicand_words[chunk_idx][CHUNK_WIDTH-1];

                    if (chunk_idx == LAST_CHUNK_IDX) begin
                        multiplier_reg <= multiplier_reg >> 1;
                        bit_count      <= bit_count + 1'b1;
                        state          <= CHECK;
                    end else begin
                        chunk_idx <= chunk_idx + 1'b1;
                    end
                end

                PACK: begin
                    product_out[chunk_idx * CHUNK_WIDTH +: CHUNK_WIDTH] <= product_words[chunk_idx];
                    if (chunk_idx == LAST_CHUNK_IDX) begin
                        state <= DONE;
                    end else begin
                        chunk_idx <= chunk_idx + 1'b1;
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
