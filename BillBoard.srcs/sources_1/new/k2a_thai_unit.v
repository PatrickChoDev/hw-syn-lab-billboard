`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2024 03:06:23 AM
// Design Name: 
// Module Name: k2a_thai_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module k2a_thai_unit(
		input wire letter_case,
		input wire [7:0] scan_code,
		output reg [7:0] ascii
	);
	
always @*
	begin
	if(letter_case == 1'b0)  // No-shift 
		begin
		case(scan_code)
            8'h23: ascii = 8'h00; // ก
            8'h4E: ascii = 8'h01; // ข
            8'h5D: ascii = 8'h02; // ฃ
            8'h3E: ascii = 8'h03; // ค
            8'h52: ascii = 8'h06; // ง
            8'h45: ascii = 8'h07; // จ
            8'h55: ascii = 8'h09; // ช
            8'h2B: ascii = 8'h13; // ด
            8'h46: ascii = 8'h14; // ต
            8'h2E: ascii = 8'h15; // ถ
            8'h3A: ascii = 8'h16; // ท
            8'h44: ascii = 8'h18; // น
            8'h54: ascii = 8'h19; // บ
            8'h22: ascii = 8'h1A; // ป
            8'h1A: ascii = 8'h1B; // ผ
            8'h4A: ascii = 8'h1C; // ฝ
            8'h2D: ascii = 8'h1D; // พ
            8'h1C: ascii = 8'h1E; // ฟ
            8'h25: ascii = 8'h1F; // ภ
            8'h41: ascii = 8'h20; // ม
            8'h4D: ascii = 8'h21; // ย
            8'h43: ascii = 8'h22; // ร
            8'h5B: ascii = 8'h24; // ล
            8'h4C: ascii = 8'h26; // ว
            8'h4B: ascii = 8'h29; // ส
            8'h1B: ascii = 8'h2A; // ห
            8'h2A: ascii = 8'h2C; // อ
            8'h2C: ascii = 8'h2F; // ะ
            8'h35: ascii = 8'h30; //  ั
            8'h42: ascii = 8'h31; // า
            8'h24: ascii = 8'h32; // ำ
            8'h32: ascii = 8'h33; //  ิ
            8'h3C: ascii = 8'h34; //  ี
            8'h3D: ascii = 8'h35; //  ึ
            8'h34: ascii = 8'h37; // เ
            8'h21: ascii = 8'h38; // แ
            8'h49: ascii = 8'h3A; // ใ
            8'h1D: ascii = 8'h3B; // ไ
            8'h16: ascii = 8'h3C; // ๅ
            8'h15: ascii = 8'h3D; // ๆ
            8'h3B: ascii = 8'h3F; //  ่
            8'h33: ascii = 8'h40; //  ้
            8'h29: ascii = 8'h4D;
            8'h5a: ascii = 8'h4E;   // enter
            8'h66: ascii = 8'h4F;   // backspace
            8'h50: ascii = 8'h50;   // horizontal tab    
          
            default: ascii = 8'h00;
        endcase
        end
    else   // Shifted
        begin
        case(scan_code)
            8'h5D: ascii = 8'h04; // ต
            8'h1B: ascii = 8'h05; // ฆ
            8'h21: ascii = 8'h08; // ฉ
            8'h4C: ascii = 8'h0A; // ซ
            8'h34: ascii = 8'h0B; // ฌ
            8'h4D: ascii = 8'h0C; // ญ
            8'h24: ascii = 8'h0D; // ฎ
            8'h23: ascii = 8'h0E; // ฏ
            8'h54: ascii = 8'h0F; // ฐ
            8'h2D: ascii = 8'h10; // ฑ
            8'h41: ascii = 8'h11; // ฒ
            8'h43: ascii = 8'h12; // ณ
            8'h2C: ascii = 8'h17; // ธ
            8'h1C: ascii = 8'h23; // ฤ
            8'h4A: ascii = 8'h25; // ฦ
            8'h4B: ascii = 8'h27; // ศ
            8'h42: ascii = 8'h28; // ษ
            8'h49: ascii = 8'h2B; // ฬ
            8'h2A: ascii = 8'h2D; // ฮ
            8'h44: ascii = 8'h2E; // ฯ
            8'h3D: ascii = 8'h36; // ฿
            8'h2B: ascii = 8'h39; // โ
            8'h33: ascii = 8'h3E; //  ็
            8'h32: ascii = 8'h41; // ๏
            8'h15: ascii = 8'h42; // ๐
            8'h1E: ascii = 8'h43; // ๑
            8'h26: ascii = 8'h44; // ๒
            8'h25: ascii = 8'h45; // ๓
            8'h2E: ascii = 8'h46; // ๔
            8'h3E: ascii = 8'h47; // ๕
            8'h46: ascii = 8'h48; // ๖
            8'h45: ascii = 8'h49; //๗
            8'h4E: ascii = 8'h4A; // ๘
            8'h55: ascii = 8'h4B; // ๙
            8'h1B: ascii = 8'h4C; // ๚
            8'h29: ascii = 8'h4D;
            8'h5a: ascii = 8'h4E;   // enter
            8'h66: ascii = 8'h4F;   // backspace
            8'h50: ascii = 8'h50;   // horizontal tab    
            
            default: ascii = 8'h51; // *
         endcase
      end
   end
endmodule