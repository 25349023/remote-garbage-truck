`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/19 10:48:03
// Design Name: 
// Module Name: motor_tb
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


module motor_tb;
    reg clk = 1'b1, rst_n = 1'b1;
    wire dclk, mclk;
    wire [1:0] state;
    
    parameter cyc = 2;
    always #(cyc / 2) clk = ~clk;
    
    motor_divider md(clk, rst_n, dclk);

    initial begin 
        @ (negedge clk) rst_n = 1'b0;
        @ (posedge clk);
        @ (negedge clk) rst_n = 1'b1;
        #(cyc * 100) $finish;
    end 
    
    
    
endmodule
