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
    input  logic           I_CLK                              ,
    input  logic           I_RST_N                            ,
    input  logic           I_START_FLAG                       ,
    input  logic           I_END_FLAG                         ,
    input  logic [D_W-1:0] I_X          [0:SA_R-1]            ,//input x(from left)
    input  logic [D_W-1:0] I_W          [0:SA_C-1]            ,//input weight(from up)
    input  logic [D_W-1:0] I_D          [0:SA_R-1][0:SA_C-1]  ,
    output logic           O_SHIFT                            ,//PE shift,O_SHIFT <= 1
    output logic [D_W-1:0] O_OUT        [0:SA_R-1][0:SA_C-1]   //output data,
);


logic                         x_vld     ;
logic [D_W-1:0] w_io_matrix [0:SA_R-1] [0:SA_C-1];
logic [D_W-1:0] x_io_matrix [0:SA_R-1] [0:SA_C-1];
logic                        pe00_vld  ;


assign O_SHIFT = pe00_vld;

always_ff@(posedge I_CLK or negedge I_RST_N) begin
    if(!I_RST_N | I_START_FLAG)begin
        x_vld <= 0;
    end else begin
        if(I_END_FLAG)begin
            x_vld <= 0;
        end else begin
            x_vld <= 1;
        end
    end
end
                                                        //   SA:                 SA_C(j)
genvar i;                                               //       x|<--------------------------------->|
genvar j;                                               //       |
generate                                                //SA_R(i)|             SA_R x SA_C
    for(i=0;i<SA_R;i=i+1)begin                          //       |
        for(j=0;j<SA_C;j=j+1)begin                         //       x
            if(i == 0 & j == 0)begin
                PE #(
                    .D_W(D_W)
                )u_PE(
                    .I_CLK      (I_CLK  ),
                    .I_ASYN_RSTN(I_RST_N),
                    .I_SYNC_RSTN(!I_START_FLAG),
                    .I_VLD      (x_vld),
                    .I_X        (I_X[0]),//input x(from left)
                    .I_W        (I_W[0]),//input weight(from up)
                    .I_D        (I_D[i][j]),//input load data
                    .O_VLD      (pe00_vld),
                    .O_X        (x_io_matrix[0][0]),//output x(right shift)
                    .O_W        (w_io_matrix[0][0]),
                    .O_D        (O_OUT[0][0])
                );
            end
            else if(i != 0 & j == 0)begin
                PE #(
                    .D_W(D_W)
                )u_PE(
                    .I_CLK      (I_CLK  ),
                    .I_ASYN_RSTN(I_RST_N),
                    .I_SYNC_RSTN(!I_START_FLAG),
                    .I_VLD      (x_vld),
                    .I_X        (I_X[i]),//input x(from left)
                    .I_W        (w_io_matrix[i-1][0]),//input weight(from up)
                    .I_D        (I_D[i][j]),//input load data
                    .O_VLD      (),
                    .O_X        (x_io_matrix[i][0]),//output x(right shift)
                    .O_W        (w_io_matrix[i][0]),
                    .O_D        (O_OUT[i][0])
                );
            end else if(i == 0 & j != 0)begin
                PE #(
                    .D_W(D_W)
                ) u_PE(
                    .I_CLK      (I_CLK  ),
                    .I_ASYN_RSTN(I_RST_N),
                    .I_SYNC_RSTN(!I_START_FLAG),
                    .I_VLD      (x_vld),
                    .I_X        (x_io_matrix[0][j-1]),//input x(from left)
                    .I_W        (I_W[j]),//input weight(from up)
                    .I_D        (I_D[i][j]),//input load data
                    .O_VLD      (),
                    .O_X        (x_io_matrix[0][j]),//output x(right shift)
                    .O_W        (w_io_matrix[0][j]),
                    .O_D        (O_OUT[0][j])
                );
            end else begin
                PE #(
                    .D_W(D_W)
                )u_PE(
                    .I_CLK      (I_CLK  ),
                    .I_ASYN_RSTN(I_RST_N),
                    .I_SYNC_RSTN(!I_START_FLAG),
                    .I_VLD      (x_vld),
                    .I_X        (x_io_matrix[i][j-1]),//input x(from left)
                    .I_W        (w_io_matrix[i-1][j]),//input weight(from up)
                    .I_D        (I_D[i][j]),//input load data
                    .O_VLD      (),
                    .O_X        (x_io_matrix[i][j]),//output x(right shift)
                    .O_W        (w_io_matrix[i][j]),
                    .O_D        (O_OUT[i][j])
                );
            end
        end
    end
endgenerate
endmodule