`timescale 1ns/1ps
`include "defines.v"
module tb_SA_wrapper(

);
localparam D_W    = 16;
localparam SA_R   = 16;
localparam SA_C   = 16;

bit                     I_CLK        ;
bit                     I_ASYN_RSTN  ;
bit                     I_SYNC_RSTN  ;
bit                     I_START_FLAG ;

bit   [SA_R*SA_C*D_W-1:0] I_X_MATRIX   ;
bit   [SA_R*SA_C*D_W-1:0] I_W_MATRIX   ;
  
//logic                        O_MATRIX_OVER;//
logic  [(SA_R*SA_C*D_W)-1:0] O_OUT        ;
logic                        O_PE_SHIFT   ;
logic                        O_OUT_VLD    ;

bit [D_W-1:0] X_MATRIX [0:SA_R-1][0:SA_C-1];
bit [D_W-1:0] W_MATRIX [0:SA_R-1][0:SA_C-1];
bit [D_W-1:0] O_MATRIX [0:SA_R-1][0:SA_C-1];
`MATRIX_TO_VARIABLE(D_W,SA_R,SA_C,I_X_MATRIX,X_MATRIX) //format:(D_W,ROW,COLUMN,VARIABLE,ARRAY)
`MATRIX_TO_VARIABLE(D_W,SA_R,SA_C,I_W_MATRIX,W_MATRIX) //format:(D_W,ROW,COLUMN,VARIABLE,ARRAY)
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
    .I_X_MATRIX     (I_X_MATRIX   ),//input x(from left)     
    .I_W_MATRIX     (I_W_MATRIX   ),//input weight(from ddr)             
    .O_OUT_VLD      (O_OUT_VLD    ),// 
    .O_PE_SHIFT     (O_PE_SHIFT   ),                                  
    .O_OUT          (O_OUT        ) //OUT.shape = (X_R,64)               
);           

always #5 I_CLK = ~I_CLK;

`VARIABLE_TO_MATRIX(D_W,SA_R,SA_C,O_OUT,O_MATRIX) //format:(D_W,ROW,COLUMN,VARIABLE,ARRAY)


//function [15:0] mul_16;
//    input [15:0] a;
//    input [15:0] b;
//    reg [31:0] c;
//    begin
//        c = $signed(a) * $signed(b);
//        mul_16 = {c[31],c[27:13]};
//    end
//endfunction

initial begin
    #100
    I_ASYN_RSTN  = 1;
    I_SYNC_RSTN  = 1;
    I_START_FLAG = 1;
    X_MATRIX = '{
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00}
    };
    W_MATRIX = '{
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00},
        '{16'h000,16'h100,16'h200,16'h300,16'h400,16'h500,16'h600,16'h700,16'h800,16'h900,16'ha00,16'hb00,16'hc00,16'hd00,16'he00,16'hf00}
    };
    //X_MATRIX = '{
    //    '{16'h000,16'h100,16'h200},
    //    '{16'h000,16'h100,16'h200},
    //    '{16'h000,16'h100,16'h200}
    //};
    //W_MATRIX = '{
    //    '{16'h000,16'h100,16'h200},
    //    '{16'h000,16'h100,16'h200},
    //    '{16'h000,16'h100,16'h200}
    //};
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
