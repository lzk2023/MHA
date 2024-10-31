`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: lzk
// 
// Create Date: 2024/10/31 10:05:11
// Design Name: 
// Module Name: multiplier_16
// Project Name: MHA
// Target Devices: 
// Tool Versions: 
// Description: pipeline multiplier for 16 bits,

// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module multiplier_16(
input           I_CLK    ,
input           I_RST_N  ,
input           I_VLD    ,//input valid
input   [15:0]  I_M1     ,//multiplicand(被乘数)
input   [15:0]  I_M2     ,//multiplier  (乘数)
output          O_VLD    ,//output valid
output  [15:0]  O_PRODUCT //product     (积)
);

wire    [14:0]  ab_m1     ;
wire    [14:0]  ab_m2     ;

reg             mul_busy  ;
reg             prd_msb   ;//product msb   积符号位
reg     [14:0]  ab_m1_reg ;
reg     [14:0]  ab_m2_reg ;//reg input(absolute value)寄存输入数据绝对值

assign ab_m1 = I_M1[15] ? ~I_M1[14:0] + 1 : I_M1[14:0];
assign ab_m2 = I_M2[15] ? ~I_M2[14:0] + 1 : I_M2[14:0];

always@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        ab_m1_reg <= 16'b0;
        ab_m2_reg <= 16'b0;
        prd_msb  <=     0;
        mul_busy <=     0;
    end else if(I_VLD & !mul_busy)begin
        ab_m1_reg <= ab_m1;
        ab_m2_reg <= ab_m2;
        prd_msb  <= I_M1[15] ^ I_M2[15];
        mul_busy <=    1;
    end else begin
        ab_m1_reg <= ab_m1_reg;
        ab_m2_reg <= ab_m2_reg;
        prd_msb   <= prd_msb  ;
        mul_busy  <= mul_busy ;
    end
end

always@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
    end else begin
    end
end
endmodule