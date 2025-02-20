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

module PE#(
    parameter D_W = 16
)
(
    input                I_CLK      ,
    input                I_ASYN_RSTN,
    input                I_SYNC_RSTN,
    input                I_VLD      ,
    input      [D_W-1:0] I_X        ,//input x(from left)
    input      [D_W-1:0] I_W        ,//input weight(from up)
    output reg           O_VLD      ,
    output reg [D_W-1:0] O_X        ,//output x(right shift)
    output reg [D_W-1:0] O_W        ,//output weight(down shift)
    output reg [D_W-1:0] O_D         //output data
);

wire [2*D_W-1:0] o_mul_out;

always@(posedge I_CLK or negedge I_ASYN_RSTN)begin
    if (!I_ASYN_RSTN | !I_SYNC_RSTN) begin
        O_X     <= 'b0;
        O_W     <= 'b0;
        O_D     <= 'b0;
        O_VLD   <= 'b0;
    end else if(I_VLD)begin
        O_X     <= I_X;
        O_W     <= I_W;
        O_D     <= O_D + {o_mul_out[31],o_mul_out[28:13]};
        O_VLD   <= 'b1;
    end else begin
        O_X     <= O_X;
        O_W     <= O_W;
        O_D     <= O_D;
        O_VLD   <= 'b0;
    end
end

mul_fast #(
    .IN_DW(D_W)
)u_mul_16(
    .I_IN1    (I_X),
    .I_IN2    (I_W),
    .O_MUL_OUT(o_mul_out)
);
//multiplier #(
//    .D_W(D_W)
//)u_mul_16(
//    .I_CLK      (I_CLK      ),
//    .I_ASYN_RSTN(I_ASYN_RSTN),
//    .I_SYNC_RSTN(I_SYNC_RSTN),
//    .I_VLD      (i_mul_vld  ),//input valid
//    .I_M1       (I_X        ),//multiplicand(被乘数)
//    .I_M2       (I_W        ),//multiplier  (乘数)
//    .O_VLD      (o_mul_vld  ),//output valid
//    .O_PRODUCT  (o_mul_out  ) //product     (积)
//);
endmodule