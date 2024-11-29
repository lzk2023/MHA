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

wire    [31:0]  prod_shift;
wire    [31:0]  prod_32   ;
wire    [31:0]  o_m1_sft5 ;
wire    [14:0]  m2_15     ;//reg input  寄存输入数据
wire            m2_msb    ;

reg     [31:0]  product_reg;//15 bits * 15bits
reg     [31:0]  m1_reg ;
reg     [1:0]   mul_cycle ;//

assign m2_15     = I_M2[14:0];
assign m2_msb    = I_M2[15];
assign O_VLD     = (O_MUL_BUSY & mul_cycle == 3) ? 1 : 0;
assign O_PRODUCT = {prod_32[31],prod_32[27:13]};
assign prod_32   = product_reg - (m2_msb ? m1_reg<<1 : 0);//select output 选择输出

always@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        m1_reg     <= 'b0;
        O_MUL_BUSY <=   0;
        mul_cycle  <=   0;
    end else if(I_VLD & !O_MUL_BUSY)begin          //
        m1_reg     <= {{16{I_M1[15]}},I_M1};
        O_MUL_BUSY <=           1 ;
        mul_cycle  <=           0 ;
    //end else if(O_MUL_BUSY & ab_m2_reg != 0)begin
    end else if(O_MUL_BUSY & mul_cycle < 3)begin
        m1_reg    <= o_m1_sft5     ;                          //clk 2/3/4:pipeline_3
        mul_cycle <= mul_cycle + 1 ;
    end else begin
        m1_reg      <=     'b0;
        O_MUL_BUSY  <=       0;
        mul_cycle   <=       0;
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
.I_IN2(ab_m2_reg[(mul_cycle-1)*5+:5]),
.O_OUT(prod_shift),
.O_SFT1(o_m1_sft5)
    );
endmodule
