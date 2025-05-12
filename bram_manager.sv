`timescale 1ns/1ps

module bram_manager(
    input  logic       I_CLK             , 
    input  logic       I_RST_N           , 
    input  logic       I_RD_ENA          ,
    input  logic       I_WR_ENA          ,
    input  logic [1:0] I_SEL_MAT         ,//sel,matrix Q(2'b00),K(2'b01),V(2'b10),O(2'b11)
    input  logic [5:0] I_SEL_LINE        ,//sel,choose line
    input  logic [2:0] I_SEL_COL         ,//sel,choose column
    input  logic [7:0] I_MAT [0:15][0:15],
    output logic       O_VLD             ,
    output logic [7:0] O_MAT [0:15][0:15],
    output logic       O_WR_DONE          
);

enum logic [1:0] {
    S_IDLE  = 2'b00,
    S_DELAY = 2'b01,
    S_OUT   = 2'b11,
    S_WRITE = 2'b10
} state;

logic          delay_ff;
logic          ena;
logic          wea;
logic [10:0]   addra;
logic [2047:0] dina;
logic [2047:0] douta;
logic [7:0]    dout_mat [0:15][0:15];

assign addra = {I_SEL_MAT,I_SEL_LINE,I_SEL_COL}; //{[1:0],[5:0],[2:0]}
bram_ip u_single_port_ram (
    .clka (I_CLK), // input wire clka
    .ena  (ena  ), // input wire ena
    .wea  (wea  ), // input wire [0 : 0] wea
    .addra(addra), // input wire [10 : 0] addra
    .dina (dina ), // input wire [2047 : 0] dina
    .douta(douta)  // output wire [2047 : 0] douta,delay 2 clks
);
///////////////////////////////////
//bram: ena wea   function
//       0   0
//       0   1
//       1   0    bram read
//       1   1    bram write
///////////////////////////////////
generate
    for(genvar i=0;i<16;i=i+1)begin
        for(genvar j=0;j<16;j=j+1)begin
            assign dina[((15-i)*16+(15-j))*8 +: 8] = I_MAT[i][j];
        end
    end
endgenerate

generate
    for(genvar x=0;x<16;x=x+1)begin
        for(genvar y=0;y<16;y=y+1)begin
            assign dout_mat[x][y] = douta[((15-x)*16+(15-y))*8 +: 8];
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
        O_VLD <= 0;
        O_MAT <= '{default:0};
        O_WR_DONE <= 0;
    end else begin
        case(state)
            S_IDLE   :begin
                if(I_WR_ENA & !O_WR_DONE)begin
                    state <= S_WRITE;
                    ena <= 1;
                    wea <= 1;
                    O_WR_DONE <= 0;
                end else if(I_RD_ENA & !O_VLD)begin
                    state <= S_DELAY;
                    delay_ff <= 0;
                    ena <= 1;
                    wea <= 0;
                    O_VLD <= 0;
                end else begin
                    state <= state;
                    O_VLD <= 0;
                    O_WR_DONE <= 0;
                end
            end
            S_DELAY  :begin
                if(delay_ff == 0)begin
                    delay_ff <= 1;
                    state <= state;
                end else begin
                    state <= S_OUT;
                end
            end
            S_OUT    :begin
                O_VLD <= 1;
                ena   <= 0;
                wea   <= 0;
                O_MAT <= dout_mat;
                state <= S_IDLE;
            end
            S_WRITE  :begin
                state <= S_IDLE;
                ena   <= 0;
                wea   <= 0;
                O_WR_DONE <= 1;
            end
        endcase
    end
end
endmodule