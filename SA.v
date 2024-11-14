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

module SA #(
    parameter s = 64
)
(
input                   I_CLK     ,
input                   I_RST_N   ,
input      [s-1:0]      I_X_VLD   ,
input      [(s*16)-1:0] I_X       ,//input x(from left)
input      [s-1:0]      I_W_VLD   ,
input      [(s*16)-1:0] I_W       ,//input weight(from ddr)
input      [s-1:0]      I_D_VLD   ,
input      [(s*16)-1:0] I_D       ,//input data(from up)
output     [s-1:0]      O_X_VLD   ,
output     [(s*16)-1:0] O_X       ,//output x(right shift)
output     [s-1:0]      O_OUT_VLD ,
output     [(s*16)-1:0] O_OUT     //output data(down shift)
);

genvar i;
generate for(i=0;i<s;i=i+1)begin
    PE u_PE(
        .I_CLK     (I_CLK  ),
        .I_RST_N   (I_RST_N),
        .I_X_VLD   (),
        .I_X       (),//input x(from left)
        .I_W_VLD   (),
        .I_W       (),//input weight(from ddr)
        .I_D_VLD   (),
        .I_D       (),//input data(from up)
        .O_X_VLD   (),
        .O_X       (),//output x(right shift)
        .O_MUL_DONE(),//multiply done,next clk add,ID_VLD <=0
        .O_OUT_VLD (),
        .O_OUT     ()//output data(down shift)
    );
end

endgenerate
endmodule