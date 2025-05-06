`timescale 1ns/1ps

module bram_manager(
    input  logic       I_CLK              , 
    input  logic       I_RST_N            , 
    input  logic       I_RD_ENA_PULSE     ,
    input  logic       I_WR_ENA_PULSE     ,
    input  logic [7:0] I_SEL              ,//sel,addr:{[2:0],[5:0]} high_addr to choose Q,K,V,low_addr to choose line
    input  logic [7:0] I_MAT [0:15][0:127],
    output logic       O_VLD              ,
    output logic [7:0] O_MAT [0:15][0:127],
    output logic       O_WR_DONE          
);

enum logic [2:0] {
    S_IDLE   ,
    S_DELAY  ,
    S_CONCAT0,
    S_CONCAT1,
    S_OUT    ,
    S_WR_CONC
} state;

logic          delay_ff;
logic [1:0]    sel;
logic          ena;
logic          wea;
logic [9:0]    addra;
logic [4095:0] dina;
logic [4095:0] douta;
logic [7:0]    dout_mat [0:3][0:127];

assign addra = {I_SEL,sel}; //{[7:0],[1:0]}
bram_ip u_single_port_ram (
    .clka (I_CLK), // input wire clka
    .ena  (ena  ), // input wire ena
    .wea  (wea  ), // input wire [0 : 0] wea
    .addra(addra), // input wire [9 : 0] addra
    .dina (dina ), // input wire [4095 : 0] dina
    .douta(douta)  // output wire [4095 : 0] douta,delay 2 clks
);

generate
    for(genvar i=0;i<4;i=i+1)begin
        for(genvar j=0;j<128;j=j+1)begin
            assign dina[(i*128+j)*8 +: 8] = I_MAT[sel*4 + i][j];
        end
    end
endgenerate

generate
    for(genvar x=0;x<4;x=x+1)begin
        for(genvar y=0;y<128;y=y+1)begin
            assign dout_mat[x][y] = douta[(x*128+y)*8 +: 8];
        end
    end
endgenerate
/////////////////FSM///////////////////
always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        state <= S_IDLE;
        delay_ff <= 0;
        ena <= 0;
        wea <= 0;
        sel <= 0;
        O_VLD <= 0;
        O_MAT <= '{default:0};
        O_WR_DONE <= 0;
    end else begin
        case(state)
            S_IDLE   :begin
                if(I_WR_ENA_PULSE)begin
                    state <= S_WR_CONC;
                    ena <= 1;
                    wea <= 1;
                    sel <= 0;
                    O_WR_DONE <= 0;
                end else if(I_RD_ENA_PULSE)begin
                    state <= S_DELAY;
                    delay_ff <= 0;
                    ena <= 1;
                    wea <= 0;
                    sel <= 0;
                    O_VLD <= 0;
                end else begin
                    state <= state;
                end
            end
            S_DELAY  :begin
                if(I_WR_ENA_PULSE)begin
                    state <= S_WR_CONC;
                    ena <= 1;
                    wea <= 1;
                    sel <= 0;
                    O_WR_DONE <= 0;
                end else if(I_RD_ENA_PULSE)begin
                    state <= S_DELAY;
                    delay_ff <= 0;
                    ena <= 1;
                    wea <= 0;
                    sel <= 0;
                    O_VLD <= 0;
                end else begin
                    if(delay_ff == 0)begin
                        delay_ff <= 1;
                        sel <= sel + 1;
                        state <= state;
                    end else begin
                        sel <= sel + 1;
                        state <= S_CONCAT0;
                    end
                end
            end
            S_CONCAT0:begin
                if(I_WR_ENA_PULSE)begin
                    state <= S_WR_CONC;
                    ena <= 1;
                    wea <= 1;
                    sel <= 0;
                    O_WR_DONE <= 0;
                end else if(I_RD_ENA_PULSE)begin
                    state <= S_DELAY;
                    delay_ff <= 0;
                    ena <= 1;
                    wea <= 0;
                    sel <= 0;
                    O_VLD <= 0;
                end else begin
                    if(sel < 2'b11)begin
                        sel <= sel + 1;
                        state <= state;
                        O_MAT[0:3] <= dout_mat;
                    end else begin//sel == 3
                        state <= S_CONCAT1;
                        O_MAT[4:7] <= dout_mat;
                    end
                end
            end
            S_CONCAT1:begin
                if(I_WR_ENA_PULSE)begin
                    state <= S_WR_CONC;
                    ena <= 1;
                    wea <= 1;
                    sel <= 0;
                    O_WR_DONE <= 0;
                end else if(I_RD_ENA_PULSE)begin
                    state <= S_DELAY;
                    delay_ff <= 0;
                    ena <= 1;
                    wea <= 0;
                    sel <= 0;
                    O_VLD <= 0;
                end else begin
                    O_MAT[8:11] <= dout_mat;
                    state <= S_OUT;
                end
            end
            S_OUT    :begin
                if(I_WR_ENA_PULSE)begin
                    state <= S_WR_CONC;
                    ena <= 1;
                    wea <= 1;
                    sel <= 0;
                    O_WR_DONE <= 0;
                end else if(I_RD_ENA_PULSE)begin
                    state <= S_DELAY;
                    delay_ff <= 0;
                    ena <= 1;
                    wea <= 0;
                    sel <= 0;
                    O_VLD <= 0;
                end else begin
                    O_VLD <= 1;
                    ena <= 0;
                    wea <= 0;
                    O_MAT[12:15] <= dout_mat;
                    state <= S_IDLE;
                end
            end
            S_WR_CONC:begin
                if(I_WR_ENA_PULSE)begin
                    state <= S_WR_CONC;
                    ena <= 1;
                    wea <= 1;
                    sel <= 0;
                    O_WR_DONE <= 0;
                end else if(I_RD_ENA_PULSE)begin
                    state <= S_DELAY;
                    delay_ff <= 0;
                    ena <= 1;
                    wea <= 0;
                    sel <= 0;
                    O_VLD <= 0;
                end else begin
                    if(sel < 2'b11)begin
                        sel <= sel + 1;
                        state <= state;
                    end else begin//sel==3
                        state <= S_IDLE;
                        ena <= 0;
                        wea <= 0;
                        O_WR_DONE <= 1;
                    end
                end
            end
        endcase
    end
end
endmodule