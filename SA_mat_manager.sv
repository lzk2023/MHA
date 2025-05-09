`timescale 1ns/1ps
///////////////////////////////////////////////////////////////////
//Input the two input matrices into the systolic array in the correct input format.
//将两个输入矩阵以正确的输入形式输入到脉动阵列中
///////////////////////////////////////////////////////////////////
`include "defines.v"
module SA_mat_manager#(
    parameter D_W   = 8,
    parameter X_R   = 16,
    parameter W_C   = 16
)(
    input  logic           I_CLK                      ,
    input  logic           I_RST_N                    ,
    input  logic           I_PE_SHIFT                 ,
    input  logic           I_START                    ,
    input  logic [7:0]     I_M_DIM                    ,//max:128
    input  logic [D_W-1:0] I_X_MATRIX [0:X_R-1][0:127],//X_C == W_R == 128,dimention of the 2 multiply matrix.
    input  logic [D_W-1:0] I_W_MATRIX [0:127][0:W_C-1],
    output logic           O_OVER                     ,
    output logic [D_W-1:0] O_X_VECTOR [0:X_R-1]       ,
    output logic [D_W-1:0] O_W_VECTOR [0:W_C-1]           
);

logic  [15:0] sel  ;

///////////////////////////select matrix out/////////////////////////
generate 
    for(genvar i=0;i<X_R;i=i+1)begin
        assign O_X_VECTOR[i] = (sel >= I_M_DIM) ? 0 : I_X_MATRIX[i][I_M_DIM-1-sel];
    end
endgenerate

generate 
    for(genvar i=0;i<W_C;i=i+1)begin
        assign O_W_VECTOR[i] = (sel >= I_M_DIM) ? 0 : I_W_MATRIX[I_M_DIM-1-sel][i];
    end
endgenerate

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N | I_START)begin
        sel   <= 'b0;
    end else begin
        if(I_PE_SHIFT)begin
            if(sel<I_M_DIM)begin
                sel   <= sel + 1;
            end else begin
                sel   <= sel;
            end
        end else begin
            sel   <= sel;
        end
    end
end

//assign O_OVER = (sel == I_M_DIM) ? 1 : 0;
always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N | I_START)begin
        O_OVER <= 0;
    end else begin
        if(sel == I_M_DIM)begin
            O_OVER <= 1;
        end else begin
            O_OVER <= 0;
        end
    end
end
endmodule