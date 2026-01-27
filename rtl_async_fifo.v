`timescale 1ns/1ps
module async_fifo
  (
    input             clk_wr,clk_rd,
    input             res,
    input             wr_en,rd_en,
    input [7:0]       data_in,
    output reg [7:0]  data_out,
    output wire       full,
    output wire       empty
  );
  //dual poart ram
  reg [7:0]fifo_memory[63:0];
  
  reg [6:0]wr_ptr_b,wr_ptr_g,wr_ptr_s1,wr_ptr_s2;
  reg [6:0]rd_ptr_b,rd_ptr_g,rd_ptr_s1,rd_ptr_s2;
  
  wire [6:0]wr_ptr_b_next,wr_ptr_g_next;
  wire [6:0]rd_ptr_b_next,rd_ptr_g_next;
  
  assign wr_ptr_b_next=wr_ptr_b+1;
  assign rd_ptr_b_next=rd_ptr_b+1;
  
  assign wr_ptr_g_next=(wr_ptr_b_next>>1)^(wr_ptr_b_next);
  assign rd_ptr_g_next=(rd_ptr_b_next>>1)^(rd_ptr_b_next);
  
  assign full=(wr_ptr_g_next=={~rd_ptr_s2[6:5],rd_ptr_s2[4:0]});
  assign empty=(rd_ptr_g==wr_ptr_s2);
  
  always @(posedge clk_rd or negedge res)begin
    if(!res)begin
      data_out<=8'b0;
      rd_ptr_b<=7'b0;
      rd_ptr_g<=7'b0;
    end
    else if(rd_en && (!empty))begin
      data_out<=fifo_memory[rd_ptr_b[5:0]];
      rd_ptr_b<=rd_ptr_b_next;
      rd_ptr_g<=rd_ptr_g_next;
    end
  end
  
  always @(posedge clk_wr or negedge res)begin
    if(!res)begin
      wr_ptr_b<=7'b0;
      wr_ptr_g<=7'b0;
    end
    else if(wr_en && (!full))begin
      fifo_memory[wr_ptr_b[5:0]]<=data_in;
      wr_ptr_b<=wr_ptr_b_next;
      wr_ptr_g<=wr_ptr_g_next;
    end
  end
  
  always @(posedge clk_rd or negedge res)begin
    if(!res)begin
      wr_ptr_s1<=7'b0;
      wr_ptr_s2<=7'b0;
    end
    else begin
      wr_ptr_s1<=wr_ptr_g;
      wr_ptr_s2<=wr_ptr_s1;
    end
  end
  
  always @(posedge clk_wr or negedge res)begin
    if(!res)begin
      rd_ptr_s1<=7'b0;
      rd_ptr_s2<=7'b0;
    end
    else begin
      rd_ptr_s1<=rd_ptr_g;
      rd_ptr_s2<=rd_ptr_s1;
    end
  end
endmodule
