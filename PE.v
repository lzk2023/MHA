`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: lzk
// 
// Create Date: 2024/10/31 10:05:11
// Design Name: 
// Module Name: PE
// Project Name: MHA
// Target Devices: 
// Tool Versions: 
// Description: pipeline multiplier,
//              data 16 bits,for 1 signal bit,2 int bits and 13 fraction bits
//              data format:16'b0_00_00000_0000_0000
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module PE(
input         I_CLK    ,
input         I_RST_N  ,
input         I_X_VLD  ,
input  [15:0] I_X      ,//input x(from left)
input         I_W_VLD  ,
input  [15:0] I_W      ,//input weight(from ddr)
input         I_D_VLD  ,
input  [15:0] I_D      ,//input data(from up)
output        O_X_VLD  ,
output [15:0] O_X      ,//output x(right shift)
output        O_OUT_VLD,
output [15:0] O_OUT     //output data(down shift)
);

wire        i_mul_vld;
wire        o_mul_vld;
wire        o_mul_out;
wire [15:0] out;
assign mul_vld = I_X_VLD & I_W_VLD;
assign out = ;
multiplier_16 u_dut_mul_16(
.I_CLK     (I_CLK    ),
.I_RST_N   (I_RST_N  ),
.I_VLD     (i_mul_vld),//input valid
.I_M1      (I_X      ),//multiplicand(被乘数)
.I_M2      (I_W      ),//multiplier  (乘数)
.O_VLD     (o_mul_vld),//output valid
.O_MUL_BUSY(),
.O_PRODUCT (mul_out  ) //product     (积)
);
endmodule