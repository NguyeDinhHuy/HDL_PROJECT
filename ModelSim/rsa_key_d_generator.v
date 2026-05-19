`timescale 1ns / 1ps

module rsa_key_d_generator (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          start,        
    input  wire [1023:0] phi,          
    
    output reg  [1023:0] private_d,    
    output reg           done,         
    output reg           phi_invalid   
);

    localparam IDLE          = 4'd0;
    localparam CALC_MOD      = 4'd1;  
    localparam CALC_INV      = 4'd2;
    localparam WAIT_INV_DIV  = 4'd3;
    localparam CALC_MULT     = 4'd4;
    localparam START_D_DIV   = 4'd5;
    localparam WAIT_D_DIV    = 4'd6;
    localparam STATE_DONE    = 4'd7;
    localparam MULT_ADD_LO   = 4'd8;
    localparam MULT_ADD_HI   = 4'd9;
    localparam MULT_SHIFT    = 4'd10;

    reg [3:0] state;                // Thanh ghi luu tru trang thai FSM
    reg [1023:0] phi_reg;           // Thanh ghi luu gia tri phi dau vao

    reg [10:0] bit_cnt;             // Bo dem quet dich bit tu 1023 lui ve 0
    reg [17:0] rem;                 // Thanh ghi so du tam thoi
    reg [17:0] rem_comp;            // Thanh ghi tinh so du ke tiep to hop

    reg signed [31:0] t;            // Thanh ghi he so t trong Euclid mo rong
    reg signed [31:0] new_t;        // Thanh ghi he so t moi cap nhat tung chu ky
    reg signed [31:0] r;            // Thanh ghi so du r trong Euclid mo rong
    reg signed [31:0] new_r;        // Thanh ghi so du r moi cap nhat tung chu ky
    reg [5:0]         inv_cnt;      // Bo dem khong che so vong lap toi da 40 chu ky

    reg [1040:0]      d_numerator;  // Thanh ghi dem luu tu so cua bieu thuc tinh d
    reg [1151:0]      mult_accum;
    reg [1151:0]      mult_phi_shift;
    reg [16:0]        mult_k;
    reg [4:0]         mult_cnt;
    reg [5:0]         mult_chunk_idx;
    reg               mult_carry;

    wire [32:0]       mult_chunk_sum =
        {1'b0, mult_accum[mult_chunk_idx * 32 +: 32]} +
        {1'b0, mult_phi_shift[mult_chunk_idx * 32 +: 32]} +
        mult_carry;

    reg inv_div_start;
    wire [31:0] inv_div_quotient;
    wire [31:0] inv_div_remainder;
    wire        inv_div_done;
    wire        inv_div_by_zero;

    reg d_div_start;
    wire [1040:0] d_div_quotient;
    wire [1040:0] d_div_remainder;
    wire          d_div_done;
    wire          d_div_by_zero;

    seq_div_unsigned #(
        .WIDTH(32),
        .COUNT_WIDTH(6)
    ) u_inv_divider (
        .clk(clk),
        .rst_n(rst_n),
        .start(inv_div_start),
        .dividend(r[31:0]),
        .divisor(new_r[31:0]),
        .quotient(inv_div_quotient),
        .remainder(inv_div_remainder),
        .done(inv_div_done),
        .divide_by_zero(inv_div_by_zero)
    );

    seq_div_unsigned #(
        .WIDTH(1041),
        .COUNT_WIDTH(11)
    ) u_d_divider (
        .clk(clk),
        .rst_n(rst_n),
        .start(d_div_start),
        .dividend(d_numerator),
        .divisor(1041'd65537),
        .quotient(d_div_quotient),
        .remainder(d_div_remainder),
        .done(d_div_done),
        .divide_by_zero(d_div_by_zero)
    );

    always @(*) begin
        rem_comp = {rem[16:0], phi_reg[bit_cnt]};
        if (rem_comp >= 18'd65537) begin
            rem_comp = rem_comp - 18'd65537;
        end
    end

    wire signed [31:0] comb_final_t       = (t < 32'sd0) ? (t + 32'sd65537) : t;
    wire [16:0]        comb_phi_mod_e_inv = comb_final_t[16:0];
    wire [16:0]        comb_key_k         = (comb_phi_mod_e_inv == 17'd0) ? 17'd0 : (17'd65537 - comb_phi_mod_e_inv);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            phi_reg      <= 1024'd0;
            private_d    <= 1024'd0;
            done         <= 1'b0;
            phi_invalid  <= 1'b0;
            bit_cnt      <= 11'd0;
            rem          <= 18'd0;
            t            <= 32'sd0;
            new_t        <= 32'sd0;
            r            <= 32'sd0;
            new_r        <= 32'sd0;
            inv_cnt      <= 6'd0;
            d_numerator  <= 1041'd0;
            mult_accum   <= 1152'd0;
            mult_phi_shift <= 1152'd0;
            mult_k       <= 17'd0;
            mult_cnt     <= 5'd0;
            mult_chunk_idx <= 6'd0;
            mult_carry   <= 1'b0;
            inv_div_start <= 1'b0;
            d_div_start   <= 1'b0;
        end else begin
            inv_div_start <= 1'b0;
            d_div_start   <= 1'b0;

            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        phi_reg     <= phi;
                        rem         <= 18'd0;
                        bit_cnt     <= 11'd1023; 
                        phi_invalid <= 1'b0;
                        state       <= CALC_MOD;
                    end
                end

                CALC_MOD: begin
                    rem <= rem_comp;
                    if (bit_cnt == 11'd0) begin
                        if (rem_comp == 18'd0) begin 
                            phi_invalid <= 1'b1;
                            private_d   <= 1024'd0;
                            state       <= STATE_DONE;
                        end else begin
                            t       <= 32'sd0;
                            new_t   <= 32'sd1;
                            r       <= 32'sd65537;
                            new_r   <= $signed({15'd0, rem_comp[16:0]});
                            inv_cnt <= 6'd0;
                            state   <= CALC_INV;
                        end
                    end else begin
                        bit_cnt <= bit_cnt - 1'b1; 
                    end
                end

                CALC_INV: begin
                    if (new_r != 32'sd0 && inv_cnt < 6'd40) begin 
                        inv_div_start <= 1'b1;
                        state         <= WAIT_INV_DIV;
                    end else begin
                        if (r > 32'sd1) begin
                            phi_invalid <= 1'b1;
                            private_d   <= 1024'd0;
                            state       <= STATE_DONE;
                        end else begin
                            state       <= CALC_MULT; 
                        end
                    end
                end

                WAIT_INV_DIV: begin
                    if (inv_div_done) begin
                        t       <= new_t;
                        new_t   <= t - $signed(inv_div_quotient) * new_t;
                        r       <= new_r;
                        new_r   <= r - $signed(inv_div_quotient) * new_r;
                        inv_cnt <= inv_cnt + 1'b1;
                        state   <= CALC_INV;
                    end
                end

                CALC_MULT: begin
                    mult_accum     <= 1152'd1;
                    mult_phi_shift <= {111'd0, 17'd0, phi_reg};
                    mult_k         <= comb_key_k;
                    mult_cnt       <= 5'd0;
                    state          <= MULT_ADD_LO;
                end

                MULT_ADD_LO: begin
                    if (mult_cnt == 5'd17) begin
                        d_numerator <= mult_accum[1040:0];
                        state       <= START_D_DIV;
                    end else if (mult_k[0]) begin
                        mult_chunk_idx <= 6'd0;
                        mult_carry     <= 1'b0;
                        state          <= MULT_ADD_HI;
                    end else begin
                        state <= MULT_SHIFT;
                    end
                end

                MULT_ADD_HI: begin
                    mult_accum[mult_chunk_idx * 32 +: 32] <= mult_chunk_sum[31:0];
                    mult_carry <= mult_chunk_sum[32];
                    if (mult_chunk_idx == 6'd35) begin
                        state <= MULT_SHIFT;
                    end else begin
                        mult_chunk_idx <= mult_chunk_idx + 6'd1;
                    end
                end

                MULT_SHIFT: begin
                    mult_phi_shift <= mult_phi_shift << 1;
                    mult_k         <= mult_k >> 1;
                    mult_cnt       <= mult_cnt + 5'd1;
                    state          <= MULT_ADD_LO;
                end

                START_D_DIV: begin
                    d_div_start <= 1'b1;
                    state       <= WAIT_D_DIV;
                end

                WAIT_D_DIV: begin
                    if (d_div_done) begin
                        private_d <= d_div_quotient[1023:0];
                        state     <= STATE_DONE;
                    end
                end

                STATE_DONE: begin
                    done  <= 1'b1;
                    state <= IDLE; 
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
