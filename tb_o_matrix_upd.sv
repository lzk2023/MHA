`timescale 1ns/1ps
module tb_o_matrix_upd();
localparam D_W = 8;
localparam TIL = 16;
bit I_CLK   ;
bit I_RST_N ;
bit I_VLD   ;
bit [D_W*2-1:0] I_LI_OLD [0:TIL-1];
bit [D_W-1:0]   I_MI_OLD [0:TIL-1];
bit [D_W*2-1:0] I_LI_NEW [0:TIL-1];
bit [D_W-1:0]   I_MI_NEW [0:TIL-1];
logic O_VLD        ;
logic [D_W-1:0] O_COEFFICIENT [0:TIL-1];

always#5 I_CLK = ~I_CLK;
o_matrix_upd#(
    .D_W(D_W),
    .TIL(TIL) //tiling row == 16
)u_o_matrix_upd(
    .I_CLK        (I_CLK        ),
    .I_RST_N      (I_RST_N      ),
    .I_VLD        (I_VLD        ),//keep
    .I_LI_OLD     (I_LI_OLD     ),
    .I_MI_OLD     (I_MI_OLD     ),
    .I_LI_NEW     (I_LI_NEW     ),
    .I_MI_NEW     (I_MI_NEW     ),
    .O_VLD        (O_VLD        ),
    .O_COEFFICIENT(O_COEFFICIENT)
);

initial begin
    I_LI_OLD = '{16{16'b0_000_0011_0000_0000}};//3
    I_MI_OLD = '{16{8'b0_01_01010}};//1.3125
    I_LI_NEW = '{16{16'b0_000_0100_0000_0000}};//4
    I_MI_NEW = '{16{8'b0_01_11000}};//1.75
    #100
    I_RST_N = 1;
    I_VLD   = 1;
    wait(O_VLD)
    @(posedge I_CLK)
    I_VLD = 0;
    #200
    I_LI_OLD = '{16{16'b0_000_0011_0000_0000}};//3
    I_MI_OLD = '{16{8'b0_01_11000}};//1.75
    I_LI_NEW = '{16{16'b0_000_0100_0000_0000}};//4
    I_MI_NEW = '{16{8'b0_01_01010}};//1.3125
    I_VLD = 1;
    wait(O_VLD)
    @(posedge I_CLK)
    I_VLD = 0;
    #200
    $finish;
end
endmodule