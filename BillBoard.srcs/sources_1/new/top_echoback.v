`timescale 1ns / 1ps

module top_echoback(
    input clk,                // FPGA clock
    input rst,              // Reset signal
    input RsRx,                 // UART receive input
    output RsTx                 // UART transmit output
);

    // Parameters
    parameter DATA_BITS = 8;      // Number of data bits in a word
    parameter SAMPLING = 16;      // Number of stop bit / oversampling ticks
    parameter BR_LIMIT = 52;     // Baud rate generator counter limit
    parameter BR_BITS = 6;       // Number of baud rate generator counter bits
    parameter FIFO_EXP = 8;       // Exponent for FIFO addresses

    // Internal Signals
    wire rx_empty;               // Indicates if RX FIFO is empty
    wire rx_full;                // Indicates if RX FIFO is full
    wire [DATA_BITS-1:0] read_data;   // Data read from RX FIFO
    wire [DATA_BITS-1:0] write_data;  // Data to write to TX FIFO
    wire write_uart;             // Write trigger for TX FIFO
    wire read_uart;              // Read trigger for RX FIFO

    // Assignments
    assign read_uart = ~rx_empty;   // Read from RX FIFO if not empty
    assign write_uart = ~rx_empty;  // Write to TX FIFO if RX FIFO has data
    assign write_data = read_data;  // Echo received data back to TX FIFO

    // Instantiate UART Controller
    uart_controller
        #(
            .DATA_BITS(DATA_BITS),
            .SAMPLING(SAMPLING),
            .BR_LIMIT(BR_LIMIT),
            .BR_BITS(BR_BITS),
            .FIFO_EXP(FIFO_EXP)
        )
        UART_CTRL
        (
            .clk(clk),
            .rst(rst),
            .read_uart(read_uart),
            .write_uart(write_uart),
            .rx(RsRx),
            .write_data(write_data),
            .rx_full(rx_full),
            .rx_empty(rx_empty),
            .tx(RsTx),
            .read_data(read_data)
        );

endmodule
