`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/18 09:35:23
// Design Name: 
// Module Name: lut_neg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module lut_neg(
    input  logic [12:0] vi      ,
    output logic [15:0] result  
);
logic [13:0] vi_neg;
logic [27:0] mul_1_28b;
logic [27:0] mul_2_28b;
logic [15:0] mul_1;//    1n2/sqrt(2) * x
logic [15:0] mul_2;//    ln2*x

assign vi_neg = {1'b1,~vi + 1'b1};
//assign mul_1_28b = $signed(14'd4015) * $signed(vi_neg);
assign mul_1 = {mul_1_28b[27],2'b11,mul_1_28b[25:13]};
//assign mul_2_28b = $signed(14'd5678) * $signed(vi_neg);
assign mul_2 = {mul_1_28b[27],2'b11,mul_2_28b[25:13]};
mul_fast #(
        .IN_DW(14)
    )u_mul_1(
        .I_IN1     (vi_neg   ),
        .I_IN2     (14'd4015 ),
        .O_MUL_OUT (mul_1_28b)//assign mul_1_28b = $signed(14'd4015) * $signed(vi_neg);
    );

mul_fast #(
        .IN_DW(14)
    )u_mul_2(
        .I_IN1     (vi_neg   ),
        .I_IN2     (14'd5678 ),//assign mul_2_28b = $signed(14'd5678) * $signed(vi_neg);
        .O_MUL_OUT (mul_2_28b)
    );
always_comb begin
    if($signed(vi_neg) > $signed(14'b10_0000_0000_0001) & $signed(vi_neg) < $signed(14'b11_1000_0111_0110)) begin//2^x = 1/sqrt2 + 1n2/sqrt(2) * (x+0.5)        (-1<x<-0.235595703125)
        result <= 16'd7800 + mul_1;
    end
    else if($signed(vi_neg) > $signed(14'b11_1000_0111_0110)) begin    //2^x = 1 + ln2*x                         (-0.235595703125<x<0.264404296875)
        result <= 16'h2000 + mul_2;
    end
    else begin
        result <= 16'b0_01_00000_0000_0000; //error
    end
end
endmodule
