`timescale 1ns / 1ps

module safe_softmax_lut_neg#(
    parameter D_W = 16  //support data width = 16 or 8 bits
)(
    input  logic [4:0] vi      ,
    output logic [D_W-1:0] result  
);
//localparam ln_2 = 14'd5678;
//localparam ln_2_div_sqrt2 = 14'd4015;
//localparam ln2_div_2 = 14'd2839;
//logic [13:0] vi_neg;
//logic [27:0] mul_3_full;
//logic [27:0] mul_1_full;
//logic [27:0] mul_2_full;
//logic [15:0] mul_3;//    1n2/2 * x
//logic [15:0] mul_1;//    1n2/sqrt(2) * x
//logic [15:0] mul_2;//    ln2*x
//
//assign vi_neg = {1'b1,~vi + 1'b1};
//assign mul_3 = mul_3_full[12] ? {mul_3_full[27],2'b11,mul_3_full[25:13]} + 1 : {mul_3_full[27],2'b11,mul_3_full[25:13]};//round
//assign mul_1 = mul_1_full[12] ? {mul_1_full[27],2'b11,mul_1_full[25:13]} + 1 : {mul_1_full[27],2'b11,mul_1_full[25:13]};//round
//assign mul_2 = mul_2_full[12] ? {mul_2_full[27],2'b11,mul_2_full[25:13]} + 1 : {mul_2_full[27],2'b11,mul_2_full[25:13]};//round
//mul_fast #(
//    .IN_DW(14)
//)u_mul_3(
//    .I_IN1     (vi_neg   ),
//    .I_IN2     (ln2_div_2 ),
//    .O_MUL_OUT (mul_3_full)//assign mul_1_full = $signed(14'd4015) * $signed(vi_neg);
//);
////DSP:assign mul_3_full = $signed(vi_neg) * $signed(ln2_div_2);
//
//mul_fast #(
//    .IN_DW(14)
//)u_mul_1(
//    .I_IN1     (vi_neg   ),
//    .I_IN2     (ln_2_div_sqrt2 ),
//    .O_MUL_OUT (mul_1_full)//assign mul_1_full = $signed(14'd4015) * $signed(vi_neg);
//);
////DSP:assign mul_1_full = $signed(vi_neg) * $signed(ln_2_div_sqrt2);
//
//mul_fast #(
//    .IN_DW(14)
//)u_mul_2(
//    .I_IN1     (vi_neg   ),
//    .I_IN2     (ln_2 ),//assign mul_2_full = $signed(14'd5678) * $signed(vi_neg);
//    .O_MUL_OUT (mul_2_full)
//);
////DSP:assign mul_2_full = $signed(vi_neg) * $signed(ln_2);
//
//always_comb begin
//    if($signed(vi_neg) >= $signed(14'b10_0000_0000_0001) & $signed(vi_neg) <= $signed(14'b10_1000_0111_0110))begin//2^x = (ln2/2)*x + (1+ln2)/2   (-1<x<-0.735595703125)
//        result = 16'd6935 + mul_3;
//    end else if($signed(vi_neg) > $signed(14'b10_1000_0111_0110) & $signed(vi_neg) < $signed(14'b11_1000_0111_0110)) begin//2^x = 1/sqrt2 + 1n2/sqrt(2) * (x+0.5)        (-0.735595703125<x<-0.235595703125)
//        result = 16'd7800 + mul_1;
//    end else if($signed(vi_neg) >= $signed(14'b11_1000_0111_0110)) begin    //2^x = 1 + ln2*x                         (-0.235595703125<x<0.264404296875)
//        result = 16'b0_01_00000_0000_0000 + mul_2;
//    end else begin
//        result = 16'b0_01_00000_0000_0000; //error
//    end
//end
always_comb begin
    case(vi)
        5'd 0:result = 16'd8192;
        5'd 1:result = 16'd8016;
        5'd 2:result = 16'd7845;
        5'd 3:result = 16'd7677;
        5'd 4:result = 16'd7512;
        5'd 5:result = 16'd7351;
        5'd 6:result = 16'd7194;
        5'd 7:result = 16'd7039;
        5'd 8:result = 16'd6889;
        5'd 9:result = 16'd6741;
        5'd10:result = 16'd6597;
        5'd11:result = 16'd6455;
        5'd12:result = 16'd6317;
        5'd13:result = 16'd6182;
        5'd14:result = 16'd6049;
        5'd15:result = 16'd5919;
        5'd16:result = 16'd5793;
        5'd17:result = 16'd5668;
        5'd18:result = 16'd5547;
        5'd19:result = 16'd5428;
        5'd20:result = 16'd5312;
        5'd21:result = 16'd5198;
        5'd22:result = 16'd5087;
        5'd23:result = 16'd4978;
        5'd24:result = 16'd4871;
        5'd25:result = 16'd4767;
        5'd26:result = 16'd4664;
        5'd27:result = 16'd4565;
        5'd28:result = 16'd4467;
        5'd29:result = 16'd4371;
        5'd30:result = 16'd4277;
        5'd31:result = 16'd4186;
    endcase
end
endmodule
