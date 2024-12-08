`timescale 1ns / 1ps

module thai_editor_canvas(
    input clk,           // 100 MHz clock
    input rst,           // Reset button
    input [7:0] keycode, // Keypress from a keyboard (ASCII code)
    input key_valid,     // Keypress valid signal
    input [9:0] x, y,    // Coordinates from VGA controller
    input video_on,      // Video signal from VGA controller
    output reg [11:0] rgb,  // RGB value to display text
    output wire [3:0] cursor_x, // Cursor x position
    output wire [3:0] cursor_y  // Cursor y position
);

    // Constants for screen layout
    parameter MAX_X = 640; // VGA width in pixels
    parameter MAX_Y = 480; // VGA height in pixels
    parameter CHAR_WIDTH = 8; // Width of a character in pixels
    parameter CHAR_HEIGHT = 16; // Height of a character in pixels

    // 2D array to store characters (simple buffer for a single page of text)
    reg [7:0] text_buffer [0:7][0:15]; // 8 rows, 16 columns of characters

    // Cursor position (x, y)
    reg [3:0] cur_x = 0;  // Current cursor position (x)
    reg [3:0] cur_y = 0;  // Current cursor position (y)
    
    // x and y come from the VGA controller
    wire [3:0] char_x = x / CHAR_WIDTH;  // Character column (4 bits for 16 columns)
    wire [2:0] char_y = y / CHAR_HEIGHT; // Character row (3 bits for 8 rows)
    
    integer i, j;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all text and cursor positions
            cur_x <= 0;
            cur_y <= 0;
            // Clear the text buffer
            for (i = 0; i < 8; i = i + 1) begin : row_gen
                for (j = 0; j < 16; j = j + 1) begin : col_gen
                    // Initialize each element in the text_buffer to space (8'h00)
                    text_buffer[i][j] <= 8'h4D;
                end
            end
        end else if (key_valid) begin
            // Insert character into text buffer when key is pressed
            if (keycode == 8'h50) begin // Enter key
                // Move to next line
                if (cur_y < 7) begin
                    cur_y <= cur_y + 1;
                    cur_x <= 0; // Start from the first column
                end
            end else if (keycode == 8'h4F) begin // Backspace
                if (cur_x > 0) begin
                    cur_x <= cur_x - 1; // Move cursor back
                end else if (cur_y > 0) begin
                    cur_y <= cur_y - 1;
                    cur_x <= 15;
                end
                text_buffer[cur_y][cur_x] <= 8'h4D; // Remove character
            end else if (keycode >= 8'h00 && keycode <= 8'h4D) begin
                // ASCII printable characters
                if (cur_x != 15 && cur_y != 7) begin
                    text_buffer[cur_y][cur_x] <= keycode; // Insert the character 
                    cur_x <= cur_x + 1;
                end
                if (cur_x == 15 && cur_y < 7) begin
                    cur_y <= cur_y + 1;
                    cur_x <= 0;
                end
            end
        end
    end
    
    // signal declarations
    wire [10:0] rom_addr;           // 11-bit text ROM address
    wire [3:0] char_row;            // 4-bit row of ASCII character
    wire [2:0] bit_addr;            // column number of ROM data
    wire [7:0] rom_data;            // 8-bit row data from text ROM
    wire ascii_bit, ascii_bit_on;     // ROM bit and status signal
    
    font_rom rom_thai(.clk(clk),.addr(rom_addr),.data(rom_data));
      
    // ASCII ROM interface
    assign rom_addr = {text_buffer[char_y][char_x], char_row};   // ROM address is ascii code + row
    assign ascii_bit = rom_data[~bit_addr];     // reverse bit order
    assign char_row = y[3:0];               // row number of ascii character rom
    assign bit_addr = x[2:0];               // column number of ascii character rom
    assign ascii_bit_on = ((x >= char_x * CHAR_WIDTH && x < (char_x + 1) * CHAR_WIDTH) && 
                           (y >= char_y * CHAR_HEIGHT && y < (char_y + 1) * CHAR_HEIGHT)) ? ascii_bit : 1'b0;

    // Render the screen
    always @(posedge clk) begin
        if (video_on) begin
            // Check if we're within the text region
            if(ascii_bit_on)
                rgb <= 12'hFFF; // White text
            else if (x >= cur_x * CHAR_WIDTH && x < (cur_x + 1) * CHAR_WIDTH && 
                     y >= cur_y * CHAR_HEIGHT && y < (cur_y + 1) * CHAR_HEIGHT) begin 
                // Display the cursor (overwrites the text if it's on the cursor position)
                rgb <= 12'hF00; // Red cursor color
            end else begin
                rgb <= 12'h000; // Black background
            end
        end else begin
            rgb <= 12'h000;  // No video, black screen
        end
    end

    // Output current cursor position
    assign cursor_x = cur_x;
    assign cursor_y = cur_y;

endmodule