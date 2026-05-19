module MontgomeryMul(
    input  wire          clk,
    input  wire          rst_n,
    input  wire          start,
    input  wire [1023:0] a,
    input  wire [1023:0] b,
    input  wire [1023:0] m,
    output reg  [1023:0] result,
    output reg           done
);

    localparam STATE_IDLE       = 4'd0;
    localparam STATE_ADD_B_INIT = 4'd1;
    localparam STATE_ADD_B      = 4'd2;
    localparam STATE_ADD_M_INIT = 4'd3;
    localparam STATE_ADD_M      = 4'd4;
    localparam STATE_SHIFT_S    = 4'd5;
    localparam STATE_NORM_INIT  = 4'd6;
    localparam STATE_CMP_CHUNK  = 4'd7;
    localparam STATE_SUB_INIT   = 4'd8;
    localparam STATE_SUB_CHUNK  = 4'd9;
    localparam STATE_DONE       = 4'd10;

    reg [3:0]    state;
    reg [1025:0] S;
    reg [1023:0] A_reg;
    reg [1023:0] B_reg;
    reg [1023:0] M_reg;
    reg [10:0]   count;

    reg [1151:0] add_accum;
    reg [1151:0] add_operand;
    reg          add_carry;
    reg          q_i_reg;
    reg          need_subtract;
    reg          sub_borrow;
    reg [5:0]    chunk_idx;
    reg [4:0]    cmp_idx;

    wire [32:0] add_sum =
        {1'b0, add_accum[chunk_idx * 32 +: 32]} +
        {1'b0, add_operand[chunk_idx * 32 +: 32]} +
        add_carry;

    wire [31:0] cmp_s_chunk = S[cmp_idx * 32 +: 32];
    wire [31:0] cmp_m_chunk = M_reg[cmp_idx * 32 +: 32];

    wire [32:0] sub_diff =
        {1'b0, S[chunk_idx * 32 +: 32]} -
        {1'b0, M_reg[chunk_idx * 32 +: 32]} -
        sub_borrow;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= STATE_IDLE;
            S             <= 1026'd0;
            A_reg         <= 1024'd0;
            B_reg         <= 1024'd0;
            M_reg         <= 1024'd0;
            count         <= 11'd0;
            add_accum     <= 1152'd0;
            add_operand   <= 1152'd0;
            add_carry     <= 1'b0;
            q_i_reg       <= 1'b0;
            need_subtract <= 1'b0;
            sub_borrow    <= 1'b0;
            chunk_idx     <= 6'd0;
            cmp_idx       <= 5'd0;
            result        <= 1024'd0;
            done          <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        A_reg <= a;
                        B_reg <= b;
                        M_reg <= m;
                        S     <= 1026'd0;
                        count <= 11'd0;
                        state <= STATE_ADD_B_INIT;
                    end
                end

                STATE_ADD_B_INIT: begin
                    if (count < 11'd1024) begin
                        q_i_reg     <= S[0] ^ (A_reg[0] & B_reg[0]);
                        add_accum   <= {126'd0, S};
                        add_operand <= A_reg[0] ? {128'd0, B_reg} : 1152'd0;
                        add_carry   <= 1'b0;
                        chunk_idx   <= 6'd0;
                        A_reg       <= A_reg >> 1;
                        state       <= STATE_ADD_B;
                    end else begin
                        state <= STATE_NORM_INIT;
                    end
                end

                STATE_ADD_B: begin
                    add_accum[chunk_idx * 32 +: 32] <= add_sum[31:0];
                    add_carry <= add_sum[32];
                    if (chunk_idx == 6'd35) begin
                        state <= STATE_ADD_M_INIT;
                    end else begin
                        chunk_idx <= chunk_idx + 6'd1;
                    end
                end

                STATE_ADD_M_INIT: begin
                    add_operand <= q_i_reg ? {128'd0, M_reg} : 1152'd0;
                    add_carry   <= 1'b0;
                    chunk_idx   <= 6'd0;
                    state       <= STATE_ADD_M;
                end

                STATE_ADD_M: begin
                    add_accum[chunk_idx * 32 +: 32] <= add_sum[31:0];
                    add_carry <= add_sum[32];
                    if (chunk_idx == 6'd35) begin
                        state <= STATE_SHIFT_S;
                    end else begin
                        chunk_idx <= chunk_idx + 6'd1;
                    end
                end

                STATE_SHIFT_S: begin
                    S     <= add_accum[1026:1];
                    count <= count + 11'd1;
                    state <= STATE_ADD_B_INIT;
                end

                STATE_NORM_INIT: begin
                    if (S[1025:1024] != 2'b00) begin
                        need_subtract <= 1'b1;
                        state         <= STATE_SUB_INIT;
                    end else begin
                        cmp_idx       <= 5'd31;
                        need_subtract <= 1'b0;
                        state         <= STATE_CMP_CHUNK;
                    end
                end

                STATE_CMP_CHUNK: begin
                    if (cmp_s_chunk > cmp_m_chunk) begin
                        need_subtract <= 1'b1;
                        state         <= STATE_SUB_INIT;
                    end else if (cmp_s_chunk < cmp_m_chunk) begin
                        result <= S[1023:0];
                        state  <= STATE_DONE;
                    end else if (cmp_idx == 5'd0) begin
                        need_subtract <= 1'b1;
                        state         <= STATE_SUB_INIT;
                    end else begin
                        cmp_idx <= cmp_idx - 5'd1;
                    end
                end

                STATE_SUB_INIT: begin
                    chunk_idx  <= 6'd0;
                    sub_borrow <= 1'b0;
                    state      <= STATE_SUB_CHUNK;
                end

                STATE_SUB_CHUNK: begin
                    result[chunk_idx * 32 +: 32] <= sub_diff[31:0];
                    sub_borrow <= sub_diff[32];
                    if (chunk_idx == 6'd31) begin
                        state <= STATE_DONE;
                    end else begin
                        chunk_idx <= chunk_idx + 6'd1;
                    end
                end

                STATE_DONE: begin
                    done  <= 1'b1;
                    state <= STATE_IDLE;
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule
