`timescale 1ns / 1ps

module tb_top_echoback;

    // Testbench clock and reset
    reg clk;
    reg rst;

    // UART signals
    reg RsRx;      // UART receive input
    wire RsTx;     // UART transmit output
    reg [7:0] received_data;
    // Parameters
    parameter CLK_PERIOD = 10;    // Clock period in ns (100 MHz)
    parameter BAUD_PERIOD = 10417; // Baud rate period in ns (9600 baud)

    // Instantiate DUT (Device Under Test)
    top_echoback #(
        .DATA_BITS(8),
        .SAMPLING(16),
        .BR_LIMIT(651),
        .BR_BITS(10),
        .FIFO_EXP(8)
    ) dut (
        .clk(clk),
        .rst(rst),
        .RsRx(RsRx),
        .RsTx(RsTx)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Reset logic
    initial begin
        rst = 1;
        #(CLK_PERIOD * 5);
        rst = 0;
    end

    // Task for transmitting UART data
    task uart_transmit;
        input [7:0] data;
        integer i;
        begin
            // Start bit (0)
            RsRx = 0;
            #(BAUD_PERIOD);
            
            // Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                RsRx = data[i];
                #(BAUD_PERIOD);
            end
            
            // Stop bit (1)
            RsRx = 1;
            #(BAUD_PERIOD);
        end
    endtask

    // Task for monitoring UART data
    task uart_receive;
        output [7:0] data;
        integer i;
        begin
            // Wait for start bit (falling edge)
            wait (RsTx == 0);
            #(BAUD_PERIOD / 2); // Align to the middle of the start bit
            
            // Read data bits
            for (i = 0; i < 8; i = i + 1) begin
                #(BAUD_PERIOD);
                data[i] = RsTx;
            end
            
            // Wait for stop bit
            #(BAUD_PERIOD);
        end
    endtask

    // Test process
    initial begin
        // Initialize inputs
        RsRx = 1;

        // Wait for reset
        @(negedge rst);

        // Transmit a byte
        $display("Sending: 0x55");
        uart_transmit(8'h55); // Transmit 0x55
        
        // Wait and receive echoed byte
//        #1000; // Wait for FIFO and processing delay
        $display("Receiving echoed byte...");
        uart_receive(received_data);
        $display("Received: 0x%0X", received_data);

        // Check if echoed data matches transmitted data
        if (received_data == 8'h55) begin
            $display("Test Passed: Echoed data matches transmitted data.");
        end else begin
            $display("Test Failed: Echoed data does not match transmitted data.");
        end

        // End simulation
        $stop;
    end

endmodule
