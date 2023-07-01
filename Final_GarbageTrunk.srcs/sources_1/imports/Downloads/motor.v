`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/19 13:44:54
// Design Name: 
// Module Name: TEST
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


module motor(clk,dir,in1,in2,in3,in4);
    parameter up=3'd0;
    parameter left=3'd1;
    parameter right=3'd2;
    parameter down=3'd3;
    parameter no=3'd4;
    input clk;
    input [2:0] dir;
    output in1,in2;
    output in3,in4;
    reg in1,in2;
    reg in3,in4;
    reg next_in1,next_in2;
    reg next_in3,next_in4;
    
    always@(posedge clk)begin
        in1<=next_in1;
        in2<=next_in2;
        in3<=next_in3;
        in4<=next_in4;
    end

    always@(*)begin
        case(dir)
            up:begin
                next_in1=1'b0;
                next_in2=1'b1;
                next_in3=1'b0;
                next_in4=1'b1;  
            end
            down:begin
                next_in1=1'b1;
                next_in2=1'b0;
                next_in3=1'b1;
                next_in4=1'b0;   
            end
            left:begin
                next_in1=1'b1;
                next_in2=1'b0;
                next_in3=1'b0;
                next_in4=1'b1; 
            end
            right:begin
                next_in1=1'b0;
                next_in2=1'b1;
                next_in3=1'b1;
                next_in4=1'b0; 
            end
            no:begin
                next_in1=1'b0;
                next_in2=1'b0;
                next_in3=1'b0;
                next_in4=1'b0; 
            end
        endcase
    end
    
    //PWM_gen p1(clk,10'd500,32'd100,ena);
    //PWM_gen p2(clk,10'd500,32'd100,enb);
endmodule

module PWM_gen(clk,duty,freq,PWM);
input clk;
input [9:0] duty;
input [31:0] freq;
output PWM;
reg PWM;
wire [31:0] count_max=100000000/freq;
wire [31:0] count_duty;
reg [31:0] count=32'd0;
    always@(posedge clk)begin
        if(count<count_max)begin
            count<=count+1'b1;
            if(count<count_duty)PWM<=1'b1;
            else PWM<=1'b0;
        end
        else begin
            count<=32'd0;
            PWM<=1'b0;
        end
    end
assign count_duty=count_max*duty/1024;
endmodule