`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/01/04 20:40:36
// Design Name: 
// Module Name: RemoteController
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


module RemoteController(clk, reset, sw, vauxp6, vauxn6, vauxp14, vauxn14, vp_in, vn_in, an, seg, LED, transmit);
    input clk, reset;
    input sw;
    input vauxp6, vauxn6;
    input vauxp14, vauxn14;
    input vp_in, vn_in;
    output [3:0] an;
    output [6:0] seg;
    output [15:0] LED;
    output transmit;
    
    wire [2:0] dire;
    
    wire reset_db, rst, rst_n;
    
    debounce d0(clk, reset, reset_db);
    onepulse op0(clk, reset_db, rst);
    not n0(rst_n, rst);

    PS2_control pc0(clk, rst_n, vauxp6, vauxn6, vauxp14, vauxn14, vp_in, vn_in, an, seg, LED, dire);
    
    NEC_Encoder ne0(.clk(clk), .rst_n(rst_n), .en(~dire[2]), .direction(dire[1:0]), .data(8'hFF), .irout(transmit));

    // assign LED = dire;
endmodule
