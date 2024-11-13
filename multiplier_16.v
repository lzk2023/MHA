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
output             O_VLD     ,//output valid
output reg         O_MUL_BUSY,
output     [15:0]  O_PRODUCT  //product     (积)
);

wire    [14:0]  ab_m1     ;
wire    [14:0]  ab_m2     ;//calculate m1,m2 absolute value(用于计算m1m2绝对值)
wire    [29:0]  product_reg_n;
wire    [29:0]  prod_shift;
wire    [14:0]  o_product_sel;

reg             prd_msb   ;//product msb   积符号位
reg     [29:0]  product_reg;//15 bits * 15bits
reg     [29:0]  ab_m1_reg ;
reg     [14:0]  ab_m2_reg ;//reg input(absolute value)  寄存输入数据绝对值
reg     [1:0]   mul_cycle ;//

assign ab_m1 = I_M1[15] ? ~I_M1[14:0] + 1 : I_M1[14:0];
assign ab_m2 = I_M2[15] ? ~I_M2[14:0] + 1 : I_M2[14:0];//calculate m1,m2 absolute value(用于计算m1m2绝对值)
assign product_reg_n = ~product_reg + 1;
assign o_product_sel = prd_msb ? product_reg_n[27:13] : product_reg[27:13];
//assign O_VLD = (O_MUL_BUSY & ab_m2_reg == 0) ? 1 : 0;
assign O_VLD = (O_MUL_BUSY & mul_cycle == 3) ? 1 : 0;
assign O_PRODUCT = {prd_msb,o_product_sel};//select output 选择输出

always@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        ab_m1_reg  <= 'b0;
        ab_m2_reg  <= 'b0;
        prd_msb    <=   0;
        O_MUL_BUSY <=   0;
        mul_cycle  <=   0;
    end else if(I_VLD & !O_MUL_BUSY)begin          //clk 1:calculate and store m1,m2 absolute value 计算绝对值并寄存
        ab_m1_reg  <= ab_m1;
        ab_m2_reg  <= ab_m2;
        prd_msb    <= I_M1[15] ^ I_M2[15];
        O_MUL_BUSY <=     1;
        mul_cycle  <=     0;
    //end else if(O_MUL_BUSY & ab_m2_reg != 0)begin
    end else if(O_MUL_BUSY & mul_cycle < 3)begin
        ab_m1_reg <= ab_m1_reg << 5;                          //clk 2/3/4:pipeline_3
        ab_m2_reg <= ab_m2_reg >> 5;
        mul_cycle <= mul_cycle + 1 ;
    end else begin
        ab_m1_reg   <=     'b0;
        ab_m2_reg   <=     'b0;
        prd_msb     <=       0;
        O_MUL_BUSY  <=       0;
        mul_cycle  <=        0;
    end
end

always@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        product_reg <= 'b0;
    //end else if(O_MUL_BUSY & ab_m2_reg != 0)begin
    end else if(O_MUL_BUSY & mul_cycle < 3)begin
        product_reg <= product_reg + prod_shift;  //add shift 累加移位结果   
    end else begin
        product_reg <= 'b0;
    end
end
mul_shift5 u_mul6_shift5(
.I_IN1(ab_m1_reg),
.I_IN2(ab_m2_reg[4:0]),
.O_OUT(prod_shift)
    );
endmodule
