`timescale 1ns/1ps
module tb_SA_input_fifo();

bit        I_CLK            ;
bit        I_RST_N          ;
bit        I_LOAD_EN        ;
bit   [7:0]I_LOAD_DATA[0:15];
logic [7:0]O_DATA           ;
logic      O_LOAD_EN        ;
logic      O_EMPTY          ;
SA_input_fifo#(
    .DATA_WIDTH(8 ),
    .FIFO_DEPTH(16)
)u_SA_input_fifo(
    .I_CLK      (I_CLK      ),
    .I_RST_N    (I_RST_N    ),
    .I_LOAD_EN  (I_LOAD_EN  ),
    .I_LOAD_DATA(I_LOAD_DATA),
    .O_DATA     (O_DATA     ),
    .O_LOAD_EN  (O_LOAD_EN  ),
    .O_EMPTY    (O_EMPTY    )
);
always #5 I_CLK = ~I_CLK;
initial begin
    #100
    I_RST_N = 1;
    #100
    I_LOAD_EN = 1;
    I_LOAD_DATA = '{8'hAA,8'h01,8'h02,8'h03,8'h04,8'h05,8'h06,8'h07,8'h08,8'h09,8'h0A,8'h0B,8'h0C,8'h0D,8'h0E,8'h0F};
    #10
    I_LOAD_EN = 0;
    #200
    I_LOAD_EN = 1;
    I_LOAD_DATA = '{8'hBB,8'h11,8'h22,8'h33,8'h44,8'h55,8'h66,8'h77,8'h88,8'h99,8'hAA,8'hBB,8'hCC,8'hDD,8'hEE,8'hFF};
    #10
    I_LOAD_EN = 0;
    #500
    $finish;
end
endmodule