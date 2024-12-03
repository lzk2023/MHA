`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: lzk
// 
// Create Date: 2024/10/31 10:05:11
// Design Name: 
// Module Name: multiplier_8
// Project Name: MHA
// Target Devices: 
// Tool Versions: 
// Description: pipeline multiplier for 8 bits,

// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module multiplier_8(
    input  [7:0]  I_IN1   ,
    input  [7:0]  I_IN2   ,
    output [7:0]  O_OUT_8 ,
    output [15:0] O_OUT_16
);
wire [15:0] out_16;
wire [15:0] in1_sft;
integer i;

assign in1_sft = {{8{I_IN1[7]}},I_IN1};
assign O_OUT_8 = {out_16[15],out_16[13:7]};
assign O_OUT_16 = out_16;

assign out_16 = ((I_IN2[0]) ? in1_sft << 0 : 0 )+ 
                ((I_IN2[1]) ? in1_sft << 1 : 0 )+ 
                ((I_IN2[2]) ? in1_sft << 2 : 0 )+ 
                ((I_IN2[3]) ? in1_sft << 3 : 0 )+ 
                ((I_IN2[4]) ? in1_sft << 4 : 0 )+ 
                ((I_IN2[5]) ? in1_sft << 5 : 0 )+ 
                ((I_IN2[6]) ? in1_sft << 6 : 0 )- 
                ((I_IN2[7]) ? in1_sft << 7 : 0 ); 
endmodule
