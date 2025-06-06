`timescale 1ns/1ps
module flash_attn_top(
    input  logic          I_CLK         ,
    input  logic          I_RST_N       ,
    //input  logic          I_ATTN_START  ,
    input  logic          I_RD_BRAM_EN  ,
    input  logic [5:0]    I_RD_BRAM_LINE,
    input  logic [2:0]    I_RD_BRAM_COL ,
    output logic          O_ATTN_END    ,
    output logic          O_BRAM_RD_VLD ,
    output logic [4095:0] O_BRAM_RD_MAT  
);
logic                SA_LOAD ;
logic [15:0] O_MAT_1 [0:15][0:15]   ;
logic [15:0] O_MAT_2 [0:15][0:15]   ;
logic [15:0] O_ATTN_DATA [0:15][0:127];
logic       ACCUMULATE_SIGNAL      ;
logic       LOAD_W_SIGNAL          ;
logic                I_SA_VLD     ;
logic [15:0] I_SA_RESULT [0:15][0:15] ;

logic       BRAM_RD_Q_VLD;
logic       BRAM_RD_K_VLD;
logic       BRAM_RD_V_VLD;
logic       BRAM_RD_O_VLD;
logic [15:0] BRAM_RD_Q_MAT [0:15][0:15];
logic [15:0] BRAM_RD_K_MAT [0:15][0:15];
logic [15:0] BRAM_RD_V_MAT [0:15][0:15];
logic [15:0] BRAM_RD_O_MAT [0:15][0:15];

logic       BRAM_Q_ENA  ;
logic       BRAM_K_ENA  ;
logic       BRAM_V_ENA  ;
logic       BRAM_O_ENA  ;
logic       BRAM_O_WEA  ;
logic [15:0] BRAM_WR_MAT [0:15][0:15];
logic [5:0] BRAM_SEL_Q_LINE;
logic [2:0] BRAM_SEL_Q_COL ;
logic [5:0] BRAM_SEL_K_LINE;
logic [2:0] BRAM_SEL_K_COL ;
logic [5:0] BRAM_SEL_V_LINE;
logic [2:0] BRAM_SEL_V_COL ;
logic [5:0] BRAM_SEL_O_LINE;
logic [2:0] BRAM_SEL_O_COL ;

logic        bram_rd_ena   ;
logic [5:0]  bram_rd_line  ;
logic [2:0]  bram_rd_col   ;
assign bram_rd_ena  = O_ATTN_END ? I_RD_BRAM_EN : BRAM_O_ENA;
assign bram_rd_line = O_ATTN_END ? I_RD_BRAM_LINE:BRAM_SEL_O_LINE;
assign bram_rd_col  = O_ATTN_END ? I_RD_BRAM_COL : BRAM_SEL_O_COL;
assign O_BRAM_RD_VLD = BRAM_RD_O_VLD & O_ATTN_END;
generate
    for(genvar i=0;i<16;i=i+1)begin
        for(genvar j=0;j<16;j=j+1)begin
            assign O_BRAM_RD_MAT[((15-i)*16+(15-j))*16 +: 16] = BRAM_RD_O_MAT[i][j];
        end
    end
endgenerate
attention#(
    .D_W   (16),
    .SA_R  (16),
    .SA_C  (16),
    .DIM   (16),       //sequence length
    .D_K   (128)        //Q,K,V column num（dimention/h_num)
)u_dut_attention(
    .I_CLK          (I_CLK        ),
    .I_RST_N        (I_RST_N      ),
    .I_ATTN_START   (1'b1         ),
    .I_SA_VLD       (I_SA_VLD     ),//valid from SA
    .I_SA_RESULT    (I_SA_RESULT  ),//16*16*D_W,from SA
    .I_LOAD_W_SIGNAL(LOAD_W_SIGNAL),
    .O_SA_LOAD      (SA_LOAD      ),//to SA_wrapper
    .O_MAT_1        (O_MAT_1      ),//to SA_wrapper
    .O_MAT_2        (O_MAT_2      ),//to SA_wrapper
    .O_ACC_SIGNAL   (ACCUMULATE_SIGNAL),
    .O_DATA_VLD     (O_ATTN_END   ),
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

bram_manager u_bram_manager(
    .I_CLK        (I_CLK     ), 
    .I_RST_N      (I_RST_N   ), 
    .I_ENA_Q      (BRAM_Q_ENA),
    .I_ENA_K      (BRAM_K_ENA),
    .I_ENA_V      (BRAM_V_ENA),
    .I_ENA_O      (bram_rd_ena),//
    .I_WEA_O      (BRAM_O_WEA),
    .I_SEL_Q_LINE (BRAM_SEL_Q_LINE),
    .I_SEL_Q_COL  (BRAM_SEL_Q_COL ),
    .I_SEL_K_LINE (BRAM_SEL_K_LINE),
    .I_SEL_K_COL  (BRAM_SEL_K_COL ),
    .I_SEL_V_LINE (BRAM_SEL_V_LINE),
    .I_SEL_V_COL  (BRAM_SEL_V_COL ),
    .I_SEL_O_LINE (bram_rd_line),
    .I_SEL_O_COL  (bram_rd_col ),
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
    .D_W        (16        ),
    .SA_R       (16        ),  //SA_ROW,        SA.shape = (SA_R,SA_C)
    .SA_C       (16        )   //SA_COLUMN,     
) u_dut_SA_top(
    .I_CLK              (I_CLK        ),
    .I_RST_N            (I_RST_N      ),
    .I_LOAD_FLAG        (SA_LOAD      ),
    .I_X_MATRIX         (O_MAT_1      ),//input x(from left)     
    .I_W_MATRIX         (O_MAT_2      ),//input weight(from ddr)
    .I_ACCUMULATE_SIGNAL(ACCUMULATE_SIGNAL),
    .O_INPUT_FIFO_EMPTY (),
    .O_OUTPUT_FIFO_FULL (),
    .O_LOAD_WEIGHT_VLD  (LOAD_W_SIGNAL),
    .O_OUT_VLD          (I_SA_VLD     ),//                             
    .O_OUT              (I_SA_RESULT  ) //OUT.shape = (X_R,64)               
);    
endmodule