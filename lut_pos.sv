`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/18 09:33:12
// Design Name: 
// Module Name: lut_pos
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


module lut_pos(
    input  logic [12:0]   vi      ,
    output logic [15:0]  result  
);
logic [25:0] mul_2_26b;
logic [25:0] mul_3_26b;
logic [15:0] mul_2;//    ln2*x
logic [15:0] mul_3;//    sqrt(2)*ln2*x

//assign mul_2_26b = 13'd5678 * vi;
assign mul_2 = {3'b000,mul_2_26b[25:13]};
//assign mul_3_26b = 13'd8030 * vi;
assign mul_3 = {3'b000,mul_3_26b[25:13]};
mul_fast #(
        .IN_DW(14)
    )u_mul_1(
        .I_IN1     ({1'b0,vi}),
        .I_IN2     (14'd5678 ),
        .O_MUL_OUT (mul_2_26b)//assign mul_2_26b = 13'd5678 * vi;
    );

mul_fast #(
        .IN_DW(14)
    )u_mul_2(
        .I_IN1     ({1'b0,vi}),
        .I_IN2     (14'd8030 ),//assign mul_3_26b = 13'd8030 * vi;
        .O_MUL_OUT (mul_3_26b)
    );

always_comb begin
    if(vi < 13'd2166) begin    //2^x = 1 + ln2*x                         (-0.235595703125<x<0.264404296875)
        result <= 16'h2000 + mul_2;
    end
    else if(vi > 13'd2166 & vi < 13'b1_1111_1111_1111) begin//2^x = sqrt(2) + sqrt(2)*ln2*(x-0.5)     (0.264404296875<x<1)
        result <= 16'd7570 + mul_3;
    end
    else begin
        result <= 16'b0_01_00000_0000_0000; //error
    end
end
endmodule