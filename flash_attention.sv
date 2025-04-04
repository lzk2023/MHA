`timescale 1ns/1ps
module flash_attention#(
    parameter D_W   = 8,
    parameter SA_R  = 16,
    parameter SA_C  = 16,
    parameter M_DIM = 16,       //to SA_wrapper
    parameter DIM   = 16,       //sequence length
    parameter D_K   = 16        //Q,K,V column num（dimention/h_num）
)(
    input  logic           I_CLK                            ,
    input  logic           I_ASYN_RSTN                      ,
    input  logic           I_SYNC_RSTN                      ,
    input  logic           I_ATTN_START                     ,
    input  logic           I_PE_SHIFT                       ,//connect to SA_wrapper O_PE_SHIFT
    input  logic [D_W-1:0] I_MAT_Q     [0:DIM-1][0:D_K-1]   ,
    input  logic [D_W-1:0] I_MAT_K     [0:DIM-1][0:D_K-1]   ,
    input  logic [D_W-1:0] I_MAT_V     [0:DIM-1][0:D_K-1]   ,
    input  logic           I_SA_VLD                         ,//valid from SA
    input  logic [D_W-1:0] I_SA_RESULT [0:SA_R-1][0:SA_C-1] ,//16*16*D_W,from SA
    output logic           O_SA_START                       ,//to SA_wrapper
    output logic           O_SA_CLEARN                      ,//to SA_wrapper SYNC_RSTN
    output logic [D_W-1:0] O_MAT_1     [0:SA_R-1][0:M_DIM-1],//to SA_wrapper
    output logic [D_W-1:0] O_MAT_2     [0:M_DIM-1][0:SA_C-1],//to SA_wrapper
    output logic           O_DATA_VLD                       ,
    output logic [D_W-1:0] O_ATT_DATA  [0:DIM-1][0:D_K-1]    
);
localparam SQRT_DK    = 4                       ;//square root d_k
//localparam S_DK_VALUE = 16'b0_00_0100_0000_00000;//0.25=1/4
localparam S_DK_VALUE = 8'b0_00_01000;//0.25=1/4
enum logic [10:0] {
    S_IDLE     = 11'b000_0000_0001,
    S_CLEAR0   = 11'b000_0000_0010,
    S_Q_K      = 11'b000_0000_0100,      //S = Q*K^T
    S_CLEAR1   = 11'b000_0000_1000,
    S_SCALE    = 11'b000_0001_0000,      //S/d_k
    S_CLEAR2   = 11'b000_0010_0000,
    S_SOFTMAX  = 11'b000_0100_0000,      //P = softmax(S/d_k)
    S_CLEAR3   = 11'b000_1000_0000,
    S_P_V      = 11'b001_0000_0000,      //O = P*V
    S_CLEAR4   = 11'b010_0000_0000,
    S_O        = 11'b100_0000_0000 
} state;

//wire [D_W-1:0] query_data_matrix [0:DIM-1][0:D_K-1];          //matrix:Q                                             calculate_matrix_2
//wire [D_W-1:0] key_data_matrix [0:DIM-1][0:D_K-1];            //matrix:K                                                      |
wire [D_W-1:0] key_data_matrix_transpose [0:D_K-1][0:DIM-1];    //matrix:K^T                                                    v
//wire [D_W-1:0] value_data_matrix [0:DIM-1][0:D_K-1];          //matrix:V                   
//wire [D_W-1:0] calculate_matrix_1 [0:SA_R-1][0:D_K-1];        //matrix:input SA                     calculate_matrix_1 ->    SA (16 X 16)
//wire [D_W-1:0] calculate_matrix_2 [0:D_K-1][0:SA_C-1];        //matrix:input SA
wire [D_W-1:0] scale_matrix [0:SA_R-1][0:SA_C-1];               //matrix:scale(*1/sqrt(d_k))

wire [D_W-1:0]       softmax_out [0:D_K-1] ;

reg  [4:0]             sel_dim;
reg                    softmax_start;
//////////////////////////////////////////////////////////////////////

generate      //matrix transpose
    for(genvar i=0;i<DIM;i=i+1)begin
        for(genvar j=0;j<D_K;j=j+1)begin
            assign key_data_matrix_transpose[j][i] = I_MAT_K[i][j];
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
//////////////////////////////////////////////////////////////////////

always@(posedge I_CLK or negedge I_ASYN_RSTN)begin
    if(!I_ASYN_RSTN | !I_SYNC_RSTN)begin
        state         <= S_IDLE  ;
        O_MAT_1       <= '{default:'b0};
        O_MAT_2       <= '{default:'b0};
        O_SA_CLEARN   <= 1       ;//clear SA
        O_SA_START    <= 0       ;
        softmax_start <= 0       ;
        sel_dim       <= 0       ;
        O_DATA_VLD    <= 0       ;
        O_ATT_DATA    <= '{default:'b0};
    end else begin
        case(state)
            S_IDLE    :begin
                if(I_ATTN_START)begin
                    state       <= S_CLEAR0;
                    O_MAT_1     <= I_MAT_Q ;
                    O_MAT_2     <= key_data_matrix_transpose ;
                    O_SA_CLEARN <= 0       ;//clear SA
                    O_SA_START  <= 0       ;
                end else begin
                    state       <= state   ;
                    O_MAT_1     <= '{default:'b0}       ;
                    O_MAT_2     <= '{default:'b0}       ;
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
                    O_MAT_2     <= scale_matrix  ;
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
                    O_MAT_2     <= '{default:'b0}          ;
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
                        O_MAT_1[sel_dim] <= softmax_out ;
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
                softmax_start <= 0      ;
            end
            S_P_V     :begin
                if(I_SA_VLD)begin
                    state       <= S_CLEAR4   ;
                    O_MAT_1     <= O_MAT_1    ;
                    O_MAT_2     <= O_MAT_2    ;
                    O_ATT_DATA  <= I_SA_RESULT;
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

safe_softmax#(  
    .D_W(D_W),
    .NUM(D_K) //dimention
)u_softmax_for_attn(
    .I_CLK      (I_CLK        ),
    .I_RST_N    (I_ASYN_RSTN  ),
    .I_START    (softmax_start),//keep when calculate
    .I_DATA     (O_MAT_1[sel_dim]),
    .O_VLD      (out_vld ),
    .O_DATA     (softmax_out)
);
endmodule