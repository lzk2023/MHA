`timescale 1ns/1ps
module FPGA_flash_attn(
    input  logic I_CLK  ,
    input  logic I_RST_N,
    output logic O_ATTN_END,
    output logic O_BRAM_RD_1bit
);
logic          RD_BRAM_EN  ;
logic [5:0]    RD_BRAM_LINE;
logic [2:0]    RD_BRAM_COL ;
logic          BRAM_RD_VLD ;
logic [4095:0] BRAM_RD_MAT ;
logic [11:0]   cnt;
logic [27:0]   cnt_for_sec ;

flash_attn_top u_flash_attn(
    .I_CLK         (I_CLK         ),
    .I_RST_N       (I_RST_N       ),
//    .I_ATTN_START  (I_ATTN_START  ),
    .I_RD_BRAM_EN  (RD_BRAM_EN  ),
    .I_RD_BRAM_LINE(RD_BRAM_LINE),
    .I_RD_BRAM_COL (RD_BRAM_COL ),
    .O_ATTN_END    (O_ATTN_END  ),
    .O_BRAM_RD_VLD (BRAM_RD_VLD ),
    .O_BRAM_RD_MAT (BRAM_RD_MAT )
);
always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        RD_BRAM_EN   <= 'b0;
        RD_BRAM_LINE <= 'b0;
        RD_BRAM_COL  <= 'b0;
        cnt          <= 'b0;
        cnt_for_sec  <= 'b0;
    end else if(O_ATTN_END)begin
        cnt_for_sec <= cnt_for_sec + 1;
        if(cnt_for_sec == 28'hffff_fff)begin
            cnt <= cnt + 1;
        end
        if(BRAM_RD_VLD)begin
            RD_BRAM_EN   <= 'b0;
            RD_BRAM_LINE <= RD_BRAM_LINE;
            RD_BRAM_COL  <= RD_BRAM_COL;
        end else if(cnt == 12'd4095)begin
            if(RD_BRAM_COL == 3'd7)begin
                if(RD_BRAM_LINE == 6'd63)begin
                    RD_BRAM_EN   <= 'b1;
                    RD_BRAM_LINE <= RD_BRAM_LINE + 1;
                    RD_BRAM_COL  <= RD_BRAM_COL + 1;
                end else begin
                    RD_BRAM_EN   <= 'b1;
                    RD_BRAM_LINE <= RD_BRAM_LINE + 1;
                    RD_BRAM_COL  <= RD_BRAM_COL + 1;
                end
            end else begin
                RD_BRAM_EN   <= 'b1;
                RD_BRAM_LINE <= RD_BRAM_LINE;
                RD_BRAM_COL  <= RD_BRAM_COL + 1;
            end
        end else begin
            RD_BRAM_EN   <= 'b1;
            RD_BRAM_LINE <= RD_BRAM_LINE;
            RD_BRAM_COL  <= RD_BRAM_COL;
        end
    end else begin
        RD_BRAM_EN   <= RD_BRAM_EN   ;
        RD_BRAM_LINE <= RD_BRAM_LINE ;
        RD_BRAM_COL  <= RD_BRAM_COL  ;
    end
end
assign O_BRAM_RD_1bit = O_ATTN_END ? BRAM_RD_MAT[cnt]: 1'b0;
endmodule