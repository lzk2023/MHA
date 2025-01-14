`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: lzk
// 
// Create Date: 2024/10/31 10:05:11
// Design Name: 
// Module Name: SA_wrapper
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

module SA_wrapper#(
    parameter D_W = 8,  //Data_Width
    parameter S   = 64,  //W_ROW,     W.shape = (S,64)
    parameter X_R = 64   //X_ROW,     X.shape = (X_R,S)
) (
    input                        I_CLK       ,
    input                        I_RST_N     ,
    input                        I_START_FLAG,//                                               X_R    
    input   [(S*X_R*D_W)-1:0]    I_X         ,//input x(from left)     matrix x:     x|<------------------>|
    input   [(S*64*D_W)-1:0]     I_W         ,//input weight(from ddr)               |
    output                       O_OUT_VLD   ,//                                   S |
    //output  [(X_R*64*D_W)-1:0]    O_OUT        //OUT.shape = (X_R,64)                 |
    output  [64*D_W-1:0]         O_OUT
);                                            //                                     x
localparam X_SEL_W = $clog2(S+X_R-1+64);

wire                             pe_shift    ;
wire        [(S*D_W)-1:0]         sa_x_in     ;
wire        [(64*D_W)-1:0]        sa_out      ;

wire [D_W-1:0] x_matrix   [0:X_R-1] [0:S-1]    ;
wire [D_W-1:0] x_t_matrix [0:S-1] [0:X_R-1]    ;
wire [D_W-1:0] x_r_matrix [0:S-1] [0:X_R-1]    ;
wire [D_W-1:0] x_in_matrix [0:S-1] [0:S+X_R-2] ;
reg [X_SEL_W-1:0] x_sel   ;
reg               end_flag;

assign O_OUT = sa_out;
generate
    for(genvar i=0;i<X_R;i=i+1)begin
        for(genvar j=0;j<S;j=j+1)begin
            assign x_matrix[i][j] = I_X[(i*S+j)*D_W +: D_W];
            assign x_t_matrix[j][i] = x_matrix[i][j];
            assign x_r_matrix[j][i] = x_t_matrix[j][X_R-1-i];
        end
    end
endgenerate


genvar i;
genvar j;
generate
    for(i=0;i<S;i=i+1)begin
        for(j=0;j<S+X_R-1;j=j+1)begin
            if(j>=S-1-i & j<S-1-i+X_R)begin
                assign x_in_matrix[i][j] = x_r_matrix[i][j-(S-1-i)];
            end else begin
                assign x_in_matrix[i][j] = 0;
            end
        end
    end
endgenerate

genvar k;
generate
    for(k=0;k<S;k=k+1)begin
        assign sa_x_in[k*D_W+:D_W] = (x_sel < S+X_R-1) ? x_in_matrix[k] [S+X_R-2-x_sel] : {D_W{1'b0}};
    end
endgenerate
always@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        x_sel <= 0;
        end_flag <= 0;
    end else if(I_START_FLAG)begin
        x_sel <= 0;
        end_flag <= 0;
    end else if(pe_shift)begin
        if(x_sel < S+X_R-1+64)begin
            x_sel <= x_sel + 1;
            end_flag <= 0;
        end else begin
            x_sel <= x_sel;
            end_flag <= 1;
        end
    end else begin
        x_sel <= x_sel;
        end_flag <= 0;
    end
end
SA #(
    .D_W         (D_W         ),
    .S           (S           )
) u_SA (
    .I_CLK       (I_CLK       ),
    .I_RST_N     (I_RST_N     ),
    .I_START_FLAG(I_START_FLAG),
    .I_END_FLAG  (end_flag    ),
    .I_X         (sa_x_in     ),//input x(from left)
    .I_W         (I_W         ),//input weight(from ddr)
    .O_SHIFT     (pe_shift    ),//PE shift,O_SHIFT <= 1
    .O_OUT       (sa_out      ) //output data(down shift),
);
endmodule