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
//              input shift(left to right),output maintain,weight shift(up to down).
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
    parameter D_W = 16,  //Data_Width
    parameter S   = 16,  //SA_ROW,     SA.shape = (S,C)
    parameter C   = 16   //SA_COLUMN
) (
    input                        I_CLK       ,
    input                        I_RST_N     ,
    input                        I_START_FLAG,
    input                        I_END_FLAG  ,//                                              C    
    input   [(S*D_W)-1:0]        I_X         ,//input x(from left)     matrix x:     x|<-------------->|
    input   [(C*D_W)-1:0]        I_W         ,//input weight(from up)                |
    output                       O_OUT_VLD   ,//                                   S |
    //output  [(X_R*C*D_W)-1:0]    O_OUT        //OUT.shape = (X_R,C)                |
    output                       O_PE_SHIFT  ,//                                     x
    output  [S*C*D_W-1:0]        O_OUT        
);

wire        [(S*D_W)-1:0] input_x ;
wire        [(C*D_W)-1:0] input_w ;

reg         [D_W-1:0] in_x_ff[0:S-1][0:S-1];
reg         [D_W-1:0] in_w_ff[0:C-1][0:C-1];


generate
    for(genvar i=0;i<S;i=i+1)begin
        if(i==0)
            assign input_x[0*D_W +: D_W] = I_X[0*D_W +: D_W];
        else
            assign input_x[i*D_W +: D_W] = in_x_ff[i][0];
        for(genvar j=0;j<i;j=j+1)begin
            if(j == i-1)begin
                always@(posedge I_CLK or negedge I_RST_N)begin
                    if(!I_RST_N)begin
                        in_x_ff[i][j] <= 0;
                    end else if(O_PE_SHIFT)begin
                        in_x_ff[i][j] <= I_X[i*D_W +: D_W];
                    end else begin
                        in_x_ff[i][j] <= in_x_ff[i][j];
                    end
                end
            end else begin
                always@(posedge I_CLK or negedge I_RST_N)begin
                    if(!I_RST_N)begin
                        in_x_ff[i][j] <= 0;
                    end else if(O_PE_SHIFT)begin
                        in_x_ff[i][j] <= in_x_ff[i][j+1];
                    end else begin
                        in_x_ff[i][j] <= in_x_ff[i][j];
                    end
                end
            end
        end
    end
endgenerate

generate
    for(genvar i=0;i<C;i=i+1)begin
        if(i==0)
            assign input_w[0*D_W +: D_W] = I_W[0*D_W +: D_W];
        else
            assign input_w[i*D_W +: D_W] = in_w_ff[i][0];
        for(genvar j=0;j<i;j=j+1)begin
            if(j == i-1)begin
                always@(posedge I_CLK or negedge I_RST_N)begin
                    if(!I_RST_N)begin
                        in_w_ff[i][j] <= 0;
                    end else if(O_PE_SHIFT)begin
                        in_w_ff[i][j] <= I_W[i*D_W +: D_W];
                    end else begin
                        in_w_ff[i][j] <= in_w_ff[i][j];
                    end
                end
            end else begin
                always@(posedge I_CLK or negedge I_RST_N)begin
                    if(!I_RST_N)begin
                        in_w_ff[i][j] <= 0;
                    end else if(O_PE_SHIFT)begin
                        in_w_ff[i][j] <= in_w_ff[i][j+1];
                    end else begin
                        in_w_ff[i][j] <= in_w_ff[i][j];
                    end
                end
            end
        end
    end
endgenerate

SA #(
    .D_W         (D_W         ),
    .S           (S           ),
    .C           (C           )
) u_SA (
    .I_CLK       (I_CLK       ),
    .I_RST_N     (I_RST_N     ),
    .I_START_FLAG(I_START_FLAG),
    .I_END_FLAG  (I_END_FLAG  ),
    .I_X         (input_x     ),//input x(from left)
    .I_W         (input_w     ),//input weight(from up)
    .O_SHIFT     (O_PE_SHIFT  ),//PE shift,O_SHIFT <= 1
    .O_OUT       (O_OUT       ) //output data(keep),
);
endmodule