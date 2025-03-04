`timescale 1ns/1ps
`include "defines.v"
module attention#(
    parameter D_W   = 16,
    parameter SA_R  = 16,
    parameter SA_C  = 16,
    parameter M_DIM = 16,       //to SA_wrapper
    parameter DIM   = 16,       //sequence length
    parameter D_K   = 16        //Q,K,V column num（dimention/h_num）
)(
    input                           I_CLK          ,
    input                           I_ASYN_RSTN    ,
    input                           I_SYNC_RSTN    ,
    input                           I_ATTN_START   ,
    input                           I_PE_SHIFT     ,//connect to SA_wrapper O_PE_SHIFT
    input      [DIM*D_K*D_W-1:0]    I_MAT_Q        ,
    input      [DIM*D_K*D_W-1:0]    I_MAT_K        ,
    input      [DIM*D_K*D_W-1:0]    I_MAT_V        ,
    input                           I_SA_VLD       ,//valid from SA
    input      [SA_R*SA_C*D_W-1:0]  I_SA_RESULT    ,//16*16*D_W,from SA
    output reg                      O_SA_START     ,//to SA_wrapper
    output reg                      O_SA_CLEARN    ,//to SA_wrapper SYNC_RSTN
    output reg [SA_R*M_DIM*D_W-1:0] O_MAT_1        ,//to SA_wrapper
    output reg [M_DIM*SA_C*D_W-1:0] O_MAT_2        ,//to SA_wrapper
    output reg                      O_DATA_VLD     ,
    output     [DIM*D_K*D_W-1:0]    O_ATT_DATA     
);
localparam SQRT_DK    = 4        ;      //square root d_k
localparam S_DK_VALUE = 16'b0_00_0100_0000_00000;//0.25=1/4
localparam S_IDLE     = 11'b000_0000_0001;
localparam S_CLEAR0   = 11'b000_0000_0010;
localparam S_Q_K      = 11'b000_0000_0100;      //S = Q*K^T
localparam S_CLEAR1   = 11'b000_0000_1000;
localparam S_SCALE    = 11'b000_0001_0000;      //S/d_k
localparam S_CLEAR2   = 11'b000_0010_0000;
localparam S_SOFTMAX  = 11'b000_0100_0000;      //P = softmax(S/d_k)
localparam S_CLEAR3   = 11'b000_1000_0000;
localparam S_P_V      = 11'b001_0000_0000;      //O = P*V
localparam S_CLEAR4   = 11'b010_0000_0000;
localparam S_O        = 11'b100_0000_0000;
wire [D_W-1:0] query_data_matrix [0:DIM-1][0:D_K-1];          //matrix:Q                                             calculate_matrix_2
wire [D_W-1:0] key_data_matrix [0:DIM-1][0:D_K-1];            //matrix:K                                                      |
wire [D_W-1:0] key_data_matrix_transpose [0:D_K-1][0:DIM-1];  //matrix:K^T                                                    v
wire [D_W-1:0] value_data_matrix [0:DIM-1][0:D_K-1];          //matrix:V                   
wire [D_W-1:0] calculate_matrix_1 [0:SA_R-1][0:D_K-1];        //matrix:input SA                     calculate_matrix_1 ->    SA (16 X 16)
wire [D_W-1:0] calculate_matrix_2 [0:D_K-1][0:SA_C-1];        //matrix:input SA
wire [D_W-1:0] scale_matrix [0:SA_R-1][0:SA_C-1];             //matrix:scale(*1/sqrt(d_k))

wire [SA_R*D_K*D_W-1:0]  input_sa_1   ;
wire [D_K*SA_C*D_W-1:0]  input_sa_2   ;
wire [D_K*DIM*D_W-1:0]   k_t_var      ;
wire [SA_R*SA_C*D_W-1:0] scale_var    ;
wire [D_K*D_W-1:0] softmax_out;

reg  [D_W-1:0] s_p_matrix [0:DIM-1][0:DIM-1];                 //matrix:S and P


reg  [10:0] state;
reg  [4:0] sel_dim;
reg        softmax_start;
reg  [DIM*D_K*D_W-1:0] attention_o;
//////////////////////////////////////////////////////////////////////
`VARIABLE_TO_MATRIX(D_W,DIM,D_K,I_MAT_Q,query_data_matrix);
`VARIABLE_TO_MATRIX(D_W,DIM,D_K,I_MAT_K,key_data_matrix);
`VARIABLE_TO_MATRIX(D_W,DIM,D_K,I_MAT_V,value_data_matrix);     //input to matrix

`MATRIX_TO_VARIABLE(D_W,SA_R,D_K,input_sa_1,calculate_matrix_1);
`MATRIX_TO_VARIABLE(D_W,D_K,SA_C,input_sa_2,calculate_matrix_2);//matrix to SA
`MATRIX_TO_VARIABLE(D_W,D_K,DIM,k_t_var,key_data_matrix_transpose);

generate      //matrix transpose
    for(genvar i=0;i<DIM;i=i+1)begin
        for(genvar j=0;j<D_K;j=j+1)begin
            assign key_data_matrix_transpose[j][i] = key_data_matrix[i][j];
        end
    end 
endgenerate

generate      //assign matrix scale 
    for(genvar i=0;i<SA_R;i=i+1)begin
        for(genvar j=0;j<SA_C;j=j+1)begin
            if(i==j)begin
                assign scale_matrix [i][j]= S_DK_VALUE;
            end else begin
                assign scale_matrix [i][j]= 0;
            end
        end
    end
endgenerate
`MATRIX_TO_VARIABLE(D_W,SA_R,SA_C,scale_var,scale_matrix);    //matrix(reg) to output
//////////////////////////////////////////////////////////////////////

assign O_ATT_DATA = attention_o;
//assign calculate_matrix_1[0:SA_R-1][0:D_K-1]= (state == S_Q_M_K) ? query_data_matrix[sel_row*SA_R +: SA_R][0:D_K-1] : att_data_matrix[sel_row*SA_R +: SA_R][0:D_K-1];
//assign calculate_matrix_2[0:D_K-1][0:SA_C-1]= (state == S_Q_M_K) ? key_data_matrix_transpose[0:D_K-1][sel_column*SA_C +: SA_C] : value_data_matrix[0:DIM-1][sel_column*SA_C +: SA_C];

always@(posedge I_CLK or negedge I_ASYN_RSTN)begin
    if(!I_ASYN_RSTN | !I_SYNC_RSTN)begin
        state         <= S_IDLE  ;
        O_MAT_1       <= 0       ;
        O_MAT_2       <= 0       ;
        O_SA_CLEARN   <= 1       ;//clear SA
        O_SA_START    <= 0       ;
        softmax_start <= 0       ;
        sel_dim       <= 0       ;
        O_DATA_VLD    <= 0       ;
        attention_o   <= 0       ;
    end else begin
        case(state)
            S_IDLE    :begin
                if(I_ATTN_START)begin
                    state       <= S_CLEAR0;
                    O_MAT_1     <= I_MAT_Q ;
                    O_MAT_2     <= k_t_var ;
                    O_SA_CLEARN <= 0       ;//clear SA
                    O_SA_START  <= 0       ;
                end else begin
                    state       <= state   ;
                    O_MAT_1     <= 0       ;
                    O_MAT_2     <= 0       ;
                    O_SA_CLEARN <= 1       ;
                    O_SA_START  <= 0       ;
                end
            end
            S_CLEAR0  :begin
                state       <= S_Q_K  ;
                O_SA_CLEARN <= 1      ;
                O_SA_START  <= 1      ;
            end
            S_Q_K     :begin
                if(I_SA_VLD)begin
                    state       <= S_CLEAR1   ;
                    O_MAT_1     <= I_SA_RESULT;
                    O_MAT_2     <= scale_var  ;
                    O_SA_CLEARN <= 0          ;//clear SA
                    O_SA_START  <= 0          ;
                end else begin
                    state       <= state   ;
                    O_MAT_1     <= O_MAT_1 ;//Q
                    O_MAT_2     <= O_MAT_2 ;//K^T
                    O_SA_CLEARN <= 1       ;
                    O_SA_START  <= 0       ;
                end
            end
            S_CLEAR1  :begin
                state       <= S_SCALE;
                O_SA_CLEARN <= 1      ;
                O_SA_START  <= 1      ;
            end
            S_SCALE   :begin
                if(I_SA_VLD)begin
                    state       <= S_CLEAR2   ;
                    O_MAT_1     <= I_SA_RESULT;//S/sqrt(d_k)
                    O_MAT_2     <= 0          ;
                    O_SA_CLEARN <= 0          ;//clear SA
                    O_SA_START  <= 0          ;
                end else begin
                    state       <= state      ;
                    O_MAT_1     <= O_MAT_1    ;//S
                    O_MAT_2     <= O_MAT_2    ;//scale
                    O_SA_CLEARN <= 1          ;//clear SA
                    O_SA_START  <= 0          ;
                end
            end
            S_CLEAR2  :begin
                state         <= S_SOFTMAX;
                O_SA_CLEARN   <= 1        ;
                O_SA_START    <= 0        ;
                softmax_start <= 1        ;
            end
            S_SOFTMAX :begin
                if(sel_dim == 5'd16)begin
                    state       <= S_CLEAR3   ;
                    O_MAT_1     <= O_MAT_1    ;
                    O_MAT_2     <= I_MAT_V    ;
                    O_SA_CLEARN <= 0          ;//clear SA
                    O_SA_START  <= 0          ;
                end else begin
                    state         <= state    ;
                    softmax_start <= 1        ;
                    O_SA_CLEARN   <= 1        ;//clear SA
                    O_SA_START    <= 0        ;
                    if(out_vld)begin
                        O_MAT_1[sel_dim*M_DIM*D_W +: M_DIM*D_W] <= softmax_out ;
                        sel_dim     <= sel_dim + 1;
                    end else begin
                        O_MAT_1     <= O_MAT_1    ;
                        sel_dim     <= sel_dim    ;
                    end
                end
            end
            S_CLEAR3  :begin
                state       <= S_P_V    ;
                O_SA_CLEARN <= 1        ;
                O_SA_START  <= 1        ;
            end
            S_P_V     :begin
                if(out_vld)begin
                    state       <= S_CLEAR4   ;
                    O_MAT_1     <= O_MAT_1    ;
                    O_MAT_2     <= O_MAT_2    ;
                    attention_o <= I_SA_RESULT;
                    O_SA_CLEARN <= 0          ;//clear SA
                    O_SA_START  <= 0          ;
                end else begin
                    state       <= state      ;
                    O_MAT_1     <= O_MAT_1    ;//S
                    O_MAT_2     <= O_MAT_2    ;//scale
                    O_SA_CLEARN <= 1          ;//clear SA
                    O_SA_START  <= 0          ;
                end
            end
            S_CLEAR4  :begin
                state       <= S_O      ;
                O_SA_CLEARN <= 1        ;
                O_SA_START  <= 0        ;
            end
            S_O       :begin
                state      <= state;
                O_DATA_VLD <= 1    ;
            end
        endcase
    end
end

softmax#(  
    .D_W(D_W),
    .NUM(D_K) //dimention
)u_softmax_for_attn(
    .I_CLK      (I_CLK        ),
    .I_RST_N    (I_ASYN_RSTN  ),
    .I_START    (softmax_start),//keep when calculate
    .I_DATA     (O_MAT_1[sel_dim*M_DIM*D_W +: M_DIM*D_W]    ),
    .O_VLD      (out_vld ),
    .O_DATA     (softmax_out)
);
endmodule