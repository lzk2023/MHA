`timescale 1ns/1ps
module tb_bram_mi_li_manager();

bit             I_CLK                ;
bit             I_RST_N              ;
bit             I_RD_ENA             ;
bit             I_WR_ENA             ;
bit   [5:0]     I_ADDR               ;
bit   [15:0] I_WR_MI_VEC[0:15];
bit   [15:0] I_WR_LI_VEC[0:15];
logic           O_BUSY               ;
logic           O_VLD                ;
logic [15:0] O_RD_MI_VEC[0:15];
logic [15:0] O_RD_LI_VEC[0:15];

bram_mi_li_manager#(
    .D_W (16),
    .SA_R(16),
    .SA_C(16)
)u_dut_bram_mi_li_manager(
    .I_CLK      (I_CLK      ),
    .I_RST_N    (I_RST_N    ),
    .I_RD_ENA   (I_RD_ENA   ),
    .I_WR_ENA   (I_WR_ENA   ),
    .I_ADDR     (I_ADDR     ),
    .I_WR_MI_VEC(I_WR_MI_VEC),
    .I_WR_LI_VEC(I_WR_LI_VEC),
    .O_BUSY     (O_BUSY     ),
    .O_VLD      (O_VLD      ),
    .O_RD_MI_VEC(O_RD_MI_VEC),
    .O_RD_LI_VEC(O_RD_LI_VEC)
);
always #5 I_CLK = ~I_CLK;
initial begin
    #100
    I_RST_N = 1;
    @(posedge I_CLK)
    I_WR_ENA    <= 1;
    I_ADDR      <= 6'd30;
    I_WR_MI_VEC <= 
    {
        16'h0000,
        16'h0001,
        16'h0002,
        16'h0003,
        16'h0004,
        16'h0005,
        16'h0006,
        16'h0007,
        16'h0008,
        16'h0009,
        16'h000a,
        16'h000b,
        16'h000c,
        16'h000d,
        16'h000e,
        16'h000f
    };
    I_WR_LI_VEC <= 
    {
        16'h0000,
        16'h0001,
        16'h0002,
        16'h0003,
        16'h0004,
        16'h0005,
        16'h0006,
        16'h0007,
        16'h0008,
        16'h0009,
        16'h000a,
        16'h000b,
        16'h000c,
        16'h000d,
        16'h000e,
        16'h000f
    };
    @(posedge I_CLK)
    I_WR_ENA    <= 0;

    @(posedge I_CLK)
    I_WR_ENA    <= 1;
    I_ADDR      <= 6'd31;
    I_WR_MI_VEC <= 
    {
        16'h0000,
        16'h0011,
        16'h0022,
        16'h0033,
        16'h0044,
        16'h0055,
        16'h0066,
        16'h0077,
        16'h0088,
        16'h0099,
        16'h00aa,
        16'h00bb,
        16'h00cc,
        16'h00dd,
        16'h00ee,
        16'h00ff
    };
    I_WR_LI_VEC <= 
    {
        16'h0000,
        16'h0101,
        16'h0202,
        16'h0303,
        16'h0404,
        16'h0505,
        16'h0606,
        16'h0707,
        16'h0808,
        16'h0909,
        16'h0a0a,
        16'h0b0b,
        16'h0c0c,
        16'h0d0d,
        16'h0e0e,
        16'h0f0f
    };
    @(posedge I_CLK)
    I_WR_ENA    <= 0;

    @(posedge I_CLK)
    I_RD_ENA    <= 1;
    I_ADDR      <= 6'd30;
    @(posedge I_CLK)
    I_RD_ENA    <= 0;
    wait(O_VLD)
    @(posedge I_CLK)
    I_RD_ENA    <= 1;
    I_ADDR      <= 6'd31;
    @(posedge I_CLK)
    I_RD_ENA    <= 0;
end
endmodule