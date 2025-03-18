`timescale 1ns/1ps

module get_mat_from_bram(
    input  logic        I_CLK              , 
    input  logic        I_RST_N            , 
    input  logic        I_VLD_PULSE        ,
    input  logic [5:0]  I_SEL              ,//sel,64
    output logic        O_VLD              ,
    output logic [7:0]  O_MAT [0:15][0:127]
);

enum logic [1:0] {
    S_IDLE  ,
    S_DELAY ,
    S_CONCAT,
    S_OUT   
} state;

//logic          delay_2_ff;
logic [1:0]    sel;
logic [7:0]    addra;
logic [4095:0] douta;
logic [7:0]    dout_mat [0:3][0:127];

mat_Q_rom_ip Query_rom (
    .clka (I_CLK), // input wire clka
    .addra(addra), // input wire [7 : 0] addra
    .douta(douta)  // output wire [4095 : 0] douta,delay 2 clks
);

generate
    for(genvar x=0;x<4;x=x+1)begin
        for(genvar y=0;y<128;y=y+1)begin
            assign dout_mat[x][y] = douta[x*y*8 +: 8];
        end
    end
endgenerate

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        state <= S_IDLE;
        delay_2_ff <= 0;
        sel <= 0;
        O_VLD <= 0;
        O_MAT <= '{default:0};
    end else begin
        case(state)
            S_IDLE  :begin
                if(I_VLD_PULSE)begin
                    state <= S_DELAY;
                    delay_2_ff <= 0;
                    sel <= 0;
                    O_VLD <= 0;
                end else begin
                    state <= state;
                end
            end
            S_DELAY :begin
                if(I_VLD_PULSE)begin
                    state <= S_DELAY;
                    delay_2_ff <= 0;
                    sel <= 0;
                    O_VLD <= 0;
                end else begin
                    state <= S_CONCAT;
                end
            end
            S_CONCAT:begin
                if(I_VLD_PULSE)begin
                    state <= S_DELAY;
                    delay_2_ff <= 0;
                    sel <= 0;
                    O_VLD <= 0;
                end else begin
                    state <= state;
                end
            end
            S_OUT   :begin
                if(I_VLD_PULSE)begin
                    state <= S_DELAY;
                    delay_2_ff <= 0;
                    sel <= 0;
                    O_VLD <= 0;
                end else begin
                    state <= state;
                end
            end
        endcase
    end
end
endmodule