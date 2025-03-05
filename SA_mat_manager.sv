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
    input  logic           I_CLK                          ,
    input  logic           I_ASYN_RSTN                    ,
    input  logic           I_SYNC_RSTN                    ,
    input  logic           I_PE_SHIFT                     ,
    input  logic           I_START                        ,
    input  logic [D_W-1:0] I_X_MATRIX [0:X_R-1][0:M_DIM-1],
    input  logic [D_W-1:0] I_W_MATRIX [0:M_DIM-1][0:W_C-1],
    output logic           O_OVER                         ,
    output logic [D_W-1:0] O_X_VECTOR [0:X_R-1]           ,
    output logic [D_W-1:0] O_W_VECTOR [0:W_C-1]           
);

logic  [15:0] sel  ;
enum logic [1:0]  {
    S_IDLE  = 2'b01,
    S_COUNT = 2'b10
}state;

///////////////////////////select matrix out/////////////////////////
generate 
    for(genvar i=0;i<X_R;i=i+1)begin
        assign O_X_VECTOR[i] = (sel == M_DIM) ? 0 : I_X_MATRIX[i][M_DIM-1-sel];
    end
endgenerate

generate 
    for(genvar i=0;i<W_C;i=i+1)begin
        assign O_W_VECTOR[i] = (sel == M_DIM) ? 0 : I_W_MATRIX[M_DIM-1-sel][i];
    end
endgenerate

always_ff@(posedge I_CLK or negedge I_ASYN_RSTN)begin
    if(!I_ASYN_RSTN | !I_SYNC_RSTN)begin
        sel   <= 'b0;
        state <= S_IDLE;
    end else begin
        case(state)
            S_IDLE :begin
                if(I_START)begin
                    sel   <= 'b0;
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