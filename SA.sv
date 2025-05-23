`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: lzk
// 
// Create Date: 2024/10/31 10:05:11
// Design Name: 
// Module Name: SA
// Project Name: MHA
// Target Devices: 
// Tool Versions: 
// Description: Systolic Array,5clk update PE.
//              input shift(left to right),weight shift(up to down),output maintain.
//              data 16 bits,for 1 signal bit,2 int bits and 13 fraction bits
//              data format:16'b0_00_00000_0000_0000
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"
module SA #(
    parameter D_W  = 8,
    parameter SA_R = 16,
    parameter SA_C = 16
)
(
    input  logic           I_CLK                        ,
    input  logic           I_RST_N                      ,
    input  logic           I_LOAD_SIGNAL                ,
    input  logic [D_W-1:0] I_X [0:SA_R-1]               ,//input x(from left)
    input  logic [D_W-1:0] I_W [0:SA_R-1][0:SA_C-1]     ,//input weight(load)
    input  logic [D_W-1:0] I_W_LAST [0:SA_R-1][0:SA_C-1],
    output logic [D_W-1:0] O_D [0:SA_C-1]           //output data,
);

logic [D_W-1:0] d_io_matrix [0:SA_R-1] [0:SA_C-1];
logic [D_W-1:0] x_io_matrix [0:SA_R-1] [0:SA_C-1];
logic           clr_signal_row [0:SA_R-1] [0:SA_C-1];
logic           clr_signal_col [0:SA_R-1] [0:SA_C-1];

logic [D_W-1:0] DEBUG_W_MATRIX [0:SA_R-1][0:SA_C-1];
assign O_D = d_io_matrix[SA_R-1][0:SA_C-1];
                                                        //   SA:                 SA_C(j)
genvar i;                                               //       x|<--------------------------------->|
genvar j;                                               //       |
generate                                                //SA_R(i)|             SA_R x SA_C
    for(i=0;i<SA_R;i=i+1)begin                          //       |
        for(j=0;j<SA_C;j=j+1)begin                      //       x
            if(i == 0 & j == 0)begin
                PE #(
                    .D_W(D_W)
                )u_PE(
                    .I_CLK       (I_CLK  ),
                    .I_ASYN_RSTN (I_RST_N),
                    .I_X         (I_X[0]),//input x(from left)
                    .I_W         (I_W[0][0]),//input weight(load)
                    .I_D         ('b0),//input data(from up)
                    .I_LOAD_LEFT (I_LOAD_SIGNAL),
                    .I_LOAD_UP   (I_LOAD_SIGNAL),
                    .O_X         (x_io_matrix[i][j]),//output x(right shift)
                    .O_W         (DEBUG_W_MATRIX[i][j]),//debug
                    .O_D         (d_io_matrix[i][j]),
                    .O_LOAD_RIGHT(clr_signal_row[i][j]),
                    .O_LOAD_DOWN (clr_signal_col[i][j]) 
                );
            end
            else if(i != 0 & j == 0)begin
                PE #(
                    .D_W(D_W)
                )u_PE(
                    .I_CLK       (I_CLK  ),
                    .I_ASYN_RSTN (I_RST_N),
                    .I_X         (I_X[i]),//input x(from left)
                    .I_W         (I_W[i][0]),//input weight(load)
                    .I_D         (d_io_matrix[i-1][0]),//input data(from up)
                    .I_LOAD_LEFT (1'b0),
                    .I_LOAD_UP   (clr_signal_col[i-1][0]),
                    .O_X         (x_io_matrix[i][j]),//output x(right shift)
                    .O_W         (DEBUG_W_MATRIX[i][j]),//debug
                    .O_D         (d_io_matrix[i][j]),
                    .O_LOAD_RIGHT(clr_signal_row[i][j]),
                    .O_LOAD_DOWN (clr_signal_col[i][j]) 
                );
            end else if(i == 0 & j != 0)begin
                PE #(
                    .D_W(D_W)
                ) u_PE(
                    .I_CLK       (I_CLK  ),
                    .I_ASYN_RSTN (I_RST_N),
                    .I_X         (x_io_matrix[0][j-1]),//input x(from left)
                    .I_W         (I_W[0][j]),//input weight(load)
                    .I_D         ('b0),//input data(from up)
                    .I_LOAD_LEFT (clr_signal_row[0][j-1]),
                    .I_LOAD_UP   (1'b0),
                    .O_X         (x_io_matrix[i][j]),//output x(right shift)
                    .O_W         (DEBUG_W_MATRIX[i][j]),//debug
                    .O_D         (d_io_matrix[i][j]),
                    .O_LOAD_RIGHT(clr_signal_row[i][j]),
                    .O_LOAD_DOWN (clr_signal_col[i][j]) 
                );
            end else if(j>SA_C-1-i)begin
                PE #(
                    .D_W(D_W)
                )u_PE(
                    .I_CLK       (I_CLK  ),
                    .I_ASYN_RSTN (I_RST_N),
                    .I_X         (x_io_matrix[i][j-1]),//input x(from left)
                    .I_W         (I_W_LAST[i][j]),//input weight_last(load)
                    .I_D         (d_io_matrix[i-1][j]),//input data(from up)
                    .I_LOAD_LEFT (clr_signal_row[i][j-1]),
                    .I_LOAD_UP   (clr_signal_col[i-1][j]),
                    .O_X         (x_io_matrix[i][j]),//output x(right shift)
                    .O_W         (DEBUG_W_MATRIX[i][j]),//debug
                    .O_D         (d_io_matrix[i][j]),
                    .O_LOAD_RIGHT(clr_signal_row[i][j]),
                    .O_LOAD_DOWN (clr_signal_col[i][j]) 
                );
            end else begin
                PE #(
                    .D_W(D_W)
                )u_PE(
                    .I_CLK       (I_CLK  ),
                    .I_ASYN_RSTN (I_RST_N),
                    .I_X         (x_io_matrix[i][j-1]),//input x(from left)
                    .I_W         (I_W[i][j]),//input weight(load)
                    .I_D         (d_io_matrix[i-1][j]),//input data(from up)
                    .I_LOAD_LEFT (clr_signal_row[i][j-1]),
                    .I_LOAD_UP   (clr_signal_col[i-1][j]),
                    .O_X         (x_io_matrix[i][j]),//output x(right shift)
                    .O_W         (DEBUG_W_MATRIX[i][j]),//debug
                    .O_D         (d_io_matrix[i][j]),
                    .O_LOAD_RIGHT(clr_signal_row[i][j]),
                    .O_LOAD_DOWN (clr_signal_col[i][j]) 
                );
            end
        end
    end
endgenerate
endmodule