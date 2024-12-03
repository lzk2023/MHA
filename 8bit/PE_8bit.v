`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: lzk
// 
// Create Date: 2024/10/31 10:05:11
// Design Name: 
// Module Name: PE
// Project Name: MHA
// Target Devices: 
// Tool Versions: 
// Description: pipeline multiplier,
//              data 16 bits,for 1 signal bit,2 int bits and 13 fraction bits
//              data format:16'b0_00_00000_0000_0000
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module PE_8bit(
input             I_CLK     ,
input             I_RST_N   ,
input      [7:0]  I_X       ,//input x(from left)
input      [7:0]  I_W       ,//input weight(from ddr)
input      [7:0]  I_D       ,//input data(from up)
output reg [7:0]  O_X       ,//output x(right shift)
output reg [7:0]  O_OUT     //output data(down shift)
);

always@(posedge I_CLK or negedge I_RST_N)begin
    if (!I_RST_N) begin
        O_X <= 8'b0;
    end else begin
        O_X <= I_X;
    end
end

always@(posedge I_CLK or negedge I_RST_N)begin
    if (!I_RST_N) begin
        O_OUT     <= 8'b0;
    end else begin
        O_OUT     <= o_mul_out + I_D;
    end
end

multiplier_8 u_dut_mul8(
    .I_IN1   (I_X),
    .I_IN2   (I_W),
    .O_OUT_8 (o_mul_out),
    .O_OUT_16()
);
endmodule
