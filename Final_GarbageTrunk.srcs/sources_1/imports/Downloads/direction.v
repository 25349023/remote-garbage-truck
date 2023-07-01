`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/19 02:30:41
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


module PS2_control(clk,rst,vauxp6,vauxn6,vauxp14,vauxn14,vp_in,vn_in,an,seg, LED, dir);
    input clk;
    input rst;
    wire dclk;
    input vauxp6;
    input vauxn6;
    input vauxp14;
    input vauxn14;
    input vp_in;
    input vn_in;
    output [3:0] an;
    output [6:0] seg;
    output [15:0] LED;
    output [2:0] dir;  
    reg [6:0] seg;
    wire num;

    wire enable1, enable2;  
    wire ready1, ready2;
    wire [15:0] data_h, data_v;   
    reg [6:0] Address_in;
    
    clock_divider #(17) cd(clk, dclk);
    
    wire dir_control;
    dir_change dc(dclk,rst,dir_control);


    xadc_wiz_1  XLXI_7 (
        .daddr_in(Address_in), //addresses can be found in the artix 7 XADC user guide DRP register space
        .dclk_in(clk), 
        .den_in(enable1), 
        .di_in(0), 
        .dwe_in(0), 
        .busy_out(),                    
        .vauxp7(vauxp6),
        .vauxn7(vauxn6),
        .vauxp15(vauxp14),
        .vauxn15(vauxn14),
        .vn_in(vn_in), 
        .vp_in(vp_in), 
        .alarm_out(), 
        .do_out(data_h), 
        .reset_in(),
        .eoc_out(enable1),
        .channel_out(),
        .drdy_out(ready1)
    );
    
    
//    xadc_wiz_1  XLXI_0 (
//        .daddr_in(8'h1e), //addresses can be found in the artix 7 XADC user guide DRP register space
//        .dclk_in(clk), 
//        .den_in(1'b1), 
//        .di_in(0), 
//        .dwe_in(0), 
//        .busy_out(),                    
//        .vauxp14(vauxp14),
//        .vauxn14(vauxn14),
//        .vn_in(vn_in), 
//        .vp_in(vp_in), 
//        .alarm_out(), 
//        .do_out(data_v), 
//        .reset_in(),
//        .eoc_out(enable2),
//        .channel_out(),
//        .drdy_out(ready2)
//    );
    
    
    
    always @(posedge(clk)) begin
        case(dir_control)
        1'b0: Address_in <= 8'h17;//horizon
        1'b1: Address_in <= 8'h1f;//vertical
        endcase
    end

  
    direction d(dclk, rst, dir_control, data_h, ready1, dir);
    parameter up=3'd0;
    parameter left=3'd1;
    parameter right=3'd2;
    parameter down=3'd3;
    parameter no=3'd4;
    
    always@(posedge clk)begin
        case(dir)
            up:seg=7'b0111111;
            down:seg=7'b1110111;
            left:seg=7'b1111001;
            right:seg=7'b1001111;
            no:seg=7'b0000000;
        endcase
    end
    
    assign an=4'b1110;
    assign LED=data_h;    
endmodule


module direction(clk, rst_n, dir_ctrl, data_h, ready ,dir);
    parameter up=3'd0;
    parameter left=3'd1;
    parameter right=3'd2;
    parameter down=3'd3;
    parameter no=3'd4;
    input clk, rst_n, dir_ctrl;
    input [15:0] data_h;
    input ready;
    output [2:0] dir;
    reg [2:0] dir;
    reg [2:0] next_dir;
    reg flag, next_flag;
    
    always@(posedge clk)begin
        if (!rst_n) begin 
            dir<=no;
            flag <= 1'b0;        
        end 
        else begin 
            dir<=next_dir;
            flag <= next_flag;
        end 
    end
    
    always@(*)begin
//        if (ready) begin 
        if (dir_ctrl == 1'b0) begin 
            if(data_h==16'd0) begin 
                next_dir = left;
                next_flag = 1'b0;
            end 
            else if(data_h==16'd65535) begin 
                next_dir = right;
                next_flag = 1'b0;
            end 
            else begin 
                if (flag) begin 
                    next_dir = no;
                    next_flag = 1'b0;
                end else begin 
                    next_dir = dir;
                    next_flag = 1'b1;
                end  
            end 
        end else begin 
            if(data_h==16'd0) begin 
                next_dir = up;
                next_flag = 1'b0;
            end 
            else if(data_h>=16'd55000) begin 
                next_dir = down;
                next_flag = 1'b0;
            end 
            else begin 
                if (flag) begin 
                    next_dir = no;
                    next_flag = 1'b0;
                end else begin 
                    next_dir = dir;
                    next_flag = 1'b1;
                end  
            end 
        end 
//        end else begin 
//            next_dir = dir;
//            next_flag = flag;
//        end 
    end
endmodule

module dir_change(clk,rst,dir_control);
    input clk;
    input rst;
    output dir_control;
    reg dir_control;
    wire next_dir_control;
    
    always@(posedge clk)begin
        if(rst == 1'b0)dir_control<=1'b0;
        else dir_control<=next_dir_control;
    end
    assign next_dir_control=~dir_control;
endmodule
