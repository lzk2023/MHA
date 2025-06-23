`timescale 1ns/1ps
`include "defines.v"
////////////////////////////////////////////////
//                  calculate_matrix_2
//                           |
//                           v
// calculate_matrix_1 ->    SA (16 X 16)
///////////////////////////////////////////////
module attention#(
    parameter D_W   = 16,
    parameter SA_R  = 16,
    parameter SA_C  = 16,
    parameter DIM   = 16,       //sequence length
    parameter D_K   = 128        //Q,K,V column num（dimention/h_num）
)(
    //*******************main ports*******************//
    input  logic           I_CLK                            ,
    input  logic           I_RST_N                          ,
    input  logic           I_ATTN_START                     ,
    input  logic           I_SA_VLD                         ,//valid from SA
    input  logic [D_W-1:0] I_SA_RESULT [0:SA_R-1][0:SA_C-1] ,//16*16,from SA
    input  logic           I_LOAD_W_SIGNAL                  ,//from SA_wrapper
    output logic           O_SA_LOAD                        ,//to SA_wrapper
    output logic [D_W-1:0] O_MAT_1     [0:SA_R-1][0:SA_C-1] ,//to SA_wrapper.I_X_MATRIX
    output logic [D_W-1:0] O_MAT_2     [0:SA_R-1][0:SA_C-1] ,//to SA_wrapper.I_W_MATRIX
    output logic           O_ACC_SIGNAL                     ,//to SA_wrapper.I_ACCUMULATE_SIGNAL
    output logic           O_DATA_VLD                       ,
    output logic [D_W-1:0] O_ATTN_DATA [0:SA_R-1][0:D_K-1]  ,//output O'


    //*************bram_manager ports************//
    input  logic           I_BRAM_RD_Q_VLD                    ,
    input  logic           I_BRAM_RD_K_VLD                    ,
    input  logic           I_BRAM_RD_V_VLD                    ,
    input  logic           I_BRAM_RD_O_VLD                    ,
    input  logic [D_W-1:0] I_BRAM_RD_Q_MAT [0:SA_R-1][0:SA_C-1],
    input  logic [D_W-1:0] I_BRAM_RD_K_MAT [0:SA_R-1][0:SA_C-1],
    input  logic [D_W-1:0] I_BRAM_RD_V_MAT [0:SA_R-1][0:SA_C-1],
    input  logic [D_W-1:0] I_BRAM_RD_O_MAT [0:SA_R-1][0:SA_C-1],
    output logic [D_W-1:0] O_BRAM_WR_MAT   [0:SA_R-1][0:SA_C-1],
    output logic           O_BRAM_Q_ENA                        ,//out to bram_manager
    output logic           O_BRAM_K_ENA                        ,//out to bram_manager
    output logic           O_BRAM_V_ENA                        ,//out to bram_manager
    output logic           O_BRAM_O_ENA                        ,//out to bram_manager
    output logic           O_BRAM_O_WEA                        ,
    output logic [5:0]     O_BRAM_SEL_Q_LINE                   ,
    output logic [2:0]     O_BRAM_SEL_Q_COL                    ,
    output logic [5:0]     O_BRAM_SEL_K_LINE                   ,
    output logic [2:0]     O_BRAM_SEL_K_COL                    ,
    output logic [5:0]     O_BRAM_SEL_V_LINE                   ,
    output logic [2:0]     O_BRAM_SEL_V_COL                    ,
    output logic [5:0]     O_BRAM_SEL_O_LINE                   ,
    output logic [2:0]     O_BRAM_SEL_O_COL                     
);
localparam S_DK_VALUE = 16'd724;//0.08838*32,1/(sqrt(dk=128))
enum logic [3:0] {
    S_IDLE     = 4'b0000,
    S_LOAD_Q_K = 4'b0001,//load Q,K from bram
    S_Q_K      = 4'b0011,//S = Q*K^T
    S_SCALE    = 4'b0010,//scale: S/d_k
    S_SOFTMAX  = 4'b0110,//P = softmax(S/d_k)
    S_P_V      = 4'b0111,
    S_LOAD_O   = 4'b0101,
    S_O_UPD    = 4'b0100,//O = P*V
    S_O_WRMEM  = 4'b1100 //upd O_new = (diag(li_new)^-1 * diag(li)*exp(mi-mi_new)) * O_old + O
} state;

logic [15:0]  mi_old_bram_out[0:15];
logic [15:0]  li_old_bram_out[0:15];
logic [15:0]  mi_old[0:15];
logic [15:0]  li_old[0:15];
logic [15:0]  mi_new[0:15];
logic [15:0]  li_new[0:15];
logic         mi_ena      ;
logic         mi_wea      ;
logic [255:0] mi_dina     ;
logic [255:0] mi_douta    ;
logic         li_ena      ;
logic         li_wea      ;
logic [255:0] li_dina     ;
logic [255:0] li_douta    ;                         
logic [15:0]  o_coefficient[0:15];
logic [15:0]  coefficient[0:15];
logic coef_upd_ena;
logic coef_upd_vld;
logic [15:0] coef_vector [0:SA_R-1];

logic [5:0]     sel_q_o;//  1024/16 = 64,select tiling Q,O,mi,li
logic [5:0]     sel_k_v;//  1024/16 = 64,select tiling K,V
logic [2:0]     sel_col;//  select tiling column
logic [2:0]     sa_vld_cnt;
logic [D_W-1:0] key_data_matrix_transpose [0:SA_R-1][0:SA_C-1]; //matrix:K^T
logic [D_W-1:0] scale_vector [0:SA_R-1];              //vector:scale(*1/sqrt(d_k))

logic           softmax_start              ;
logic [D_W-1:0] softmax_in     [0:15][0:15];
logic [15:0]    o_softmax_m    [0:15]      ;//new mi
logic [15:0]    o_softmax_l    [0:15]      ;//new li
logic           softmax_out_vld            ;
logic [D_W-1:0] softmax_out    [0:15][0:15];

logic           softmax_start_ff                ;
logic [D_W-1:0] softmax_in_ff      [0:15][0:15] ;
logic [15:0]    i_softmax_m_ff     [15:0]       ;
logic [15:0]    i_softmax_l_ff     [15:0]       ;
logic [15:0]    o_softmax_m_ff     [15:0]       ;
logic [15:0]    o_softmax_l_ff     [15:0]       ;
logic           softmax_out_vld_ff              ;
logic [D_W-1:0] softmax_out_ff     [0:15][0:15] ;

logic           softmax_start_ff1                ;
logic [D_W-1:0] softmax_in_ff1      [0:15][0:15] ;
logic [15:0]    i_softmax_m_ff1     [15:0]       ;
logic [15:0]    i_softmax_l_ff1     [15:0]       ;
logic [15:0]    o_softmax_m_ff1     [15:0]       ;
logic [15:0]    o_softmax_l_ff1     [15:0]       ;
logic           softmax_out_vld_ff1              ;
logic [D_W-1:0] softmax_out_ff1     [0:15][0:15] ;

logic           softmax_start_ff2                ;
logic [D_W-1:0] softmax_in_ff2      [0:15][0:15] ;
logic [15:0]    i_softmax_m_ff2     [15:0]       ;
logic [15:0]    i_softmax_l_ff2     [15:0]       ;
logic [15:0]    o_softmax_m_ff2     [15:0]       ;
logic [15:0]    o_softmax_l_ff2     [15:0]       ;
logic           softmax_out_vld_ff2              ;
logic [D_W-1:0] softmax_out_ff2     [0:15][0:15] ;

logic [D_W-1:0] mat_mul_mat_in [0:SA_R-1][0:SA_C-1];
logic [D_W-1:0] mat_mul_vec_in [0:SA_R-1]          ;
logic [D_W-1:0] mat_mul_mat_o  [0:SA_R-1][0:SA_C-1];

logic [D_W-1:0] matrix_adder_in1 [0:SA_R-1][0:SA_C-1];
logic [D_W-1:0] matrix_adder_in2 [0:SA_R-1][0:SA_C-1];
logic [D_W-1:0] matrix_adder_out [0:SA_R-1][0:SA_C-1];
logic [1:0]     cnt        ;

//////////////////////////////////////////////////////////////////////


generate      //matrix transpose
    for(genvar i=0;i<SA_R;i=i+1)begin
        for(genvar j=0;j<SA_C;j=j+1)begin
            assign key_data_matrix_transpose[j][i] = I_BRAM_RD_K_MAT[i][j];
        end
    end 
endgenerate

generate      //assign matrix scale 
    for(genvar i=0;i<SA_R;i=i+1)begin
        assign scale_vector[i] = S_DK_VALUE;
    end
endgenerate
//////////////////////////////////////////////////////////////////////

always@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        state             <= S_IDLE        ;
        mi_old            <= '{default:'b0};
        li_old            <= '{default:'b0};
        mi_new            <= '{default:'b0};
        li_new            <= '{default:'b0};
        mi_ena            <= 'b0           ;
        mi_wea            <= 'b0           ;
        li_ena            <= 'b0           ;
        li_wea            <= 'b0           ;
        sel_q_o           <= 6'd0          ;
        sel_k_v           <= 6'd0          ;
        sel_col           <= 3'd0          ;
        sa_vld_cnt        <= 3'd0          ;
        O_BRAM_Q_ENA      <= 1'b0          ;
        O_BRAM_K_ENA      <= 1'b0          ;
        O_BRAM_V_ENA      <= 1'b0          ;
        O_BRAM_O_ENA      <= 1'b0          ;
        O_BRAM_O_WEA      <= 1'b0          ;
        O_BRAM_SEL_Q_LINE <= 6'd0          ;
        O_BRAM_SEL_Q_COL  <= 3'd0          ;
        O_BRAM_SEL_K_LINE <= 6'd0          ;
        O_BRAM_SEL_K_COL  <= 3'd0          ;
        O_BRAM_SEL_V_LINE <= 6'd0          ;
        O_BRAM_SEL_V_COL  <= 3'd0          ;
        O_BRAM_SEL_O_LINE <= 6'd0          ;
        O_BRAM_SEL_O_COL  <= 3'd0          ;
        O_MAT_1           <= '{default:'b0};
        O_MAT_2           <= '{default:'b0};
        O_SA_LOAD         <= 0             ;
        O_ACC_SIGNAL      <= 1'b0          ;
        softmax_in        <= '{default:'b0};
        softmax_start     <= 0             ;
        O_DATA_VLD        <= 0             ;
        O_ATTN_DATA       <= '{default:'b0};
        mat_mul_mat_in    <= '{default:'b0};
        mat_mul_vec_in    <= '{default:'b0};
        matrix_adder_in1  <= '{default:'b0};
        matrix_adder_in2  <= '{default:'b0};
        cnt               <= 'b0           ;
    end else begin
        case(state)
            S_IDLE    :begin
                if(I_ATTN_START & !O_DATA_VLD)begin
                    state       <= S_LOAD_Q_K;
                    O_SA_LOAD   <= 0         ;
                    sel_q_o     <= 6'd0      ;
                    sel_k_v     <= 6'd0      ;
                    sel_col     <= 3'd0      ;
                end else begin
                    state       <= state   ;
                    mi_ena      <= 1'b0    ;
                    li_ena      <= 1'b0    ;
                    O_MAT_1     <= '{default:'b0}       ;
                    O_MAT_2     <= '{default:'b0}       ;
                    O_SA_LOAD   <= 0       ;
                end
            end
            S_LOAD_Q_K:begin
                if(I_BRAM_RD_Q_VLD)begin
                    state        <= S_Q_K;
                    O_BRAM_Q_ENA <= 1'b0;
                    O_BRAM_K_ENA <= 1'b0;
                    O_MAT_1      <= I_BRAM_RD_Q_MAT;
                    O_MAT_2      <= key_data_matrix_transpose;
                    mi_ena       <= 1'b1;
                    li_ena       <= 1'b1;
                    O_SA_LOAD    <= 1'b1;
                    O_ACC_SIGNAL <= 1'b1;
                    sel_col      <= sel_col + 1;
                end else begin
                    state             <= state;
                    O_BRAM_Q_ENA      <= 1'b1;
                    O_BRAM_K_ENA      <= 1'b1;
                    O_BRAM_SEL_Q_LINE <= sel_q_o;
                    O_BRAM_SEL_Q_COL  <= sel_col;
                    O_BRAM_SEL_K_LINE <= sel_k_v;
                    O_BRAM_SEL_K_COL  <= sel_col;
                end
            end
            S_Q_K     :begin
                if(I_SA_VLD)begin
                    if(sa_vld_cnt == 3'd7)begin
                        state      <= S_SCALE     ;
                        sa_vld_cnt <= 3'd0        ;
                        sel_col    <= 3'd0        ;
                        mat_mul_mat_in <= I_SA_RESULT;
                        mat_mul_vec_in <= scale_vector;
                        O_ACC_SIGNAL <= 1'b0;
                        O_BRAM_Q_ENA <= 1'b0 ;
                        O_BRAM_K_ENA <= 1'b0 ;
                    end else begin
                        state      <= state       ;
                        sa_vld_cnt <= sa_vld_cnt + 1;
                    end
                end else if(I_LOAD_W_SIGNAL)begin
                    if(sel_col == 3'd7)begin
                        state       <= state     ;
                        sel_col     <= sel_col   ;
                        O_MAT_1     <= I_BRAM_RD_Q_MAT;
                        O_MAT_2     <= key_data_matrix_transpose;
                        if(sa_vld_cnt > 3'd4)begin
                            O_SA_LOAD   <= 0         ;
                        end else begin
                            O_SA_LOAD   <= 1         ;
                        end
                    end else begin
                        state       <= state      ;
                        sel_col     <= sel_col + 1;
                        O_MAT_1     <= I_BRAM_RD_Q_MAT;
                        O_MAT_2     <= key_data_matrix_transpose;
                        O_SA_LOAD   <= 1'b1       ;
                    end
                end else begin
                    state        <= state;
                    O_BRAM_Q_ENA <= 1'b1 ;
                    O_BRAM_K_ENA <= 1'b1 ;
                    O_BRAM_SEL_Q_LINE <= sel_q_o;
                    O_BRAM_SEL_Q_COL  <= sel_col;
                    O_BRAM_SEL_K_LINE <= sel_k_v;
                    O_BRAM_SEL_K_COL  <= sel_col;
                    O_SA_LOAD    <= 1'b0 ;
                end
            end
            S_SCALE   :begin
                if(cnt == 2'b01)begin
                    state         <= S_SOFTMAX    ;
                    softmax_start <= 1            ;
                    softmax_in    <= mat_mul_mat_o;//S/sqrt(d_k)
                    mi_old        <= mi_old_bram_out;
                    li_old        <= li_old_bram_out;
                    cnt           <= 2'b00          ;
                end else begin
                    state         <= state           ;
                    cnt           <= 2'b01           ;
                end
            end
            S_SOFTMAX :begin
                if(softmax_out_vld_ff2)begin
                    O_MAT_1       <= softmax_out_ff2 ;
                    mi_new        <= o_softmax_m_ff2 ;
                    li_new        <= o_softmax_l_ff2 ;
                    state         <= S_P_V          ;
                    O_SA_LOAD     <= 1              ;
                    softmax_start <= 0              ;
                    O_MAT_2       <= I_BRAM_RD_V_MAT;
                    sel_col       <= sel_col+1      ;
                end else begin
                    O_MAT_1           <= O_MAT_1    ;
                    O_BRAM_V_ENA      <= 1'b1       ;
                    O_BRAM_SEL_V_LINE <= sel_k_v    ;
                    O_BRAM_SEL_V_COL  <= sel_col    ;
                end
            end
            S_P_V     :begin
                if(I_SA_VLD)begin
                    if(sa_vld_cnt == 3'd7)begin
                        state      <= S_LOAD_O    ;
                        sa_vld_cnt <= 3'd0        ;
                        sel_col    <= 3'd0        ;
                        for(int n=0;n<SA_R;n=n+1)begin
                            O_ATTN_DATA[n][sa_vld_cnt*16 +: 16] <= I_SA_RESULT[n];//O_ATTN_DATA[0:SA_R-1][sa_vld_cnt*16 +: 16] <= I_SA_RESULT;
                        end
                        O_SA_LOAD   <= 1'b0       ;
                        O_BRAM_V_ENA <= 1'b0 ;
                    end else begin
                        state      <= state       ;
                        sa_vld_cnt <= sa_vld_cnt + 1;
                        for(int n=0;n<SA_R;n=n+1)begin
                            O_ATTN_DATA[n][sa_vld_cnt*16 +: 16] <= I_SA_RESULT[n];//O_ATTN_DATA[0:SA_R-1][sa_vld_cnt*16 +: 16] <= I_SA_RESULT;
                        end
                    end
                end else if(I_LOAD_W_SIGNAL)begin
                    if(sel_col == 3'd7)begin
                        state       <= state     ;
                        sel_col     <= sel_col   ;
                        O_MAT_1     <= O_MAT_1   ;//P
                        O_MAT_2     <= I_BRAM_RD_V_MAT;
                        if(sa_vld_cnt > 3'd4)begin
                            O_SA_LOAD   <= 0         ;
                        end else begin
                            O_SA_LOAD   <= 1         ;
                        end
                    end else begin
                        state       <= state      ;
                        sel_col     <= sel_col + 1;
                        O_MAT_1     <= O_MAT_1    ;//P
                        O_MAT_2     <= I_BRAM_RD_V_MAT;
                        O_SA_LOAD   <= 1'b1       ;
                    end
                end else begin
                    state        <= state;
                    O_BRAM_V_ENA <= 1'b1 ;
                    O_BRAM_SEL_V_LINE <= sel_k_v;
                    O_BRAM_SEL_V_COL  <= sel_col;
                    O_SA_LOAD    <= 1'b0 ;
                end
            end
            S_LOAD_O  :begin
                if(I_BRAM_RD_O_VLD)begin
                    state            <= state;
                    O_BRAM_O_ENA     <= 1'b0;
                    mat_mul_mat_in   <= I_BRAM_RD_O_MAT;
                    mat_mul_vec_in   <= coef_vector    ;//
                    sel_col          <= sel_col        ;
                    cnt              <= 2'd1           ;
                end else if(cnt == 2'd1)begin
                    cnt              <= 2'd2           ;
                end else if(cnt == 2'd2)begin
                    cnt              <= 2'd3           ;
                    matrix_adder_in1 <= mat_mul_mat_o  ;
                    for(int n=0;n<SA_R;n=n+1)begin
                        matrix_adder_in2[n] <= O_ATTN_DATA[n][sel_col*16 +: 16];
                    end
                end else if(cnt == 2'd3)begin
                    if(sel_col == 3'd7)begin
                        state <= S_O_WRMEM;
                        O_BRAM_O_ENA    <= 1'b1   ;
                        O_BRAM_O_WEA    <= 1'b1   ;
                        O_BRAM_SEL_O_LINE <= sel_q_o;
                        O_BRAM_SEL_O_COL  <= 3'd0   ;
                        for(int n=0;n<SA_R;n=n+1)begin
                            O_ATTN_DATA[n][sel_col*16 +: 16] <= matrix_adder_out[n];//O_ATTN_DATA[0:SA_R-1][sa_vld_cnt*16 +: 16] <= matrix_adder_out;
                        end
                        sel_col <= 'b0;
                        cnt <= 2'd0;
                    end else begin
                        state <= state;
                        for(int n=0;n<SA_R;n=n+1)begin
                            O_ATTN_DATA[n][sel_col*16 +: 16] <= matrix_adder_out[n];//O_ATTN_DATA[0:SA_R-1][sa_vld_cnt*16 +: 16] <= matrix_adder_out;
                        end
                        sel_col        <= sel_col + 1    ;
                        cnt <= 2'd0;
                    end
                end else begin
                    state             <= state;
                    O_BRAM_O_ENA      <= 1'b1;
                    O_BRAM_SEL_O_LINE <= sel_q_o;
                    O_BRAM_SEL_O_COL  <= sel_col;
                    cnt               <= 2'd0   ;
                end
            end
            S_O_WRMEM :begin
                if(sel_col == 3'd7)begin
                    mi_wea          <= 1'b0;
                    li_wea          <= 1'b0;
                    O_BRAM_O_ENA    <= 1'b0;
                    O_BRAM_O_WEA    <= 1'b0;
                    if(sel_q_o == 6'd63)begin
                        if(sel_k_v == 6'd63)begin
                            sel_q_o    <= 6'd0       ;
                            sel_k_v    <= 6'd0       ;
                            sel_col    <= 3'd0       ;
                            state      <= S_IDLE     ;
                            O_DATA_VLD <= 1          ;
                        end else begin
                            sel_q_o    <= 6'd0       ;
                            sel_k_v    <= sel_k_v + 1;
                            sel_col    <= 3'd0       ;
                            state      <= S_LOAD_Q_K ;
                        end
                    end else begin
                        sel_q_o    <= sel_q_o + 1;
                        sel_k_v    <= sel_k_v    ;
                        sel_col    <= 3'd0       ;
                        state      <= S_LOAD_Q_K ;
                    end
                end else begin
                    mi_wea          <= 1'b1;
                    li_wea          <= 1'b1;
                    O_BRAM_O_ENA    <= 1'b1;
                    O_BRAM_O_WEA    <= 1'b1;
                    O_BRAM_SEL_O_LINE <= sel_q_o;
                    O_BRAM_SEL_O_COL  <= sel_col + 1;
                    sel_col <= sel_col + 1;
                end
            end
        endcase
    end
end
generate
    for(genvar i=0;i<SA_R;i=i+1)begin
        assign O_BRAM_WR_MAT[i] = O_ATTN_DATA[i][sel_col*16 +: 16];
    end
endgenerate

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        coefficient  <= '{default:'b0};
        coef_upd_ena <= 1'b0;
    end else if(state == S_P_V)begin
        if(coef_upd_vld)begin
            coef_upd_ena <= 1'b0;
            coefficient  <= o_coefficient;
        end else begin
            coef_upd_ena <= 1'b1;
        end
    end else begin
        coefficient  <= coefficient;
        coef_upd_ena <= 1'b0;
    end
end

assign coef_vector = coefficient;
/////////////////////////mi & li bram/////////////////////////////////////
generate
    for(genvar i=0;i<16;i=i+1)begin
        assign mi_dina[(15-i)*16 +: 16] = mi_new[i];
        assign mi_old_bram_out[i] = mi_douta[(15-i)*16 +: 16];
    end
endgenerate

generate
    for(genvar i=0;i<16;i=i+1)begin
        assign li_dina[(15-i)*16 +: 16] = li_new[i];
        assign li_old_bram_out[i] = li_douta[(15-i)*16 +: 16];
    end
endgenerate

mi_ram u_mi_ram (
  .clka (I_CLK   ), // input wire clka
  .ena  (mi_ena  ), // input wire ena
  .wea  (mi_wea  ), // input wire [0 : 0] wea
  .addra(sel_q_o ), // input wire [5 : 0] addra
  .dina (mi_dina ), // input wire [255 : 0] dina
  .douta(mi_douta)  // output wire [255 : 0] douta
);

li_ram u_li_ram (
  .clka (I_CLK   ), // input wire clka
  .ena  (li_ena  ), // input wire ena
  .wea  (li_wea  ), // input wire [0 : 0] wea
  .addra(sel_q_o ), // input wire [5 : 0] addra
  .dina (li_dina ), // input wire [255 : 0] dina
  .douta(li_douta)  // output wire [255 : 0] douta
);
/////////////////////////mi & li bram/////////////////////////////////////
always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        softmax_start_ff  <= 'b0         ;
        softmax_in_ff     <= '{default:0};
        i_softmax_m_ff    <= '{default:0};
        i_softmax_l_ff    <= '{default:0};
        o_softmax_m_ff    <= '{default:0};
        o_softmax_l_ff    <= '{default:0};
        softmax_out_vld_ff<= 'b0         ;
        softmax_out_ff    <= '{default:0};
        
        softmax_start_ff1  <= 'b0         ;
        softmax_in_ff1     <= '{default:0};
        i_softmax_m_ff1    <= '{default:0};
        i_softmax_l_ff1    <= '{default:0};
        o_softmax_m_ff1    <= '{default:0};
        o_softmax_l_ff1    <= '{default:0};
        softmax_out_vld_ff1<= 'b0         ;
        softmax_out_ff1    <= '{default:0};

        softmax_start_ff2  <= 'b0         ;
        softmax_in_ff2     <= '{default:0};
        i_softmax_m_ff2    <= '{default:0};
        i_softmax_l_ff2    <= '{default:0};
        o_softmax_m_ff2    <= '{default:0};
        o_softmax_l_ff2    <= '{default:0};
        softmax_out_vld_ff2<= 'b0         ;
        softmax_out_ff2    <= '{default:0};
    end else begin
        softmax_start_ff    <= softmax_start  ;
        softmax_in_ff       <= softmax_in     ;
        i_softmax_m_ff      <= mi_old         ;
        i_softmax_l_ff      <= li_old         ;
        o_softmax_m_ff      <= o_softmax_m    ;
        o_softmax_l_ff      <= o_softmax_l    ;
        softmax_out_vld_ff  <= softmax_out_vld;
        softmax_out_ff      <= softmax_out    ;

        softmax_start_ff1    <= softmax_start_ff  ;
        softmax_in_ff1       <= softmax_in_ff     ;
        i_softmax_m_ff1      <= i_softmax_m_ff    ;
        i_softmax_l_ff1      <= i_softmax_l_ff    ;
        o_softmax_m_ff1      <= o_softmax_m_ff    ;
        o_softmax_l_ff1      <= o_softmax_l_ff    ;
        softmax_out_vld_ff1  <= softmax_out_vld_ff;
        softmax_out_ff1      <= softmax_out_ff    ;

        softmax_start_ff2    <= softmax_start_ff1  ;
        softmax_in_ff2       <= softmax_in_ff1     ;
        i_softmax_m_ff2      <= i_softmax_m_ff1    ;
        i_softmax_l_ff2      <= i_softmax_l_ff1    ;
        o_softmax_m_ff2      <= o_softmax_m_ff1    ;
        o_softmax_l_ff2      <= o_softmax_l_ff1    ;
        softmax_out_vld_ff2  <= softmax_out_vld_ff1;
        softmax_out_ff2      <= softmax_out_ff1    ;
    end
end
safe_softmax_wrapper#(  
    .D_W(D_W)
)u_softmax_wrapper_for_attn(
    .I_CLK      (I_CLK          ),
    .I_RST_N    (I_RST_N        ),
    .I_START    (softmax_start_ff2),//keep when calculate
    .I_DATA     (softmax_in_ff2   ),
    .I_X_MAX    (i_softmax_m_ff2  ),
    .I_EXP_SUM  (i_softmax_l_ff2  ),
    .O_X_MAX    (o_softmax_m    ),
    .O_EXP_SUM  (o_softmax_l    ),
    .O_VLD      (softmax_out_vld),
    .O_DATA     (softmax_out    )
);

o_matrix_upd#(
    .D_W(D_W),
    .TIL(16) //tiling row == 16
)u_o_matrix_upd(
    .I_CLK        (I_CLK        ),
    .I_RST_N      (I_RST_N      ),
    .I_ENA        (coef_upd_ena ),//keep
    .I_LI_OLD     (li_old       ),
    .I_MI_OLD     (mi_old       ),
    .I_LI_NEW     (li_new       ),
    .I_MI_NEW     (mi_new       ),
    .O_VLD        (coef_upd_vld ),
    .O_COEFFICIENT(o_coefficient)
);

matrix_mul u_mat_mul(
    .I_CLK  (I_CLK         ),
    .I_RST_N(I_RST_N       ),
    .I_MAT  (mat_mul_mat_in),
    .I_VEC  (mat_mul_vec_in),
    .O_MAT  (mat_mul_mat_o )
);

matrix_add#(
    .D_W  (D_W ),
    .SA_R (SA_R),
    .SA_C (SA_C)
)u_matrix_adder(
    .I_MAT_1(matrix_adder_in1),
    .I_MAT_2(matrix_adder_in2),//O_ATTN_DATA[0:SA_R-1][sa_vld_cnt*16 +: 16]
    .O_MAT_O(matrix_adder_out)
);
endmodule