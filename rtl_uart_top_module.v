`timescale 1ns/1ps

module uart_top_module(
  input wire 		      system_clk,			//more than 100MHz
  input wire 		      uart_clk,			//100Mhz
  input wire 		      peripheral_clk,		//less than 100Mhz
  
  input wire 		      res,
  
  input wire 		      system_wr_en,
  input wire [7:0]	  input_data,			//total module input
  
  input wire		      peripheral_rd_en,
  output wire [7:0]	  output_data,		//total module output
  
  input wire		      uart_rx_in,			// rx input line
  output wire		      uart_tx_out			// tx output line
);
  //tx_fifo wires
  wire 		tx_fifo_full;
  wire 		tx_fifo_empty;
  wire [7:0]tx_fifo_data_out;
  wire 		tx_fifo_rd_en;
  
  //rx_fifo wires
  wire 		rx_fifo_full;
  wire 		rx_fifo_empty;
  wire [7:0]rx_fifo_data_in;
  wire 		rx_fifo_wr_en;
  
  //tx  module wires
  wire tx_busy;
  wire tx_done;
  
  //rx module wires
  wire rx_busy;
  wire rx_data_valid;
  wire rx_error;
  
  assign tx_fifo_rd_en=((~tx_fifo_empty)&&(~tx_busy));
  assign rx_fifo_wr_en=((~rx_fifo_full)&&(rx_data_valid));
  
  // tx_fifo instantiation
  async_fifo tx_fifo (
    .clk_wr(system_clk),
    .clk_rd(uart_clk),
    .res(res),
    .wr_en(system_wr_en),
    .rd_en(tx_fifo_rd_en),
    .data_in(input_data),
    .data_out(tx_fifo_data_out),
    .full(tx_fifo_full),
    .empty(tx_fifo_empty)
  );
  
  //tx_module instantiation
  tx_module uart_tx (
    .tx_clk(uart_clk),
    .res(res),
    .tx_data_input(tx_fifo_data_out),
    .tx_data_valid(tx_fifo_rd_en),
    .busy(tx_busy),
    .done(tx_done),
    .data_out(uart_tx_out)
  );
  
  //rx_module instantiation
  rx_module uart_rx (
    .rx_clk(uart_clk),
    .res(res),
    .rx_in(uart_rx_in),
    .rx_data_reg(rx_fifo_data_in),
    .busy(rx_busy),
    .data_valid(rx_data_valid),
    .error(rx_error)
  );
  
  //rx_fifo instantiation
  async_fifo rx_fifo (
    .clk_wr(uart_clk),
    .clk_rd(peripheral_clk),
    .res(res),
    .wr_en(rx_fifo_wr_en),
    .rd_en(peripheral_rd_en),
    .data_in(rx_fifo_data_in),
    .data_out(output_data),
    .full(rx_fifo_full),
    .empty(rx_fifo_empty)
  );
  
endmodule
