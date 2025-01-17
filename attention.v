`timescale 1ns/1ps
module attention#(
    parameter D_W = 16,
    parameter DIM = 4 ,       //dimention
    parameter HID = 3        //hidden
)(
    input                    I_CLK     ,
    input                    I_RST_N   ,
    input                    I_START   ,
    input  [DIM*HID*D_W-1:0] I_MAT_Q   ,
    input  [DIM*HID*D_W-1:0] I_MAT_K   ,
    input  [DIM*HID*D_W-1:0] I_MAT_V   ,
    output                   O_VLD     ,
    output [DIM*HID*D_W-1:0] O_ATT_DATA
);
endmodule