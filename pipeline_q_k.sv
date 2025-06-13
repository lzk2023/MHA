`timescale 1ns/1ps
module pipeline_q_k#(
    parameter D_W   = 16,
    parameter SA_R  = 16,
    parameter SA_C  = 16
)(
    input  logic           I_CLK                         ,
    input  logic           I_RST_N                       ,
    input  logic           I_ENA                         ,//when !O_VLD & !O_BUSY
    input  logic [5:0]     I_SEL_Q_O                     ,
    input  logic [5:0]     I_SEL_K_V                     ,
    input  logic           I_RDY                         ,//from next pipeline
    output logic           O_BUSY                        ,
    output logic           O_VLD                         ,
    output logic [D_W-1:0] O_MAT_Q_K [0:SA_R-1][0:SA_C-1],
    output logic [5:0]     O_SEL_Q_O                     ,
    output logic [5:0]     O_SEL_K_V                     ,
    
    //*************bram_manager ports************//
    input  logic           I_BRAM_RD_Q_VLD                    ,
    input  logic           I_BRAM_RD_K_VLD                    ,
    input  logic [D_W-1:0] I_BRAM_RD_Q_MAT [0:SA_R-1][0:SA_C-1],
    input  logic [D_W-1:0] I_BRAM_RD_K_MAT [0:SA_R-1][0:SA_C-1],
    output logic           O_BRAM_Q_ENA                        ,//out to bram_manager
    output logic           O_BRAM_K_ENA                        ,//out to bram_manager
    output logic [5:0]     O_BRAM_SEL_Q_LINE                   ,
    output logic [2:0]     O_BRAM_SEL_Q_COL                    ,
    output logic [5:0]     O_BRAM_SEL_K_LINE                   ,
    output logic [2:0]     O_BRAM_SEL_K_COL                    
);
enum logic [1:0]{
    S_IDLE     = 2'b00,
    S_LOAD_Q_K = 2'b01,
    S_Q_K      = 2'b11
}state;

logic [D_W-1:0] sa_in_mat_1          [0:SA_R-1][0:SA_C-1];
logic [D_W-1:0] sa_in_mat_2          [0:SA_R-1][0:SA_C-1];
logic           sa_in_load                               ;
logic           sa_in_acc_signal                         ;
logic           sa_out_load_w_signal                     ;
logic           sa_out_vld                               ;
logic [D_W-1:0] sa_out_result        [0:SA_R-1][0:SA_C-1];
logic [2:0]     sa_vld_cnt                               ;
logic [2:0]     sel_col                                  ;

logic [D_W-1:0] key_data_matrix_transpose [0:SA_R-1][0:SA_C-1]; //matrix:K^T
generate      //matrix transpose
    for(genvar i=0;i<SA_R;i=i+1)begin
        for(genvar j=0;j<SA_C;j=j+1)begin
            assign key_data_matrix_transpose[j][i] = I_BRAM_RD_K_MAT[i][j];
        end
    end 
endgenerate
always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        state             <= S_IDLE;
        sa_in_mat_1       <= 'b0   ;
        sa_in_mat_2       <= 'b0   ;
        sa_in_load        <= 'b0   ;
        sa_in_acc_signal  <= 'b0   ;
        sa_vld_cnt        <= 'b0   ;
        sel_col           <= 'b0   ;
        O_BUSY            <= 1'b1  ;
        O_VLD             <= 1'b1  ;
        O_SEL_Q_O         <= 1'b1  ;
        O_SEL_K_V         <= 1'b1  ;
        O_BRAM_Q_ENA      <= 'b0   ;
        O_BRAM_K_ENA      <= 'b0   ;
        O_BRAM_SEL_Q_LINE <= 'b0   ;
        O_BRAM_SEL_Q_COL  <= 'b0   ;
        O_BRAM_SEL_K_LINE <= 'b0   ;
        O_BRAM_SEL_K_COL  <= 'b0   ;
    end else begin
        case(state)
            S_IDLE     :begin
                if(I_ENA)begin
                    state       <= S_LOAD_Q_K;
                    O_BUSY      <= 1'b1      ;
                    sa_in_load  <= 0         ;
                    O_SEL_Q_O   <= I_SEL_Q_O ;
                    O_SEL_K_V   <= I_SEL_K_V ;
                    sel_col     <= 3'd0      ;
                end else if(I_RDY & O_VLD)begin
                    state       <= state      ;
                    O_VLD       <= 1'b0       ;
                    sa_in_mat_1 <= sa_in_mat_1;
                    sa_in_mat_2 <= sa_in_mat_2;
                    sa_in_load  <= 0          ;
                end else begin
                    state       <= state      ;
                    sa_in_mat_1 <= sa_in_mat_1;
                    sa_in_mat_2 <= sa_in_mat_2;
                    sa_in_load  <= 0          ;
                end
            end
            S_LOAD_Q_K :begin
                if(I_BRAM_RD_Q_VLD)begin
                    state            <= S_Q_K;
                    O_BRAM_Q_ENA     <= 1'b0;
                    O_BRAM_K_ENA     <= 1'b0;
                    sa_in_mat_1      <= I_BRAM_RD_Q_MAT;
                    sa_in_mat_2      <= key_data_matrix_transpose;
                    sa_in_load       <= 1'b1;
                    sa_in_acc_signal <= 1'b1;
                    sel_col          <= sel_col + 1;
                end else begin
                    state             <= state;
                    O_BRAM_Q_ENA      <= 1'b1;
                    O_BRAM_K_ENA      <= 1'b1;
                    O_BRAM_SEL_Q_LINE <= O_SEL_Q_O;
                    O_BRAM_SEL_Q_COL  <= sel_col;
                    O_BRAM_SEL_K_LINE <= O_SEL_K_V;
                    O_BRAM_SEL_K_COL  <= sel_col;
                end
            end
            S_Q_K      :begin
                if(sa_out_vld)begin
                    if(sa_vld_cnt == 3'd7)begin
                        state            <= S_IDLE     ;
                        O_BUSY           <= 1'b0       ;
                        O_VLD            <= 1'b1       ;
                        sa_vld_cnt       <= 3'd0       ;
                        sel_col          <= 3'd0       ;
                        sa_in_mat_1      <= sa_out_result;//S
                        sa_in_mat_2      <= sa_in_mat_2;
                        sa_in_load       <= 1'b0       ;
                        sa_in_acc_signal <= 1'b0       ;
                        O_BRAM_Q_ENA     <= 1'b0       ;
                        O_BRAM_K_ENA     <= 1'b0       ;
                    end else begin
                        state      <= state       ;
                        sa_vld_cnt <= sa_vld_cnt + 1;
                    end
                end else if(sa_out_load_w_signal)begin
                    if(sel_col == 3'd7)begin
                        state       <= state     ;
                        sel_col     <= sel_col   ;
                        sa_in_mat_1 <= I_BRAM_RD_Q_MAT;
                        sa_in_mat_2 <= key_data_matrix_transpose;
                        if(sa_vld_cnt > 3'd4)begin
                            sa_in_load   <= 0         ;
                        end else begin
                            sa_in_load   <= 1         ;
                        end
                    end else begin
                        state       <= state      ;
                        sel_col     <= sel_col + 1;
                        sa_in_mat_1 <= I_BRAM_RD_Q_MAT;
                        sa_in_mat_2 <= key_data_matrix_transpose;
                        sa_in_load  <= 1'b1       ;
                    end
                end else begin
                    state        <= state;
                    O_BRAM_Q_ENA <= 1'b1 ;
                    O_BRAM_K_ENA <= 1'b1 ;
                    O_BRAM_SEL_Q_LINE <= O_SEL_Q_O;
                    O_BRAM_SEL_Q_COL  <= sel_col;
                    O_BRAM_SEL_K_LINE <= O_SEL_K_V;
                    O_BRAM_SEL_K_COL  <= sel_col;
                    sa_in_load    <= 1'b0 ;
                end
            end
        endcase
    end
end
assign O_MAT_Q_K = sa_in_mat_1;
SA_wrapper#(
    .D_W        (D_W ),
    .SA_R       (SA_R),  //SA_ROW,        SA.shape = (SA_R,SA_C)
    .SA_C       (SA_C)   //SA_COLUMN,     
) u_SA_in_pipeline_q_k(
    .I_CLK              (I_CLK               ),
    .I_RST_N            (I_RST_N             ),
    .I_LOAD_FLAG        (sa_in_load          ),
    .I_X_MATRIX         (sa_in_mat_1         ),//input x(from left)     
    .I_W_MATRIX         (sa_in_mat_2         ),//input weight(from ddr)
    .I_ACCUMULATE_SIGNAL(sa_in_acc_signal    ),
    .O_INPUT_FIFO_EMPTY (),
    .O_OUTPUT_FIFO_FULL (),
    .O_LOAD_WEIGHT_VLD  (sa_out_load_w_signal),
    .O_OUT_VLD          (sa_out_vld          ),//                             
    .O_OUT              (sa_out_result       ) //OUT.shape = (X_R,64)               
);    
endmodule