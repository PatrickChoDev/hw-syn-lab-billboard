`timescale 1ns / 1ps

module uart_receiver
#(
    parameter DATA_BITS = 8,
    parameter SAMPLING = 16
)
(
    input clk,
    input rst,
    input rx,
    input tick,
    output reg data_ready,
    output [DATA_BITS-1 : 0] dout
);

localparam [1:0] idle  = 2'b00,
             start = 2'b01,
             data  = 2'b10,
             stop  = 2'b11;
             
// Registers                 
reg [1:0] state, next_state;        // state registers
reg [3:0] tick_reg, tick_next;      // number of ticks received from baud rate generator
reg [2:0] nbits_reg, nbits_next;    // number of bits received in data state
reg [7:0] data_reg, data_next;      // reassembled data word

always @(posedge clk, posedge rst)
     if(rst) begin
         state <= idle;
         tick_reg <= 0;
         nbits_reg <= 0;
         data_reg <= 0;
     end
     else begin
         state <= next_state;
         tick_reg <= tick_next;
         nbits_reg <= nbits_next;
         data_reg <= data_next;
     end
     
// State Machine Logic
always @* begin
    next_state = state;
    data_ready = 1'b0;
    tick_next = tick_reg;
    nbits_next = nbits_reg;
    data_next = data_reg;
    
    case(state)
     idle:
         if(~rx) begin               // when data line goes LOW (start condition)
             next_state = start;
             tick_next = 0;
         end
     start:
         if(tick)
             if(tick_reg == 7) begin
                 next_state = data;
                 tick_next = 0;
                 nbits_next = 0;
             end
             else
                 tick_next = tick_reg + 1;
     data:
         if(tick)
             if(tick_reg == 15) begin
                 tick_next = 0;
                 data_next = {rx, data_reg[7:1]};
                 if(nbits_reg == (DATA_BITS-1))
                     next_state = stop;
                 else
                     nbits_next = nbits_reg + 1;
             end
             else
                 tick_next = tick_reg + 1;
     stop:
         if(tick)
             if(tick_reg == (SAMPLING-1)) begin
                 next_state = idle;
                 data_ready = 1'b1;
             end
             else
                 tick_next = tick_reg + 1;
    endcase             
end

assign dout = data_reg;

endmodule
