module Fast_R2_Mod_N (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          start,
    input  wire [1023:0] n,

    output reg  [1023:0] r2_mod_n,
    output reg           done
);

    localparam CHUNK_WIDTH = 32;
    localparam CHUNK_COUNT = 33; // 1025 bit, padded to 33 x 32-bit words

    localparam IDLE        = 4'd0;
    localparam INIT_WORK   = 4'd1;
    localparam LOAD_N      = 4'd2;
    localparam SHIFT       = 4'd3;
    localparam SHIFT_WRITE = 4'd4;
    localparam CMP_READ    = 4'd5;
    localparam CMP_UPDATE  = 4'd6;
    localparam SUB_READ    = 4'd7;
    localparam SUB_WRITE   = 4'd8;
    localparam PACK        = 4'd9;
    localparam FINISH      = 4'd10;

    reg [3:0]  state;
    reg [11:0] count;
    reg [5:0]  word_idx;
    reg        cmp_decided;
    reg        cmp_ge;
    reg        borrow;
    reg        shift_carry;
    reg [31:0] work_read;
    reg [31:0] n_read;

    reg [CHUNK_WIDTH-1:0] work_words [0:CHUNK_COUNT-1];
    reg [CHUNK_WIDTH-1:0] n_words    [0:CHUNK_COUNT-1];

    wire [32:0] sub_word = {1'b0, work_read} - {1'b0, n_read} - borrow;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            count       <= 12'd0;
            word_idx    <= 6'd0;
            cmp_decided <= 1'b0;
            cmp_ge      <= 1'b0;
            borrow      <= 1'b0;
            shift_carry <= 1'b0;
            work_read   <= 32'd0;
            n_read      <= 32'd0;
            r2_mod_n    <= 1024'd0;
            done        <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        count       <= 12'd0;
                        word_idx    <= 6'd0;
                        cmp_decided <= 1'b0;
                        cmp_ge      <= 1'b0;
                        borrow      <= 1'b0;
                        shift_carry <= 1'b0;
                        r2_mod_n    <= 1024'd0;
                        state       <= INIT_WORK;
                    end
                end

                INIT_WORK: begin
                    work_words[word_idx] <= (word_idx == 6'd0) ? 32'd1 : 32'd0;

                    if (word_idx == 6'd32) begin
                        word_idx <= 6'd0;
                        state    <= LOAD_N;
                    end else begin
                        word_idx <= word_idx + 1'b1;
                    end
                end

                LOAD_N: begin
                    if (word_idx == 6'd32) begin
                        n_words[word_idx] <= 32'd0;
                        word_idx          <= 6'd0;
                        state             <= SHIFT;
                    end else begin
                        n_words[word_idx] <= n[word_idx * CHUNK_WIDTH +: CHUNK_WIDTH];
                        word_idx          <= word_idx + 1'b1;
                    end
                end

                SHIFT: begin
                    if (count == 12'd2048) begin
                        word_idx <= 6'd0;
                        state    <= PACK;
                    end else begin
                        word_idx    <= 6'd0;
                        shift_carry <= 1'b0;
                        state       <= SHIFT_WRITE;
                    end
                end

                SHIFT_WRITE: begin
                    work_read <= work_words[word_idx];
                    work_words[word_idx] <= {work_words[word_idx][30:0], shift_carry};
                    shift_carry <= work_words[word_idx][31];

                    if (word_idx == 6'd32) begin
                        word_idx    <= 6'd32;
                        cmp_decided <= 1'b0;
                        cmp_ge      <= 1'b1;
                        state       <= CMP_READ;
                    end else begin
                        word_idx <= word_idx + 1'b1;
                    end
                end

                CMP_READ: begin
                    work_read <= work_words[word_idx];
                    n_read    <= n_words[word_idx];
                    state     <= CMP_UPDATE;
                end

                CMP_UPDATE: begin
                    if (!cmp_decided) begin
                        if (work_read > n_read) begin
                            cmp_ge      <= 1'b1;
                            cmp_decided <= 1'b1;
                        end else if (work_read < n_read) begin
                            cmp_ge      <= 1'b0;
                            cmp_decided <= 1'b1;
                        end
                    end

                    if (word_idx == 6'd0) begin
                        if (!cmp_decided) begin
                            cmp_ge <= (work_read >= n_read);
                        end

                        if ((!cmp_decided && (work_read >= n_read)) || (cmp_decided && cmp_ge)) begin
                            word_idx <= 6'd0;
                            borrow   <= 1'b0;
                            state    <= SUB_READ;
                        end else begin
                            count <= count + 1'b1;
                            state <= SHIFT;
                        end
                    end else begin
                        word_idx <= word_idx - 1'b1;
                        state    <= CMP_READ;
                    end
                end

                SUB_READ: begin
                    work_read <= work_words[word_idx];
                    n_read    <= n_words[word_idx];
                    state     <= SUB_WRITE;
                end

                SUB_WRITE: begin
                    work_words[word_idx] <= sub_word[31:0];
                    borrow <= sub_word[32];

                    if (word_idx == 6'd32) begin
                        count <= count + 1'b1;
                        state <= SHIFT;
                    end else begin
                        word_idx <= word_idx + 1'b1;
                        state    <= SUB_READ;
                    end
                end

                PACK: begin
                    r2_mod_n[word_idx * CHUNK_WIDTH +: CHUNK_WIDTH] <= work_words[word_idx];

                    if (word_idx == 6'd31) begin
                        state <= FINISH;
                    end else begin
                        word_idx <= word_idx + 1'b1;
                    end
                end

                FINISH: begin
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
