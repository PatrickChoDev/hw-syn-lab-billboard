`timescale 1ns / 1ps

module top(
    input wire clk,          // 100 MHz Basys 3 clock
    input wire rst,          // Reset button
    input wire sw_btn,       // Switch to UART button (UP)
    input wire [15:0] sw,
    input wire ps2_clk,      // PS/2 clock signal
    input wire ps2_data,     // PS/2 data signal
    input wire uart_rx,      // UART receive signal (not used, loopback possible)
    input wire xuart_rx,
    output wire xuart_tx,
    output wire uart_tx,     // UART transmit signal,
    output wire hsync,       // to VGA connector
    output wire vsync,       // to VGA connector
    output reg [11:0] rgb,   // to DAC, to VGA connector
    output reg [15:0] led
    );
    
    // Parameters for UART
    localparam DATA_BITS = 8;
    localparam SAMPLING = 16;
    localparam BR_LIMIT = 651;  // Baud rate for 9600bps @ 100MHz clock
    localparam BR_BITS = 10;
    localparam FIFO_EXP = 8;    // FIFO depth of 2^8 = 256 entries
    
    // Video Signals
    wire [9:0] w_x, w_y;
    wire w_video_on;
    wire [11:0] rgb_next;
    wire [11:0] rgb_thai;
    wire [11:0] rgb_canvas;
    wire [11:0] rgb_thai_canvas;
    wire [11:0] rgb_graphics;
    
    // Internal Signals
    wire rx_empty, xrx_empty;               // Indicates if RX FIFO is empty
    wire scan_code_ready;
    wire [DATA_BITS-1:0] write_data;  // Data to write to TX FIFO
    wire [DATA_BITS-1:0] write_xdata;  // Data to write to TX FIFO
    wire [DATA_BITS-1:0] read_data;  // Data to write to TX FIFO
    wire [DATA_BITS-1:0] read_xdata;  // Data to write to TX FIFO
    wire write_uart;             // Write trigger for TX FIFO
    wire read_uart = ~rx_empty;   // Read from RX FIFO if not empty
    wire read_xuart = ~xrx_empty;
    wire [7:0] scan_code;
    wire [7:0] ascii_code;     // Converted ASCII data
    wire [7:0] thai_ascii_code;     // Converted ASCII data
    wire letter_case;
    wire ctrl_key;
    wire sw_ready;
    
    // Always block to update LED
    always @(posedge clk) begin
        led = 16'b0;
        led[7:0] = write_data;      // Show transmitted data on LEDs
        led[15] = write_uart;        // Indicate PS/2 readiness
        led[13] = ctrl_key;
        led[12] = letter_case;
    end
    
    single_pulser pulser(
        .clk(clk),
        .reset(rst),
        .trigger(sw_btn),
        .pulse(sw_ready)
    );

    // PS/2 Keyboard Input
    keyboard kb_unit (.clk(clk), .reset(rst), .ps2_data(ps2_data), .ps2_clk(ps2_clk),
                 .scan_code(scan_code), .scan_code_ready(scan_code_ready), .letter_case_out(letter_case),.ctrl_key_active(ctrl_key));
        
    // ASCII Conversion
    key2ascii k2a_unit (.letter_case(letter_case), .scan_code(scan_code), .ascii_code(ascii_code));
    k2a_thai_unit k2a_thai_unit (.letter_case(letter_case), .scan_code(scan_code), .ascii(thai_ascii_code));

    // Assignments for bindings UART, PS/2 and Switches
    assign write_xdata = sw_ready? sw[7:0]: (read_uart ? read_data :( sw[13]? thai_ascii_code:ascii_code));  // Echo received data back to TX FIFO
    assign write_data = sw_ready? sw[7:0] : (read_xuart? read_xdata : read_uart? read_data : ( sw[13]? thai_ascii_code:ascii_code));
    assign write_uart = scan_code_ready | read_uart | read_xuart | sw_ready;
    assign write_xuart = scan_code_ready | read_uart | sw_ready;


        // Instantiate UART Controller Loopback
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
            .read_uart(read_xuart),
            .write_uart(write_uart),
            .rx(xuart_rx),
            .write_data(write_data),
            .rx_full(),
            .rx_empty(xrx_empty),
            .tx(uart_tx),
            .read_data(read_xdata),
            .tx_empty()
        );
        
    // Instantiate UART Controller for Pair Device
    uart_controller
        #(
            .DATA_BITS(DATA_BITS),
            .SAMPLING(SAMPLING),
            .BR_LIMIT(BR_LIMIT),
            .BR_BITS(BR_BITS),
            .FIFO_EXP(FIFO_EXP)
        )
        XUART_CTRL
        (
            .clk(clk),
            .rst(rst),
            .read_uart(read_uart),
            .write_uart(write_xuart),
            .rx(uart_rx),
            .write_data(write_xdata),
            .rx_full(),
            .rx_empty(rx_empty),
            .tx(xuart_tx),
            .read_data(read_data),
            .tx_empty()
        );

    

    // VGA Controller
    vga_controller vga(.clk_100MHz(clk), .reset(rst), .hsync(hsync), .vsync(vsync),
                       .video_on(w_video_on), .x(w_x), .y(w_y));
    
    // Text Generation Circuit
    ascii_tester at(.clk(clk), .video_on(w_video_on), .x(w_x), .y(w_y), .rgb(rgb_next));
    ascii_tester_thai at2(.clk(clk), .video_on(w_video_on), .x(w_x), .y(w_y), .rgb(rgb_thai));
    
    bg_tester(.clk(clk),.h_pos(w_x),.v_pos(w_y),.rgb(rgb_graphics));

    //Prevent non-canvas mode
    wire [7:0] canvas_data = (sw[15:14] == 2'b10 && ~sw[13])? write_data: 7'bZ;
    wire canvas_valid = (sw[15:14] == 2'b10 && ~sw[13])? write_uart: 1'bZ;
    wire [7:0] thai_canvas_data = (sw[15:14] == 2'b10 && sw[13])? write_data: 7'bZ;
    wire thai_canvas_valid = (sw[15:14] == 2'b10 && sw[13])? write_uart: 1'bZ;
    
    
    editor_canvas cv(.clk(clk),.rst(rst),.keycode(canvas_data),.key_valid(canvas_valid),.x(w_x),.y(w_y),.video_on(w_video_on),.rgb(rgb_canvas));
    thai_editor_canvas cv_thai(.clk(clk),.rst(rst),.keycode(thai_canvas_data),.key_valid(thai_canvas_valid),.x(w_x),.y(w_y),.video_on(w_video_on),.rgb(rgb_thai_canvas));
    
    // Video output
    always @* begin
        case (sw[15:14])
            2'b00: rgb = rgb_next;
            2'b01: rgb = rgb_thai;
            2'b10: rgb = sw[13] ? rgb_thai_canvas : rgb_canvas ;
            2'b11: rgb = rgb_graphics;
        endcase
    end
endmodule
    