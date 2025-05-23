`timescale 1ns/1ps

module tb_SA_output_fifo();
bit         I_CLK            ;
bit         I_RST_N          ;
bit         I_PUSH_EN        ;
bit   [7:0] I_PUSH_DATA      ;
logic [7:0] O_ALL_DATA [0:15];
logic [7:0] O_POP_DATA       ;
logic       O_PUSH_EN        ;
logic       O_FULL           ;
integer i;
SA_output_fifo#(
    .DATA_WIDTH(8 ),
    .FIFO_DEPTH(16)
)u_SA_output_fifo(
    .I_CLK      (I_CLK      ),
    .I_RST_N    (I_RST_N    ),
    .I_PUSH_EN  (I_PUSH_EN  ),
    .I_PUSH_DATA(I_PUSH_DATA),
    .O_ALL_DATA (O_ALL_DATA ),
    .O_POP_DATA (O_POP_DATA ),
    .O_PUSH_EN  (O_PUSH_EN  ),
    .O_FULL     (O_FULL     )
);
always #5 I_CLK = ~I_CLK;
initial begin
    #100
    I_RST_N = 1;
    #500
    I_PUSH_EN = 1;
    I_PUSH_DATA = 8'h0F;
    for(i=0;i<15;i=i+1)begin
        @(posedge I_CLK)
        I_PUSH_EN <= 0;
        I_PUSH_DATA <= I_PUSH_DATA - 1;
    end
    @(O_FULL)
    @(posedge I_CLK)
    I_PUSH_EN <= 1;
    I_PUSH_DATA <= 8'h10;
    for(i=0;i<15;i=i+1)begin
        @(posedge I_CLK)
        I_PUSH_EN <= 0;
        I_PUSH_DATA <= I_PUSH_DATA - 1;
    end
end
//initial begin
//    while(1)begin
//        @(O_FULL)
//        I_PUSH_EN = 1;
//        #10
//        I_PUSH_EN = 0;
//    end
//end
initial begin
    #2000
    $finish;
end
endmodule