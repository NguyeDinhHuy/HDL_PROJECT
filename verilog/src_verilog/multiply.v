module multiply
(
  input               start, clk, rst_n,
  input       [7 : 0] x, y,
  output reg  [7 : 0] result,
  output reg          done
);

wire  [7 : 0] shifted;
reg   [7 : 0] value, factor; 
parameter IDLE = 2'b00;
parameter RUN  = 2'b01;
parameter DONE = 2'b10;

reg [1 : 0] cur_state, next_state;

always @(*)
begin
  case(cur_state)
    IDLE:
      next_state = start ? RUN : IDLE;
    RUN:
      next_state = factor ? RUN : DONE;
    DONE:
      next_state = IDLE;
    default:
      next_state = cur_state;
    endcase
end

always @(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    begin
      cur_state = IDLE;
    end
    else
      begin
        cur_state <= next_state;
      end
end

always @(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    begin
      result  <= 0;
      done    <= 0;
      factor  <= 0;
      value   <= 0;
    end
    else
      begin
        if(cur_state == IDLE)
          begin
            result  <= 0;
            done    <= 0;
            if(start)
              begin
                factor  <= y;
                value   <= x;
              end
          end
          else
            begin
              if(cur_state == RUN)
                begin
                  if(factor != 0)
                    begin
                      if(factor[0]) result <= result ^ value;
                        value <= shifted;
                        factor <= factor >> 1;
                    end
                end
                else
                  begin
                    if(cur_state == DONE)
                      begin
                        done <= 1;
                      end
                  end
              end 
      end
end

xtime xtime1
(
  .iData    (value),
  .shifted  (shifted)
);

endmodule