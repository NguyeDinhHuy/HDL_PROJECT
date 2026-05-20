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

    function integer clog2;
        input integer value;
        integer tmp;
        begin
            tmp = value - 1;
            for (clog2 = 0; tmp > 0; clog2 = clog2 + 1) begin
                tmp = tmp >> 1;
            end
        end
    endfunction

    localparam PRODUCT_WIDTH   = 2 * WIDTH;
    localparam CHUNK_COUNT     = PRODUCT_WIDTH / CHUNK_WIDTH;
    localparam INPUT_CHUNKS    = WIDTH / CHUNK_WIDTH;
    localparam COUNT_WIDTH     = clog2(WIDTH + 1);
    localparam CHUNK_IDX_WIDTH = clog2(CHUNK_COUNT);
    localparam [COUNT_WIDTH-1:0]     LAST_BIT_COUNT = WIDTH;
    localparam [CHUNK_IDX_WIDTH-1:0] LAST_CHUNK_IDX = CHUNK_COUNT - 1;

    localparam IDLE      = 3'd0;
    localparam CHECK     = 3'd1;
    localparam ADD_READ  = 3'd2;
    localparam ADD_WRITE = 3'd3;
    localparam SHIFT     = 3'd4;
    localparam PACK      = 3'd5;
    localparam DONE      = 3'd6;

    reg [2:0]                         state;
    reg [COUNT_WIDTH-1:0]             bit_count;
    reg [WIDTH-1:0]                   multiplier_reg;
    reg                               add_carry;
    reg [CHUNK_IDX_WIDTH-1:0]         chunk_idx;
    reg [CHUNK_WIDTH-1:0]             product_read;
    reg [CHUNK_WIDTH-1:0]             multiplicand_read;

    reg [CHUNK_WIDTH-1:0]             product_words [0:CHUNK_COUNT-1];
    reg [CHUNK_WIDTH-1:0]             multiplicand_words [0:CHUNK_COUNT-1];

    wire [CHUNK_WIDTH:0] chunk_sum =
        {1'b0, product_read} + {1'b0, multiplicand_read} + add_carry;

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state             <= IDLE;
            bit_count         <= {COUNT_WIDTH{1'b0}};
            multiplier_reg    <= {WIDTH{1'b0}};
            add_carry         <= 1'b0;
            chunk_idx         <= {CHUNK_IDX_WIDTH{1'b0}};
            product_read      <= {CHUNK_WIDTH{1'b0}};
            multiplicand_read <= {CHUNK_WIDTH{1'b0}};
            product_out       <= {PRODUCT_WIDTH{1'b0}};
            done              <= 1'b0;

            for (i = 0; i < CHUNK_COUNT; i = i + 1) begin
                product_words[i]      <= {CHUNK_WIDTH{1'b0}};
                multiplicand_words[i] <= {CHUNK_WIDTH{1'b0}};
            end
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        bit_count      <= {COUNT_WIDTH{1'b0}};
                        multiplier_reg <= multiplier_in;
                        add_carry      <= 1'b0;
                        chunk_idx      <= {CHUNK_IDX_WIDTH{1'b0}};
                        product_out    <= {PRODUCT_WIDTH{1'b0}};

                        for (i = 0; i < CHUNK_COUNT; i = i + 1) begin
                            product_words[i] <= {CHUNK_WIDTH{1'b0}};
                            if (i < INPUT_CHUNKS) begin
                                multiplicand_words[i] <= multiplicand_in[i * CHUNK_WIDTH +: CHUNK_WIDTH];
                            end else begin
                                multiplicand_words[i] <= {CHUNK_WIDTH{1'b0}};
                            end
                        end

                        state <= CHECK;
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
                    multiplicand_words[0] <= {multiplicand_words[0][CHUNK_WIDTH-2:0], 1'b0};
                    for (i = 1; i < CHUNK_COUNT; i = i + 1) begin
                        multiplicand_words[i] <= {
                            multiplicand_words[i][CHUNK_WIDTH-2:0],
                            multiplicand_words[i-1][CHUNK_WIDTH-1]
                        };
                    end

                    multiplier_reg <= multiplier_reg >> 1;
                    bit_count      <= bit_count + 1'b1;
                    state          <= CHECK;
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
