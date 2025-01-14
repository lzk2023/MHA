`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/02 11:52:52
// Design Name: 
// Module Name: mul_shift5
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


module mul_shift5#(
    parameter D_W = 16
)(
    input  [D_W*2-1:0] I_IN1 ,
    input         I_IN2 ,
    output [D_W*2-1:0] O_OUT ,
    output [D_W*2-1:0] O_SFT1
    );
    assign O_OUT =  (I_IN2 ? I_IN1 : 0);
    assign O_SFT1 = I_IN1<<1;
endmodule