`timescale 1ns/1ps
module attention#(
    parameter D_W = 16,
    parameter DIM = 64,       //sequence length
    parameter D_K = 64        //Q,K,V column num（dimention/h_num）
)(
    input                    I_CLK     ,
    input                    I_RST_N   ,
    input                    I_START   ,
    input  [DIM*D_K*D_W-1:0] I_MAT_Q   ,
    input  [DIM*D_K*D_W-1:0] I_MAT_K   ,
    input  [DIM*D_K*D_W-1:0] I_MAT_V   ,
    output                   O_VLD     ,
    output [DIM*D_K*D_W-1:0] O_ATT_DATA
);
localparam SQRT_DK = 8;       //square root d_k
endmodule