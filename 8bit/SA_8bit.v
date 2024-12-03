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
//              data 8 bits,for 1 signal bit,2 int bits and 5 fraction bits
//              data format:8'b0_00_00000
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module SA_8bit #(
    parameter S   = 64
)
(
input                      I_CLK       ,
input                      I_RST_N     ,
input                      I_START_FLAG,
input                      I_END_FLAG  ,
input      [(S*8)-1:0]     I_X         ,//input x(from left)
input      [(S*64*8)-1:0]  I_W         ,//input weight(from ddr)
output     [(64*8)-1:0]    O_OUT        //output data(down shift),
);
localparam S_IDLE = 1'b0;
localparam S_CAL  = 1'b1;
reg                             state     ;

wire [7:0] i_w_matrix      [0:S-1] [0:63];
wire [7:0] data_io_matrix  [0:S-1] [0:63];
wire [7:0] x_io_matrix     [0:S-1] [0:63];

//wire       [S*64*8-1:0]        data_i_o  ;
//wire       [S*64*8-1:0]        x_i_o     ;

generate 
    for(genvar i=0;i<S;i=i+1)begin
        for(genvar j=0;j<64;j=j+1)begin
            assign i_w_matrix[i][j] = I_W[(i*64+j)*8 +: 8];
            //assign data_io_matrix[i][j] = data_i_o[(i*64+j)*8 +: 8];
            //assign x_io_matrix [i][j] = x_i_o[(i*64+j)*8 +: 8];
        end
    end
endgenerate

generate 
    for(genvar j=0;j<64;j=j+1)begin
        assign O_OUT[j*8 +: 8] = data_io_matrix[S-1][j];//data_i_o[S*64*8-1:(S-1)*64*8];
    end
endgenerate

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
                                                        //   SA:                   64(j)
genvar i;                                               //       x|<--------------------------------->|
genvar j;                                               //       |
generate                                                //  S(i) |               S x 64
    for(i=0;i<S;i=i+1)begin                             //       |
        for(j=0;j<64;j=j+1)begin                        //       x
            if(i == 0 & j == 0)begin
                PE_8bit u_PE_8bit(
                    .I_CLK     (I_CLK               ),
                    .I_RST_N   (I_RST_N             ),
                    .I_X       (I_X[0 +: 8]         ),//input x(from left)
                    .I_W       (i_w_matrix[0][0]    ),//input weight(from ddr)
                    .I_D       (8'b0                ),//input data(from up)
                    .O_X       (x_io_matrix[0][0]   ),//output x(right shift)
                    .O_OUT     (data_io_matrix[0][0])//output data(down shift)
                );
            end
            else if(i != 0 & j == 0)begin
                PE_8bit u_PE_8bit(
                    .I_CLK     (I_CLK                  ),
                    .I_RST_N   (I_RST_N                ),
                    .I_X       (I_X[i*8 +: 8]          ),//input x(from left)
                    .I_W       (i_w_matrix[i][0]       ),//input weight(from ddr)
                    .I_D       (data_io_matrix[i-1][0] ),//input data(from up)
                    .O_X       (x_io_matrix[i][0]      ),//output x(right shift)
                    .O_OUT     (data_io_matrix[i][0]   )//output data(down shift)
                );
            end else if(i == 0 & j != 0)begin
                PE_8bit u_PE_8bit(
                    .I_CLK     (I_CLK                  ),
                    .I_RST_N   (I_RST_N                ),
                    .I_X       (x_io_matrix[0][j-1]    ),//input x(from left)
                    .I_W       (i_w_matrix[0][j]       ),//input weight(from ddr)
                    .I_D       (8'b0                   ),//input data(from up)
                    .O_X       (x_io_matrix[0][j]      ),//output x(right shift)
                    .O_OUT     (data_io_matrix[0][j]   )//output data(down shift)
                );
            end else begin
                PE_8bit u_PE_8bit(
                    .I_CLK     (I_CLK                  ),
                    .I_RST_N   (I_RST_N                ),
                    .I_X       (x_io_matrix[i][j-1]    ),//input x(from left)
                    .I_W       (i_w_matrix[i][j]       ),//input weight(from ddr)
                    .I_D       (data_io_matrix[i-1][j] ),//input data(from up)
                    .O_X       (x_io_matrix[i][j]      ),//output x(right shift)
                    .O_OUT     (data_io_matrix[i][j]   )//output data(down shift)
                );
            end
        end
    end
endgenerate
endmodule
