`timescale 1ns/1ps
import Utils::*;
module tb_flash_attn_top();

bit       I_CLK         ;
bit       I_RST_N       ;
bit       I_ATTN_START  ;
bit       I_RD_BRAM_EN  ;
bit [5:0] I_RD_BRAM_LINE;
bit [2:0] I_RD_BRAM_COL ;

logic          O_ATTN_END   ;
logic          O_BRAM_RD_VLD;
logic [2047:0] O_BRAM_RD_MAT;

logic [7:0] data_matrix_compare [0:15][0:15];
logic       data_compare_vld;

integer save_file;

flash_attn_top dut_flash_attn(
    .I_CLK         (I_CLK         ),
    .I_RST_N       (I_RST_N       ),
    .I_ATTN_START  (I_ATTN_START  ),
    .I_RD_BRAM_EN  (I_RD_BRAM_EN  ),
    .I_RD_BRAM_LINE(I_RD_BRAM_LINE),
    .I_RD_BRAM_COL (I_RD_BRAM_COL ),
    .O_ATTN_END    (O_ATTN_END    ),
    .O_BRAM_RD_VLD (O_BRAM_RD_VLD ),
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
    #100
    for(int i=0;i<64;i=i+1)begin
        for(int j=0;j<8;j=j+1)begin
            @(posedge I_CLK)
            I_RD_BRAM_EN   <= 1'b1;
            I_RD_BRAM_LINE <= i;
            I_RD_BRAM_COL  <= j;
            wait(O_BRAM_RD_VLD)
            @(posedge I_CLK)
            I_RD_BRAM_EN   <= 1'b0;
        end
    end
    #1000
    $finish;
end

initial begin
    while(1)begin
        if(dut_flash_attn.SA_LOAD)begin
            @(posedge dut_flash_attn.I_CLK)
            mul_matrix_16_16(dut_flash_attn.O_MAT_1,dut_flash_attn.O_MAT_2,data_matrix_compare);
            data_compare_vld = 1;
        end else begin
            @(posedge dut_flash_attn.I_CLK)
            data_compare_vld = 0;
        end
    end
end

initial begin
    save_file = $fopen("H:/flash_attn_output_files/output_mat.txt");
    if(save_file == 0)begin 
        $display ("can not open the file!");    //如果创建文件失败，则会显示"can not open the file!"信息。
        $stop;
    end
end
always@(posedge I_CLK)begin
    if(O_ATTN_END)begin
        if(O_BRAM_RD_VLD)begin
            $fdisplay(save_file,"%b",O_BRAM_RD_MAT);
        end
    end
end
endmodule