`timescale 1ns/1ps
`include "defines.v"
module tb_attention(
);

bit                I_CLK        ;
bit                I_RST_N  ;
bit                I_ATTN_START ;

logic                O_SA_LOAD     ;
logic [7:0] O_MAT_1 [0:15][0:15]   ;
logic [7:0] O_MAT_2 [0:15][0:15]   ;
logic                O_DATA_VLD    ;
logic [7:0] O_ATTN_DATA [0:15][0:127];
logic                I_SA_VLD     ;
logic [7:0] I_SA_RESULT [0:15][0:15] ;
logic       I_LOAD_W_SIGNAL;
logic       O_ACC_SIGNAL;

logic       BRAM_RD_Q_VLD;
logic       BRAM_RD_K_VLD;
logic       BRAM_RD_V_VLD;
logic       BRAM_RD_O_VLD;
logic [7:0] BRAM_RD_Q_MAT [0:15][0:15];
logic [7:0] BRAM_RD_K_MAT [0:15][0:15];
logic [7:0] BRAM_RD_V_MAT [0:15][0:15];
logic [7:0] BRAM_RD_O_MAT [0:15][0:15];

logic       BRAM_Q_ENA  ;
logic       BRAM_K_ENA  ;
logic       BRAM_V_ENA  ;
logic       BRAM_O_ENA  ;
logic       BRAM_O_WEA  ;
logic [7:0] BRAM_WR_MAT [0:15][0:15];
logic [5:0] BRAM_SEL_Q_LINE;
logic [2:0] BRAM_SEL_Q_COL ;
logic [5:0] BRAM_SEL_K_LINE;
logic [2:0] BRAM_SEL_K_COL ;
logic [5:0] BRAM_SEL_V_LINE;
logic [2:0] BRAM_SEL_V_COL ;
logic [5:0] BRAM_SEL_O_LINE;
logic [2:0] BRAM_SEL_O_COL ;


attention#(
    .D_W   (8 ),
    .SA_R  (16),
    .SA_C  (16),
    .DIM   (16),       //sequence length
    .D_K   (128)        //Q,K,V column num（dimention/h_num)
)u_dut_attention(
    .I_CLK          (I_CLK        ),
    .I_RST_N        (I_RST_N      ),
    .I_ATTN_START   (I_ATTN_START ),
    .I_SA_VLD       (I_SA_VLD     ),//valid from SA
    .I_SA_RESULT    (I_SA_RESULT  ),//16*16*D_W,from SA
    .I_LOAD_W_SIGNAL(I_LOAD_W_SIGNAL),
    .O_SA_LOAD      (O_SA_LOAD    ),//to SA_wrapper
    .O_MAT_1        (O_MAT_1      ),//to SA_wrapper
    .O_MAT_2        (O_MAT_2      ),//to SA_wrapper
    .O_ACC_SIGNAL   (O_ACC_SIGNAL),
    .O_DATA_VLD     (O_DATA_VLD   ),
    .O_ATTN_DATA    (O_ATTN_DATA  ),
//****************bram ports**************//
    .I_BRAM_RD_Q_VLD   (BRAM_RD_Q_VLD),
    .I_BRAM_RD_K_VLD   (BRAM_RD_K_VLD),
    .I_BRAM_RD_V_VLD   (BRAM_RD_V_VLD),
    .I_BRAM_RD_O_VLD   (BRAM_RD_O_VLD),
    .I_BRAM_RD_Q_MAT   (BRAM_RD_Q_MAT),
    .I_BRAM_RD_K_MAT   (BRAM_RD_K_MAT),
    .I_BRAM_RD_V_MAT   (BRAM_RD_V_MAT),
    .I_BRAM_RD_O_MAT   (BRAM_RD_O_MAT),
    .O_BRAM_WR_MAT     (BRAM_WR_MAT),
    .O_BRAM_Q_ENA      (BRAM_Q_ENA),
    .O_BRAM_K_ENA      (BRAM_K_ENA),
    .O_BRAM_V_ENA      (BRAM_V_ENA),
    .O_BRAM_O_ENA      (BRAM_O_ENA),
    .O_BRAM_O_WEA      (BRAM_O_WEA),
    .O_BRAM_SEL_Q_LINE (BRAM_SEL_Q_LINE),
    .O_BRAM_SEL_Q_COL  (BRAM_SEL_Q_COL ),
    .O_BRAM_SEL_K_LINE (BRAM_SEL_K_LINE),
    .O_BRAM_SEL_K_COL  (BRAM_SEL_K_COL ),
    .O_BRAM_SEL_V_LINE (BRAM_SEL_V_LINE),
    .O_BRAM_SEL_V_COL  (BRAM_SEL_V_COL ),
    .O_BRAM_SEL_O_LINE (BRAM_SEL_O_LINE),
    .O_BRAM_SEL_O_COL  (BRAM_SEL_O_COL ) 
);

bram_manager u_bram(
    .I_CLK        (I_CLK     ), 
    .I_RST_N      (I_RST_N   ), 
    .I_ENA_Q      (BRAM_Q_ENA),
    .I_ENA_K      (BRAM_K_ENA),
    .I_ENA_V      (BRAM_V_ENA),
    .I_ENA_O      (BRAM_O_ENA),
    .I_WEA_O      (BRAM_O_WEA),
    .I_SEL_Q_LINE (BRAM_SEL_Q_LINE),
    .I_SEL_Q_COL  (BRAM_SEL_Q_COL ),
    .I_SEL_K_LINE (BRAM_SEL_K_LINE),
    .I_SEL_K_COL  (BRAM_SEL_K_COL ),
    .I_SEL_V_LINE (BRAM_SEL_V_LINE),
    .I_SEL_V_COL  (BRAM_SEL_V_COL ),
    .I_SEL_O_LINE (BRAM_SEL_O_LINE),
    .I_SEL_O_COL  (BRAM_SEL_O_COL ),
    .I_MAT        (BRAM_WR_MAT),
    .O_VLD_Q      (BRAM_RD_Q_VLD   ),
    .O_VLD_K      (BRAM_RD_K_VLD   ),
    .O_VLD_V      (BRAM_RD_V_VLD   ),
    .O_VLD_O      (BRAM_RD_O_VLD   ),
    .O_MAT_Q      (BRAM_RD_Q_MAT   ),
    .O_MAT_K      (BRAM_RD_K_MAT   ),
    .O_MAT_V      (BRAM_RD_V_MAT   ),
    .O_MAT_O      (BRAM_RD_O_MAT   ) 
);

SA_wrapper#(
    .D_W        (8         ),
    .SA_R       (16        ),  //SA_ROW,        SA.shape = (SA_R,SA_C)
    .SA_C       (16        )   //SA_COLUMN,     
) u_dut_SA_top(
    .I_CLK          (I_CLK        ),
    .I_RST_N        (I_RST_N      ),
    .I_LOAD_FLAG    (O_SA_LOAD    ),
    .I_X_MATRIX     (O_MAT_1      ),//input x(from left)     
    .I_W_MATRIX     (O_MAT_2      ),//input weight(from ddr)      
    .I_ACCUMULATE_SIGNAL(O_ACC_SIGNAL),
    .O_INPUT_FIFO_EMPTY(),
    .O_OUTPUT_FIFO_FULL(),
    .O_LOAD_WEIGHT_VLD (I_LOAD_W_SIGNAL),
    .O_OUT_VLD      (I_SA_VLD     ),//                              
    .O_OUT          (I_SA_RESULT  ) //OUT.shape = (X_R,64)               
);    
always #5 I_CLK = ~I_CLK;
initial begin
    I_CLK        = 0;
    I_RST_N      = 0;
    I_ATTN_START = 0;
    #100
    I_RST_N      = 1;
    I_ATTN_START = 1;
    //for(int i=0;i<16;i=i+1)begin
    //    for(int i_1=0;i_1<8;i_1=i_1+1)begin
    //        Q_MATRIX[i][i_1*16 +: 16] = '{8'h02,8'h01,8'h02,8'h03,8'h04,8'h05,8'h06,8'h07,8'h08,8'h09,8'h0a,8'h0b,8'h0c,8'h0d,8'h0e,8'h0f};
    //    end
    //end
    //for(int j=0;j<16;j=j+1)begin
    //    for(int j_1=0;j_1<8;j_1=j_1+1)begin
    //        K_MATRIX[j][j_1*16 +: 16] = '{8'h02,8'h01,8'h02,8'h03,8'h04,8'h05,8'h06,8'h07,8'h08,8'h09,8'h0a,8'h0b,8'h0c,8'h0d,8'h0e,8'h0f};
    //    end
    //end
    //for(int k=0;k<16;k=k+1)begin
    //    for(int x=0;x<8;x=x+1)begin
    //        V_MATRIX[k][x*16 +: 16] = '{8'h02,8'h01,8'h02,8'h03,8'h04,8'h05,8'h06,8'h07,8'h08,8'h09,8'h0a,8'h0b,8'h0c,8'h0d,8'h0e,8'h0f};
    //    end
    //end
    #10
    I_ATTN_START = 0;
    wait(O_DATA_VLD)
    #1000
    $finish;
end
endmodule