`timescale 1ns / 1ps

module ps2_keyboard (
    input wire          clk,
    input wire          reset,
    input wire          ps2_data,
    input wire          ps2_clk,
    output wire [8:0]   rx_data,    // data with parity in MSB position
    output wire         rx_ready    // rx_data has valid/stable data
    );

    reg [9:0]   rx_reg, rx_next;                // one less to discard the start bit 
    reg [3:0]   rx_count_reg, rx_count_next;
    reg         rx_ready_reg, rx_ready_next;
    reg         ps2_clk_sync_1, ps2_clk_sync_2; // Synchronize ps2_clk to FPGA clock
    wire        rx_ready_pulse;
    wire        ps2_clk_rising_edge;

    // Synchronize the ps2_clk to the FPGA clock domain
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ps2_clk_sync_1 <= 1'b0;
            ps2_clk_sync_2 <= 1'b0;
        end else begin
            ps2_clk_sync_1 <= ps2_clk;
            ps2_clk_sync_2 <= ps2_clk_sync_1;
        end
    end

    // Detect rising edge of synchronized ps2_clk
    assign ps2_clk_rising_edge = (ps2_clk_sync_1 & ~ps2_clk_sync_2);

    // Generate pulse when rx_ready_next is high (indicating a new byte)
    single_pulser pulser(
        .clk(clk),
        .reset(reset),
        .trigger(rx_ready_next),
        .pulse(rx_ready_pulse)
    );

    // Async reset for data and counters
    always @ (posedge ps2_clk_sync_2 or posedge reset) begin
        if (reset) begin
            rx_reg <= 0;
            rx_count_reg <= 0;
            rx_ready_reg <= 0;
        end else if (ps2_clk_rising_edge) begin
            rx_reg <= rx_next;
            rx_count_reg <= rx_count_next;
            rx_ready_reg <= rx_ready_pulse;
        end
    end

    // Update next states for data and counters
    always @(*) begin
        rx_next = { ps2_data, rx_reg[9:1] };        // shift in LSB first
        rx_count_next = ( rx_count_reg + 1 ) % 11;  // modulo 11 counter (for 8 data bits + 1 parity + 1 stop)
        rx_ready_next = (rx_count_reg == 10) && (ps2_data == 1'b0); // rx_ready high when key is pressed (ps2_data is 0)
    end

    // Final output assignments
    assign rx_ready = rx_ready_reg;
    assign rx_data = rx_reg[8:0];                   // prune off the stop bit

endmodule
