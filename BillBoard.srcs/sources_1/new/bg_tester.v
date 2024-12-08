`timescale 1ns / 1ps

module bg_tester(
    input clk,
    input wire [9:0] h_pos, // Horizontal position of the pixel
    input wire [9:0] v_pos, // Vertical position of the pixel
    output wire [11:0] rgb   // 12-bit RGB color for VGA output
);

    // VGA resolution constants
    parameter H_DISPLAY = 640;  // Horizontal active video
    parameter V_DISPLAY = 480;  // Vertical active video

    // Address calculation for ROM access
    wire [18:0] address = (v_pos / 2) * (H_DISPLAY / 2) + (h_pos / 2);
    wire [11:0] pixel_data;  // 12-bit pixel data from ROM

    // Instantiate the ROM module
    bg_rom rom (
        .clk(clk),
        .addr(address),
        .data(pixel_data)
    );

    // Temporary registers for RGB channels
    reg [3:0] r, g, b;

    // Output RGB signals
    assign rgb = pixel_data;  // Concatenate the 3 color channels to form 12-bit color

    // Render background image on the VGA
    always @(posedge clk) begin
        if (h_pos < H_DISPLAY && v_pos < V_DISPLAY) begin
            // Decode 12-bit pixel data into RGB channels
            r = pixel_data[11:8]; // Red channel (bits 11 to 8)
            g = pixel_data[7:4];  // Green channel (bits 7 to 4)
            b = pixel_data[3:0];  // Blue channel (bits 3 to 0)
        end else begin
            // Default color if outside the visible area
            r = 4'b0000;
            g = 4'b0000;
            b = 4'b0000;
        end
    end
endmodule

