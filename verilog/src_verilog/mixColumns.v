module mixColumns
(
  input start, rst_n, clk,
  input [7 : 0] iData,
  output reg [7 : 0] oData,
  output reg done, we,
  output reg [3 : 0] r_address, w_address         
);

parameter IDLE = 2'b00;
parameter RUN  = 2'b01;
parameter DONE = 2'b10;

reg [7 : 0] w0, w1;

wire [7 : 0] result_multiply1, result_multiply2;
reg valid, valid_index, valid_index_1, valid_index_2, valid_index_3;
reg finish;
reg finish_write_index, finish_write_index_1, finish_write_index_2, finish_write_index_3;
reg valid_wait_s0, valid_wait_s1, valid_wait_s2, valid_wait_s3;
reg valid_s0, valid_s1, valid_s2, valid_s3;
reg start_multiply;
wire done_multiply1, done_multiply2;
reg waiting_multiply, waiting_multiply1, waiting_multiply2, waiting_multiply3;

wire [3 : 0] index;

reg [1 : 0] cur_state, next_state;

reg [7 : 0] s0, s1, s2, s3;

reg [1 : 0] col;

assign index = col * 4;

always @(*)
begin
  case(cur_state)
    IDLE:
      next_state = start ? RUN : IDLE;
    RUN:
      next_state = (finish && finish_write_index_3) ? DONE : RUN;
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
      cur_state <= IDLE;
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
        col <= 0;
        valid <= 0;  
        finish <= 0;
        done <= 0;
      end
      else
        begin
          if(cur_state == IDLE)
            begin
              col <= 0;
              finish <= 0;
              done <=0;
              if(start) valid <= 1;
            end
            else
              begin
                if(cur_state == RUN)
                  begin
                    if(col < 3)
                      begin
                        if(finish_write_index_3)
                          begin
                            col <= col + 1;
                            valid <= 1;
                          end
                        else valid <= 0;
                      end
                      else
                        begin
                          finish  <= 1;
                          valid <= 0;
                        end
                  end
                  else
                    begin
                      if(cur_state == DONE)
                        begin
                          done <= 1;
                          valid <= 0;
                        end
                    end
              end
        end
end

//read
always @(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    begin
        valid_index   <= 0;
        valid_index_1 <= 0;
        valid_index_2 <= 0;
        valid_index_3 <= 0;
        r_address     <= 0;
    end
    else
      begin
        if(cur_state == IDLE)
          begin
            valid_index   <= 0;
            valid_index_1 <= 0;
            valid_index_2 <= 0;
            valid_index_3 <= 0;
            r_address     <= 0;
          end
          else
            begin
              if(cur_state === RUN)
                begin
                  valid_index   <= 0;
                  valid_index_1 <= 0;
                  valid_index_2 <= 0;
                  valid_index_3 <= 0;
                  if(valid)
                    begin
                      valid_index <= 1;
                      r_address   <= index;
                    end
        
                  if(valid_index)
                    begin
                      r_address     <= r_address + 1;
                      valid_index_1 <= 1; 
                    end
          
                  if(valid_index_1)
                    begin
                      r_address     <= r_address + 1;
                      valid_index_2 <= 1;
                    end
        
                  if(valid_index_2)
                    begin
                      r_address     <= r_address + 1;
                      valid_index_3 <= 1;
                    end
                end
                else
                  if(cur_state == DONE)
                    begin
                      
                    end
            end
      end
      
end

//wait
always @(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    begin
      valid_wait_s0 <= 0;
      valid_wait_s1 <= 0;
      valid_wait_s2 <= 0;
      valid_wait_s3 <= 0;
    end
    else
      begin
        if(cur_state == IDLE)
          begin
            valid_wait_s0   <= 0;
            valid_wait_s1 <= 0;
            valid_wait_s2 <= 0;
            valid_wait_s3 <= 0;
          end
          else
            begin
              if(cur_state === RUN)
                begin
                  
                  valid_wait_s0 <= 0;
                  valid_wait_s1 <= 0;
                  valid_wait_s2 <= 0;
                  valid_wait_s3 <= 0;
                  if(valid_index)   valid_wait_s0 <= 1;
                  if(valid_index_1) valid_wait_s1 <= 1;
                  if(valid_index_2) valid_wait_s2 <= 1;
                  if(valid_index_3) valid_wait_s3 <= 1; 
                end
                else
                  if(cur_state == DONE)
                    begin
                      
                    end
            end
      end
      
end

//write s0, s1, s2, s3
always @(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    begin
        valid_s0 <= 0;
        valid_s1 <= 0;
        valid_s2 <= 0;
        valid_s3 <= 0;
        s0 <= 0;
        s1 <= 0;
        s2 <= 0;
        s3 <= 0;
    end
    else
      begin
        if(cur_state == IDLE)
          begin
            valid_s0 <= 0;
            valid_s1 <= 0;
            valid_s2 <= 0;
            valid_s3 <= 0;
            s0 <= 0;
            s1 <= 0;
            s2 <= 0;
            s3 <= 0;
          end
          else
            begin
              if(cur_state === RUN)
                begin
                  valid_s3 <= 0;
                  if(valid_wait_s0) 
                    begin
                      s0 <= iData;
                    end
                  if(valid_wait_s1)
                    begin
                      s1 <= iData;
                    end
                  if(valid_wait_s2)
                    begin
                      s2 <= iData;
                    end 
                  if(valid_wait_s3)
                    begin
                      s3 <= iData;
                      valid_s3 <= 1;
                    end 
                end
                else
                  if(cur_state == DONE)
                    begin
                      
                    end
            end
      end
end

always @(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    begin
      start_multiply        <= 0;
      waiting_multiply     <= 0;
      waiting_multiply1    <= 0;
      waiting_multiply2    <= 0;
      waiting_multiply3    <= 0;
      we                    <= 0;
      finish_write_index    <= 0;
      finish_write_index_1  <= 0;
      finish_write_index_2  <= 0;
      finish_write_index_3  <= 0;
    end
    else
      begin
        if(cur_state == IDLE)
          begin
            start_multiply        <= 0;
            waiting_multiply     <= 0;
            waiting_multiply1    <= 0;
            waiting_multiply2    <= 0;
            waiting_multiply3    <= 0;
            we                    <= 0;
            finish_write_index    <= 0;
            finish_write_index_1  <= 0;
            finish_write_index_2  <= 0;
            finish_write_index_3  <= 0;
          end
          else
            begin
              if(cur_state === RUN)
                begin
                  start_multiply        <= 0;
                  we                    <= 0;
                  finish_write_index    <= 0;
                  finish_write_index_1  <= 0;
                  finish_write_index_2  <= 0;
                  finish_write_index_3  <= 0;
                  if(valid_s3 || waiting_multiply)
                  begin
                    w0 <= s0;
                    w1 <= s1;
                    if(waiting_multiply && !valid_s3) start_multiply <= 0;
                      else start_multiply <= 1;
                    waiting_multiply <= 1;
                    if(done_multiply1 && done_multiply2)
                      begin
                        oData     <= result_multiply1 ^ result_multiply2 ^ s2 ^ s3;
                        we        <= 1;
                        w_address <= index;
                        finish_write_index <= 1;
                        waiting_multiply <= 0;
                      end
                  end
                  else
                    begin
                      if(finish_write_index || waiting_multiply1)
                        begin
                          w0 <= s1;
                          w1 <= s2;
                          if(waiting_multiply1) start_multiply <= 0;
                            else start_multiply <= 1;
                          waiting_multiply1 <= 1;
                          if(done_multiply1 && done_multiply2)
                            begin
                              oData     <= s0 ^ result_multiply1 ^ result_multiply2 ^ s3;
                              we        <= 1;
                              w_address <= w_address + 1;
                              finish_write_index_1 <= 1;
                              waiting_multiply1 <= 0;
                            end
                        end
                        else
                          begin
                            if(finish_write_index_1 || waiting_multiply2)
                              begin
                                w0 <= s2;
                                w1 <= s3;
                                if(waiting_multiply2) start_multiply <= 0;
                                  else start_multiply <= 1;
                                waiting_multiply2 <= 1;
                                if(done_multiply1 && done_multiply2)
                                  begin
                                    oData     <= s0 ^ s1 ^ result_multiply1 ^ result_multiply2;
                                    we        <= 1;
                                    w_address <= w_address + 1;
                                    finish_write_index_2 <= 1;
                                    waiting_multiply2 <= 0;
                                  end
                              end
                              else
                                begin
                                  if(finish_write_index_2 || waiting_multiply3)
                                    begin
                                      w0 <= s3;
                                      w1 <= s0;
                                      if(waiting_multiply3) start_multiply <= 0;
                                        else start_multiply <= 1;
                                      waiting_multiply3 <= 1;
                                      if(done_multiply1 && done_multiply2)
                                        begin
                                          oData     <= result_multiply1 ^ s1 ^ s2 ^ result_multiply2;
                                          we        <= 1;
                                          w_address <= w_address + 1;
                                          finish_write_index_3 <= 1;
                                          waiting_multiply3 <= 0;
                                        end
                                  end
                              end
                          end      
                    end  
                end
                else
                  if(cur_state == DONE)
                    begin
                      we        <= 0;
                    end
            end
      end
end

multiply mul1
(
  .start  (start_multiply),
  .done   (done_multiply1),
  .rst_n  (rst_n),
  .clk    (clk),
  .x      (w0),
  .y      (8'd2),
  .result (result_multiply1)
);

multiply mul2
(
  .start  (start_multiply),
  .done   (done_multiply2),
  .rst_n  (rst_n),
  .clk    (clk),
  .x      (w1),
  .y      (8'd3),
  .result (result_multiply2)
);

endmodule