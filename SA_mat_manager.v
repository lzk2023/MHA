`timescale 1ns/1ps
///////////////////////////////////////////////////////////////////
//Input the two input matrices into the systolic array in the correct input format.
//将两个输入矩阵以正确的输入形式输入到脉动阵列中
///////////////////////////////////////////////////////////////////
`include "defines.v"
module SA_mat_manager#(
    parameter D_W   = 16,
    parameter X_R   = 16,
    parameter M_DIM = 16,//X_C == W_R == M_DIM,dimention of the 2 multiply matrix.
    parameter W_C   = 16
)(
    input                      I_CLK      ,
    input                      I_ASYN_RSTN,
    input                      I_SYNC_RSTN,
    input                      I_PE_SHIFT ,
    input                      I_START    ,
    input  [X_R*M_DIM*D_W-1:0] I_X_MATRIX ,
    input  [M_DIM*W_C*D_W-1:0] I_W_MATRIX ,
    output                     O_OVER     ,
    output [X_R*D_W-1:0]       O_X_VECTOR ,
    output [W_C*D_W-1:0]       O_W_VECTOR 
);
localparam S_IDLE  = 2'b01;
localparam S_COUNT = 2'b10;
reg  [15:0] sel  ;
reg  [2:0]  state;
///////////////////////////input matrix assign/////////////////////////
wire [D_W-1:0] x_matrix [0:X_R-1][0:M_DIM-1];
wire [D_W-1:0] w_matrix [0:M_DIM-1][0:W_C-1];
`VARIABLE_TO_MATRIX(D_W,X_R,M_DIM,I_X_MATRIX,x_matrix)
`VARIABLE_TO_MATRIX(D_W,M_DIM,W_C,I_W_MATRIX,w_matrix)
///////////////////////////select matrix out/////////////////////////
generate 
    for(genvar i=0;i<X_R;i=i+1)begin
        assign O_X_VECTOR[i*D_W +: D_W] = (sel == M_DIM) ? 0 : x_matrix[i][M_DIM-1-sel];
    end
endgenerate

generate 
    for(genvar i=0;i<W_C;i=i+1)begin
        assign O_W_VECTOR[i*D_W +: D_W] = (sel == M_DIM) ? 0 : w_matrix[M_DIM-1-sel][i];
    end
endgenerate

always@(posedge I_CLK or negedge I_ASYN_RSTN)begin
    if(!I_ASYN_RSTN | !I_SYNC_RSTN)begin
        sel   <= 0;
        state <= S_IDLE;
    end else begin
        case(state)
            S_IDLE :begin
                if(I_START)begin
                    sel   <= 0;
                    state <= S_COUNT;
                end else begin
                    sel   <= sel;
                    state <= state;
                end
            end
            S_COUNT:begin
                if(I_PE_SHIFT)begin
                    if(sel<M_DIM)begin
                        sel   <= sel + 1;
                        state <= state;
                    end else begin
                        sel   <= sel;
                        state <= S_IDLE;
                    end
                end else begin
                    sel   <= sel;
                    state <= state;
                end
            end
        endcase
    end
end

assign O_OVER = (sel == M_DIM) ? 1 : 0;
endmodule