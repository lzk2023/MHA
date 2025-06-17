`timescale 1ns / 1ps

module safe_softmax_exp #(
    parameter D_W = 16
)(
    input  logic [D_W-1:0] I_X    ,
    output logic [D_W-1:0] O_EXP
);
logic [15:0] mul_out;
logic [8:0] uivi;
logic [7:0] uivi_ab;//absolute value
logic [2:0]  ui;
logic [4:0] vi;
logic [15:0] n_2_vi;
mul_fast #(
    .IN_DW(8)
)u_mul_in_loge(
    .I_IN1     (I_X[15:8]),
    .I_IN2     (8'd46),//1.442695040889*2^13//
    .O_MUL_OUT (mul_out  )
);
//DSP:assign mul_out = $signed(I_X) * $signed(16'd11819);

assign uivi = mul_out[4] ? {mul_out[15],mul_out[12:5]} + 1 : {mul_out[15],mul_out[12:5]};//[16:0]expand 1 bit
assign uivi_ab = (uivi == 0) ? 0 : ~uivi[7:0] + 1'b1;
assign ui = uivi_ab[7:5];
assign vi = uivi_ab[4:0];
always_comb begin
    O_EXP = n_2_vi >> ui;
end
safe_softmax_lut_neg #(
    .D_W(D_W)
)u_lut_n(
    .vi    (vi),
    .result(n_2_vi)
);
endmodule