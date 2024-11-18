`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: lzk
// 
// Create Date: 2024/10/31 10:05:11
// Design Name: 
// Module Name: SA
// Project Name: MHA
// Target Devices: 
// Tool Versions: 
// Description: Systolic Array,5clk update PE.
//              input shift(left to right),output shift(up to down),weight maintain.
//              data 16 bits,for 1 signal bit,2 int bits and 13 fraction bits
//              data format:16'b0_00_00000_0000_0000
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module SA #(
    parameter S   = 64
)
(
input                      I_CLK       ,
input                      I_RST_N     ,
input                      I_START_FLAG,
input                      I_END_FLAG  ,
input      [(S*16)-1:0]    I_X         ,//input x(from left)
input      [(S*16)-1:0]    I_W         ,//input weight(from ddr)
input      [(S*16)-1:0]    I_D         ,//input data(from up)
output                     O_SHIFT     ,//PE shift,O_SHIFT <= 1
output     [(64*16)-1:0]   O_OUT        //output data(down shift),
);
localparam S_IDLE = 0;
localparam S_CAL  = 1;
reg                             state     ;
reg        [2:0]                cycle_cnt ;
reg                             x_vld     ;
reg                             w_vld     ;
reg                             d_vld     ;
wire       [S*64*16-1:0]        data_i_o  ;
wire       [S*64*16-1:0]        x_i_o     ;

assign O_OUT = data_i_o[S*64*16-1:(S-1)*64*16];

always@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        x_vld     <= 0;
        w_vld     <= 0;
        d_vld     <= 0;
        cycle_cnt <= 0;
        state     <= 0;
    end else begin
        case(state)
            S_IDLE:begin
                x_vld     <= 0;
                w_vld     <= 0;
                d_vld     <= 0;
                cycle_cnt <= 0;
                if(I_START_FLAG)begin
                    state <= S_CAL;
                end else begin
                    state <= state;
                end
            end
            S_CAL :begin
                if(I_END_FLAG)begin
                    x_vld     <= 0;
                    w_vld     <= 0;
                    d_vld     <= 0;
                    cycle_cnt <= 0;
                    state <= S_IDLE;
                end else begin
                    state <= state;
                    if(cycle_cnt < 3'd4)begin
                        x_vld     <= 1;
                        w_vld     <= 1;
                        d_vld     <= 1;
                        cycle_cnt <= cycle_cnt + 1;
                    end else begin
                        x_vld     <= 0;
                        w_vld     <= 0;
                        d_vld     <= 0;
                        cycle_cnt <= 3'd0;
                    end
                end  
            end
        endcase
    end
end
                                                        //   SA:                   64
genvar i;                                               //       x|<--------------------------------->|
genvar j;                                               //       |
generate                                                //     S |               S x 64
    for(j=0;j<S;j=j+1)begin                             //       |
        for(i=0;i<64;i=i+1)begin                        //       x
            if(i == 0 & j == 0)begin
                PE u_PE(
                    .I_CLK     (I_CLK  ),
                    .I_RST_N   (I_RST_N),
                    .I_X_VLD   (x_vld),
                    .I_X       (I_X[j*16 +: 16]),//input x(from left)
                    .I_W_VLD   (w_vld),
                    .I_W       (I_W[(j*64+i)*16 +: 16]),//input weight(from ddr)
                    .I_D_VLD   (d_vld),
                    .I_D       (16'b0),//input data(from up)
                    .O_X_VLD   (),
                    .O_X       (x_i_o[j*64*16 +: 16]),//output x(right shift)
                    .O_MUL_DONE(),//multiply done,next clk add,ID_VLD <=0
                    .O_OUT_VLD (),
                    .O_OUT     (data_i_o[(j*64+i)*16 +: 16])//output data(down shift)
                );
            end
            else if(i == 0 & j != 0)begin
                PE u_PE(
                    .I_CLK     (I_CLK  ),
                    .I_RST_N   (I_RST_N),
                    .I_X_VLD   (x_vld),
                    .I_X       (I_X[j*16 +: 16]),//input x(from left)
                    .I_W_VLD   (w_vld),
                    .I_W       (I_W[(j*64+i)*16 +: 16]),//input weight(from ddr)
                    .I_D_VLD   (d_vld),
                    .I_D       (data_i_o[((j-1)*64+i)*16 +: 16]),//input data(from up)
                    .O_X_VLD   (),
                    .O_X       (x_i_o[j*64*16 +: 16]),//output x(right shift)
                    .O_MUL_DONE(),//multiply done,next clk add,ID_VLD <=0
                    .O_OUT_VLD (),
                    .O_OUT     (data_i_o[(j*64+i)*16 +: 16])//output data(down shift)
                );
            end else if(i != 0 & j == 0)begin
                PE u_PE(
                    .I_CLK     (I_CLK  ),
                    .I_RST_N   (I_RST_N),
                    .I_X_VLD   (x_vld),
                    .I_X       (x_i_o[(j*64+(i-1))*16 +: 16]),//input x(from left)
                    .I_W_VLD   (w_vld),
                    .I_W       (I_W[(j*64+i)*16 +: 16]),//input weight(from ddr)
                    .I_D_VLD   (d_vld),
                    .I_D       (16'b0),//input data(from up)
                    .O_X_VLD   (),
                    .O_X       (x_i_o[(j*64+i)*16 +: 16]),//output x(right shift)
                    .O_MUL_DONE(),//multiply done,next clk add,ID_VLD <=0
                    .O_OUT_VLD (),
                    .O_OUT     (data_i_o[(j*64+i)*16 +: 16])//output data(down shift)
                );
            end else begin
                PE u_PE(
                    .I_CLK     (I_CLK  ),
                    .I_RST_N   (I_RST_N),
                    .I_X_VLD   (x_vld),
                    .I_X       (x_i_o[(j*64+(i-1))*16 +: 16]),//input x(from left)
                    .I_W_VLD   (w_vld),
                    .I_W       (I_W[(j*64+i)*16 +: 16]),//input weight(from ddr)
                    .I_D_VLD   (d_vld),
                    .I_D       (data_i_o[((j-1)*64+i)*16 +: 16]),//input data(from up)
                    .O_X_VLD   (),
                    .O_X       (x_i_o[(j*64+i)*16 +: 16]),//output x(right shift)
                    .O_MUL_DONE(),//multiply done,next clk add,ID_VLD <=0
                    .O_OUT_VLD (),
                    .O_OUT     (data_i_o[(j*64+i)*16 +: 16])//output data(down shift)
                );
            end
        end
    end
endgenerate
endmodule
