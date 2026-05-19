module Fast_R2_Mod_N (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          start,
    input  wire [1023:0] n,

    output reg  [1023:0] r2_mod_n,
    output reg           done
);

    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;

    reg [1:0]    state;
    reg [11:0]   count;
    reg [1024:0] V;

    wire [1024:0] V_shifted = V << 1;
    wire [1024:0] n_extended = {1'b0, n};
    wire          is_greater_or_equal = (V_shifted >= n_extended);
    wire [1024:0] V_next = is_greater_or_equal ? (V_shifted - n_extended) : V_shifted;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= IDLE;
            V        <= 1025'd0;
            count    <= 12'd0;
            r2_mod_n <= 1024'd0;
            done     <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        V     <= 1025'd1;
                        count <= 12'd0;
                        state <= CALC;
                    end
                end

                CALC: begin
                    if (count < 12'd2048) begin
                        V     <= V_next;
                        count <= count + 1'b1;
                    end else begin
                        state <= DONE;
                    end
                end

                DONE: begin
                    r2_mod_n <= V[1023:0];
                    done     <= 1'b1;
                    state    <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
