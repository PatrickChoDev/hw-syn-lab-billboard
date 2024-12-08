`timescale 1ns / 1ps
module top_ps2_to_uart(
    input wire clk,          // 100 MHz Basys 3 clock
    input wire rst,          // Reset button
    input wire ps2_clk,      // PS/2 clock signal
    input wire ps2_data,     // PS/2 data signal
    input wire uart_rx,      // UART receive signal (not used, loopback possible)
    output wire uart_tx      // UART transmit signal
);

    // Parameters for UART
    localparam DATA_BITS = 8;
    localparam SAMPLING = 16;
    localparam BR_LIMIT = 52;  // Baud rate for 115200bps @ 100MHz clock
    localparam BR_BITS = 6;
    localparam FIFO_EXP = 8;    // FIFO depth of 2^8 = 256 entries

    // Wires for PS/2 and UART
    wire [7:0] scan_code;       // Scan code from PS/2 keyboard
    wire rx_ready;          // PS/2 data received
    wire [7:0] ascii_data;      // Mapped ASCII data
    reg write_uart;             // Trigger UART transmission
    reg [9:0] tx_state;

    // PS/2 Keyboard Instantiation
    ps2_keyboard ps2_unit (
        .reset(rst),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .rx_ready(rx_ready),
        .rx_data(scan_code)
    );

    // ASCII Conversion
    rom_ps2_to_ascii mapper (
        .ps2_code(scan_code),
        .ascii(ascii_data)
    );

    // UART Controller Instantiation
    uart_controller #(
        .DATA_BITS(DATA_BITS),
        .SAMPLING(SAMPLING),
        .BR_LIMIT(BR_LIMIT),
        .BR_BITS(BR_BITS),
        .FIFO_EXP(FIFO_EXP)
    ) uart_unit (
        .clk(clk),
        .rst(rst),
        .read_uart(1'b0),        // Not reading from UART in this example
        .write_uart(rx_ready),
        .rx(uart_rx),
        .write_data(ascii_data),
        .rx_full(),
        .rx_empty(),
        .tx(uart_tx),
        .read_data()             // Not used
    );

    // FSM to handle scan code to UART transmission
    reg [1:0] state_reg, state_next;
    localparam IDLE = 2'b00, SEND = 2'b01;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
                write_uart <= 0;
                tx_state <= 0;
        end 
        else case (tx_state)
            10'd0: begin
                if (rx_ready) begin 
                    tx_state <= 1;
                    write_uart <= 1;
                end
            end
            10'd1: begin
                write_uart <= 0;
                tx_state <= 2;
            end
            default: tx_state <= tx_state + 1;
        endcase
    end
endmodule
