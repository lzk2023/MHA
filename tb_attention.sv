`timescale 1ns/1ps
`include "defines.v"
module tb_attention(
);

bit                I_CLK        ;
bit                I_ASYN_RSTN  ;
bit                I_SYNC_RSTN  ;
bit                I_ATTN_START ;

bit [8-1:0] Q_MATRIX [0:16-1][0:128-1];
bit [8-1:0] K_MATRIX [0:16-1][0:128-1];
bit [8-1:0] V_MATRIX [0:16-1][0:128-1];

logic                O_SA_START ;
logic [7:0] O_MAT_1 [0:15][0:127]   ;
logic [7:0] O_MAT_2 [0:127][0:15]   ;
logic [7:0] O_M_DIM ;
logic                O_DATA_VLD ;
logic [7:0] O_ATT_DATA [0:15][0:127];
logic                I_SA_VLD     ;
logic [7:0] I_SA_RESULT [0:15][0:15] ;
logic                I_PE_SHIFT   ;

attention#(
    .D_W   (8 ),
    .SA_R  (16),
    .SA_C  (16),
    .DIM   (16),       //sequence length
    .D_K   (128)        //Q,K,V column num（dimention/h_num)
)u_dut_attention(
    .I_CLK          (I_CLK        ),
    .I_ASYN_RSTN    (I_ASYN_RSTN  ),
    .I_SYNC_RSTN    (I_SYNC_RSTN  ),
    .I_ATTN_START   (I_ATTN_START ),
    .I_PE_SHIFT     (I_PE_SHIFT   ),//connect to SA_wrapper O_PE_SHIFT
    .I_MAT_Q        (Q_MATRIX     ),
    .I_MAT_K        (K_MATRIX     ),
    .I_MAT_V        (V_MATRIX     ),
    .I_SA_VLD       (I_SA_VLD     ),//valid from SA
    .I_SA_RESULT    (I_SA_RESULT  ),//16*16*D_W,from SA
    .O_SA_START     (O_SA_START   ),//to SA_wrapper
    .O_MAT_1        (O_MAT_1      ),//to SA_wrapper
    .O_MAT_2        (O_MAT_2      ),//to SA_wrapper
    .O_M_DIM        (O_M_DIM      ),//to SA_wrapper
    .O_DATA_VLD     (O_DATA_VLD   ),
    .O_ATT_DATA     (O_ATT_DATA   )
);

SA_wrapper#(
    .D_W        (8         ),
    .SA_R       (16        ),  //SA_ROW,        SA.shape = (SA_R,SA_C)
    .SA_C       (16        )   //SA_COLUMN,     
) u_dut_SA_top(
    .I_CLK          (I_CLK        ),
    .I_ASYN_RSTN    (I_ASYN_RSTN  ),
    .I_START_FLAG   (O_SA_START   ),
    .I_M_DIM        (O_M_DIM      ),//
    .I_X_MATRIX     (O_MAT_1      ),//input x(from left)     
    .I_W_MATRIX     (O_MAT_2      ),//input weight(from ddr)             
    .O_OUT_VLD      (I_SA_VLD     ),// 
    .O_PE_SHIFT     (I_PE_SHIFT   ),                                  
    .O_OUT          (I_SA_RESULT  ) //OUT.shape = (X_R,64)               
);    
always #5 I_CLK = ~I_CLK;
initial begin
    I_CLK        = 0;
    I_ASYN_RSTN  = 0;
    I_SYNC_RSTN  = 1;
    I_ATTN_START = 0;
    #100
    I_ASYN_RSTN  = 1;
    I_ATTN_START = 1;
    for(int i=0;i<16;i=i+1)begin
        for(int i_1=0;i_1<8;i_1=i_1+1)begin
            Q_MATRIX[i][i_1*16 +: 16] = '{8'h02,8'h01,8'h02,8'h03,8'h04,8'h05,8'h06,8'h07,8'h08,8'h09,8'h0a,8'h0b,8'h0c,8'h0d,8'h0e,8'h0f};
        end
    end
    for(int j=0;j<16;j=j+1)begin
        for(int j_1=0;j_1<8;j_1=j_1+1)begin
            K_MATRIX[j][j_1*16 +: 16] = '{8'h02,8'h01,8'h02,8'h03,8'h04,8'h05,8'h06,8'h07,8'h08,8'h09,8'h0a,8'h0b,8'h0c,8'h0d,8'h0e,8'h0f};
        end
    end
    for(int k=0;k<16;k=k+1)begin
        for(int x=0;x<8;x=x+1)begin
            V_MATRIX[k][x*16 +: 16] = '{8'h02,8'h01,8'h02,8'h03,8'h04,8'h05,8'h06,8'h07,8'h08,8'h09,8'h0a,8'h0b,8'h0c,8'h0d,8'h0e,8'h0f};
        end
    end
    #10
    I_ATTN_START = 0;
    #12000
    $finish;
end
endmodule