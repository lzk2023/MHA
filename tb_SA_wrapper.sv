`timescale 1ns/1ps
`include "defines.v"
module tb_SA_wrapper(

);
localparam D_W    = 8;
localparam SA_R   = 16;
localparam SA_C   = 16;

bit                     I_CLK        ;
bit                     I_ASYN_RSTN  ;
bit                     I_SYNC_RSTN  ;
bit                     I_START_FLAG ;
  
//logic                        O_MATRIX_OVER;//
logic                        O_PE_SHIFT   ;
logic                        O_OUT_VLD    ;
bit [D_W-1:0] X_MATRIX [0:SA_R-1][0:127];
bit [D_W-1:0] W_MATRIX [0:127][0:SA_C-1];
bit [D_W-1:0] O_MATRIX [0:SA_R-1][0:SA_C-1];
//SA_mat_manager#(
//    .D_W  (D_W  ),
//    .X_R  (SA_R ),
//    .M_DIM(SA_C ),//X_C == W_R == M_DIM,dimention of the 2 multiply matrix.
//    .W_C  (SA_C )
//)u_dut_SA_mat_manager(
//    .I_CLK      (I_CLK        ),
//    .I_ASYN_RSTN(I_ASYN_RSTN  ),
//    .I_SYNC_RSTN(I_SYNC_RSTN  ),
//    .I_PE_SHIFT (O_PE_SHIFT   ),
//    .I_START    (I_START_FLAG ),
//    .I_X_MATRIX (I_X_MATRIX   ),
//    .I_W_MATRIX (I_W_MATRIX   ),
//    .O_OVER     (O_MATRIX_OVER),
//    .O_X_VECTOR (I_X          ),
//    .O_W_VECTOR (I_W          )
//);

SA_wrapper#(
    .D_W        (D_W          ),
    .SA_R       (SA_R         ),  //SA_ROW,        SA.shape = (SA_R,SA_C)
    .SA_C       (SA_C         )   //SA_COLUMN,     
) u_dut_SA_top(
    .I_CLK          (I_CLK        ),
    .I_ASYN_RSTN    (I_ASYN_RSTN  ),
    .I_SYNC_RSTN    (I_SYNC_RSTN  ),
    .I_START_FLAG   (I_START_FLAG ),//
    .I_X_MATRIX     (X_MATRIX     ),//input x(from left)     
    .I_W_MATRIX     (W_MATRIX     ),//input weight(from ddr)             
    .O_OUT_VLD      (O_OUT_VLD    ),// 
    .O_PE_SHIFT     (O_PE_SHIFT   ),                                  
    .O_OUT          (O_MATRIX     ) //OUT.shape = (X_R,64)               
);           

always #5 I_CLK = ~I_CLK;

//function [15:0] mul_16;
//    input [15:0] a;
//    input [15:0] b;
//    reg [31:0] c;
//    begin
//        c = $signed(a) * $signed(b);
//        mul_16 = {c[31],c[27:13]};
//    end
//endfunction
//int i,j;
initial begin
    #100
    I_ASYN_RSTN  = 1;
    I_SYNC_RSTN  = 1;
    I_START_FLAG = 1;
    for(int i=0;i<16;i=i+1)begin
        X_MATRIX[i][0:15] = '{8'h00,8'h01,8'h02,8'h03,8'h04,8'h05,8'h06,8'h07,8'h08,8'h09,8'h0a,8'h0b,8'h0c,8'h0d,8'h0e,8'h0f};
    end
    for(int j=0;j<16;j=j+1)begin
        W_MATRIX[j][0:15] = '{8'h00,8'h01,8'h02,8'h03,8'h04,8'h05,8'h06,8'h07,8'h08,8'h09,8'h0a,8'h0b,8'h0c,8'h0d,8'h0e,8'h0f};
    end
    #10
    I_START_FLAG = 0;
    #1000



    I_SYNC_RSTN  = 0;
    #10
    I_SYNC_RSTN  = 1;
    #100
    I_START_FLAG = 1;
    #10
    I_START_FLAG = 0;
    #1000
    $finish;
end
endmodule
