`timescale 1ns/1ps

module bram_manager(
    input  logic       I_CLK              , 
    input  logic       I_RST_N            , 
    input  logic       I_VLD_PULSE        ,
    input  logic [5:0] I_SEL              ,//sel,64 = 256/4
    output logic       O_VLD              ,
    output logic [7:0] O_MAT [0:15][0:127]
);

enum logic [2:0] {
    S_IDLE   ,
    S_DELAY  ,
    S_CONCAT0,
    S_CONCAT1,
    S_OUT    
} state;

logic          delay_ff;
logic [1:0]    sel;
logic          ena;
logic [7:0]    addra;
logic [4095:0] douta;
logic [7:0]    dout_mat [0:3][0:127];

assign addra = {{2'b0},I_SEL,sel};//{2'b0,[5:0],[1:0]}
bram_ip u_single_port_ram (
    .clka (I_CLK), // input wire clka
    .ena  (ena  ), // input wire ena
    .wea  (), // input wire [0 : 0] wea
    .addra(addra), // input wire [9 : 0] addra
    .dina (), // input wire [4095 : 0] dina
    .douta(douta)  // output wire [4095 : 0] douta,delay 2 clks
);

generate
    for(genvar x=0;x<4;x=x+1)begin
        for(genvar y=0;y<128;y=y+1)begin
            assign dout_mat[x][y] = douta[(x*128+y)*8 +: 8];
        end
    end
endgenerate

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        state <= S_IDLE;
        delay_ff <= 0;
        ena <= 0;
        sel <= 0;
        O_VLD <= 0;
        O_MAT <= '{default:0};
    end else begin
        case(state)
            S_IDLE   :begin
                if(I_VLD_PULSE)begin
                    state <= S_DELAY;
                    delay_ff <= 0;
                    ena <= 1;
                    sel <= 0;
                    O_VLD <= 0;
                end else begin
                    state <= state;
                end
            end
            S_DELAY  :begin
                if(I_VLD_PULSE)begin
                    state <= S_DELAY;
                    delay_ff <= 0;
                    ena <= 1;
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
                if(I_VLD_PULSE)begin
                    state <= S_DELAY;
                    delay_ff <= 0;
                    ena <= 1;
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
                if(I_VLD_PULSE)begin
                    state <= S_DELAY;
                    delay_ff <= 0;
                    ena <= 1;
                    sel <= 0;
                    O_VLD <= 0;
                end else begin
                    O_MAT[8:11] <= dout_mat;
                    state <= S_OUT;
                end
            end
            S_OUT    :begin
                if(I_VLD_PULSE)begin
                    state <= S_DELAY;
                    delay_ff <= 0;
                    ena <= 1;
                    sel <= 0;
                    O_VLD <= 0;
                end else begin
                    O_VLD <= 1;
                    ena <= 0;
                    O_MAT[12:15] <= dout_mat;
                    state <= S_IDLE;
                end
            end
        endcase
    end
end
endmodule