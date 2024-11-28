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
reg [15:0] out_16;
integer i;

assign O_OUT_8 = out_16[15:8];
assign O_OUT_16 = out_16;
always@(*)begin
    for(i=0;i<8;i=i+1)begin
        if(i == 7)begin
            if(I_IN2[i] == 1)begin
                out_16 = out_16 - I_IN1<<i;
            end else begin
                out_16 = out_16;
            end
        end else begin
            if(I_IN2[i] == 1)begin
                out_16 = out_16 + I_IN1<<i;
            end else begin
                out_16 = out_16;
            end
        end
    end
end
endmodule
