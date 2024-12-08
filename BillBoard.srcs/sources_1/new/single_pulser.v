`timescale 1ns / 1ps

module single_pulser (
    input wire clk,       // Clock input
    input wire reset,     // Reset input
    input wire trigger,   // Trigger signal to generate a pulse
    output reg pulse      // Single pulse output
);

    // State to track the pulse generation
    reg trigger_d; // Delayed trigger to detect trigger edge

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pulse <= 0;  // Reset pulse
            trigger_d <= 0; // Reset delayed trigger
        end
        else begin
            // Detect the rising edge of the trigger
            if (trigger && !trigger_d) begin
                pulse <= 1;  // Generate the pulse on rising edge of trigger
            end else begin
                pulse <= 0;  // End pulse after one clock cycle
            end

            // Delay the trigger signal by one clock cycle
            trigger_d <= trigger;
        end
    end

endmodule

