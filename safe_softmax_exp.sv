`timescale 1ns / 1ps

module safe_softmax_exp #(
    parameter D_W = 16
)(
    input  logic [D_W-1:0] I_X    ,
    output logic [D_W-1:0] O_EXP
);
logic [31:0] mul_out;
logic [16:0] uivi;
logic [15:0] uivi_ab;//absolute value
logic [2:0]  ui;
logic [12:0] vi;
logic [15:0] n_2_vi;
mul_fast #(
    .IN_DW(16)
)u_mul_in_loge(
    .I_IN1     (I_X      ),
    .I_IN2     (16'd11819),//1.442695040889*2^13//
    .O_MUL_OUT (mul_out  )
);
assign uivi = mul_out[12] ? {mul_out[31],mul_out[28:13]} + 1 : {mul_out[31],mul_out[28:13]};//[16:0]expand 1 bit
assign uivi_ab = (uivi == 0) ? 0 : ~uivi[15:0] + 1'b1;
assign ui = uivi_ab[15:13];
assign vi = uivi_ab[12:0];
always_comb begin
    if(I_X == 0)begin
        O_EXP = 16'b0_00_11111_1111_1111;//exp0 == 1
    end else begin
        O_EXP = n_2_vi >> ui;
    end
end
safe_softmax_lut_neg #(
    .D_W(D_W)
)u_lut_n(
    .vi    (vi),
    .result(n_2_vi)
);
endmodule