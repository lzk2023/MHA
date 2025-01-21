`timescale 1ns/1ps
`include "defines.v"
module attention#(
    parameter D_W  = 16,
    parameter SA_R = 16,
    parameter SA_C = 16,
    parameter DIM  = 64,       //sequence length
    parameter D_K  = 64        //Q,K,V column num（dimention/h_num）
)(
    input                    I_CLK          ,
    input                    I_RST_N        ,
    input                    I_ATTN_START   ,
    input                    I_PE_SHIFT     ,//connect to SA_wrapper O_PE_SHIFT
    input  [DIM*D_K*D_W-1:0] I_MAT_Q        ,
    input  [DIM*D_K*D_W-1:0] I_MAT_K        ,
    input  [DIM*D_K*D_W-1:0] I_MAT_V        ,
    output                   O_MATSHIFT_OVER,//connect to SA_wrapper I_MATSHIFT_OVER
    output                   O_VECTOR_VLD   ,
    output [SA_R*D_W-1:0]    O_VECTOR_1     ,
    output [SA_C*D_W-1:0]    O_VECTOR_2     ,
    output                   O_DATA_VLD     ,
    output [DIM*D_K*D_W-1:0] O_ATT_DATA     
);
localparam SQRT_DK = 8;       //square root d_k
wire [D_W-1:0] query_data_matrix [0:DIM-1][0:D_K-1];          //matrix:Q
wire [D_W-1:0] key_data_matrix [0:DIM-1][0:D_K-1];            //matrix:K
wire [D_W-1:0] key_data_matrix_transpose [0:D_K-1][0:DIM-1];  //matrix:K^T
wire [D_W-1:0] value_data_matrix [0:DIM-1][0:D_K-1];          //matrix:V
wire [D_W-1:0] calculate_matrix_1 [0:SA_R-1][0:D_K-1];        //matrix:input SA
wire [D_W-1:0] calculate_matrix_2 [0:D_K-1][0:SA_C-1];        //matrix:input SA

wire [SA_R*D_K*D_W-1:0] input_sa_1;
wire [D_K*SA_C*D_W-1:0] input_sa_2;

reg  [D_W-1:0] att_data_matrix [0:DIM-1][0:D_K-1];            //matrix:attention_out

`VARIABLE_TO_MATRIX(D_W,DIM,D_K,I_MAT_Q,query_data_matrix);
`VARIABLE_TO_MATRIX(D_W,DIM,D_K,I_MAT_K,key_data_matrix);
`VARIABLE_TO_MATRIX(D_W,DIM,D_K,I_MAT_V,value_data_matrix);

`MATRIX_TO_VARIABLE(D_W,SA_R,D_K,input_sa_1,calculate_matrix_1);
`MATRIX_TO_VARIABLE(D_W,D_K,SA_C,input_sa_2,calculate_matrix_2);
generate      //matrix transpose
    for(genvar i=0;i<DIM;i=i+1)begin
        for(genvar j=0;j<D_K;j=j+1)begin
            assign key_data_matrix_transpose[j][i] = key_data_matrix[i][j];
        end
    end 
endgenerate

SA_mat_manager#(
    .D_W  (D_W  ),
    .X_R  (SA_R ),
    .M_DIM(D_K  ),//X_C == W_R == M_DIM,dimention of the 2 multiply matrix.
    .W_C  (SA_C )
)u_dut_SA_mat_manager(
    .I_CLK      (I_CLK          ),
    .I_ASYN_RSTN(I_RST_N        ),
    .I_SYNC_RSTN(),
    .I_PE_SHIFT (I_PE_SHIFT     ),
    .I_START    (),
    .I_X_MATRIX (input_sa_1     ),
    .I_W_MATRIX (input_sa_2     ),
    .O_OVER     (O_MATSHIFT_OVER),
    .O_X_VECTOR (O_VECTOR_1     ),
    .O_W_VECTOR (O_VECTOR_2     )
);
endmodule