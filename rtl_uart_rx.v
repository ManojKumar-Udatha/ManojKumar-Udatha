`timescale 1ns/1ps

module rx_module
  (
    input 	wire         rx_clk,			  //uart receiver clkk
    input 	wire         res,				    //active low asynchronous reset
    input 	wire         rx_in,				  //uart input signal
    output 	wire [7:0]   rx_data_reg,	  //uart output(1- Byte)
    output 	wire         busy,				  //uart busy flag
    output 	wire         data_valid,		//uart data_valid flag
    output 	wire         error				  //uart error flag
  );
  //frequency
  localparam             freq		          =100000000;
  localparam             baud_rate	      =115200;
  //states declaration
  parameter              idle		          =2'b00;
  parameter              start_bit	      =2'b01;
  parameter              data_bits	      =2'b10;
  parameter              stop_bit	        =2'b11;
  //baudrate values for 3x oversampling
  localparam             clks_per_bit    	=(freq/baud_rate);	// for 100MHz clock and baud rate=115200
  localparam             clks_per_sample  =clks_per_bit/3;
  localparam             count_width	=10;					//$clog2(clks_per_sample);					// for 100MHz clock and baud rate=115200
  //sampling counters
  localparam             sample_1_count   =clks_per_bit/6;
  localparam             sample_2_count   =clks_per_bit/2;
  localparam             sample_3_count   =5*clks_per_bit/6;
  //3x over sampling registers
  reg                    sample_1;
  reg                    sample_2;
  reg                    sample_3;
  wire                   sample_result;
  //output registers decleration
  reg 		               rx_data1;
  reg 		               rx_data;
  reg [12:0]             rx_output_data;
  reg 		               rx_busy;
  reg 		               rx_data_valid;
  reg 		               rx_error;
  //hamming code signals
  wire                   c1,c2,c4,c8;
  wire                   p1,p2,p4,p8;
  wire                   overall_parity;
  wire [3:0]             error_pos;
  
  reg [count_width-1:0]	 counter			    ={count_width{1'b0}};
  reg [3:0]				       bit_index		    =4'b0000;
  reg [1:0]				       current_state	  =2'b00;
  
  //2-stage synchronization logic for rx_data
  always @(posedge rx_clk or negedge res)begin
    if(!res)begin
      rx_data1<=1;
      rx_data<=1;
    end
    else begin
      rx_data1<=rx_in;
      rx_data<=rx_data1;
    end
  end
  
  //sampling logic
  always @(posedge rx_clk or negedge res)begin
    if (!res) begin
      sample_1 <= 1'b1;
      sample_2 <= 1'b1;
      sample_3 <= 1'b1;
    end
    else begin
      if(counter==0)begin
        sample_1<=1'b1;
        sample_2<=1'b1;
        sample_3<=1'b1;
      end
      else if(counter == (sample_1_count))begin
        sample_1 <= rx_data;
      end
      else if(counter == (sample_2_count))begin
        sample_2 <= rx_data;
      end
      else if(counter == (sample_3_count))begin
        sample_3 <= rx_data;
      end
    end
  end
  
  //uart receiver logic
  always @(posedge rx_clk or negedge res)begin
    
    if(!res)begin
      current_state	<=idle;
      rx_output_data<=13'b0;
      rx_data_valid	<=1'b0;
      rx_error		<=1'b0;
      rx_busy		<=1'b0;
      counter		<={count_width{1'b0}};
      bit_index		<=4'b0000;
    end
    
    else begin
      case(current_state)
        //idle state
      idle:begin
        rx_error		<=1'b0;
        rx_data_valid	<=1'b0;
        rx_busy			<=1'b0;
        counter			<=0;
        bit_index		<=4'b0000;
        if(rx_data==1'b0)begin
          current_state<=start_bit;
        end
      end
        //start bit detection
      start_bit:begin
        if(counter==clks_per_bit-1)begin
          counter<=0;
          if(~sample_result)begin
            current_state<=data_bits;
            rx_busy<=1'b1;
          end
          else begin
            current_state<=idle;
          end
        end
        else begin
          counter<=counter+1'b1;
        end
      end
        //data bits collection
      data_bits:begin
        if(counter==clks_per_bit-1)begin
          counter<=0;
          rx_output_data[bit_index]<=sample_result;
          if(bit_index<12)begin
            bit_index<=bit_index+1'b1;
          end
          else begin
            bit_index<=4'b0000;
            current_state<=stop_bit;
          end
        end
        else begin
          counter<=counter+1'b1;
        end
      end
        //stop bit detection
      stop_bit:begin
        if(counter==clks_per_bit-1)begin
          counter<=0;
          if(sample_result)begin
            if(error_pos==4'b0000 && overall_parity==1'b0)begin
              rx_data_valid<=1'b1;
              rx_busy<=1'b0;
              current_state<=idle;
            end
            else if(error_pos!=4'b0000 && error_pos<4'b1101 && overall_parity==1'b1)begin
              rx_output_data[error_pos-1]<=(~rx_output_data[error_pos-1]);
              rx_data_valid<=1'b1;
              rx_busy<=1'b0;
              current_state<=idle;
            end
            else if(error_pos==4'b0000 && overall_parity==1'b1)begin
              rx_output_data[12]<=~rx_output_data[12];
              rx_data_valid<=1'b1;
              rx_busy<=1'b0;
              current_state<=idle;
            end
            else begin
              rx_error<=1'b1;
              rx_output_data<=13'b0;
              rx_data_valid<=1'b0;
              current_state<=idle;
              end
          end
          else begin
            rx_error<=1'b1;
            rx_output_data<=13'b0;
            rx_data_valid<=1'b0;
            current_state<=idle;
          end
        end
        else begin
          counter<=counter+1'b1;
        end
      end
        //default case
      default :current_state<=idle;
    endcase
    end
  end
  
  //data assignments
  assign rx_data_reg={rx_output_data[11:8],rx_output_data[6:4],rx_output_data[2]};
  assign busy		=rx_busy;
  assign data_valid	=rx_data_valid;
  assign error		=rx_error;
  
  //sampling assignments
  assign sample_result=((sample_1&sample_2)|(sample_2&sample_3)|(sample_3&sample_1))?1'b1:1'b0;
  
  //hamming code parity bits
  assign p1=rx_output_data[0];
  assign p2=rx_output_data[1];
  assign p4=rx_output_data[3];
  assign p8=rx_output_data[7];
  
  //hamming code parity checkers
  assign c1=(rx_output_data[2]^rx_output_data[4]^rx_output_data[6]^rx_output_data[8]^rx_output_data[10]^p1);
  assign c2=(rx_output_data[2]^rx_output_data[5]^rx_output_data[6]^rx_output_data[9]^rx_output_data[10]^p2);
  assign c4=(rx_output_data[4]^rx_output_data[5]^rx_output_data[6]^rx_output_data[11]^p4);
  assign c8=(rx_output_data[8]^rx_output_data[9]^rx_output_data[10]^rx_output_data[11]^p8);
  assign overall_parity=^rx_output_data;
  
  //hamming code error posintion
  assign error_pos={c8,c4,c2,c1};
  
endmodule
