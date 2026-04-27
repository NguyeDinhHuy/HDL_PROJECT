module shiftRows
(
    input                 clk,
    input                 start,
    input                 rst_n,
    input       [7 : 0]   iData,
    output  reg [3 : 0]   r_address, w_address,
    output  reg           done,we,
    output  reg [7 : 0]   oData
);

parameter IDLE  = 2'b00;
parameter RUN = 2'b01;
parameter DONE  = 2'b10;

reg [1 : 0] cur_state, next_state;

reg [3 : 0] w_address0;
reg valid_input, valid_wait;

reg finish, finish1, finish2;

always @(*)
begin
  case(cur_state)
    IDLE:
      next_state = start ? RUN : IDLE;
    RUN:
      next_state = finish2 ? DONE : RUN;
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
      w_address0 <= 0;
    end
    else
      begin
        case(r_address)
          4'd0:
            w_address0 <= 0;
          4'd1:
            w_address0 <= 13;
          4'd2:
            w_address0 <= 10;
          4'd3:
            w_address0 <= 7;
          4'd4:
            w_address0 <= 4;
          4'd5:
            w_address0 <= 1;
          4'd6:
            w_address0 <= 14;
          4'd7:
            w_address0 <= 11;
          4'd8:
            w_address0 <= 8;
          4'd9:
            w_address0 <= 5;
          4'd10:
            w_address0 <= 2;
          4'd11:
            w_address0 <= 15;
          4'd12:
            w_address0 <= 12;
          4'd13:
            w_address0 <= 9;
          4'd14:
            w_address0 <= 6;
          4'd15:
            w_address0 <= 3;
          default:
            w_address0 <= 0;
        endcase
      end
end

//r_addresss
always @(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    begin
      r_address   <= 0;
      valid_input <= 1;
      done        <= 0;
      finish      <= 0;
    end
    else
      begin
        if(cur_state == IDLE)
          begin
            r_address   <= 0;
            valid_input <= 1;
            done        <= 0;
            finish      <= 0;
          end
          else
            begin
            if(cur_state == RUN)
              begin
                if(r_address < 15)
                  begin
                    r_address   <= r_address + 1;
                  end
              else
                begin
                  finish <= 1;
                  valid_input <= 0;
                end
              end
              else 
                begin
                  if(cur_state == DONE) 
                  begin
                    done <= 1;
                    valid_input <= 0;
                  end
                end
             end
      end
end

//wait bram
always @(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    begin
      valid_wait  <= 0;
      finish1     <= 0;
    end
    else
      begin
        if(cur_state == IDLE)
          begin
            valid_wait  <= 0;
            finish1     <= 0;
          end
          else
            if(cur_state == RUN)
              begin
                valid_wait  <= 0;
                finish1     <= finish;
                if(valid_input)
                begin
                  valid_wait <= 1;
                end  
              end
      end
end

//write
always @(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    begin
      we        <= 0;
      finish2   <= 0;
      oData     <= 0;
      w_address <= 0;
    end
    else
      begin
        if(cur_state == IDLE)
          begin
            we        <= 0;
            finish2   <= 0;
            oData     <= 0;
            w_address <= 0;
          end
          else
            if(cur_state == RUN)
              begin
                finish2 <= finish1;
                we <= 0;
                if(valid_wait)
                begin
                  w_address <= w_address0;
                  we <= 1;
                  oData <= iData;
                end
              end
            else
              if(cur_state == DONE)
                begin
                  we <= 0;
                end
      end
end

endmodule