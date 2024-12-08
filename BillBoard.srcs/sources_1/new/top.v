`timescale 1ns / 1ps

module top(
    input wire clk,          // 100 MHz Basys 3 clock
    input wire rst,          // Reset button
    input wire sw_btn,       // Switch to UART button (UP)
    input wire [15:0] sw,
    input wire ps2_clk,      // PS/2 clock signal
    input wire ps2_data,     // PS/2 data signal
    input wire uart_rx,      // UART receive signal (not used, loopback possible)
    output wire uart_tx,     // UART transmit signal,
    output reg [15:0] led
    );
    
    // Parameters for UART
    localparam DATA_BITS = 8;
    localparam SAMPLING = 16;
    localparam BR_LIMIT = 651;  // Baud rate for 9600bps @ 100MHz clock
    localparam BR_BITS = 10;
    localparam FIFO_EXP = 8;    // FIFO depth of 2^8 = 256 entries
    
    
    // Internal Signals
        wire rx_empty;               // Indicates if RX FIFO is empty
        wire rx_full;                // Indicates if RX FIFO is full
        wire scan_code_ready;
        wire [DATA_BITS-1:0] write_data;  // Data to write to TX FIFO
        wire [DATA_BITS-1:0] read_data;  // Data to write to TX FIFO
        wire write_uart;             // Write trigger for TX FIFO
        wire read_uart;              // Read trigger for RX FIFO
        wire [7:0] scan_code;
        wire [7:0] ascii_code;     // Converted ASCII data
        wire tx_empty;
        wire letter_case;
        wire ctrl_key;
        wire [7:0] sw_data;
        wire sw_ready;
        
        single_pulser pulser(
            .clk(clk),
            .reset(rst),
            .trigger(sw_btn),
            .pulse(sw_ready)
        );
    
        // Assignments
        assign read_uart = ~rx_empty;   // Read from RX FIFO if not empty
        assign write_data = sw_ready? sw[7:0]: (read_uart ? read_data :ascii_code);  // Echo received data back to TX FIFO
        // Write UART signal: triggered by PS/2 ready or any condition you prefer
        assign write_uart = scan_code_ready | read_uart | sw_ready; 
    
        // Always block to update LED
        always @(posedge clk) begin
            led[7:0] <= write_data;      // Show transmitted data on LEDs
            led[15] <= write_uart;        // Indicate PS/2 readiness
            led[14] <= tx_empty;
            led[13] <= ctrl_key;
            led[12] <= letter_case;
        end
    
        // PS/2 Keyboard Input
        keyboard kb_unit (.clk(clk), .reset(rst), .ps2_data(ps2_data), .ps2_clk(ps2_clk),
                     .scan_code(scan_code), .scan_code_ready(scan_code_ready), .letter_case_out(letter_case),.ctrl_key_active(ctrl_key));
            
        // ASCII Conversion
        key2ascii k2a_unit (.letter_case(letter_case), .scan_code(scan_code), .ascii_code(ascii_code));
    
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
                .rx(uart_rx),
                .write_data(write_data),
                .rx_full(rx_full),
                .rx_empty(rx_empty),
                .tx(uart_tx),
                .read_data(read_data),
                .tx_empty(tx_empty)
            );
    
endmodule
    