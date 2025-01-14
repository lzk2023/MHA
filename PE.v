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
parameter D_W = 8
)
(
input                I_CLK     ,
input                I_RST_N   ,
input                I_X_VLD   ,
input      [D_W-1:0] I_X       ,//input x(from left)
input                I_W_VLD   ,
input      [D_W-1:0] I_W       ,//input weight(from ddr)
input                I_D_VLD   ,
input      [D_W-1:0] I_D       ,//input data(from up)
output reg           O_X_VLD   ,
output reg [D_W-1:0] O_X       ,//output x(right shift)
output               O_MUL_DONE,//multiply done,next clk add,ID_VLD <=0
output reg           O_OUT_VLD ,
output reg [D_W-1:0] O_OUT     //output data(down shift)
);

wire        i_mul_vld;
wire        o_mul_vld;
wire [D_W-1:0] o_mul_out;
wire        mul_busy ;

reg [D_W-1:0]     i_x_ff;

assign O_MUL_DONE = o_mul_vld;
assign i_mul_vld = I_X_VLD & I_W_VLD;
//assign O_OUT = I_D_VLD ? o_mul_out + I_D : 16'bz;
always@(posedge I_CLK or negedge I_RST_N)begin
    if (!I_RST_N) begin
        i_x_ff <= 'b0;
    end else if(I_X_VLD & !mul_busy)begin
        i_x_ff <= I_X  ;
    end else begin
        i_x_ff <= i_x_ff;
    end
end

always@(posedge I_CLK or negedge I_RST_N)begin
    if (!I_RST_N) begin
        O_OUT     <= 'b0;
        O_OUT_VLD <= 1'b0;
    end else if(I_D_VLD & o_mul_vld)begin
        O_OUT     <= o_mul_out + I_D;
        O_OUT_VLD <= 1'b1;
    end else begin
        O_OUT     <= O_OUT;
        O_OUT_VLD <= 1'b0;
    end
end

always@(posedge I_CLK or negedge I_RST_N)begin
    if (!I_RST_N) begin
        O_X     <= 'b0;
        O_X_VLD <= 1'b0 ;
    end else if(I_D_VLD & o_mul_vld)begin
        O_X     <= i_x_ff;
        O_X_VLD <= 1'b1  ;
    end else begin
        O_X     <= O_X  ;
        O_X_VLD <= 1'b0 ;
    end
end

multiplier_16 #(
.D_W(D_W)
)u_mul_16(
.I_CLK     (I_CLK    ),
.I_RST_N   (I_RST_N  ),
.I_VLD     (i_mul_vld),//input valid
.I_M1      (I_X      ),//multiplicand(被乘数)
.I_M2      (I_W      ),//multiplier  (乘数)
.O_VLD     (o_mul_vld),//output valid
.O_MUL_BUSY(mul_busy ),
.O_PRODUCT (o_mul_out) //product     (积)
);
endmodule