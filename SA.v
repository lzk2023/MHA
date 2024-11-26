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
input      [(S*64*16)-1:0] I_W         ,//input weight(from ddr)
output                     O_SHIFT     ,//PE shift,O_SHIFT <= 1
output     [(64*16)-1:0]   O_OUT        //output data(down shift),
);
localparam S_IDLE = 1'b0;
localparam S_CAL  = 1'b1;
reg                             state     ;
reg                             x_vld     ;
reg                             w_vld     ;
reg                             d_vld     ;

wire [15:0] i_w_matrix      [0:S-1] [0:63];
wire [15:0] data_io_matrix  [0:S-1] [0:63];
wire [15:0] x_io_matrix     [0:S-1] [0:63];

//wire       [S*64*16-1:0]        data_i_o  ;
//wire       [S*64*16-1:0]        x_i_o     ;
wire                            pe00_vld  ;

generate 
    for(genvar i=0;i<S;i=i+1)begin
        for(genvar j=0;j<64;j=j+1)begin
            assign i_w_matrix[i][j] = I_W[(i*64+j)*16 +: 16];
            //assign data_io_matrix[i][j] = data_i_o[(i*64+j)*16 +: 16];
            //assign x_io_matrix [i][j] = x_i_o[(i*64+j)*16 +: 16];
        end
    end
endgenerate

generate 
    for(genvar j=0;j<64;j=j+1)begin
        assign O_OUT[j*16 +: 16] = data_io_matrix[S-1][j];//data_i_o[S*64*16-1:(S-1)*64*16];
    end
endgenerate
assign O_SHIFT = pe00_vld;

always@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        state     <= 0;
    end else begin
        case(state)
            S_IDLE:begin
                if(I_START_FLAG)begin
                    state <= S_CAL;
                end else begin
                    state <= state;
                end
            end
            S_CAL :begin
                if(I_END_FLAG)begin
                    state <= S_IDLE;
                end else begin
                    state <= state;
                end  
            end
        endcase
    end
end

always@(*)begin
    if(state == S_CAL)begin
        if(!pe00_vld)begin
            x_vld = 1;
            w_vld = 1;
            d_vld = 1;
        end else begin
            x_vld = 0;
            w_vld = 0;
            d_vld = 0;
        end
    end else begin
        x_vld = 0;
        w_vld = 0;
        d_vld = 0;
    end
end
                                                        //   SA:                   64(j)
genvar i;                                               //       x|<--------------------------------->|
genvar j;                                               //       |
generate                                                //  S(i) |               S x 64
    for(i=0;i<S;i=i+1)begin                             //       |
        for(j=0;j<64;j=j+1)begin                        //       x
            if(i == 0 & j == 0)begin
                PE u_PE(
                    .I_CLK     (I_CLK  ),
                    .I_RST_N   (I_RST_N),
                    .I_X_VLD   (x_vld),
                    .I_X       (I_X[0 +: 16]),//input x(from left)
                    .I_W_VLD   (w_vld),
                    .I_W       (i_w_matrix[0][0]),//input weight(from ddr)
                    .I_D_VLD   (d_vld),
                    .I_D       (16'b0),//input data(from up)
                    .O_X_VLD   (),
                    .O_X       (x_io_matrix[0][0]),//output x(right shift)
                    .O_MUL_DONE(),//multiply done,next clk add,ID_VLD <=0
                    .O_OUT_VLD (pe00_vld),
                    .O_OUT     (data_io_matrix[0][0])//output data(down shift)
                );
            end
            else if(i != 0 & j == 0)begin
                PE u_PE(
                    .I_CLK     (I_CLK  ),
                    .I_RST_N   (I_RST_N),
                    .I_X_VLD   (x_vld),
                    .I_X       (I_X[i*16 +: 16]),//input x(from left)
                    .I_W_VLD   (w_vld),
                    .I_W       (i_w_matrix[i][0]),//input weight(from ddr)
                    .I_D_VLD   (d_vld),
                    .I_D       (data_io_matrix[i-1][0]),//input data(from up)
                    .O_X_VLD   (),
                    .O_X       (x_io_matrix[i][0]),//output x(right shift)
                    .O_MUL_DONE(),//multiply done,next clk add,ID_VLD <=0
                    .O_OUT_VLD (),
                    .O_OUT     (data_io_matrix[i][0])//output data(down shift)
                );
            end else if(i == 0 & j != 0)begin
                PE u_PE(
                    .I_CLK     (I_CLK  ),
                    .I_RST_N   (I_RST_N),
                    .I_X_VLD   (x_vld),
                    .I_X       (x_io_matrix[0][j-1]),//input x(from left)
                    .I_W_VLD   (w_vld),
                    .I_W       (i_w_matrix[0][j]),//input weight(from ddr)
                    .I_D_VLD   (d_vld),
                    .I_D       (16'b0),//input data(from up)
                    .O_X_VLD   (),
                    .O_X       (x_io_matrix[0][j]),//output x(right shift)
                    .O_MUL_DONE(),//multiply done,next clk add,ID_VLD <=0
                    .O_OUT_VLD (),
                    .O_OUT     (data_io_matrix[0][j])//output data(down shift)
                );
            end else begin
                PE u_PE(
                    .I_CLK     (I_CLK  ),
                    .I_RST_N   (I_RST_N),
                    .I_X_VLD   (x_vld),
                    .I_X       (x_io_matrix[0][j-1]),//input x(from left)
                    .I_W_VLD   (w_vld),
                    .I_W       (i_w_matrix[i][j]),//input weight(from ddr)
                    .I_D_VLD   (d_vld),
                    .I_D       (data_io_matrix[i-1][j]),//input data(from up)
                    .O_X_VLD   (),
                    .O_X       (x_i_o[(i*64+j)*16 +: 16]),//output x(right shift)
                    .O_MUL_DONE(),//multiply done,next clk add,ID_VLD <=0
                    .O_OUT_VLD (),
                    .O_OUT     (data_io_matrix[i][j])//output data(down shift)
                );
            end
        end
    end
endgenerate
endmodule
