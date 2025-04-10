`timescale 1ns/1ps
module o_matrix_upd#(
    parameter D_W = 8,
    parameter TIL = 16 //tiling row == 16
)(
    input  logic             I_CLK                  ,
    input  logic             I_RST_N                ,
    input  logic             I_VLD                  ,//keep
    input  logic [D_W*2-1:0] I_LI_OLD [0:TIL-1]     ,
    input  logic [D_W-1:0]   I_MI_OLD [0:TIL-1]     ,
    input  logic [D_W*2-1:0] I_LI_NEW [0:TIL-1]     ,
    input  logic [D_W-1:0]   I_MI_NEW [0:TIL-1]     ,
    output logic             O_VLD                  ,
    output logic [D_W-1:0]   O_COEFFICIENT [0:TIL-1]
);

logic [D_W-1:0]   in_exp   [0:TIL-1];
logic [D_W-1:0]   out_exp  [0:TIL-1];
logic [D_W*2-1:0] quotient [0:TIL-1];
logic             div_vld           ;
logic [TIL-1:0]   divider_vld_o     ;
logic [D_W*2-1:0] mul_o    [0:TIL-1];

assign div_vld = & divider_vld_o; 
assign O_VLD = div_vld;

generate
    for(genvar i=0;i<TIL;i=i+1)begin:divider_gen
        assign in_exp[i] = I_MI_OLD[i] - I_MI_NEW[i];
        assign O_COEFFICIENT[i] = {mul_o[i][15],mul_o[i][11:5]};
        div_fast #(
            .D_W           (16),
            .FRAC_BIT      (13),   //fraction bits
            .USE_IN_SOFTMAX(0 )
        )u_fast_divider_16bit(
            .I_CLK      (I_CLK    ),
            .I_RST_N    (I_RST_N  ),
            .I_DIV_START(I_VLD    ),//开始标志,计算时应保持
            .I_DIVIDEND (I_LI_OLD[i]),
            .I_DIVISOR  (I_LI_NEW[i]),
            .O_QUOTIENT (quotient[i]),
            .O_VLD      (divider_vld_o[i]) 
        );

        Exp_x #(
            .D_W(8)
        )u_Exp_x(
            .I_X  (in_exp[i] ),
            .O_EXP(out_exp[i])
        );

        mul_fast#(
            .IN_DW(8)
        )u_mul_fast(
            .I_IN1    (out_exp[i]),
            .I_IN2    (quotient[i][D_W*2-1:D_W]),
            .O_MUL_OUT(mul_o[i])
        );
    end
endgenerate
endmodule