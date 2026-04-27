module mul_512_bit (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [511:0] a,
    input  wire [511:0] b,
    output reg  [1023:0] result,
    output reg  done
); 
    reg [1026:0] temp_result; 
    reg [8:0]    count;       

    reg [513:0] b_x3;

    // Bộ MUX chọn giá trị cộng 
    reg [513:0] add_val;
    always @(*) begin
        case (temp_result[1:0])
            2'b00: add_val = 514'd0;                           // + 0
            2'b01: add_val = {2'b00, b};                       // + 1*b
            2'b10: add_val = {1'b0, b, 1'b0};                  // + 2*b 
            2'b11: add_val = b_x3;                             // + 3*b
        endcase
    end


    wire [514:0] sum = temp_result[1026:512] + add_val;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            temp_result <= 1027'b0;
            count       <= 9'd0;
            done        <= 1'b0;
            result      <= 1024'b0;
            b_x3        <= 514'b0;
        end else if (start) begin
            temp_result <= {515'b0, a};
            
            b_x3  <= {1'b0, b, 1'b0} + {2'b00, b}; 
            
            count       <= 9'd0;
            done        <= 1'b0;
        end else if (!done) begin
            if (count < 9'd256) begin
                
                temp_result <= {2'b00, sum, temp_result[511:2]};
                
                count <= count + 1'b1;
            end else begin
                result <= temp_result[1023:0]; 
                done   <= 1'b1;
            end
        end
    end
endmodule