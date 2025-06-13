`timescale 1ns/1ps
module flash_attn_pipeline_top(
    input  logic          I_CLK         ,
    input  logic          I_RST_N       ,
    input  logic          I_RD_BRAM_EN  ,
    input  logic [5:0]    I_RD_BRAM_LINE,
    input  logic [2:0]    I_RD_BRAM_COL ,
    output logic          O_ATTN_END    ,
    output logic          O_BRAM_RD_VLD ,
    output logic [4095:0] O_BRAM_RD_MAT  
);
pipeline_q_k#(
    .D_W (16),
    .SA_R(16),
    .SA_C(16)
)u_pipeline_q_k(
    .I_CLK     (I_CLK    ),
    .I_RST_N   (I_RST_N  ),
    .I_ENA     (I_ENA    ),//when !O_VLD & !O_BUSY
    .I_SEL_Q_O (),
    .I_SEL_K_V (),
    .I_RDY     (),//from next pipeline
    .O_BUSY    (),
    .O_VLD     (),
    .O_MAT_Q_K (),
    .O_SEL_Q_O (),
    .O_SEL_K_V (),
    
    //*************bram_manager ports************//
    .I_BRAM_RD_Q_VLD   (),
    .I_BRAM_RD_K_VLD   (),
    .I_BRAM_RD_Q_MAT   (),
    .I_BRAM_RD_K_MAT   (),
    .O_BRAM_Q_ENA      (),//out to bram_manager
    .O_BRAM_K_ENA      (),//out to bram_manager
    .O_BRAM_SEL_Q_LINE (),
    .O_BRAM_SEL_Q_COL  (),
    .O_BRAM_SEL_K_LINE (),
    .O_BRAM_SEL_K_COL  ()
);
endmodule