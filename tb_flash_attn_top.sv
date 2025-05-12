`timescale 1ns/1ps
module tb_flash_attn_top();

bit       I_CLK         ;
bit       I_RST_N       ;
bit       I_ATTN_START  ;
bit       I_RD_BRAM_EN  ;
bit [5:0] I_RD_BRAM_LINE;
bit [2:0] I_RD_BRAM_COL ;

logic       O_ATTN_END   ;
logic [7:0] O_BRAM_RD_MAT[0:15][0:15];

flash_attn_top dut_flash_attn(
    .I_CLK         (I_CLK         ),
    .I_RST_N       (I_RST_N       ),
    .I_ATTN_START  (I_ATTN_START  ),
    .I_RD_BRAM_EN  (I_RD_BRAM_EN  ),
    .I_RD_BRAM_LINE(I_RD_BRAM_LINE),
    .I_RD_BRAM_COL (I_RD_BRAM_COL ),
    .O_ATTN_END    (O_ATTN_END    ),
    .O_BRAM_RD_MAT (O_BRAM_RD_MAT )
);

always#5 I_CLK = ~ I_CLK;

initial begin
    #100
    I_RST_N = 1;
    #100
    I_ATTN_START = 1;
    #10000
    I_ATTN_START = 0;

    wait(O_ATTN_END);
    #1000
    $finish;
end
endmodule