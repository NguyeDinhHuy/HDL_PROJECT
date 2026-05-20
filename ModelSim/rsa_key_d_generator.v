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
    localparam PREP_D_CALC   = 4'd4;
    localparam GEN_LOAD      = 4'd5;
    localparam GEN_PRODUCT   = 4'd6;
    localparam DIVIDE_D      = 4'd7;
    localparam STATE_DONE    = 4'd8;

    reg [3:0] state;                // Thanh ghi luu tru trang thai FSM
    reg [1023:0] phi_reg;           // Thanh ghi luu gia tri phi dau vao
    reg [1023:0] phi_mod_shift;

    reg [10:0] bit_cnt;             // Bo dem quet dich bit tu 1023 lui ve 0
    reg [17:0] rem;                 // Thanh ghi so du tam thoi
    reg [17:0] rem_comp;            // Thanh ghi tinh so du ke tiep to hop

    reg signed [31:0] t;            // Thanh ghi he so t trong Euclid mo rong
    reg signed [31:0] new_t;        // Thanh ghi he so t moi cap nhat tung chu ky
    reg signed [31:0] r;            // Thanh ghi so du r trong Euclid mo rong
    reg signed [31:0] new_r;        // Thanh ghi so du r moi cap nhat tung chu ky
    reg [5:0]         inv_cnt;      // Bo dem khong che so vong lap toi da 40 chu ky

    reg [16:0]        key_k;        // He so k thoa man (k * phi + 1) chia het cho e
    reg [1040:0]      numerator_shift_reg;
    reg [1023:0]      phi_shift_reg;
    reg [16:0]        phi_window;
    reg [10:0]        prod_idx;
    reg [10:0]        div_idx;
    reg [5:0]         prod_carry;
    reg [17:0]        div_rem;

    reg inv_div_start;
    wire [31:0] inv_div_quotient;
    wire [31:0] inv_div_remainder;
    wire        inv_div_done;
    wire        inv_div_by_zero;

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

    always @(*) begin
        rem_comp = {rem[16:0], phi_mod_shift[1023]};
        if (rem_comp >= 18'd65537) begin
            rem_comp = rem_comp - 18'd65537;
        end
    end

    wire signed [31:0] comb_final_t       = (t < 32'sd0) ? (t + 32'sd65537) : t;
    wire [16:0]        comb_phi_mod_e_inv = comb_final_t[16:0];
    wire [16:0]        comb_key_k         = (comb_phi_mod_e_inv == 17'd0) ? 17'd0 : (17'd65537 - comb_phi_mod_e_inv);
    wire               current_phi_bit    = (prod_idx < 11'd1024) ? phi_shift_reg[0] : 1'b0;
    wire [5:0]         prod_sum           = prod_carry + window_sum(phi_window, key_k);
    wire [17:0]        div_shifted        = {div_rem[16:0], numerator_shift_reg[1040]};
    wire               div_can_subtract   = (div_shifted >= 18'd65537);
    wire [17:0]        div_next_rem       = div_can_subtract ? (div_shifted - 18'd65537) : div_shifted;

    function [5:0] window_sum;
        input [16:0] phi_bits;
        input [16:0] key_bits;
        integer i;
        begin
            window_sum = 6'd0;
            for (i = 0; i < 17; i = i + 1) begin
                if (key_bits[i] && phi_bits[i]) begin
                    window_sum = window_sum + 1'b1;
                end
            end
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            phi_reg      <= 1024'd0;
            phi_mod_shift <= 1024'd0;
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
            inv_div_start <= 1'b0;
            key_k        <= 17'd0;
            numerator_shift_reg <= 1041'd0;
            phi_shift_reg <= 1024'd0;
            phi_window    <= 17'd0;
            prod_idx     <= 11'd0;
            div_idx      <= 11'd0;
            prod_carry   <= 6'd0;
            div_rem      <= 18'd0;
        end else begin
            inv_div_start <= 1'b0;

            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        phi_reg     <= phi;
                        phi_mod_shift <= phi;
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
                        phi_mod_shift <= phi_mod_shift << 1;
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
                            state       <= PREP_D_CALC; 
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

                PREP_D_CALC: begin
                    key_k          <= comb_key_k;
                    numerator_shift_reg <= 1041'd0;
                    phi_shift_reg  <= phi_reg;
                    phi_window     <= 17'd0;
                    prod_idx       <= 11'd0;
                    prod_carry     <= 6'd1;
                    state          <= GEN_LOAD;
                end

                GEN_LOAD: begin
                    phi_window <= {phi_window[15:0], current_phi_bit};
                    if (prod_idx < 11'd1024) begin
                        phi_shift_reg <= phi_shift_reg >> 1;
                    end
                    state <= GEN_PRODUCT;
                end

                GEN_PRODUCT: begin
                    numerator_shift_reg <= {prod_sum[0], numerator_shift_reg[1040:1]};
                    prod_carry <= {1'b0, prod_sum[5:1]};

                    if (prod_idx == 11'd1040) begin
                        private_d <= 1024'd0;
                        div_rem   <= 18'd0;
                        div_idx   <= 11'd1040;
                        state     <= DIVIDE_D;
                    end else begin
                        prod_idx <= prod_idx + 1'b1;
                        state    <= GEN_LOAD;
                    end
                end

                DIVIDE_D: begin
                    div_rem <= div_next_rem;
                    numerator_shift_reg <= {numerator_shift_reg[1039:0], 1'b0};
                    if (div_idx <= 11'd1023) begin
                        private_d <= {private_d[1022:0], div_can_subtract};
                    end

                    if (div_idx == 11'd0) begin
                        state     <= STATE_DONE;
                    end else begin
                        div_idx <= div_idx - 1'b1;
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
