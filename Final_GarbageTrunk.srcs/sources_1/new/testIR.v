`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/12 19:42:32
// Design Name: 
// Module Name: testIR
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


module testIR(clk, reset, sw, dire, LED, an, seg, transmit, receive);
    input clk, reset;
    input sw, receive;
    input [1:0] dire;
    output [15:0] LED;
    output [3:0] an;
    output reg [6:0] seg;
    output transmit;
    
    wire reset_db, rst, rst_n;
    
    debounce d0(clk, reset, reset_db);
    onepulse op0(clk, reset_db, rst);
    not n0(rst_n, rst);
    
    
    NEC_Encoder nec_e(.clk(clk), .rst_n(rst_n), .en(sw), .direction(dire), .data(8'hFF), .irout(transmit));
    
    wire [7:0] data;
    
    NEC_Decoder nec_d(clk, rst_n, ~receive, data);
        
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
    
    assign an = 4'b1110;
    
    assign LED[0] = sw;
    assign LED[1] = transmit;
    assign LED[15] = ~receive;
    assign LED[14] = (data != 8'h0);
    assign LED[13:2] = 1'b0;
endmodule


module NEC_Encoder(clk, rst_n, en, direction, data, irout);
    input clk, rst_n, en;
    input [1:0] direction;
    input [7:0] data;
    output irout;

    parameter STOP        = 3'd0; 
    parameter HDR_MARK1   = 3'd1; 
    parameter HDR_MARK2   = 3'd2; 
    parameter HDR_SPACE   = 3'd3; 
    parameter BIT_MARK    = 3'd4; 
    parameter ONE_SPACE   = 3'd5; 
    parameter ZERO_SPACE  = 3'd6; 
    parameter RPT_SPACE   = 3'd7; 
    
    reg [2:0] state, next_state;
    reg [2:0] sel, next_sel;
    
    reg en_hdr, en_onesp, en_mark, en_rpt;
    wire hdr_done, onesp_done, mark_done, rpt_done;
    reg [31:0] rpt_period;
    
    
    reg ir_raw;
    
    Modulation_38kHz md38(.clk(clk), .rst_n(rst_n), .en(ir_raw), .signal_md(irout));
    
    // 32'd56000, 32'd169000, 32'd450000
    timer tm_hdr(.clk(clk), .rst_n(rst_n), .en(en_hdr), .period(32'd450000), .dout(hdr_done));
    timer tm_one(.clk(clk), .rst_n(rst_n), .en(en_onesp), .period(32'd169000), .dout(onesp_done));
    timer tm_mark(.clk(clk), .rst_n(rst_n), .en(en_mark), .period(32'd56000), .dout(mark_done));
    timer tm_rpt(.clk(clk), .rst_n(rst_n), .en(en_rpt), .period(rpt_period), .dout(rpt_done));
    
    always @(posedge clk) begin 
        if (rst_n == 1'b0) begin
            state <= STOP;
            sel <= 3'd7;
        end else begin 
            state <= next_state;
            sel <= next_sel;
        end 
    end 
    
    always @(*) begin 
        case (state) 
            STOP: begin 
                if (en)  next_state = HDR_MARK1;
                else     next_state = state;
            end 
            HDR_MARK1: begin 
                if (en) begin  
                    if (hdr_done)  next_state = HDR_MARK2;
                    else           next_state = state;
                end 
                else  next_state = STOP;
            end 
            HDR_MARK2: begin 
                if (en) begin  
                    if (hdr_done)  next_state = HDR_SPACE;
                    else           next_state = state;                
                end 
                else  next_state = STOP;
            end 
            HDR_SPACE: begin 
                if (en) begin  
                    if (hdr_done)  next_state = BIT_MARK;
                    else           next_state = state;                
                end 
                else  next_state = STOP;
            end 
            BIT_MARK: begin 
                if (en) begin  
                    if (mark_done) begin 
                        next_state = (data[sel] == 1'b1) ? ONE_SPACE : ZERO_SPACE; 
                    end  
                    else  next_state = state;                
                end 
                else  next_state = STOP;
            end 
            ONE_SPACE: begin 
                if (en) begin  
                    if (onesp_done) begin 
                        if (sel == 3'b0)  next_state = RPT_SPACE;
                        else              next_state = BIT_MARK;
                    end 
                    else           next_state = state;                
                end 
                else  next_state = STOP;
            end 
            ZERO_SPACE: begin 
                if (en) begin  
                    if (mark_done) begin 
                        if (sel == 3'b0)  next_state = RPT_SPACE;
                        else              next_state = BIT_MARK;
                    end 
                    else           next_state = state;                
                end 
                else  next_state = STOP;
            end 
            RPT_SPACE: begin 
                if (en) begin  
                    if (rpt_done)  next_state = HDR_MARK1;
                    else           next_state = state;                
                end 
                else  next_state = STOP;
            end 
            default: begin 
                next_state = STOP;
            end 
        endcase
    end 
    
    always @(*) begin 
        case (state) 
            STOP: begin 
                if (en) begin 
                    {en_hdr, en_onesp, en_mark, en_rpt} = 4'b1000;
                end else begin 
                    {en_hdr, en_onesp, en_mark, en_rpt} = 4'b0000;
                end 
            end 
            HDR_MARK1: begin 
                {en_hdr, en_onesp, en_mark, en_rpt} = 4'b1000;
            end 
            HDR_MARK2: begin 
                {en_hdr, en_onesp, en_mark, en_rpt} = 4'b1000;
            end 
            HDR_SPACE: begin 
                if (hdr_done) begin 
                    {en_hdr, en_onesp, en_mark, en_rpt} = 4'b0010;
                end else begin 
                    {en_hdr, en_onesp, en_mark, en_rpt} = 4'b1000;
                end 
            end 
            BIT_MARK: begin 
                if (mark_done) begin 
                    {en_hdr, en_onesp, en_mark, en_rpt} = (data[sel] == 1'b1) ? 4'b0100 : 4'b0010;
                end else begin 
                    {en_hdr, en_onesp, en_mark, en_rpt} = 4'b0010;
                end 
            end 
            ONE_SPACE: begin 
                if (onesp_done) begin 
                    if (sel == 3'b0)  {en_hdr, en_onesp, en_mark, en_rpt} = 4'b0001;
                    else              {en_hdr, en_onesp, en_mark, en_rpt} = 4'b0010;
                end else begin 
                    {en_hdr, en_onesp, en_mark, en_rpt} = 4'b0100;
                end 
            end 
            ZERO_SPACE: begin 
                if (sel == 3'b0)  {en_hdr, en_onesp, en_mark, en_rpt} = 4'b0001;
                else              {en_hdr, en_onesp, en_mark, en_rpt} = 4'b0010;
            end 
            RPT_SPACE: begin 
                if (rpt_done) begin 
                    {en_hdr, en_onesp, en_mark, en_rpt} = 4'b1000;
                end else begin  
                    {en_hdr, en_onesp, en_mark, en_rpt} = 4'b0001;
                end 
            end 
            default: begin 
                {en_hdr, en_onesp, en_mark, en_rpt} = 4'b0000;
            end 
        endcase
    end 
    
    always @(*) begin 
        case (state) 
            STOP: begin 
                next_sel = 3'd7;
            end 
            ONE_SPACE: begin 
                if (onesp_done)  next_sel = sel - 1'b1;
                else             next_sel = sel;
            end 
            ZERO_SPACE: begin 
                if (mark_done)   next_sel = sel - 1'b1;
                else             next_sel = sel;
            end 
            RPT_SPACE: begin 
                next_sel = 3'd7;
            end 
            default: begin 
                next_sel = sel;
            end 
        endcase 
    end 
    
    always @(*) begin 
        case (state) 
            STOP:        ir_raw = 1'b0;
            HDR_MARK1:   ir_raw = 1'b1;
            HDR_MARK2:   ir_raw = 1'b1;
            HDR_SPACE:   ir_raw = 1'b0;
            BIT_MARK:    ir_raw = 1'b1;
            ONE_SPACE:   ir_raw = 1'b0;
            ZERO_SPACE:  ir_raw = 1'b0;
            RPT_SPACE:   ir_raw = 1'b0;
            default:     ir_raw = 1'b0;
        endcase 
    end 
    
    always @(*) begin 
        case (direction)
            2'b00:   rpt_period = 32'd2500000;
            2'b01:   rpt_period = 32'd5000000;
            2'b10:   rpt_period = 32'd7500000;
            2'b11:   rpt_period = 32'd10000000;
        endcase 
        
    end 
    
endmodule 


module NEC_Decoder(clk, rst_n, din, data);
    input clk, rst_n;
    input din;
    output reg [7:0] data;
    
    reg [7:0] next_data;
        
    parameter NOTHING    = 3'h0;
    parameter DATAINF    = 3'h1;
    parameter DATAINL    = 3'h2;
    parameter DATAINR    = 3'h3;
    parameter DATAINB    = 3'h4;
    
    reg [2:0] state, next_state; 
    
    reg [3:0] en;
    wire [3:0] done;
    
    reg en_chk;
    wire done_chk;
    
    
//    output [3:0] fin;
    reg [3:0] fin, next_fin;
    parameter RPT_F   = 3'd0;
    parameter RPT_L   = 3'd1;
    parameter RPT_R   = 3'd2;
    parameter RPT_B   = 3'd3;
        
    // 32'd56000, 32'd169000, 32'd450000
    timer tm_rptf(.clk(clk), .rst_n(rst_n), .en(en[RPT_F]), .period(32'd3000000), .dout(done[RPT_F]));
    timer tm_rptl(.clk(clk), .rst_n(rst_n), .en(en[RPT_L]), .period(32'd5500000), .dout(done[RPT_L]));
    timer tm_rptr(.clk(clk), .rst_n(rst_n), .en(en[RPT_R]), .period(32'd8000000), .dout(done[RPT_R]));
    timer tm_rptb(.clk(clk), .rst_n(rst_n), .en(en[RPT_B]), .period(32'd10500000), .dout(done[RPT_B]));
    timer tm_chk(.clk(clk), .rst_n(rst_n), .en(en_chk), .period(32'd12000000), .dout(done_chk));
    
    
    reg [4:0] chk_poscount, next_chk_poscount;
    reg [4:0] chk_negcount, next_chk_negcount;
    wire check_mark, check_space;
    
    assign check_mark  = (din & (chk_poscount == 5'd16));
    assign check_space = ((!din) & (chk_negcount == 5'd16));
     
    always @(posedge clk) begin 
        if (rst_n == 1'b0) begin 
            state <= NOTHING;
            chk_poscount <= 5'b0;
            chk_negcount <= 5'b0;
            fin <= 4'b0;
            data <= 8'b0;
        end else begin 
            state <= next_state;
            chk_poscount <= next_chk_poscount;
            chk_negcount <= next_chk_negcount;
            fin <= next_fin;
            data <= next_data;
        end 
    end 

    always @(*) begin 
        case (state) 
            NOTHING: begin 
                if (check_mark) begin 
                    next_state = DATAINF;
                end else begin 
                    next_state = state;
                end  
            end 
            DATAINF: begin 
                if (fin[RPT_F]) begin
                    if (check_space) begin  
                        next_state = DATAINL;
                    end else begin 
                        next_state = state;
                    end 
                end else begin 
                    next_state = state;
                end 
            end 
            DATAINL: begin 
                if (fin[RPT_L]) begin
                    if (check_space) begin  
                        next_state = DATAINR;
                    end else begin 
                        next_state = state;
                    end 
                end else begin 
                    if (done_chk)  next_state = DATAINF; 
                    else           next_state = state;
                end 
            end 
            DATAINR: begin 
                if (fin[RPT_R]) begin
                    if (check_space) begin  
                        next_state = DATAINB;
                    end else begin 
                        next_state = state;
                    end 
                end else begin 
                    if (done_chk)  next_state = DATAINL; 
                    else           next_state = state;
                end 
            end 
            DATAINB: begin 
                if (fin[RPT_B]) begin
                    if (check_space) begin  
                        next_state = NOTHING;
                    end else begin 
                        next_state = state;
                    end 
                end else begin 
                    if (done_chk)  next_state = DATAINR; 
                    else           next_state = state;
                end 
            end 

            default: begin 
                next_state = NOTHING;
            end 
        endcase 
    end 
    
    always @(*) begin 
        if (state == NOTHING) begin 
            next_fin = 4'b0;
        end else begin 
            if (en[RPT_F]) begin 
                if (done[RPT_F])  next_fin[RPT_F] = 1'b1;
                else              next_fin[RPT_F] = fin[RPT_F];
            end else begin 
                next_fin[RPT_F] = 1'b0;
            end 
            if (en[RPT_L]) begin 
                if (done[RPT_L])  next_fin[RPT_L] = 1'b1;
                else              next_fin[RPT_L] = fin[RPT_L];
            end else begin 
                next_fin[RPT_L] = 1'b0;
            end 
            if (en[RPT_R]) begin 
                if (done[RPT_R])  next_fin[RPT_R] = 1'b1;
                else              next_fin[RPT_R] = fin[RPT_R];
            end else begin 
                next_fin[RPT_R] = 1'b0;
            end 
            if (en[RPT_B]) begin 
                if (done[RPT_B])  next_fin[RPT_B] = 1'b1;
                else              next_fin[RPT_B] = fin[RPT_B];
            end else begin 
                next_fin[RPT_B] = 1'b0;
            end 
        end 
        
    end 
    
    always @(*) begin 
        case (state) 
            NOTHING: begin 
                en = 4'b0;
            end 
            DATAINF: begin 
                if (din == 1'b0) begin  
                    en = 4'b0001;
                end else begin 
                    en = 4'b0;
                end 
            end 
            DATAINL: begin 
                if (din == 1'b0) begin  
                    en = 4'b0011;
                end else begin 
                    en = 4'b0000;
                end 
            end 
            DATAINR: begin 
                if (din == 1'b0) begin  
                    en = 4'b0111;
                end else begin 
                    en = 4'b0001;
                end 
            end 
            DATAINB: begin 
                if (din == 1'b0) begin  
                    en = 4'b1111;
                end else begin 
                    en = 4'b0011;
                end 
            end 
            default: begin 
                en = 4'b0;
            end 
        endcase 
    end 
    
    always @(*) begin 
        case (state) 
            NOTHING: begin 
                en_chk = 1'b0;
            end 
            DATAINF: begin 
                en_chk = 1'b0;
            end 
            DATAINL: begin 
                en_chk = ~fin[RPT_F];
            end 
            DATAINR: begin 
                en_chk = ~fin[RPT_L];
            end 
            DATAINB: begin 
                en_chk = ~fin[RPT_R];
            end 
            default: begin 
                en_chk = 1'b0;
            end 
        endcase 
        
    end 
    
    always @(*) begin 
        case (state) 
            NOTHING: begin 
                next_data = 8'b0;
            end 
            DATAINF: begin
                next_data = 8'h33; 
            end 
            DATAINL: begin
                next_data = 8'h77; 
            end 
            DATAINR: begin
                next_data = 8'hBB; 
            end 
            DATAINB: begin
                next_data = 8'hFF; 
            end 
            default: begin 
                next_data = 8'b0;
            end 
        endcase 
    end 
    
    always @(*) begin 
        if (din) begin 
            next_chk_poscount = chk_poscount + 1'b1;
            next_chk_negcount = 5'b0;
        end else begin 
            next_chk_negcount = chk_negcount + 1'b1;
            next_chk_poscount = 5'b0;
        end 
    end 
    
endmodule


module Modulation_38kHz (clk, rst_n, en, signal_md);
    input clk, rst_n, en;
    output reg signal_md;
    
    reg next_signal_md;
    
    reg [11:0] count, next_count;
    
    wire dclk;
    
    // clock_divide_pulse #(27) cp0 (clk, dclk);
    
    parameter full = 12'd1315;
    
    
    always @(posedge clk) begin 
        if (rst_n == 1'b0) begin 
            count <= 12'b0;
            signal_md <= 1'b0;
        end 
        else begin 
            count <= next_count;
            signal_md <= next_signal_md;
        end  
    end 
    
    always @(*) begin 
        if (en) begin 
            if (count == full) begin 
                next_count = 12'b0;
                next_signal_md = ~signal_md;
            end 
            else begin 
                next_count = count + 1'b1;
                next_signal_md = signal_md;
            end 
        end else begin 
            next_count = 12'b0;
            next_signal_md = 1'b0;
        end 
    end 
    
    // assign md = (count == full);
endmodule 

module timer(clk, rst_n, en, period, dout);
    input clk, rst_n, en;
    input [31:0] period;
    output dout;
    
    wire full;
    reg [31:0] count, next_count;
    assign full = (count >= period);
    
    always @(posedge clk) begin 
        if (rst_n == 1'b0) begin 
            count <= 32'b0;
        end 
        else begin 
            count <= next_count;
        end 
    end 
    
    always @(*) begin 
        if (en) begin 
            if (full)  next_count = 32'b0;
            else       next_count = count + 1'b1;
        end 
        else begin 
            next_count = 32'b0;
        end 
    end 
    
    assign dout = full; 
endmodule 

module debounce(clk, pb, pb_deb);
    input clk, pb;
    output pb_deb;
    
    reg [5:0] DFF;
    
    always @(posedge clk) begin 
        DFF[5:1] <= DFF[4:0];
        DFF[0] <= pb;
    end 
    
    assign pb_deb = &DFF; 
endmodule


module onepulse(clk, pb_deb, pb_onp);
    input clk, pb_deb;
    output reg pb_onp;
    reg pb_delay;
    
    always @(posedge clk) begin 
        pb_onp <= pb_deb & (!pb_delay);
        pb_delay <= pb_deb;
    end 
endmodule


