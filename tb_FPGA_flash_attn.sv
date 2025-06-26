`timescale 1ns/1ps
module tb_FPGA_flash_attn();
bit   I_CLK         ;
bit   I_RST_N       ;
logic O_ATTN_END    ;
logic O_CNT_1bit    ;
logic O_BRAM_RD_1bit;

FPGA_flash_attn dut_FPGA_top(
    .I_CLK         (I_CLK         ),
    .I_RST_N       (I_RST_N       ),
    .O_ATTN_END    (O_ATTN_END    ),
    .O_CNT_1bit    (O_CNT_1bit    ),
    .O_BRAM_RD_1bit(O_BRAM_RD_1bit)
);
always #5 I_CLK = ~I_CLK;
initial begin
    #100
    I_RST_N = 1'b1;
    wait(O_ATTN_END)
    #50000
    $finish;    
end
endmodule