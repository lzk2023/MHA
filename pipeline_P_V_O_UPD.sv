`timescale 1ns/1ps
module pipeline_P_V_O_UPD#(
    parameter D_W   = 16,
    parameter SA_R  = 16,
    parameter SA_C  = 16
)(
    input  logic           I_CLK                         ,
    input  logic           I_RST_N                       ,
    input  logic           I_ENA                         ,//when !O_VLD & !O_BUSY
    input  logic [D_W-1:0] I_MAT_P   [0:SA_R-1][0:SA_C-1],
    input  logic [5:0]     I_SEL_Q_O                     ,
    input  logic [5:0]     I_SEL_K_V                     ,
    input  logic [D_W-1:0] I_MI_OLD [0:SA_R-1]           ,
    input  logic [D_W-1:0] I_LI_OLD [0:SA_R-1]           ,
    input  logic [D_W-1:0] I_MI_NEW [0:SA_R-1]           ,
    input  logic [D_W-1:0] I_LI_NEW [0:SA_R-1]           ,
    output logic           O_BUSY                        ,
    output logic           O_VLD                         ,
    output logic [5:0]     O_SEL_Q_O                     ,
    output logic [5:0]     O_SEL_K_V                     ,
    
    //*************bram_manager ports************//
    input  logic           I_BRAM_RD_V_VLD                     ,
    input  logic           I_BRAM_RD_O_VLD                     ,
    input  logic [D_W-1:0] I_BRAM_RD_V_MAT [0:SA_R-1][0:SA_C-1],
    input  logic [D_W-1:0] I_BRAM_RD_O_MAT [0:SA_R-1][0:SA_C-1],
    output logic [D_W-1:0] O_BRAM_WR_MAT   [0:SA_R-1][0:SA_C-1],
    output logic           O_BRAM_V_ENA                        ,//out to bram_manager
    output logic           O_BRAM_O_ENA                        ,//out to bram_manager
    output logic           O_BRAM_O_WEA                        ,
    output logic [5:0]     O_BRAM_SEL_V_LINE                   ,
    output logic [2:0]     O_BRAM_SEL_V_COL                    ,
    output logic [5:0]     O_BRAM_SEL_O_LINE                   ,
    output logic [2:0]     O_BRAM_SEL_O_COL                    ,
);
enum logic [2:0]{
    S_IDLE     = 3'b000,
    S_CAL_COEF = 3'b001,
    S_LOAD_V   = 3'b011,
    S_P_V      = 3'b010,
    S_LOAD_O   = 3'b110,
    S_O_UPD    = 3'b111,
    S_O_WR_MEM = 3'b101
}state;

logic [D_W-1:0] mi_old       [0:SA_R-1];
logic [D_W-1:0] li_old       [0:SA_R-1];
logic [D_W-1:0] mi_new       [0:SA_R-1];
logic [D_W-1:0] li_new       [0:SA_R-1];
logic [D_W-1:0] mat_p_ff     [0:SA_R-1][0:SA_C-1];
logic [2:0]     sel_col                             ;
logic           sa_p_v_load                         ;
logic [D_W-1:0] sa_p_v_mat_1 [0:SA_R-1][0:SA_C-1]   ;
logic [D_W-1:0] sa_p_v_mat_2 [0:SA_R-1][0:SA_C-1]   ;
logic           sa_p_v_load_w_signal                ;
logic           sa_p_v_vld                          ;
logic [D_W-1:0] sa_p_v_result[0:SA_R-1][0:SA_C-1]   ;
logic [2:0]     sa_vld_cnt                          ;

logic           coef_upd_ena                        ;
logic           coef_upd_vld                        ;
logic [D_W-1:0] o_coefficient [0:SA_R-1]            ;
logic [D_W-1:0] coefficient   [0:SA_R-1]            ;
logic [D_W-1:0] mat_o_mul     [0:SA_R-1][0:SA_C-1]  ;
logic [D_W-1:0] matrix_adder_out[0:SA_R-1][0:SA_C-1];
logic [D_W-1:0] attn_data       [0:SA_R-1][0:127]   ;
logic [D_W-1:0] matrix_adder_in [0:SA_R-1][0:SA_C-1];

integer i;

always_ff@(posedge  I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        state             <= S_IDLE      ;
        O_BUSY            <= 'b0         ;
        O_VLD             <= 'b0         ;
        O_SEL_Q_O         <= 'b0         ;
        O_SEL_K_V         <= 'b0         ;
        mat_p_ff          <= '{default:0};
        mi_old            <= '{default:0};
        li_old            <= '{default:0};
        mi_new            <= '{default:0};
        li_new            <= '{default:0};
        sel_col           <= 'b0         ;
        coef_upd_ena      <= 'b0         ;
        coefficient       <= '{default:0};
        O_BRAM_V_ENA      <= 'b0         ;
        O_BRAM_SEL_V_LINE <= 'b0         ;
        O_BRAM_SEL_V_COL  <= 'b0         ;
        O_BRAM_O_ENA      <= 'b0         ;
        O_BRAM_O_WEA      <= 'b0         ;
        O_BRAM_WR_MAT     <= '{default:0};
        O_BRAM_SEL_O_LINE <= 'b0         ;
        O_BRAM_SEL_O_COL  <= 'b0         ;
        sa_p_v_mat_1      <= '{default:0};
        sa_p_v_mat_2      <= '{default:0};
        sa_p_v_load       <= 'b0         ;
        sa_vld_cnt        <= 'b0         ;
        attn_data         <= '{default:0};
        matrix_adder_in   <= '{default:0};
    end else begin
        case(state)
            S_IDLE     :begin
                if(I_ENA)begin
                    state     <= S_CAL_COEF;
                    O_BUSY    <= 1'b1      ;
                    O_VLD     <= 1'b1      ;
                    O_SEL_Q_O <= I_SEL_Q_O ;
                    O_SEL_K_V <= I_SEL_K_V ;
                    mat_p_ff  <= I_MAT_P   ;
                    mi_old    <= I_MI_OLD  ;
                    li_old    <= I_LI_OLD  ;
                    mi_new    <= I_MI_NEW  ;
                    li_new    <= I_LI_NEW  ;
                    sel_col   <= 'b0       ;
                end else begin
                    state     <= state;
                    O_BUSY    <= 1'b0      ;
                    O_VLD     <= O_VLD     ;
                    O_SEL_Q_O <= 'b0       ;
                    O_SEL_K_V <= 'b0       ;
                    mat_p_ff  <= mat_p_ff  ;
                    mi_old    <= mi_old    ;
                    li_old    <= li_old    ;
                    mi_new    <= mi_new    ;
                    li_new    <= li_new    ;
                    sel_col   <= sel_col   ;
                end
            end
            S_CAL_COEF :begin
                if(coef_upd_vld)begin
                    state <= S_LOAD_V   ;
                    coef_upd_ena <= 1'b0;
                    coefficient  <= o_coefficient;
                end else begin
                    state <= state;
                    coef_upd_ena <= 1'b1;
                end
            end
            S_LOAD_V   :begin
                if(I_BRAM_RD_V_VLD)begin
                    state        <= S_P_V  ;
                    O_BRAM_V_ENA <= 1'b0   ;
                    sa_p_v_mat_1 <= mat_p_ff;
                    sa_p_v_mat_2 <= I_BRAM_RD_V_MAT;//V
                    sa_p_v_load  <= 1'b1;
                    sel_col      <= sel_col + 1;
                end else begin
                    state             <= state;
                    sa_p_v_load       <= 1'b0;
                    O_BRAM_V_ENA      <= 1'b1;
                    O_BRAM_SEL_V_LINE <= O_SEL_K_V;
                    O_BRAM_SEL_V_COL  <= sel_col;
                end
            end
            S_P_V      :begin
                if(sa_p_v_vld)begin
                    if(sa_vld_cnt == 3'd7)begin
                        state      <= S_LOAD_O    ;
                        sa_vld_cnt <= 3'd0        ;
                        sel_col    <= 3'd0        ;
                        for(int n=0;n<SA_R;n=n+1)begin
                            attn_data[n][sa_vld_cnt*16 +: 16] <= sa_p_v_result[n];//O_ATTN_DATA[0:SA_R-1][sa_vld_cnt*16 +: 16] <= I_SA_RESULT;
                        end
                        sa_p_v_load  <= 1'b0       ;
                        O_BRAM_V_ENA <= 1'b0 ;
                    end else begin
                        state      <= state       ;
                        sa_vld_cnt <= sa_vld_cnt + 1;
                        for(int n=0;n<SA_R;n=n+1)begin
                            attn_data[n][sa_vld_cnt*16 +: 16] <= sa_p_v_result[n];//O_ATTN_DATA[0:SA_R-1][sa_vld_cnt*16 +: 16] <= I_SA_RESULT;
                        end
                    end
                end else if(sa_p_v_load_w_signal)begin
                    if(sel_col == 3'd7)begin
                        state        <= state     ;
                        sel_col      <= sel_col   ;
                        sa_p_v_mat_1 <= sa_p_v_mat_1   ;//P
                        sa_p_v_mat_2 <= I_BRAM_RD_V_MAT;
                        if(sa_vld_cnt > 3'd4)begin
                            sa_p_v_load   <= 0         ;
                        end else begin
                            sa_p_v_load   <= 1         ;
                        end
                    end else begin
                        state        <= state      ;
                        sel_col      <= sel_col + 1;
                        sa_p_v_mat_1 <= sa_p_v_mat_1    ;//P
                        sa_p_v_mat_2 <= I_BRAM_RD_V_MAT;
                        sa_p_v_load  <= 1'b1       ;
                    end
                end else begin
                    state        <= state;
                    O_BRAM_V_ENA <= 1'b1 ;
                    O_BRAM_SEL_V_LINE <= sel_k_v;
                    O_BRAM_SEL_V_COL  <= sel_col;
                    sa_p_v_load  <= 1'b0 ;
                end
            end
            S_LOAD_O   :begin
                if(I_BRAM_RD_O_VLD)begin
                    if(sel_col == 3'd7)begin
                        state        <= S_O_WR_MEM;
                        O_BRAM_O_ENA <= 1'b0;
                        sel_col      <= 3'd0;
                        for(i=0;i<SA_R;i=i+1)begin
                            attn_data[i][sel_col*16 +: 16] <= matrix_adder_out;
                        end
                    end else begin
                        state        <= state;
                        O_BRAM_O_ENA <= 1'b0;
                        sel_col      <= sel_col + 1;
                        for(i=0;i<SA_R;i=i+1)begin
                            attn_data[i][sel_col*16 +: 16] <= matrix_adder_out;
                        end
                    end
                end else begin
                    state             <= state;
                    O_BRAM_O_ENA      <= 1'b1;
                    O_BRAM_SEL_O_LINE <= O_SEL_Q_O;
                    O_BRAM_SEL_O_COL  <= sel_col;
                    for(i=0;i<SA_R;i=i+1)begin
                        matrix_adder_in   <= attn_data[i][sel_col*16 +: 16];
                    end
                end
            end
            S_O_WR_MEM :begin
                if(sel_col == 3'd7)begin
                    state           <= S_IDLE;
                    O_BUSY          <= 1'b0;
                    O_VLD           <= 1'b1;
                    O_BRAM_O_ENA    <= 1'b0;
                    O_BRAM_O_WEA    <= 1'b0;
                    sel_col         <= 3'd0;
                    for(i=0;i<SA_R;i=i+1)begin
                        O_BRAM_WR_MAT[i] <= attn_data[i][sel_col*16 +: 16];
                    end
                end else begin
                    state           <= state;
                    O_BRAM_O_ENA    <= 1'b1;
                    O_BRAM_O_WEA    <= 1'b1;
                    O_BRAM_SEL_O_LINE <= O_SEL_Q_O;
                    O_BRAM_SEL_O_COL  <= sel_col;
                    for(i=0;i<SA_R;i=i+1)begin
                        O_BRAM_WR_MAT[i] <= attn_data[i][sel_col*16 +: 16];
                    end
                    sel_col <= sel_col + 1;
                end
            end
        endcase
    end
end

SA_wrapper#(
    .D_W        (D_W         ),
    .SA_R       (SA_R        ),  //SA_ROW,        SA.shape = (SA_R,SA_C)
    .SA_C       (SA_C        )   //SA_COLUMN,     
) u_SA_P_V(
    .I_CLK              (I_CLK               ),
    .I_RST_N            (I_RST_N             ),
    .I_LOAD_FLAG        (sa_p_v_load         ),
    .I_X_MATRIX         (sa_p_v_mat_1        ),//input x(from left)     
    .I_W_MATRIX         (sa_p_v_mat_2        ),//input weight(from ddr)
    .I_ACCUMULATE_SIGNAL(1'b0                ),
    .O_INPUT_FIFO_EMPTY (),
    .O_OUTPUT_FIFO_FULL (),
    .O_LOAD_WEIGHT_VLD  (sa_p_v_load_w_signal),
    .O_OUT_VLD          (sa_p_v_vld          ),//                             
    .O_OUT              (sa_p_v_result       ) //OUT.shape = (X_R,64)               
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
    .I_MAT(I_BRAM_RD_O_MAT),
    .I_VEC(coefficient),
    .O_MAT(mat_o_mul)
);

matrix_add#(
    .D_W  (D_W ),
    .SA_R (SA_R),
    .SA_C (SA_C)
)u_matrix_adder(
    .I_MAT_1(matrix_adder_in),
    .I_MAT_2(mat_o_mul      ),//O_ATTN_DATA[0:SA_R-1][sa_vld_cnt*16 +: 16]
    .O_MAT_O(matrix_adder_out)
);
endmodule