`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/11 09:16:18
// Design Name: 
// Module Name: Exp_x
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


module Exp_x(
    input      [15:0] I_X    ,
    output reg [15:0] O_EXP
    );
    wire [31:0] mul_out;
    wire [16:0] uivi;
    wire [15:0] uivi_ab;//absolute value
    wire [2:0]  ui;
    wire [12:0] vi;
    wire        uivi_msb;
    wire [15:0] p_2_vi;
    wire [15:0] n_2_vi;
    mul_fast #(
        .IN_DW(16)
    )u_mul_in_loge(
        .I_IN1     (I_X      ),
        .I_IN2     (16'd11819),//1.442695040889*2^13
        .O_MUL_OUT (mul_out  )
    );
    assign uivi = {mul_out[31],mul_out[28:13]};//[16:0]expand 1 bit
    assign uivi_ab = (uivi_msb) ? ~uivi[15:0] + 1'b1 : uivi[15:0];
    assign uivi_msb = uivi[16];
    assign ui = uivi_ab[15:13];
    assign vi = uivi_ab[12:0];
    lut_pos u_lut_p(
        .vi    (vi),
        .result(p_2_vi)
    );
    lut_neg u_lut_n(
        .vi    (vi),
        .result(n_2_vi)
    );
    always@(*)begin
        if(!I_X[15] & I_X[14:0] >= 15'd11357)begin//I_X >= ln4
            O_EXP = 16'b0_11_11111_1111_1111;
        end else begin
            if(!uivi_msb)begin
                O_EXP = p_2_vi << ui;
            end else begin
                O_EXP = n_2_vi >> ui;
            end
        end
    end
endmodule