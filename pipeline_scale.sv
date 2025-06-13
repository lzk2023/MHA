`timescale 1ns/1ps
module pipeline_scale#(
    parameter D_W      = 16,
    parameter SA_R     = 16,
    parameter SA_C     = 16,
    parameter DK_VALUE = 724  //0.08838*8192,1/(sqrt(dk=128))
)(
    input  logic           I_CLK                         ,
    input  logic           I_RST_N                       ,
    input  logic           I_ENA                         ,//when !O_VLD & !O_BUSY
    input  logic [D_W-1:0] I_MAT_Q_K [0:SA_R-1][0:SA_C-1],
    input  logic [5:0]     I_SEL_Q_O                     ,
    input  logic [5:0]     I_SEL_K_V                     ,
    input  logic           I_RDY                         ,//from next pipeline
    output logic           O_BUSY                        ,
    output logic           O_VLD                         ,
    output logic [D_W-1:0] O_MAT_S   [0:SA_R-1][0:SA_C-1],
    output logic [5:0]     O_SEL_Q_O                     ,
    output logic [5:0]     O_SEL_K_V                     
);
integer i;
integer j;
logic [D_W*2-1:0] mat_s_mul[0:SA_R-1][0:SA_C-1];
generate
    for(genvar x=0;x<SA_R;x=x+1)begin:gen_mat_mul
        for(genvar y=0;y<SA_C;y=y+1)begin
            assign mat_s_mul[i][j] = I_MAT_Q_K[i][j] * DK_VALUE;
        end
    end
endgenerate
always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        O_BUSY    <= 'b0         ;
        O_VLD     <= 'b0         ;
        O_SEL_Q_O <= 'b0         ;
        O_SEL_K_V <= 'b0         ;
        O_MAT_S   <= '{default:0};
    end else if(I_ENA)begin
        O_BUSY    <= 1'b0     ;
        O_VLD     <= 1'b1     ;
        O_SEL_Q_O <= I_SEL_Q_O;
        O_SEL_K_V <= I_SEL_K_V;
        for(i=0;i<SA_R;i=i+1)begin
            for(j=0;j<SA_C;j=j+1)begin
                if(mat_s_mul[i][j][12])begin
                    O_MAT_S[i][j] <= {mat_s_mul[i][j][31],mat_s_mul[i][j][27:13]} + 1;
                end else begin
                    O_MAT_S[i][j] <= {mat_s_mul[i][j][31],mat_s_mul[i][j][27:13]};
                end
            end
        end
    end else if(I_RDY & O_VLD)begin
        O_BUSY    <= O_BUSY    ;
        O_VLD     <= 1'b0      ;
        O_SEL_Q_O <= O_SEL_Q_O ;
        O_SEL_K_V <= O_SEL_K_V ;
        O_MAT_S   <= O_MAT_S   ;
    end else begin
        O_BUSY    <= O_BUSY    ;
        O_VLD     <= O_VLD     ;
        O_SEL_Q_O <= O_SEL_Q_O ;
        O_SEL_K_V <= O_SEL_K_V ;
        O_MAT_S   <= O_MAT_S   ;
    end
end
endmodule