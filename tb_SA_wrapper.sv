`timescale 1ns/1ps
`include "defines.v"
module tb_SA_wrapper(

);
localparam D_W    = 8;
localparam SA_R   = 16;
localparam SA_C   = 16;

bit                     I_CLK        ;
bit                     I_RST_N      ;
bit                     I_START_FLAG ;

logic                        O_PE_SHIFT   ;
logic                        O_OUT_VLD    ;
bit [D_W-1:0] X_MATRIX [0:SA_R-1][0:SA_C-1];
bit [D_W-1:0] W_MATRIX [0:SA_R-1][0:SA_C-1];
bit [D_W-1:0] D_MATRIX [0:SA_R-1][0:SA_C-1];
bit [D_W-1:0] O_MATRIX [0:SA_R-1][0:SA_C-1];

SA_wrapper#(
    .D_W        (D_W          ),
    .SA_R       (SA_R         ),  //SA_ROW,        SA.shape = (SA_R,SA_C)
    .SA_C       (SA_C         )   //SA_COLUMN,     
) u_dut_SA_top(
    .I_CLK          (I_CLK        ),
    .I_RST_N        (I_RST_N      ),
    .I_START_FLAG   (I_START_FLAG ),//
    .I_X_MATRIX     (X_MATRIX     ),//input x(from left)     
    .I_W_MATRIX     (W_MATRIX     ),//input weight(from ddr)             
    .I_DATA_LOAD    (D_MATRIX     ),
    .O_OUT_VLD      (O_OUT_VLD    ),// 
    .O_PE_SHIFT     (O_PE_SHIFT   ),                                  
    .O_OUT          (O_MATRIX     ) //OUT.shape = (X_R,64)               
);           

always #5 I_CLK = ~I_CLK;

initial begin
    #100
    I_RST_N      = 1;
    I_START_FLAG = 1;
    for(int i=0;i<16;i=i+1)begin
        X_MATRIX[i][0:15] = '{8'h00,8'h01,8'h02,8'h03,8'h04,8'h05,8'h06,8'h07,8'h08,8'h09,8'h0a,8'h0b,8'h0c,8'h0d,8'h0e,8'h0f};
    end
    for(int j=0;j<16;j=j+1)begin
        W_MATRIX[j][0:15] = '{8'h00,8'h01,8'h02,8'h03,8'h04,8'h05,8'h06,8'h07,8'h08,8'h09,8'h0a,8'h0b,8'h0c,8'h0d,8'h0e,8'h0f};
    end
    #10
    I_START_FLAG = 0;

    wait(O_OUT_VLD)
    @(posedge I_CLK)
    I_START_FLAG  = 1;
    D_MATRIX = '{default:8'h01};
    for(int j=0;j<16;j=j+1)begin
        for(int k=0;k<16;k=k+1)begin
            if(k == j)begin
                W_MATRIX[j][k] = 8'h20;
            end else begin
                W_MATRIX[j][k] = 8'h00;
            end
        end
    end
    @(posedge I_CLK)
    I_START_FLAG  = 0;
    #1000
    $finish;
end
endmodule
