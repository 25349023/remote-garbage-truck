`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/01/04 22:19:00
// Design Name: 
// Module Name: TrunkDriver
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


module TrunkDriver(clk, reset, sw, speed, receive, an, seg, in1, in2, in3, in4, step);
    input clk, reset;
    input sw, speed;
    input receive;
    output [3:0] an;
    output reg [6:0] seg;
    output in1, in2, in3, in4;
    output [3:0] step;
    
    wire reset_db, rst, rst_n;
    
    debounce d0(clk, reset, reset_db);
    onepulse op0(clk, reset_db, rst);
    not n0(rst_n, rst);
    
    parameter up    = 3'd0;
    parameter left  = 3'd1;
    parameter right = 3'd2;
    parameter down  = 3'd3;
    parameter no    = 3'd4;
    
    wire [7:0] data;
    reg [2:0] dire;

    motor mt0(clk, dire, in1, in2, in3, in4);
    
    NEC_Decoder nd0(clk, rst_n, ~receive, data);
    
    
    wire mclk;
    wire [3:0] step_2, step_12;
    
    motor_divider md(.clk(clk), .rst_n(rst_n),  .dclk(mclk));
    
    step_motor_ph12 stm1(mclk, rst_n, sw, step_12);
    step_motor_ph2 stm2(mclk, rst_n, sw, step_2);
    
    assign step = (speed)? step_2 : step_12;

        
    always @(*) begin 
        case (data) 
            8'h00:   seg = 7'b0000001;
            8'h33:   seg = 7'b1001111;
            8'h77:   seg = 7'b0010010;
            8'hBB:   seg = 7'b0000110;
            8'hFF:   seg = 7'b1001100;
            default: seg = 7'b0110110;
        endcase 
    end 
    
    always @(*) begin 
        case (data) 
            8'h00:   dire = no;
            8'h33:   dire = up;
            8'h77:   dire = left;
            8'hBB:   dire = right;
            8'hFF:   dire = down;
            default: dire = no;
        endcase 
    end 
    
    assign an = 4'b1110;
endmodule
