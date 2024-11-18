`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: lzk
// 
// Create Date: 2024/10/31 10:05:11
// Design Name: 
// Module Name: SA_wrapper
// Project Name: MHA
// Target Devices: 
// Tool Versions: 
// Description: Systolic Array,5clk update PE.
//              input shift(left to right),output shift(up to down),weight maintain.
//              data 16 bits,for 1 signal bit,2 int bits and 13 fraction bits
//              data format:16'b0_00_00000_0000_0000
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module SA_wrapper#(
    parameter S   = 64,  //W_ROW,     W.shape = (S,64)
    parameter X_R = 64   //X_ROW,     X.shape = (X_R,S)
) (
    input                           I_CLK       ,
    output     [(S-1):0]            O_OUT_VLD   ,
    output     [(X_R*64*16)-1:0]    O_OUT        //OUT.shape = (X_R,64)
);

endmodule