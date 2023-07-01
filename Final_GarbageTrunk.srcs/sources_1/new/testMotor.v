`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/17 21:58:47
// Design Name: 
// Module Name: testMotor
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


module testMotor(clk, reset, sw, LED, step);
    input clk, reset;
    input [1:0] sw;
    output LED;
    output [3:0] step;
    
    wire reset_db, rst, rst_n;
    wire dclk, mclk;
    
    clock_divider #(12) cd0(clk, dclk);

    motor_divider md(.clk(clk), .rst_n(rst_n),  .dclk(mclk));
    
    debounce d0(dclk, reset, reset_db);
    onepulse op0(clk, reset_db, rst);
    not n0(rst_n, rst);
    
    wire [3:0] step_2, step_12;
    
    step_motor_ph12 stm1(mclk, rst_n, sw[0], step_12);
    step_motor_ph2 stm2(mclk, rst_n, sw[0], step_2);
    
    assign LED = sw[0];
    assign step = (sw[1])? step_2 : step_12;
endmodule

module step_motor_ph2(clk, rst_n, en, step_cmd);
    input clk, rst_n, en;
    output [3:0] step_cmd;
    
    parameter AB = 2'b00; 
    parameter BC = 2'b01; 
    parameter CD = 2'b10; 
    parameter DA = 2'b11;
    
    reg [1:0] state, next_state;
    reg [3:0] cmd;
    
    always @(posedge clk) begin 
        if (rst_n == 1'b0)  state <= AB;
        else                state <= next_state;
    end 
    
    always @(*) begin 
        case (state) 
            AB: begin
                next_state = BC;
                cmd = 4'b0011;
            end
            BC: begin
                next_state = CD;
                cmd = 4'b0110;
            end
            CD: begin
                next_state = DA;
                cmd = 4'b1100;
            end
            DA: begin
                next_state = AB;
                cmd = 4'b1001;
            end 
        endcase 
    end 
    
    assign step_cmd = (en)? cmd : 4'b0000; 

endmodule 

module step_motor_ph12(clk, rst_n, en, step_cmd);
    input clk, rst_n, en;
    output [3:0] step_cmd;
    
    parameter A  = 3'b000;
    parameter AB = 3'b001; 
    parameter B  = 3'b010;
    parameter BC = 3'b011; 
    parameter C  = 3'b100;
    parameter CD = 3'b101; 
    parameter D  = 3'b110;
    parameter DA = 3'b111;
    
    reg [2:0] state, next_state;
    reg [3:0] cmd;
    
    always @(posedge clk) begin 
        if (rst_n == 1'b0)  state <= AB;
        else                state <= next_state;
    end 
    
    always @(*) begin 
        case (state) 
            A: begin
                next_state = AB;
                cmd = 4'b0001;
            end
            B: begin
                next_state = BC;
                cmd = 4'b0010;
            end
            C: begin
                next_state = CD;
                cmd = 4'b0100;
            end
            D: begin
                next_state = DA;
                cmd = 4'b1000;
            end 
            AB: begin
                next_state = B;
                cmd = 4'b0011;
            end
            BC: begin
                next_state = C;
                cmd = 4'b0110;
            end
            CD: begin
                next_state = D;
                cmd = 4'b1100;
            end
            DA: begin
                next_state = A;
                cmd = 4'b1001;
            end 
        endcase 
    end 
    
    assign step_cmd = (en)? cmd : 4'b0000; 

endmodule 

module clock_divider #(parameter n = 10) (clk, dclk);
    input clk;
    output dclk; 
    
    reg [n-1:0] count = {n{1'b0}}, next_count;
    
    always @(posedge clk) begin 
        count <= count + 1'b1; 
    end 
        
    assign dclk = count[n-1];
endmodule 

module clock_divide_pulse #(parameter n = 10) (clk, dclk);
    input clk;
    output dclk; 
    
    reg [n-1:0] count = {n{1'b0}}, next_count;
    
    always @(posedge clk) begin 
        count <= count + 1'b1; 
    end 
        
    assign dclk = &count;
endmodule 

module motor_divider (clk, rst_n, dclk);
    input clk, rst_n;
    output dclk;
    
    wire mclk;
    clock_divide_pulse #(16) cd(clk, mclk);
    
    parameter UP    = 2'b00;
    parameter DOWN1 = 2'b01;
    parameter DOWN2 = 2'b10;

    reg [1:0] state, next_state;
    
    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            state <= UP;
        end 
        else begin  
            if (mclk)  state <= next_state;
            else       state <= state;
        end 
    end 
    
    always @(*) begin 
        case (state)
            UP: begin 
                next_state = DOWN1;
            end 
            DOWN1: begin 
                next_state = DOWN2;
            end 
            DOWN2: begin 
                next_state = UP;
            end 
            default: begin 
                next_state = DOWN1;
             end
        endcase
    end 
    
    assign dclk = (state == UP)? 1'b1: 1'b0;
        
endmodule 
