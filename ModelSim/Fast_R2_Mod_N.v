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

    localparam IDLE       = 3'd0;
    localparam SHIFT      = 3'd1;
    localparam CMP_READ   = 3'd2;
    localparam CMP_UPDATE = 3'd3;
    localparam SUB_READ   = 3'd4;
    localparam SUB_WRITE  = 3'd5;
    localparam FINISH     = 3'd6;

    reg [2:0]  state;
    reg [11:0] count;
    reg [5:0]  word_idx;
    reg        cmp_decided;
    reg        cmp_ge;
    reg        borrow;
    reg [31:0] work_read;
    reg [31:0] n_read;

    reg [CHUNK_WIDTH-1:0] work_words [0:CHUNK_COUNT-1];
    reg [CHUNK_WIDTH-1:0] n_words    [0:CHUNK_COUNT-1];

    wire [32:0] sub_word = {1'b0, work_read} - {1'b0, n_read} - borrow;

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            count       <= 12'd0;
            word_idx    <= 6'd0;
            cmp_decided <= 1'b0;
            cmp_ge      <= 1'b0;
            borrow      <= 1'b0;
            work_read   <= 32'd0;
            n_read      <= 32'd0;
            r2_mod_n    <= 1024'd0;
            done        <= 1'b0;

            for (i = 0; i < CHUNK_COUNT; i = i + 1) begin
                work_words[i] <= 32'd0;
                n_words[i]    <= 32'd0;
            end
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
                        r2_mod_n    <= 1024'd0;

                        work_words[0] <= 32'd1;
                        for (i = 1; i < CHUNK_COUNT; i = i + 1) begin
                            work_words[i] <= 32'd0;
                        end

                        for (i = 0; i < 32; i = i + 1) begin
                            n_words[i] <= n[i * CHUNK_WIDTH +: CHUNK_WIDTH];
                        end
                        n_words[32] <= 32'd0;

                        state <= SHIFT;
                    end
                end

                SHIFT: begin
                    if (count == 12'd2048) begin
                        for (i = 0; i < 32; i = i + 1) begin
                            r2_mod_n[i * CHUNK_WIDTH +: CHUNK_WIDTH] <= work_words[i];
                        end
                        state <= FINISH;
                    end else begin
                        work_words[0] <= {work_words[0][30:0], 1'b0};
                        for (i = 1; i < CHUNK_COUNT; i = i + 1) begin
                            work_words[i] <= {work_words[i][30:0], work_words[i-1][31]};
                        end

                        word_idx    <= 6'd32;
                        cmp_decided <= 1'b0;
                        cmp_ge      <= 1'b1;
                        state       <= CMP_READ;
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

                FINISH: begin
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
