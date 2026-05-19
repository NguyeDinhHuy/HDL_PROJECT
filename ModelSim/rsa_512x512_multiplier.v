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

    localparam IDLE      = 3'd0;
    localparam CHECK     = 3'd1;
    localparam ADD_CHUNK = 3'd2;
    localparam SHIFT     = 3'd3;
    localparam DONE      = 3'd4;

    reg [2:0]    state;             // Thanh ghi luu tru trang thai FSM
    reg [9:0]    count;             // Dem 512 bit cua q
    reg [511:0]  q_reg;             // Thanh ghi quet bit cua q
    reg [1023:0] multiplicand;      // p duoc dich trai theo tung bit
    reg [1023:0] product;           // Tich luy ket qua
    reg          add_carry;         // Carry giua cac chunk 32-bit
    reg [4:0]    chunk_idx;         // 32 chunk x 32 bit = 1024 bit

    wire [31:0] product_chunk      = product[chunk_idx * 32 +: 32];
    wire [31:0] multiplicand_chunk = multiplicand[chunk_idx * 32 +: 32];
    wire [32:0] chunk_sum          = {1'b0, product_chunk} + {1'b0, multiplicand_chunk} + add_carry;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            q_reg        <= 512'd0;
            multiplicand <= 1024'd0;
            product      <= 1024'd0;
            add_carry    <= 1'b0;
            chunk_idx    <= 5'd0;
            count        <= 10'd0;
            done         <= 1'b0;
            n            <= 1024'd0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        q_reg        <= q;
                        multiplicand <= {512'd0, p};
                        product      <= 1024'd0;
                        add_carry    <= 1'b0;
                        chunk_idx    <= 5'd0;
                        count        <= 10'd0;
                        state        <= CHECK;
                    end
                end

                CHECK: begin
                    if (count == 10'd512) begin
                        state <= DONE;
                    end else if (q_reg[0]) begin
                        add_carry <= 1'b0;
                        chunk_idx <= 5'd0;
                        state     <= ADD_CHUNK;
                    end else begin
                        state <= SHIFT;
                    end
                end

                ADD_CHUNK: begin
                    product[chunk_idx * 32 +: 32] <= chunk_sum[31:0];
                    add_carry <= chunk_sum[32];
                    if (chunk_idx == 5'd31) begin
                        state <= SHIFT;
                    end else begin
                        chunk_idx <= chunk_idx + 5'd1;
                    end
                end

                SHIFT: begin
                    multiplicand <= multiplicand << 1;
                    q_reg        <= q_reg >> 1;
                    count        <= count + 10'd1;
                    state        <= CHECK;
                end

                DONE: begin
                    n     <= product;
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
