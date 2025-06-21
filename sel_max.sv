`timescale 1ns/1ps
module sel_max#(
    parameter D_W = 16
)(
    input  logic           I_CLK        ,
    input  logic           I_RST_N      ,
    input  logic           I_ENA        ,
    input  logic [D_W-1:0] I_DATA [0:15],
    output logic           O_VLD        ,
    output logic [D_W-1:0] O_MAX
);
enum logic [1:0]{
    S_IDLE   = 2'b00,
    S_STAGE0 = 2'b01,
    S_STAGE1 = 2'b10,
    S_STAGE2 = 2'b11
}state;
logic [D_W-1:0] stage_0 [0:7];
logic [D_W-1:0] stage_1 [0:3];
logic [D_W-1:0] stage_2 [0:1];
integer i;

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        state   <= S_IDLE      ;
        stage_0 <= '{default:0};
        stage_1 <= '{default:0};
        stage_2 <= '{default:0};
        O_MAX   <= 'b0         ;
        O_VLD   <= 'b0         ;
    end else begin
        case(state)
            S_IDLE   :begin
                if(I_ENA)begin
                    state <= S_STAGE0;
                    O_VLD <= 1'b0    ;
                    for(i=0;i<8;i=i+1)begin
                        if($signed(I_DATA[2*i]) > $signed(I_DATA[2*i+1]))begin
                            stage_0[i] <= I_DATA[2*i];
                        end else begin
                            stage_0[i] <= I_DATA[2*i+1];
                        end
                    end
                end else begin
                    state   <= state  ;
                    stage_0 <= stage_0;
                    O_VLD   <= 1'b0   ;
                end
            end
            S_STAGE0 :begin
                state <= S_STAGE1;
                for(i=0;i<4;i=i+1)begin
                    if($signed(stage_0[2*i]) > $signed(stage_0[2*i+1]))begin
                        stage_1[i] <= stage_0[2*i];
                    end else begin
                        stage_1[i] <= stage_0[2*i+1];
                    end
                end
            end
            S_STAGE1 :begin
                state <= S_STAGE2;
                for(i=0;i<2;i=i+1)begin
                    if($signed(stage_1[2*i]) > $signed(stage_1[2*i+1]))begin
                        stage_2[i] <= stage_1[2*i];
                    end else begin
                        stage_2[i] <= stage_1[2*i+1];
                    end
                end
            end
            S_STAGE2 :begin
                state <= S_IDLE;
                O_VLD <= 1'b1  ;
                if($signed(stage_2[0]) > $signed(stage_2[1]))begin
                    O_MAX <= stage_2[0];
                end else begin
                    O_MAX <= stage_2[1];
                end
            end
        endcase
    end
end
endmodule