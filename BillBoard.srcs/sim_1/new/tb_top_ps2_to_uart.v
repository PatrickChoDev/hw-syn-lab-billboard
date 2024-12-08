`timescale 1ns / 1ps

module tb_top_ps2_to_uart;

    // Testbench Inputs
    reg clk;
    reg reset;
    reg ps2_clk;
    reg ps2_data;

    // Testbench Output
    wire tx;

    // Clock generation (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // Toggle every 5 ns -> 100 MHz
    end

    // Instantiate the top module
    top_ps2_to_uart uut (
        .clk(clk),
        .rst(reset),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .uart_rx(),
        .uart_tx(tx)
    );

    // PS/2 Keyboard Simulation
    initial begin
        // Initialize Inputs
        reset = 1;
        ps2_clk = 1;
        ps2_data = 1;

        // Release reset after some time
        #20;
        reset = 0;

        // Simulate a keypress for 'A' (scan code = 8'h1C -> ASCII = 8'h41)
        send_ps2_scan_code(8'h1C);

        // Simulate a keypress for 'B' (scan code = 8'h32 -> ASCII = 8'h42)
        #10000;  // Wait before sending next key
        send_ps2_scan_code(8'h32);

        // Simulate a keypress for 'Enter' (scan code = 8'h5A -> ASCII = 8'h0D)
        #10000;  // Wait before sending next key
        send_ps2_scan_code(8'h5A);

        // Finish simulation
        #50000;
        $stop;
    end

    // Task to simulate sending a PS/2 scan code
    task send_ps2_scan_code(input [7:0] scan_code);
        integer i;
        begin
            // Start bit (0)
            ps2_data = 0;
            ps2_clk_toggle();
            
            // Send 8 bits of scan code (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                ps2_data = scan_code[i];
                ps2_clk_toggle();
            end

            // Parity bit (odd parity)
            ps2_data = ~^scan_code;  // XOR all bits for odd parity
            ps2_clk_toggle();

            // Stop bit (1)
            ps2_data = 1;
            ps2_clk_toggle();
        end
    endtask

    // Task to simulate PS/2 clock toggling
    task ps2_clk_toggle;
        begin
            #50 ps2_clk = 0;  // Clock low for 50 ns
            #50 ps2_clk = 1;  // Clock high for 50 ns
        end
    endtask

    // Monitor Outputs
    initial begin
        $monitor("Time: %0d | tx: %b", $time, tx);
    end

endmodule
