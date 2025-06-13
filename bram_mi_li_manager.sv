`timescale 1ns/1ps
module bram_mi_li_manager#(
    parameter D_W   = 16,
    parameter SA_R  = 16,
    parameter SA_C  = 16
)(
    input  logic           I_CLK                           ,
    input  logic           I_RST_N                         ,
    input  logic           I_RD_ENA                        ,
    input  logic           I_WR_ENA                        ,
    input  logic [5:0]     I_ADDR                          ,
    input  logic [D_W-1:0] I_WR_MI_VEC [0:SA_R-1]          ,
    input  logic [D_W-1:0] I_WR_LI_VEC [0:SA_R-1]          ,
    output logic           O_BUSY                          ,
    output logic           O_VLD                           ,
    output logic [D_W-1:0] O_RD_MI_VEC [0:SA_R-1]          ,
    output logic [D_W-1:0] O_RD_LI_VEC [0:SA_R-1]          
);
enum logic [1:0]{
    S_IDLE    = 2'b00,
    S_BRAM_RD = 2'b01,
    S_BRAM_WR = 2'b11
}state;
logic           mi_ena                ;
logic           mi_wea                ;
logic [5:0]     mi_addra              ;
logic [255:0]   mi_dina               ;
logic [255:0]   mi_douta              ;
logic           li_ena                ;
logic           li_wea                ;
logic [5:0]     li_addra              ;
logic [255:0]   li_dina               ;
logic [255:0]   li_douta              ;
logic [D_W-1:0] in_mi_vec_ff[0:SA_R-1];
logic [D_W-1:0] in_li_vec_ff[0:SA_R-1];

logic [0:0]     cnt                   ;

generate
    for(genvar i=0;i<16;i=i+1)begin
        assign mi_dina[(15-i)*16 +: 16] = in_mi_vec_ff[i];
        assign O_RD_MI_VEC[i] = mi_douta[(15-i)*16 +: 16];
    end
endgenerate

generate
    for(genvar i=0;i<16;i=i+1)begin
        assign li_dina[(15-i)*16 +: 16] = in_li_vec_ff[i];
        assign O_RD_LI_VEC[i] = li_douta[(15-i)*16 +: 16];
    end
endgenerate

mi_ram u_mi_ram (
  .clka (I_CLK   ), // input wire clka
  .ena  (mi_ena  ), // input wire ena
  .wea  (mi_wea  ), // input wire [0 : 0] wea
  .addra(mi_addra), // input wire [5 : 0] addra
  .dina (mi_dina ), // input wire [255 : 0] dina
  .douta(mi_douta)  // output wire [255 : 0] douta
);

li_ram u_li_ram (
  .clka (I_CLK   ), // input wire clka
  .ena  (li_ena  ), // input wire ena
  .wea  (li_wea  ), // input wire [0 : 0] wea
  .addra(li_addra), // input wire [5 : 0] addra
  .dina (li_dina ), // input wire [255 : 0] dina
  .douta(li_douta)  // output wire [255 : 0] douta
);

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        state        <= S_IDLE      ;
        O_BUSY       <= 'b0         ;
        O_VLD        <= 'b0         ;
        mi_ena       <= 'b0         ;
        mi_wea       <= 'b0         ;
        mi_addra     <= 'b0         ;
        li_ena       <= 'b0         ;
        li_wea       <= 'b0         ;
        li_addra     <= 'b0         ;
        in_mi_vec_ff <= '{default:0};
        in_li_vec_ff <= '{default:0};
        cnt          <= 'b0         ;
    end else begin
        case(state)
            S_IDLE    :begin
                if(I_WR_ENA)begin
                    state        <= S_BRAM_WR  ;
                    O_BUSY       <= 1'b1       ;
                    O_VLD        <= 1'b0       ;
                    mi_ena       <= 1'b1       ;
                    mi_wea       <= 1'b1       ;
                    mi_addra     <= I_ADDR     ;
                    li_ena       <= 1'b1       ;
                    li_wea       <= 1'b1       ;
                    li_addra     <= I_ADDR     ;
                    in_mi_vec_ff <= I_WR_MI_VEC;
                    in_li_vec_ff <= I_WR_LI_VEC;
                end else if(I_RD_ENA)begin
                    state        <= S_BRAM_RD  ;
                    O_BUSY       <= 1'b1       ;
                    O_VLD        <= 1'b0       ;
                    mi_ena       <= 1'b1       ;
                    mi_wea       <= 1'b0       ;
                    mi_addra     <= I_ADDR     ;
                    li_ena       <= 1'b1       ;
                    li_wea       <= 1'b0       ;
                    li_addra     <= I_ADDR     ;
                end else begin
                    state        <= state      ;
                    O_BUSY       <= 1'b0       ;
                    O_VLD        <= 1'b0       ;
                    mi_ena       <= 1'b0       ;
                    mi_wea       <= 1'b0       ;
                    li_ena       <= 1'b0       ;
                    li_wea       <= 1'b0       ;
                end
            end
            S_BRAM_RD :begin
                if(cnt == 1'b0)begin
                    state  <= state ;
                    cnt    <= 1'b1  ;
                    O_VLD  <= 1'b0  ;
                    O_BUSY <= O_BUSY;
                end else begin
                    state  <= S_IDLE;
                    cnt    <= 1'b0  ;
                    O_VLD  <= 1'b1  ;
                    O_BUSY <= 1'b0  ;
                end
            end
            S_BRAM_WR :begin
                state  <= S_IDLE;
                O_BUSY <= 1'b0  ;
            end
        endcase
    end
end
endmodule