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
input              I_CLK     ,
input              I_RST_N   ,
input              I_VLD     ,//input valid
input      [15:0]  I_M1      ,//multiplicand(被乘数)
input      [15:0]  I_M2      ,//multiplier  (乘数)
output reg         O_VLD     ,//output valid
output reg         O_MUL_BUSY,
output reg [15:0]  O_PRODUCT  //product     (积)
);

wire    [14:0]  ab_m1     ;
wire    [14:0]  ab_m2     ;//calculate m1,m2 absolute value(用于计算m1m2绝对值)
wire    [29:0]  product_reg_n;

reg             prd_msb   ;//product msb   积符号位
reg     [29:0]  product_reg;//15 bits * 15bits
reg     [29:0]  ab_m1_reg ;
reg     [14:0]  ab_m2_reg ;//reg input(absolute value)  寄存输入数据绝对值

assign ab_m1 = I_M1[15] ? ~I_M1[14:0] + 1 : I_M1[14:0];
assign ab_m2 = I_M2[15] ? ~I_M2[14:0] + 1 : I_M2[14:0];//calculate m1,m2 absolute value(用于计算m1m2绝对值)
assign product_reg_n = ~product_reg + 1;

always@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        ab_m1_reg  <= 16'b0;
        ab_m2_reg  <= 16'b0;
        prd_msb    <=      0;
        O_MUL_BUSY <=      0;
    end else if(I_VLD & !O_MUL_BUSY)begin          //clk 1:calculate and store m1,m2 absolute value 计算绝对值并寄存
        ab_m1_reg  <= ab_m1;
        ab_m2_reg  <= ab_m2;
        prd_msb    <= I_M1[15] ^ I_M2[15];
        O_MUL_BUSY <=      1;
    end else if(O_MUL_BUSY & ab_m2_reg != 0)begin
        ab_m1_reg <= ab_m1_reg << 5;                          //clk 2/3/4:pipeline_3
        ab_m2_reg <= ab_m2_reg >> 5;
    end else begin
        ab_m1_reg   <=     16'b0;
        ab_m2_reg   <=     16'b0;
        prd_msb     <=         0;
        O_MUL_BUSY  <=         0;
    end
end

always@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        product_reg <= 30'b0;
        O_VLD       <= 0;
        O_PRODUCT   <= 'b0;
    end else if(O_MUL_BUSY & ab_m2_reg != 0)begin
        product_reg <= product_reg + ab_m1_reg * ab_m2_reg[4:0];
    end else if(O_MUL_BUSY & ab_m2_reg == 0)begin
        O_VLD <= 1;
        product_reg <= 30'b0;
        if(prd_msb)begin
            O_PRODUCT[15]   <= prd_msb;
            O_PRODUCT[14:0] <= product_reg_n[27:13];
        end else begin
            O_PRODUCT <= {prd_msb,product_reg[27:13]};
        end
    end else begin
        product_reg <= 30'b0;
        O_VLD       <= 0;
        O_PRODUCT   <= 'b0;
    end
end
endmodule
