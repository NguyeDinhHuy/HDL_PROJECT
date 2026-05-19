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

    localparam IDLE        = 3'd0;
    localparam CALC_MOD    = 3'd1;  
    localparam CALC_INV    = 3'd2;  
    localparam CALC_MULT   = 3'd3;  
    localparam CALC_DIV    = 3'd4;  
    localparam STATE_DONE  = 3'd5;

    reg [2:0] state;                // Thanh ghi luu tru trang thai FSM
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

    wire signed [31:0] quotient = (new_r != 32'sd0) ? (r / new_r) : 32'sd0;

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
        end else begin
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
                        t       <= new_t;
                        new_t   <= t - quotient * new_t;
                        r       <= new_r;
                        new_r   <= r - quotient * new_r;
                        inv_cnt <= inv_cnt + 1'b1;
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

                CALC_MULT: begin
                    d_numerator <= ({17'd0, phi_reg} * comb_key_k) + 1041'd1;
                    state       <= CALC_DIV; 
                end

                CALC_DIV: begin
                    private_d   <= d_numerator / 17'd65537;
                    state       <= STATE_DONE;
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