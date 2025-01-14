`timescale 1ns / 1ps
module softmax#(
    parameter DIM = 4 ,   //dimention
    parameter D_W = 16
)(
    input                I_CLK  ,
    input                I_RST_N,
    input  [DIM*D_W-1:0] I_DATA ,
    output [DIM*D_W-1:0] O_DATA 
    );
    localparam DATA_SUM_WIDTH = $clog2(4*DIM);
    wire [DATA_SUM_WIDTH-1:0] data_sum = $signed();
endmodule