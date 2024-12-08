`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Reference Book: 
// Chu, Pong P.
// Wiley, 2008
// "FPGA Prototyping by Verilog Examples: Xilinx Spartan-3 Version" 
// 
// Adapted for the Basys 3 by David J. Marion
// Comments by David J. Marion
//
// FOR USE WITH AN FPGA THAT HAS A 100MHz CLOCK SIGNAL ONLY.
// VGA Mode
// 640x480 pixels VGA screen with 25MHz pixel rate based on 60 Hz refresh rate
// 800 pixels/line * 525 lines/screen * 60 screens/second = ~25.2M pixels/second
//
// A 25MHz signal will suffice. The Basys 3 has a 100MHz signal available, so a
// 25MHz tick is created for syncing the pixel counts, pixel tick, horiz sync, 
// vert sync, and video on signals.
//////////////////////////////////////////////////////////////////////////////////

module vga_controller(
    input clk_100MHz,   // from Basys 3
    input reset,        // system reset
    output video_on,    // ON while pixel counts for x and y and within display area
    output hsync,       // horizontal sync
    output vsync,       // vertical sync
    output p_tick,      // the 25MHz pixel/second rate signal, pixel tick
    output [9:0] x,     // pixel count/position of pixel x, max 0-799
    output [9:0] y      // pixel count/position of pixel y, max 0-524
    );
    
    // Based on VGA standards found at vesa.org for 640x480 resolution
    // Total horizontal width of screen = 800 pixels, partitioned  into sections
    parameter HD = 640;             // horizontal display area width in pixels
    parameter HF = 48;              // horizontal front porch width in pixels
    parameter HB = 16;              // horizontal back porch width in pixels
    parameter HR = 96;              // horizontal retrace width in pixels
    parameter HMAX = HD+HF+HB+HR-1; // max value of horizontal counter = 799
    // Total vertical length of screen = 525 pixels, partitioned into sections
    parameter VD = 480;             // vertical display area length in pixels 
    parameter VF = 10;              // vertical front porch length in pixels  
    parameter VB = 33;              // vertical back porch length in pixels   
    parameter VR = 2;               // vertical retrace length in pixels  
    parameter VMAX = VD+VF+VB+VR-1; // max value of vertical counter = 524   
    
    // *** Generate 25MHz from 100MHz *********************************************************
	reg  [1:0] r_25MHz;
	wire w_25MHz;
	
	always @(posedge clk_100MHz or posedge reset)
		if(reset)
		  r_25MHz <= 0;
		else
		  r_25MHz <= r_25MHz + 1;
	
	assign w_25MHz = (r_25MHz == 0) ? 1 : 0; // assert tick 1/4 of the time
    // ****************************************************************************************
    
    // Counter Registers, two each for buffering to avoid glitches
    reg [9:0] h_count_reg, h_count_next;
    reg [9:0] v_count_reg, v_count_next;
    
    // Output Buffers
    reg v_sync_reg, h_sync_reg;
    wire v_sync_next, h_sync_next;
    
    // Register Control
    always @(posedge clk_100MHz or posedge reset)
        if(reset) begin
            v_count_reg <= 0;
            h_count_reg <= 0;
            v_sync_reg  <= 1'b0;
            h_sync_reg  <= 1'b0;
        end
        else begin
            v_count_reg <= v_count_next;
            h_count_reg <= h_count_next;
            v_sync_reg  <= v_sync_next;
            h_sync_reg  <= h_sync_next;
        end
         
    //Logic for horizontal counter
    always @(posedge w_25MHz or posedge reset)      // pixel tick
        if(reset)
            h_count_next = 0;
        else
            if(h_count_reg == HMAX)                 // end of horizontal scan
                h_count_next = 0;
            else
                h_count_next = h_count_reg + 1;         
  
    // Logic for vertical counter
    always @(posedge w_25MHz or posedge reset)
        if(reset)
            v_count_next = 0;
        else
            if(h_count_reg == HMAX)                 // end of horizontal scan
                if((v_count_reg == VMAX))           // end of vertical scan
                    v_count_next = 0;
                else
                    v_count_next = v_count_reg + 1;
        
    // h_sync_next asserted within the horizontal retrace area
    assign h_sync_next = (h_count_reg >= (HD+HB) && h_count_reg <= (HD+HB+HR-1));
    
    // v_sync_next asserted within the vertical retrace area
    assign v_sync_next = (v_count_reg >= (VD+VB) && v_count_reg <= (VD+VB+VR-1));
    
    // Video ON/OFF - only ON while pixel counts are within the display area
    assign video_on = (h_count_reg < HD) && (v_count_reg < VD); // 0-639 and 0-479 respectively
            
    // Outputs
    assign hsync  = h_sync_reg;
    assign vsync  = v_sync_reg;
    assign x      = h_count_reg;
    assign y      = v_count_reg;
    assign p_tick = w_25MHz;
            
endmodule


//module vga_controller(
//	input clk_100MHz, 
//	input reset,
//	output hsync, 
//	output vsync, 
//	output video_on, 
//	output p_tick,
//	output [10:0] x, 
//	output [10:0] y
//);
	
//	// VESA Signal 800 x 600 @ 72Hz timing
//	// constant declarations for VGA sync parameters
//	localparam H_DISPLAY       = 800; // horizontal display area
//	localparam H_L_BORDER      =  64; // horizontal left border
//	localparam H_R_BORDER      =  56; // horizontal right border
//	localparam H_RETRACE       =  120; // horizontal retrace
//	localparam H_MAX           = H_DISPLAY + H_L_BORDER + H_R_BORDER + H_RETRACE - 1;
//	localparam START_H_RETRACE = H_DISPLAY + H_R_BORDER;
//	localparam END_H_RETRACE   = H_DISPLAY + H_R_BORDER + H_RETRACE - 1;
	
//	localparam V_DISPLAY       = 600; // vertical display area
//	localparam V_T_BORDER      =  37; // vertical top border
//	localparam V_B_BORDER      =  23; // vertical bottom border
//	localparam V_RETRACE       =   6; // vertical retrace
//	localparam V_MAX           = V_DISPLAY + V_T_BORDER + V_B_BORDER + V_RETRACE - 1;
//    	localparam START_V_RETRACE = V_DISPLAY + V_B_BORDER;
//	localparam END_V_RETRACE   = V_DISPLAY + V_B_BORDER + V_RETRACE - 1;
	
//	// mod-2 counter to generate 50 MHz pixel tick
//	reg pixel_reg;
//	wire pixel_next, pixel_tick;
	
//	always @(posedge clk_100MHz)
//		pixel_reg <= pixel_next;
	
//	assign pixel_next = ~pixel_reg; // next state is complement of current
	
//	assign pixel_tick = (pixel_reg == 0); // assert tick half of the time
	
//	// registers to keep track of current pixel location
//	reg [10:0] h_count_reg, h_count_next, v_count_reg, v_count_next;
	
//	// register to keep track of vsync and hsync signal states
//	reg vsync_reg, hsync_reg;
//	wire vsync_next, hsync_next;
 
//	// infer registers
//	always @(posedge clk_100MHz, posedge reset)
//		if(reset)
//		    begin
//                    v_count_reg <= 0;
//                    h_count_reg <= 0;
//                    vsync_reg   <= 0;
//                    hsync_reg   <= 0;
//	            end
//		else
//		    begin
//                    v_count_reg <= v_count_next;
//                    h_count_reg <= h_count_next;
//                    vsync_reg   <= vsync_next;
//                    hsync_reg   <= hsync_next;
//	            end
			
//	// next-state logic of horizontal vertical sync counters
//	always @*
//		begin
//		h_count_next = pixel_tick ? 
//		               h_count_reg == H_MAX ? 0 : h_count_reg + 1
//			       : h_count_reg;
		
//		v_count_next = pixel_tick && h_count_reg == H_MAX ? 
//		               (v_count_reg == V_MAX ? 0 : v_count_reg + 1) 
//			       : v_count_reg;
//		end
		
//        // hsync and vsync are active low signals
//        // hsync signal asserted during horizontal retrace
//        assign hsync_next = h_count_reg >= START_H_RETRACE 
//                            && h_count_reg <= END_H_RETRACE;
   
//        // vsync signal asserted during vertical retrace
//        assign vsync_next = v_count_reg >= START_V_RETRACE 
//                            && v_count_reg <= END_V_RETRACE;

//        // video only on when pixels are in both horizontal and vertical display region
//        assign video_on = (h_count_reg < H_DISPLAY) 
//                           && (v_count_reg < V_DISPLAY);

//        // output signals
//        assign hsync  = hsync_reg;
//        assign vsync  = vsync_reg;
//        assign x      = h_count_reg;
//        assign y      = v_count_reg;
//        assign p_tick = pixel_tick;
//endmodule