`timescale 1ns/1ps
module o_matrix_upd#(
    parameter D_W = 8,
    parameter TIL = 16 //tiling row == 16
)(
    input              I_CLK                  ,
    input              I_RST_N                ,
    input  [D_W*2-1:0] I_LI_OLD [0:TIL-1]     ,
    input  [D_W-1:0]   I_MI_OLD [0:TIL-1]     ,
    input  [D_W*2-1:0] I_LI_NEW [0:TIL-1]     ,
    input  [D_W-1:0]   I_MI_NEW [0:TIL-1]     ,
    output             O_VLD                  ,
    output [D_W-1:0]   O_COEFFICIENT [0:TIL-1]
);
div_fast #(
    .D_W     (16),
    .FRAC_BIT(13),   //fraction bits
    .USE_IN_SOFTMAX(0)
)u_fast_divider_8bit(
    .I_CLK      (I_CLK    ),
    .I_RST_N    (I_RST_N  ),
    .I_DIV_START(),//开始标志,计算时应保持
    .I_DIVIDEND (),
    .I_DIVISOR  (),
    .O_QUOTIENT (),
    .O_VLD      () 
);
endmodule