`timescale 1ns / 1ps

module bg_rom(
    input clk,
    input [18:0] addr,
    output reg [11:0] data
);

parameter ROM_SIZE = 320 * 240;

reg [11:0] mem [0: ROM_SIZE - 1];
initial $readmemb("bg.mem", mem);
always @(posedge clk) begin
    data <= mem[addr];
end

endmodule