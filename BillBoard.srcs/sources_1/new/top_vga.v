`timescale 1ns / 1ps

module top_vga(
    input clk,          // 100MHz on Basys 3
    input rst,        // btnC on Basys 3
    input [15:0] sw,
    input uart_rx,
    output uart_tx,
    output hsync,       // to VGA connector
    output vsync,       // to VGA connector
    output reg [11:0] rgb,   // to DAC, to VGA connector
    output reg [15:0] led
    );
    
    // signals
    wire [9:0] w_x, w_y;
    wire w_video_on, w_p_tick;
    wire [11:0] rgb_next;
    wire [11:0] rgb_thai;
    wire [11:0] rgb_canvas;
    
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
    reg [DATA_BITS-1:0] write_data;  // Data to write to TX FIFO
    reg write_uart;             // Write trigger for TX FIFO
    reg read_uart;              // Read trigger for RX FIFO
    wire [3:0] curx, cury;

    // Assignments
    always @* begin
        read_uart = ~rx_empty;   // Read from RX FIFO if not empty
        write_uart = ~rx_empty;  // Write to TX FIFO if RX FIFO has data
        write_data = read_data;  // Echo received data back to TX FIFO
    end
    

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
            .read_data(read_data)
        );
    
    // VGA Controller
    vga_controller vga(.clk_100MHz(clk), .reset(rst), .hsync(hsync), .vsync(vsync),
                       .video_on(w_video_on), .p_tick(w_p_tick), .x(w_x), .y(w_y));
                       
    wire text_ready;
    single_pulser sg(.clk(clk),.reset(rst),.trigger(write_uart),.pulse(text_ready));
    // Text Generation Circuit
    ascii_tester at(.clk(clk), .video_on(w_video_on), .x(w_x), .y(w_y), .rgb(rgb_next));
    ascii_tester_thai at2(.clk(clk), .video_on(w_video_on), .x(w_x), .y(w_y), .rgb(rgb_thai));
    
    editor_canvas cv(.clk(clk),.rst(rst),.keycode(read_data),.key_valid(text_ready),.x(w_x),.y(w_y),.video_on(w_video_on),.rgb(rgb_canvas),.cursor_x(curx),.cursor_y(cury));
            
    // output
    always @* begin
        case (sw[1:0])
            2'b00: rgb = rgb_next;
            2'b01: rgb = rgb_thai;
            2'b10: rgb = rgb_canvas;
            2'b10: rgb = rgb_next;
        endcase
        led = {write_data,curx,cury};
    end
      
endmodule