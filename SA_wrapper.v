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
    parameter D_W  = 16,  //Data_Width
    parameter SA_R = 16,  //SA_ROW,     SA.shape = (SA_R,SA_C)
    parameter SA_C = 16   //SA_COLUMN
) (
    input                        I_CLK       ,
    input                        I_ASYN_RSTN ,
    input                        I_SYNC_RSTN ,
    input                        I_START_FLAG,
    input                        I_END_FLAG  ,//                                              SA_C    
    input   [(SA_R*D_W)-1:0]        I_X         ,//input x(from left)     matrix x:     x|<-------------->|
    input   [(SA_C*D_W)-1:0]        I_W         ,//input weight(from up)                |
    output                       O_OUT_VLD   ,//                                   SA_R |
    //output  [(X_R*SA_C*D_W)-1:0]    O_OUT        //OUT.shape = (X_R,SA_C)             |
    output                       O_PE_SHIFT  ,//                                        x
    output  [SA_R*SA_C*D_W-1:0]        O_OUT        
);

wire        [(SA_R*D_W)-1:0] input_x ;
wire        [(SA_C*D_W)-1:0] input_w ;

reg         [D_W-1:0] in_x_ff[0:SA_R-1][0:SA_R-1];
reg         [D_W-1:0] in_w_ff[0:SA_C-1][0:SA_C-1];


generate
    for(genvar i=0;i<SA_R;i=i+1)begin
        if(i==0)
            assign input_x[0*D_W +: D_W] = I_X[0*D_W +: D_W];
        else
            assign input_x[i*D_W +: D_W] = in_x_ff[i][0];
        for(genvar j=0;j<i;j=j+1)begin
            if(j == i-1)begin
                always@(posedge I_CLK or negedge I_ASYN_RSTN)begin
                    if(!I_ASYN_RSTN | !I_SYNC_RSTN)begin
                        in_x_ff[i][j] <= 0;
                    end else if(O_PE_SHIFT)begin
                        in_x_ff[i][j] <= I_X[i*D_W +: D_W];
                    end else begin
                        in_x_ff[i][j] <= in_x_ff[i][j];
                    end
                end
            end else begin
                always@(posedge I_CLK or negedge I_ASYN_RSTN)begin
                    if(!I_ASYN_RSTN | !I_SYNC_RSTN)begin
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
    for(genvar i=0;i<SA_C;i=i+1)begin
        if(i==0)
            assign input_w[0*D_W +: D_W] = I_W[0*D_W +: D_W];
        else
            assign input_w[i*D_W +: D_W] = in_w_ff[i][0];
        for(genvar j=0;j<i;j=j+1)begin
            if(j == i-1)begin
                always@(posedge I_CLK or negedge I_ASYN_RSTN)begin
                    if(!I_ASYN_RSTN | !I_SYNC_RSTN)begin
                        in_w_ff[i][j] <= 0;
                    end else if(O_PE_SHIFT)begin
                        in_w_ff[i][j] <= I_W[i*D_W +: D_W];
                    end else begin
                        in_w_ff[i][j] <= in_w_ff[i][j];
                    end
                end
            end else begin
                always@(posedge I_CLK or negedge I_ASYN_RSTN)begin
                    if(!I_ASYN_RSTN | !I_SYNC_RSTN)begin
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
    .SA_R        (SA_R        ),
    .SA_C        (SA_C        )
) u_SA (
    .I_CLK       (I_CLK       ),
    .I_ASYN_RSTN (I_ASYN_RSTN ),
    .I_SYNC_RSTN (I_SYNC_RSTN ),
    .I_START_FLAG(I_START_FLAG),
    .I_END_FLAG  (I_END_FLAG  ),
    .I_X         (input_x     ),//input x(from left)
    .I_W         (input_w     ),//input weight(from up)
    .O_SHIFT     (O_PE_SHIFT  ),//PE shift,O_SHIFT <= 1
    .O_OUT       (O_OUT       ) //output data(keep),
);
endmodule