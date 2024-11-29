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


module mul_shift5(
    input  [31:0] I_IN1,
    input  [4:0] I_IN2,
    output [31:0] O_OUT
    );
    assign O_OUT =  (I_IN2[0] ? I_IN1 : 0)
                        + (I_IN2[1] ? I_IN1<<1 : 0)
                        + (I_IN2[2] ? I_IN1<<2 : 0)
                        + (I_IN2[3] ? I_IN1<<3 : 0)
                        + (I_IN2[4] ? I_IN1<<4 : 0);
endmodule
