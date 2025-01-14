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

module multiplier_16#(
parameter D_W = 16
)(
input              I_CLK     ,
input              I_RST_N   ,
input              I_VLD     ,//input valid
input      [D_W-1:0]  I_M1      ,//multiplicand(被乘数)
input      [D_W-1:0]  I_M2      ,//multiplier  (乘数)
output             O_VLD     ,//output valid
output reg         O_MUL_BUSY,
output     [D_W-1:0]  O_PRODUCT  //product     (积)
);

wire    [D_W*2-1:0]  prod_shift ;
wire    [D_W*2-1:0]  prod_32    ;
wire    [D_W*2-1:0]  m1_reg_sft;

reg     [D_W*2-1:0]  product_reg;//16 bits * 16bits
reg     [D_W*2-1:0]  m1_reg     ;
reg     [D_W-2:0]  m2_reg     ;//reg input(absolute value)  寄存输入数据
reg             m2_msb     ;
reg     [$clog2(D_W)-1:0]   mul_cycle  ;//
generate
    if(D_W == 16)begin
        assign O_PRODUCT = {prod_32[31],prod_32[27:13]};
    end else if(D_W == 8)begin
        assign O_PRODUCT = {prod_32[15],prod_32[11:5]};
    end 
endgenerate

assign O_VLD = (O_MUL_BUSY & mul_cycle == D_W-1) ? 1 : 0;
assign prod_32 = product_reg - (m2_msb ? m1_reg : 0);//select output 选择输出


always@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        m1_reg     <= 'b0;
        m2_reg     <= 'b0;
        m2_msb     <= 'b0;
        O_MUL_BUSY <=   0;
        mul_cycle  <=   0;
    end else if(I_VLD & !O_MUL_BUSY)begin          //clk 1:
        m1_reg     <= {{D_W{I_M1[D_W-1]}},I_M1};
        m2_reg     <= I_M2[D_W-2:0]  ;
        m2_msb     <= I_M2[D_W-1]    ;
        O_MUL_BUSY <=           1 ;
        mul_cycle  <=           0 ;
    //end else if(O_MUL_BUSY & ab_m2_reg != 0)begin
    end else if(O_MUL_BUSY & mul_cycle < D_W-1)begin
        m1_reg     <= m1_reg_sft   ;                          //clk 2/3/4:pipeline_3
        m2_reg     <= m2_reg >> 1   ;
        m2_msb     <= m2_msb        ;
        mul_cycle  <= mul_cycle + 1 ;
    end else begin
        m1_reg      <=     'b0;
        m2_reg      <=     'b0;
        m2_msb      <=       0;
        O_MUL_BUSY  <=       0;
        mul_cycle   <=       0;
    end
end

always@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        product_reg <= 'b0;
    //end else if(O_MUL_BUSY & m2_reg != 0)begin
    end else if(O_MUL_BUSY & mul_cycle < D_W-1)begin
        product_reg <= product_reg + prod_shift;  //add shift 累加移位结果   
    end else begin
        product_reg <= 'b0;
    end
end
mul_shift5 #(
.D_W(D_W)
)u_mul6_shift5(
.I_IN1(m1_reg),
.I_IN2(m2_reg[0]),
.O_OUT(prod_shift),
.O_SFT1(m1_reg_sft)
    );
endmodule