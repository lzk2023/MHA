`timescale 1ns/1ps
module flash_attn_top(
    input  logic        I_CLK         ,
    input  logic        I_RST_N       ,
    input  logic        I_ATTN_START  ,
    input  logic        I_RD_BRAM_EN  ,
    input  logic [5:0]  I_RD_BRAM_ADDR,
    output logic        O_ATTN_END    ,
    output logic [7:0]  O_BRAM_RD_MAT[0:15][0:127]
);
logic                O_SA_START ;
logic [7:0] O_MAT_1 [0:15][0:127]   ;
logic [7:0] O_MAT_2 [0:127][0:15]   ;
logic [7:0] O_DATA_LOAD [0:15][0:15];
logic [7:0] O_M_DIM ;
logic [7:0] O_ATT_DATA [0:15][0:127];
logic                I_SA_VLD     ;
logic [7:0] I_SA_RESULT [0:15][0:15] ;
logic                I_PE_SHIFT   ;

logic       I_BRAM_RD_VLD ;
logic [7:0] I_BRAM_RD_MAT [0:15][0:127];
logic       I_BRAM_WR_DONE;
logic       O_RD_ENA      ;
logic       O_WR_ENA      ;
logic [7:0] O_BRAM_BLK_SEL;

logic       bram_rd_ena   ;
logic [7:0] bram_rd_addr  ;
assign bram_rd_ena  = O_ATTN_END ? I_RD_BRAM_EN : O_RD_ENA;
assign bram_rd_addr = O_ATTN_END ? {2'b11,I_RD_BRAM_ADDR}:O_BRAM_BLK_SEL;
assign O_BRAM_RD_MAT = I_BRAM_RD_MAT;

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
    .I_PE_SHIFT     (I_PE_SHIFT   ),//connect to SA_wrapper O_PE_SHIFT
    //.I_MAT_Q        (Q_MATRIX     ),
    //.I_MAT_K        (K_MATRIX     ),
    //.I_MAT_V        (V_MATRIX     ),
    .I_SA_VLD       (I_SA_VLD     ),//valid from SA
    .I_SA_RESULT    (I_SA_RESULT  ),//16*16*D_W,from SA
    .O_SA_START     (O_SA_START   ),//to SA_wrapper
    .O_MAT_1        (O_MAT_1      ),//to SA_wrapper
    .O_MAT_2        (O_MAT_2      ),//to SA_wrapper
    .O_DATA_LOAD    (O_DATA_LOAD  ),//to SA_wrapper
    .O_M_DIM        (O_M_DIM      ),//to SA_wrapper
    .O_DATA_VLD     (O_ATTN_END   ),
    .O_ATT_DATA     (O_ATT_DATA   ),
//****************bram ports**************//
    .I_BRAM_RD_VLD  (I_BRAM_RD_VLD ),
    .I_BRAM_RD_MAT  (I_BRAM_RD_MAT ),
    .I_BRAM_WR_DONE (I_BRAM_WR_DONE),
    .O_RD_ENA       (O_RD_ENA      ),//out to bram_manager
    .O_WR_ENA       (O_WR_ENA      ),
    .O_BRAM_BLK_SEL (O_BRAM_BLK_SEL) 
);

bram_manager u_bram_manager(
    .I_CLK         (I_CLK         ), 
    .I_RST_N       (I_RST_N       ), 
    .I_RD_ENA      (bram_rd_ena   ),
    .I_WR_ENA      (O_WR_ENA      ),
    .I_SEL         (bram_rd_addr  ),//sel,addr:{[2:0],[5:0]} high_addr to choose Q,K,V,low_addr to choose line
    .I_MAT         (O_ATT_DATA    ),
    .O_VLD         (I_BRAM_RD_VLD ),
    .O_MAT         (I_BRAM_RD_MAT ),
    .O_WR_DONE     (I_BRAM_WR_DONE)
);

SA_wrapper#(
    .D_W        (8         ),
    .SA_R       (16        ),  //SA_ROW,        SA.shape = (SA_R,SA_C)
    .SA_C       (16        )   //SA_COLUMN,     
) u_dut_SA_top(
    .I_CLK          (I_CLK        ),
    .I_RST_N        (I_RST_N      ),
    .I_START_FLAG   (O_SA_START   ),
    .I_M_DIM        (O_M_DIM      ),//
    .I_X_MATRIX     (O_MAT_1      ),//input x(from left)     
    .I_W_MATRIX     (O_MAT_2      ),//input weight(from ddr)             
    .I_DATA_LOAD    (O_DATA_LOAD  ),
    .O_OUT_VLD      (I_SA_VLD     ),// 
    .O_PE_SHIFT     (I_PE_SHIFT   ),                                  
    .O_OUT          (I_SA_RESULT  ) //OUT.shape = (X_R,64)               
);    
endmodule