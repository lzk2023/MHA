`timescale 1ns/1ps
module pipeline_softmax#(
    parameter D_W   = 16,
    parameter SA_R  = 16,
    parameter SA_C  = 16
)(
    input  logic           I_CLK                         ,
    input  logic           I_RST_N                       ,
    input  logic           I_ENA                         ,//when !O_VLD & !O_BUSY
    input  logic [D_W-1:0] I_MAT_S   [0:SA_R-1][0:SA_C-1],
    input  logic [5:0]     I_SEL_Q_O                     ,
    input  logic [5:0]     I_SEL_K_V                     ,
    input  logic           I_RDY                         ,//from next pipeline
    output logic           O_BUSY                        ,
    output logic           O_VLD                         ,
    output logic [D_W-1:0] O_MAT_P   [0:SA_R-1][0:SA_C-1],
    output logic [5:0]     O_SEL_Q_O                     ,
    output logic [5:0]     O_SEL_K_V                     ,
    output logic [D_W-1:0] O_MI_OLD [0:SA_R-1]           ,
    output logic [D_W-1:0] O_LI_OLD [0:SA_R-1]           ,
    output logic [D_W-1:0] O_MI_NEW [0:SA_R-1]           ,
    output logic [D_W-1:0] O_LI_NEW [0:SA_R-1]           
);
enum logic [1:0]{
    S_IDLE     = 2'b00,
    S_RD_MI_LI = 2'b01,
    S_SOFTMAX  = 2'b11,
    S_WR_MI_LI = 2'b10
}state;
logic [D_W-1:0] in_mat_s_ff[0:SA_R-1][0:SA_C-1];
logic [4:0]     sel_dim           ;
logic           mi_ena            ;
logic           mi_wea            ;
logic [255:0]   mi_dina           ;
logic [255:0]   mi_douta          ;
logic           li_ena            ;
logic           li_wea            ;
logic [255:0]   li_dina           ;
logic [255:0]   li_douta          ;
logic [D_W-1:0] mi_old [0:SA_R-1] ;
logic [D_W-1:0] li_old [0:SA_R-1] ;
logic           cnt               ;
logic           softmax_start     ;
logic [15:0]    i_softmax_m       ;//old mi
logic [15:0]    o_softmax_m       ;//new mi
logic [15:0]    i_softmax_l       ;//old li
logic [15:0]    o_softmax_l       ;//new li
logic           softmax_out_vld   ;
logic [D_W-1:0] softmax_out [0:15];

always_ff@(posedge I_Clk or negedge I_RST_N)begin
    if(!I_RST_N)begin
        state         <= S_IDLE      ;
        O_BUSY        <= 'b0         ;
        O_VLD         <= 'b0         ;
        in_mat_s_ff   <= '{default:0};
        O_SEL_Q_O     <= 'b0         ;
        O_SEL_K_V     <= 'b0         ;
        mi_ena        <= 'b0         ;
        li_ena        <= 'b0         ;
        mi_wea        <= 'b0         ;
        li_wea        <= 'b0         ;
        softmax_start <= 'b0         ;
        cnt           <= 'b0         ;
        sel_dim       <= 'b0         ;
        O_MAT_P       <= '{default:0};
        O_MI_OLD      <= '{default:0};
        O_LI_OLD      <= '{default:0};
        O_MI_NEW      <= '{default:0};
        O_LI_NEW      <= '{default:0};
    end else begin
        case(state)
            S_IDLE    :begin
                if(I_ENA)begin
                    state       <= S_RD_MI_LI;
                    O_BUSY      <= 1'b1      ;
                    in_mat_s_ff <= I_MAT_S   ;
                    O_SEL_Q_O   <= I_SEL_Q_O ;
                    O_SEL_K_V   <= I_SEL_K_V ;
                    mi_ena      <= 1'b1      ;
                    li_ena      <= 1'b1      ;
                end else if(I_RDY & O_VLD)begin
                    state  <= state ;
                    O_VLD  <= 1'b0  ;
                end else begin
                    state  <= state     ;
                    O_BUSY <= 1'b0      ;
                    mi_ena <= 1'b0      ;
                    li_ena <= 1'b0      ;
                end
            end
            S_RD_MI_LI:begin
                if(cnt == 1'b1)begin
                    state <= S_SOFTMAX;
                    cnt   <= 1'b0     ;
                    softmax_start <= 1;
                end else begin
                    state <= state;
                    cnt   <= 1'b1 ;
                end
            end
            S_SOFTMAX :begin
                if(softmax_out_vld)begin
                    O_MAT_P[sel_dim][0:SA_C-1]  <= softmax_out;
                    O_MI_NEW[sel_dim]           <= o_softmax_m;
                    O_LI_NEW[sel_dim]           <= o_softmax_l;
                    if(sel_dim == 5'd15)begin
                        state         <= S_WR_MI_LI   ;
                        O_MI_OLD      <= mi_old       ;
                        O_LI_OLD      <= li_old       ;
                        mi_wea        <= 1'b1         ;
                        li_wea        <= 1'b1         ;
                        sel_dim       <= 0            ;
                        softmax_start <= 0            ;
                    end else begin
                        sel_dim     <= sel_dim + 1;
                    end
                end else begin
                    O_MAT_P <= O_MAT_P    ;
                    sel_dim <= sel_dim    ;
                end
            end
            S_WR_MI_LI:begin
                state  <= S_IDLE;
                O_BUSY <= 1'b0  ;
                O_VLD  <= 1'b1  ;
                mi_ena <= 1'b0  ;
                li_ena <= 1'b0  ;
                mi_wea <= 1'b0  ;
                li_wea <= 1'b0  ;
            end
        endcase
    end
end
assign i_softmax_m = mi_old[sel_dim];
assign i_softmax_l = li_old[sel_dim];
generate
    for(genvar i=0;i<16;i=i+1)begin
        assign mi_dina[(15-i)*16 +: 16] = O_MI_NEW[i];
        assign mi_old[i] = mi_douta[(15-i)*16 +: 16];
    end
endgenerate

generate
    for(genvar i=0;i<16;i=i+1)begin
        assign li_dina[(15-i)*16 +: 16] = O_LI_NEW[i];
        assign li_old[i] = li_douta[(15-i)*16 +: 16];
    end
endgenerate

mi_ram u_mi_ram (
  .clka (I_CLK    ), // input wire clka
  .ena  (mi_ena   ), // input wire ena
  .wea  (mi_wea   ), // input wire [0 : 0] wea
  .addra(O_SEL_Q_O), // input wire [5 : 0] addra
  .dina (mi_dina  ), // input wire [255 : 0] dina
  .douta(mi_douta )  // output wire [255 : 0] douta
);

li_ram u_li_ram (
  .clka (I_CLK    ), // input wire clka
  .ena  (li_ena   ), // input wire ena
  .wea  (li_wea   ), // input wire [0 : 0] wea
  .addra(O_SEL_Q_O), // input wire [5 : 0] addra
  .dina (li_dina  ), // input wire [255 : 0] dina
  .douta(li_douta )  // output wire [255 : 0] douta
);

safe_softmax#(  
    .D_W(D_W),
    .NUM(16) //dimention
)u_softmax_for_attn(
    .I_CLK      (I_CLK          ),
    .I_RST_N    (I_RST_N        ),
    .I_START    (softmax_start  ),//keep when calculate
    .I_DATA     (in_mat_s_ff[sel_dim][0:SA_C-1]),
    .I_X_MAX    (i_softmax_m    ),
    .I_EXP_SUM  (i_softmax_l    ),
    .O_X_MAX    (o_softmax_m    ),
    .O_EXP_SUM  (o_softmax_l    ),
    .O_VLD      (softmax_out_vld),
    .O_DATA     (softmax_out    )
);
endmodule