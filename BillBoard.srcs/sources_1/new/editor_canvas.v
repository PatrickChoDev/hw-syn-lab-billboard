`timescale 1ns / 1ps

module editor_canvas(
    input clk,           // 100 MHz clock
    input rst,           // Reset button
    input [7:0] keycode, // Keypress from a keyboard (ASCII code)
    input key_valid,     // Keypress valid signal
    input [9:0] x, y,    // Coordinates from VGA controller
    input video_on,      // Video signal from VGA controller
    output reg [11:0] rgb,  // RGB value to display text
    output reg [3:0] cursor_x, // Cursor x position
    output reg [3:0] cursor_y  // Cursor y position
);

    // Constants for screen layout
    parameter MAX_X = 640; // VGA width in pixels
    parameter MAX_Y = 480; // VGA height in pixels
    parameter CHAR_WIDTH = 8; // Width of a character in pixels
    parameter CHAR_HEIGHT = 16; // Height of a character in pixels

    // 2D array to store characters (simple buffer for a single page of text)
    reg [7:0] text_buffer [0:15][0:15]; // 9 rows, 15 columns of characters

    // Cursor position (x, y)
    reg [9:0] cur_x = 0;  // Current cursor position (x)
    reg [9:0] cur_y = 0;  // Current cursor position (y)
    
    // x and y come from the VGA controller
    wire [3:0] char_x = x / CHAR_WIDTH;  // Character column (7 bits for 80 columns)
    wire [3:0] char_y = y / CHAR_HEIGHT; // Character row (6 bits for 40 rows)

    // Text input handler (Insert character into the buffer)
    initial begin
        text_buffer[0][0] <= 8'h65;
        text_buffer[2][2] <= 8'h65;
    end

    integer i, j;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all text and cursor positions
            cur_x <= 0;
            cur_y <= 0;
            // Clear the text buffer
            for (i = 0; i < 40; i = i + 1) begin : row_gen
                    for (j = 0; j < 80; j = j + 1) begin : col_gen
                        // Initialize each element in the text_buffer to space (8'h20)
                        text_buffer[i][j] = 8'h00;
                    end
                end
        end else if (key_valid) begin
            // Insert character into text buffer when key is pressed
            if (keycode == 8'h0D) begin // Enter key
                // Move to next line
                if (cur_y < 15) begin
                    cur_y <= cur_y + 1;
                    cur_x <= 0; // Start from the first column
                end
            end else if (keycode == 8'h08) begin // Backspace
                if (cur_x > 0) begin
                    cur_x <= cur_x - 1; // Move cursor back
                    text_buffer[cur_y][cur_x] <= 8'h00; // Remove character
                end
            end else if (keycode >= 8'h20 && keycode <= 8'h7E) begin
                // ASCII printable characters
                if (cur_x < 15) begin
                    cur_y <= cur_y + 1;
                    cur_x <= 0;
                end
                text_buffer[cur_y][cur_x] <= keycode; // Insert the character 
            end
        end
    end

    // Render the screen
    always @(posedge clk) begin
        if (video_on) begin
            // Check if we're within the text region
            rgb = (text_buffer[char_y][char_x] == 8'h00) ? 12'h000 : 12'hFFF; // White for space, Blue for text
            if (x >= cur_x * CHAR_WIDTH && x < (cur_x + 1) * CHAR_WIDTH && y >= cur_y * CHAR_HEIGHT && y < (cur_y + 1) * CHAR_HEIGHT) begin // Display the cursor (overwrites the text if it's on the cursor position)
                rgb = 12'hF00; // Red cursor color
            end
        end else begin
            rgb = 12'h000;  // No video, black screen
        end
    end

    // Output current cursor position
    always @(posedge clk) begin
        cursor_x <= cur_x;
        cursor_y <= cur_y;
    end

endmodule
