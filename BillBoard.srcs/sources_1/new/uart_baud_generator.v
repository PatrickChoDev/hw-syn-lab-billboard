`timescale 1ns / 1ps

module uart_baud_generator
#(              // Default 9600 baud
   parameter   N = 10,     // number of counter bits
               M = 651     // counter limit value
)
(
input clk,
input rst,
output wire tick
);

reg [N-1:0] counter;        // counter value
wire [N-1:0] next;          // next counter value


always @(posedge clk, posedge rst)
    if(rst)
        counter <= 0;
    else
        counter <= next;

assign next = (counter == (M-1)) ? 0 : counter + 1;

assign tick = (counter == (M-1)) ? 1'b1 : 1'b0;


endmodule
