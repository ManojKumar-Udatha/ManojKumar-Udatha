`timescale 1ns / 1ps
module tx_module
  (
    input 	wire 		    tx_clk,
    input 	wire 		    res,
    input 	wire [7:0]	tx_data_input,
    input 	wire 		    tx_data_valid,
    output 	wire 		    busy,
    output 	wire		    done,
    output 	wire		    data_out
  );
  //frequency
  localparam            freq		      =100000000;
  localparam            baud_rate	    =115200;
  //state declaration
  parameter             idle		      =2'b00;
  parameter             start_bit	    =2'b01;
  parameter             data_bits	    =2'b10;
  parameter             stop_bit	    =2'b11;
  //baudrate values
  localparam            clks_per_bit	=(freq/baud_rate);
  localparam            count_width	  =10;					//$clog2(clks_per_bit);  // for 100MHz clock and baud rate=115200
  //registers for synchronization
  reg tx_valid_data_0;
  reg tx_valid_data_1;
  //output registers
  reg 						      tx_data_out;
  reg 						      tx_busy;
  reg 						      tx_done;
  reg [12:0]				    tx_data			  =13'b0;
  //coounter & bit index registers decleration
  reg [1:0]					    current_state	=2'b00;
  reg [count_width-1:0]	counter			  ={count_width{1'b0}};
  reg [3:0]					    bit_index		  =4'b000;
  //hamming code registers decleration
  wire p1,p2,p4,p8,overall_parity;
  wire  [12:0]          tx_data_frame;
  //synchronization logic
  always @(posedge tx_clk or negedge res)begin
    if(!res)begin
      tx_valid_data_0<=0;
      tx_valid_data_1<=0;
    end
    else begin
      tx_valid_data_0<=tx_data_valid;
      tx_valid_data_1<=tx_valid_data_0;
    end
  end
  
  //valid signal edge detection
  wire tx_valid_rise	=tx_valid_data_0&~tx_valid_data_1;
  
  //transmitter logic
  always @(posedge tx_clk or negedge res)begin
    if(!res)begin
      tx_data_out	<=1'b1;
      tx_busy		<=1'b0;
      tx_done		<=1'b0;
      counter		<=0;
      bit_index		<=4'b0;
      current_state	<=idle;
    end
    
    else begin
      case(current_state)
        //ideal state
      idle:begin
        tx_data_out	<=1'b1;
        tx_busy		<=1'b0;
        tx_done		<=1'b0;
        counter		<=0;
        bit_index	<=4'b0;
        if(tx_valid_rise)begin
          tx_data		<=tx_data_frame;
          current_state	<=start_bit;
        end
      end
        //start bit passing state
      start_bit:begin
        tx_data_out	<=1'b0;
        tx_busy		<=1'b1;
        if(counter<clks_per_bit-1)begin
          counter<=counter+1'b1;
        end
        else begin
          counter		<=0;
          current_state	<=data_bits;
        end
      end
        //data bits passing state
      data_bits:begin
        tx_data_out<=tx_data[bit_index];
        if(counter<clks_per_bit-1)begin
          counter<=counter+1'b1;
        end
        else begin
          counter<=0;
          if(bit_index<12)begin
            bit_index<=bit_index+1'b1;
          end
          else begin
            bit_index		<=4'b0;
            current_state	<=stop_bit;
          end
        end
      end
        //stop bit passing state
      stop_bit:begin
        tx_data_out<=1'b1;
        if(counter<clks_per_bit-1)begin
          counter	<=counter+1'b1;
          tx_done	<=1'b0;
        end
        else begin
          tx_busy<=1'b0;
          tx_done<=1'b1;
          counter<=0;
          current_state<=idle;
        end
      end
        default :current_state<=idle;
    endcase
    end
  end
  
  assign data_out	=tx_data_out;
  assign busy		=tx_busy;
  assign done		=tx_done;
  
  assign p1=(tx_data_input[0]^tx_data_input[1]^tx_data_input[3]^tx_data_input[4]^tx_data_input[6]);
  assign p2=(tx_data_input[0]^tx_data_input[2]^tx_data_input[3]^tx_data_input[5]^tx_data_input[6]);
  assign p4=(tx_data_input[1]^tx_data_input[2]^tx_data_input[3]^tx_data_input[7]);
  assign p8=(tx_data_input[4]^tx_data_input[5]^tx_data_input[6]^tx_data_input[7]);
  assign overall_parity=^{tx_data_input[7:4],p8,tx_data_input[3:1],p4,tx_data_input[0],p2,p1};
  
  assign tx_data_frame={overall_parity,tx_data_input[7:4],p8,tx_data_input[3:1],p4,tx_data_input[0],p2,p1};
  
endmodule
