`timescale 1ns / 1ps

module safe_softmax_lut_neg#(
    parameter D_W = 16  //support data width = 16 or 8 bits
)(
    input  logic [D_W-4:0] vi      ,
    output logic [D_W-1:0] result  
);
localparam ln_2 = 14'd5678;
localparam ln_2_div_sqrt2 = 14'd4015;
localparam ln2_div_2 = 14'd2839;
logic [13:0] vi_neg;
logic [27:0] mul_3_full;
logic [27:0] mul_1_full;
logic [27:0] mul_2_full;
logic [15:0] mul_3;//    1n2/2 * x
logic [15:0] mul_1;//    1n2/sqrt(2) * x
logic [15:0] mul_2;//    ln2*x

assign vi_neg = {1'b1,~vi + 1'b1};
//assign mul_1_full = $signed(14'd4015) * $signed(vi_neg);
assign mul_3 = mul_3_full[12] ? {mul_3_full[27],2'b11,mul_3_full[25:13]} + 1 : {mul_3_full[27],2'b11,mul_3_full[25:13]};//round
assign mul_1 = mul_1_full[12] ? {mul_1_full[27],2'b11,mul_1_full[25:13]} + 1 : {mul_1_full[27],2'b11,mul_1_full[25:13]};//round
//assign mul_2_full = $signed(14'd5678) * $signed(vi_neg);
assign mul_2 = mul_2_full[12] ? {mul_2_full[27],2'b11,mul_2_full[25:13]} + 1 : {mul_2_full[27],2'b11,mul_2_full[25:13]};//round
mul_fast #(
    .IN_DW(14)
)u_mul_3(
    .I_IN1     (vi_neg   ),
    .I_IN2     (ln2_div_2 ),
    .O_MUL_OUT (mul_3_full)//assign mul_1_full = $signed(14'd4015) * $signed(vi_neg);
);

mul_fast #(
    .IN_DW(14)
)u_mul_1(
    .I_IN1     (vi_neg   ),
    .I_IN2     (ln_2_div_sqrt2 ),
    .O_MUL_OUT (mul_1_full)//assign mul_1_full = $signed(14'd4015) * $signed(vi_neg);
);

mul_fast #(
    .IN_DW(14)
)u_mul_2(
    .I_IN1     (vi_neg   ),
    .I_IN2     (ln_2 ),//assign mul_2_full = $signed(14'd5678) * $signed(vi_neg);
    .O_MUL_OUT (mul_2_full)
);
always_comb begin
    if($signed(vi_neg) >= $signed(14'b10_0000_0000_0001) & $signed(vi_neg) <= $signed(14'b10_1000_0111_0110))begin//2^x = (ln2/2)*x + (1+ln2)/2   (-1<x<-0.735595703125)
        result = 16'd6935 + mul_3;
    end else if($signed(vi_neg) > $signed(14'b10_1000_0111_0110) & $signed(vi_neg) < $signed(14'b11_1000_0111_0110)) begin//2^x = 1/sqrt2 + 1n2/sqrt(2) * (x+0.5)        (-0.735595703125<x<-0.235595703125)
        result = 16'd7800 + mul_1;
    end else if($signed(vi_neg) >= $signed(14'b11_1000_0111_0110)) begin    //2^x = 1 + ln2*x                         (-0.235595703125<x<0.264404296875)
        result = 16'b0_01_00000_0000_0000 + mul_2;
    end else begin
        result = 16'b0_01_00000_0000_0000; //error
    end
end
endmodule
