`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: lzk
// 
// Create Date: 2024/10/31 10:05:11
// Design Name: 
// Module Name: SA_wrapper
// Project Name: MHA
// Target Devices: 
// Tool Versions: 
// Description: Systolic Array,5clk update PE.
//              input shift(left to right),output shift(up to down),weight maintain.
//              data 16 bits,for 1 signal bit,2 int bits and 13 fraction bits
//              data format:16'b0_00_00000_0000_0000
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module SA_wrapper#(
    parameter S   = 64,  //W_ROW,     W.shape = (S,64)
    parameter X_R = 64   //X_ROW,     X.shape = (X_R,S)
) (
    input                        I_CLK       ,
    input                        I_RST_N     ,
    input                        I_START_FLAG,
    input   [(S*X_R*16)-1:0]     I_X         ,//input x(from left)
    input   [(S*64*16)-1:0]      I_W         ,//input weight(from ddr)
    output                       O_OUT_VLD   ,
    output  [(X_R*64*16)-1:0]    O_OUT        //OUT.shape = (X_R,64)
);
wire                             pe_shift    ;
wire        [(64*16)-1:0]        sa_out      ;

reg [15:0] x_matrix [S+X_R-2:0] [S-1:0]      ;

genvar i;
genvar j;
generate
    for(j=0;j<S;j=j+1)begin
        for(i=0;i<S+X_R-1;i=i+1)begin
            always@(posedge I_CLK or negedge I_RST_N)begin
                if(!I_RST_N)begin
                    x_matrix[i][j] <= 0;
                end else begin
                end
            end
        end
    end
endgenerate
SA #(
    .S           (S           )
) u_SA (
    .I_CLK       (I_CLK       ),
    .I_RST_N     (I_RST_N     ),
    .I_START_FLAG(I_START_FLAG),
    .I_END_FLAG  (),
    .I_X         (),//input x(from left)
    .I_W         (I_W         ),//input weight(from ddr)
    .O_SHIFT     (pe_shift    ),//PE shift,O_SHIFT <= 1
    .O_OUT       (sa_out      ) //output data(down shift),
);
endmodule
