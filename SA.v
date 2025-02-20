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
    parameter D_W  = 16,
    parameter SA_R = 16,
    parameter SA_C = 16
)
(
    input                        I_CLK       ,
    input                        I_ASYN_RSTN ,
    input                        I_SYNC_RSTN ,
    input                        I_START_FLAG,
    input  [(SA_R*D_W)-1:0]      I_X         ,//input x(from left)
    input  [(SA_C*D_W)-1:0]      I_W         ,//input weight(from up)
    output                       O_SHIFT     ,//PE shift,O_SHIFT <= 1
    output [(SA_R*SA_C*D_W)-1:0] O_OUT        //output data,
);
localparam S_IDLE = 1'b0;
localparam S_CAL  = 1'b1;
reg                         state     ;
reg                         x_vld     ;

wire [D_W-1:0] out_matrix  [0:SA_R-1] [0:SA_C-1];
wire [D_W-1:0] w_io_matrix [0:SA_R-1] [0:SA_C-1];
wire [D_W-1:0] x_io_matrix [0:SA_R-1] [0:SA_C-1];
wire                        pe00_vld  ;

`MATRIX_TO_VARIABLE(D_W,SA_R,SA_C,O_OUT,out_matrix) //format:(D_W,ROW,COLUMN,VARIABLE,ARRAY)

assign O_SHIFT = pe00_vld;

always@(posedge I_CLK or negedge I_ASYN_RSTN)begin
    if(!I_ASYN_RSTN | !I_SYNC_RSTN)begin
        state     <= 0;
    end else begin
        case(state)
            S_IDLE:begin
                if(I_START_FLAG)begin
                    state <= S_CAL;
                end else begin
                    state <= state;
                end
            end
            S_CAL :begin
                state <= state; 
            end
        endcase
    end
end

always@(*)begin
    if(state == S_CAL)begin
        x_vld = 1;
    end else begin
        x_vld = 0;
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
                    .I_ASYN_RSTN(I_ASYN_RSTN),
                    .I_SYNC_RSTN(I_SYNC_RSTN),
                    .I_VLD      (x_vld),
                    .I_X        (I_X[0 +: D_W]),//input x(from left)
                    .I_W        (I_W[0 +: D_W]),//input weight(from up)
                    .O_VLD      (pe00_vld),
                    .O_X        (x_io_matrix[0][0]),//output x(right shift)
                    .O_W        (w_io_matrix[0][0]),
                    .O_D        (out_matrix[0][0])
                );
            end
            else if(i != 0 & j == 0)begin
                PE #(
                    .D_W(D_W)
                )u_PE(
                    .I_CLK      (I_CLK  ),
                    .I_ASYN_RSTN(I_ASYN_RSTN),
                    .I_SYNC_RSTN(I_SYNC_RSTN),
                    .I_VLD      (x_vld),
                    .I_X        (I_X[i*D_W +: D_W]),//input x(from left)
                    .I_W        (w_io_matrix[i-1][0]),//input weight(from up)
                    .O_VLD      (),
                    .O_X        (x_io_matrix[i][0]),//output x(right shift)
                    .O_W        (w_io_matrix[i][0]),
                    .O_D        (out_matrix[i][0])
                );
            end else if(i == 0 & j != 0)begin
                PE #(
                    .D_W(D_W)
                ) u_PE(
                    .I_CLK      (I_CLK  ),
                    .I_ASYN_RSTN(I_ASYN_RSTN),
                    .I_SYNC_RSTN(I_SYNC_RSTN),
                    .I_VLD      (x_vld),
                    .I_X        (x_io_matrix[0][j-1]),//input x(from left)
                    .I_W        (I_W[j*D_W +: D_W]),//input weight(from up)
                    .O_VLD      (),
                    .O_X        (x_io_matrix[0][j]),//output x(right shift)
                    .O_W        (w_io_matrix[0][j]),
                    .O_D        (out_matrix[0][j])
                );
            end else begin
                PE #(
                    .D_W(D_W)
                )u_PE(
                    .I_CLK      (I_CLK  ),
                    .I_ASYN_RSTN(I_ASYN_RSTN),
                    .I_SYNC_RSTN(I_SYNC_RSTN),
                    .I_VLD      (x_vld),
                    .I_X        (x_io_matrix[i][j-1]),//input x(from left)
                    .I_W        (w_io_matrix[i-1][j]),//input weight(from up)
                    .O_VLD      (),
                    .O_X        (x_io_matrix[i][j]),//output x(right shift)
                    .O_W        (w_io_matrix[i][j]),
                    .O_D        (out_matrix[i][j])
                );
            end
        end
    end
endgenerate
endmodule