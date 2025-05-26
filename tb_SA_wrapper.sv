`timescale 1ns/1ps
`include "defines.v"

import Utils::*;
module tb_SA_wrapper(

);
localparam D_W    = 8;
localparam SA_R   = 16;
localparam SA_C   = 16;

bit I_CLK                                  ;
bit I_RST_N                                ;
bit I_LOAD_FLAG                            ;
bit [D_W-1:0] X_MATRIX [0:SA_R-1][0:SA_C-1];
bit [D_W-1:0] W_MATRIX [0:SA_R-1][0:SA_C-1];

bit [D_W-1:0] COMPARE_MAT0 [0:SA_R-1][0:SA_C-1];
bit [D_W-1:0] COMPARE_MAT1 [0:SA_R-1][0:SA_C-1];
bit [D_W-1:0] COMPARE_MAT2 [0:SA_R-1][0:SA_C-1];
bit [D_W-1:0] COMPARE_MAT3 [0:SA_R-1][0:SA_C-1];

logic O_INPUT_FIFO_EMPTY[0:SA_R-1];
logic O_OUTPUT_FIFO_FULL[0:SA_C-1];
logic O_LOAD_WEIGHT_VLD;
logic O_OUT_VLD;
logic [D_W-1:0] O_OUT[0:SA_R-1][0:SA_C-1] ;

logic [D_W-1:0] X_MATRIX_TRANSPOSE [0:SA_R-1][0:SA_C-1];
logic [D_W-1:0] X_MATRIX_ROTATE [0:SA_R-1][0:SA_C-1];

generate
    for(genvar i=0;i<SA_R;i=i+1)begin
        for(genvar j=0;j<SA_C;j=j+1)begin
            assign X_MATRIX_TRANSPOSE[i][j] = X_MATRIX[j][i];
            assign X_MATRIX_ROTATE[i][j] = X_MATRIX_TRANSPOSE[i][SA_C-1-j];
        end
    end
endgenerate
SA_wrapper#(
    .D_W        (D_W ),
    .SA_R       (SA_R),  //SA_ROW,        SA.shape = (SA_R,SA_C)
    .SA_C       (SA_C)   //SA_COLUMN,     
) u_dut_SA_top(
    .I_CLK              (I_CLK             ),
    .I_RST_N            (I_RST_N           ),
    .I_LOAD_FLAG        (I_LOAD_FLAG       ),
    .I_X_MATRIX         (X_MATRIX_ROTATE   ),
    .I_W_MATRIX         (W_MATRIX          ),
    .I_ACCUMULATE_SIGNAL(1'b1),
    .O_INPUT_FIFO_EMPTY (O_INPUT_FIFO_EMPTY),
    .O_OUTPUT_FIFO_FULL (O_OUTPUT_FIFO_FULL),
    .O_LOAD_WEIGHT_VLD  (O_LOAD_WEIGHT_VLD ),
    .O_OUT_VLD          (O_OUT_VLD         ),
    .O_OUT              (O_OUT             )             
);           

always #5 I_CLK = ~I_CLK;

initial begin
    #100
    I_RST_N      = 1;
    I_LOAD_FLAG = 1;
    for(int i=0;i<16;i=i+1)begin
        X_MATRIX[i][0:15] = '{8'h10,8'h11,8'h02,8'h03,8'h04,8'h05,8'h06,8'h07,8'h08,8'h09,8'h0a,8'h0b,8'h0c,8'h0d,8'h0e,8'h0f};
    end
    for(int j=0;j<16;j=j+1)begin
        W_MATRIX[j][0:15] = '{8'h10,8'h11,8'h02,8'h03,8'h04,8'h05,8'h06,8'h07,8'h08,8'h09,8'h0a,8'h0b,8'h0c,8'h0d,8'h0e,8'h0f};
    end
    @(posedge I_CLK)
    I_LOAD_FLAG <= 0;
    mul_matrix_16_16(X_MATRIX,W_MATRIX,COMPARE_MAT0);

    @(O_LOAD_WEIGHT_VLD)
    @(posedge I_CLK)
    I_LOAD_FLAG <= 1;
    for(int i=0;i<16;i=i+1)begin
        X_MATRIX[i][0:15] <= '{8'h13,8'h12,8'h12,8'h13,8'h14,8'h15,8'h16,8'h17,8'h18,8'h19,8'h1a,8'h1b,8'h1c,8'h1d,8'h1e,8'h1f};
    end
    for(int j=0;j<16;j=j+1)begin
        W_MATRIX[j][0:15] <= '{8'h13,8'h12,8'h12,8'h13,8'h14,8'h15,8'h16,8'h17,8'h18,8'h19,8'h1a,8'h1b,8'h1c,8'h1d,8'h1e,8'h1f};
    end
    @(posedge I_CLK)
    I_LOAD_FLAG <= 0;
    mul_matrix_16_16(X_MATRIX,W_MATRIX,COMPARE_MAT1);
    
    @(O_LOAD_WEIGHT_VLD)
    @(posedge I_CLK)
    I_LOAD_FLAG <= 1;
    for(int i=0;i<16;i=i+1)begin
        X_MATRIX[i][0:15] <= '{8'h23,8'h22,8'h22,8'h23,8'h24,8'h25,8'h26,8'h27,8'h28,8'h29,8'h2a,8'h2b,8'h2c,8'h2d,8'h2e,8'h2f};
    end
    for(int j=0;j<16;j=j+1)begin
        W_MATRIX[j][0:15] <= '{8'h23,8'h22,8'h22,8'h23,8'h24,8'h25,8'h26,8'h27,8'h28,8'h29,8'h2a,8'h2b,8'h2c,8'h2d,8'h2e,8'h2f};
    end
    @(posedge I_CLK)
    I_LOAD_FLAG <= 0;
    mul_matrix_16_16(X_MATRIX,W_MATRIX,COMPARE_MAT2);
    add_matrix_16_16(COMPARE_MAT0,COMPARE_MAT1,COMPARE_MAT3);
    add_matrix_16_16(COMPARE_MAT3,COMPARE_MAT2,COMPARE_MAT3);
    #1000
    $finish;
end
endmodule
