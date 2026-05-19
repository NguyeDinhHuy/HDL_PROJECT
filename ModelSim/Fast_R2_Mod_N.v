module Fast_R2_Mod_N (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          start,
    input  wire [1023:0] n,

    output reg  [1023:0] r2_mod_n,
    output reg           done
);

    localparam IDLE     = 4'd0;
    localparam PREP     = 4'd1;
    localparam CMP_INIT = 4'd2;
    localparam CMP      = 4'd3;
    localparam SUB_INIT = 4'd4;
    localparam SUB      = 4'd5;
    localparam CALC     = 4'd6;
    localparam DONE     = 4'd7;

    localparam PAD_WIDTH = 1152;
    localparam LAST_CHUNK = 6'd35;

    reg [3:0]    state;
    reg [11:0]   count;
    reg [1024:0] V;
    reg [PAD_WIDTH-1:0] V_shifted_pad;
    reg [PAD_WIDTH-1:0] n_pad;
    reg [PAD_WIDTH-1:0] V_sub_pad;
    reg                 is_greater_or_equal_reg;
    reg                 sub_borrow;
    reg [5:0]           chunk_idx;
    reg [5:0]           cmp_idx;

    wire [31:0] cmp_v_chunk = V_shifted_pad[cmp_idx * 32 +: 32];
    wire [31:0] cmp_n_chunk = n_pad[cmp_idx * 32 +: 32];

    wire [32:0] sub_diff =
        {1'b0, V_shifted_pad[chunk_idx * 32 +: 32]} -
        {1'b0, n_pad[chunk_idx * 32 +: 32]} -
        sub_borrow;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state                   <= IDLE;
            V                       <= 1025'd0;
            V_shifted_pad           <= {PAD_WIDTH{1'b0}};
            n_pad                   <= {PAD_WIDTH{1'b0}};
            V_sub_pad               <= {PAD_WIDTH{1'b0}};
            is_greater_or_equal_reg <= 1'b0;
            sub_borrow              <= 1'b0;
            chunk_idx               <= 6'd0;
            cmp_idx                 <= 6'd0;
            count                   <= 12'd0;
            r2_mod_n                <= 1024'd0;
            done                    <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        V             <= 1025'd1;
                        V_shifted_pad <= {PAD_WIDTH{1'b0}};
                        n_pad         <= {127'd0, 1'b0, n};
                        V_sub_pad     <= {PAD_WIDTH{1'b0}};
                        count         <= 12'd0;
                        state         <= PREP;
                    end
                end

                PREP: begin
                    if (count < 12'd2048) begin
                        V_shifted_pad <= {126'd0, V, 1'b0};
                        state         <= CMP_INIT;
                    end else begin
                        state <= DONE;
                    end
                end

                CMP_INIT: begin
                    cmp_idx                 <= LAST_CHUNK;
                    is_greater_or_equal_reg <= 1'b0;
                    state                   <= CMP;
                end

                CMP: begin
                    if (cmp_v_chunk > cmp_n_chunk) begin
                        is_greater_or_equal_reg <= 1'b1;
                        state                   <= SUB_INIT;
                    end else if (cmp_v_chunk < cmp_n_chunk) begin
                        is_greater_or_equal_reg <= 1'b0;
                        V_sub_pad               <= V_shifted_pad;
                        state                   <= CALC;
                    end else if (cmp_idx == 6'd0) begin
                        is_greater_or_equal_reg <= 1'b1;
                        state                   <= SUB_INIT;
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
                    V_sub_pad[chunk_idx * 32 +: 32] <= sub_diff[31:0];
                    sub_borrow <= sub_diff[32];
                    if (chunk_idx == LAST_CHUNK) begin
                        state <= CALC;
                    end else begin
                        chunk_idx <= chunk_idx + 6'd1;
                    end
                end

                CALC: begin
                    V     <= V_sub_pad[1024:0];
                    count <= count + 1'b1;
                    state <= PREP;
                end

                DONE: begin
                    r2_mod_n <= V[1023:0];
                    done     <= 1'b1;
                    state    <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
