`timescale 1ns/1ps

module bram_manager(
    input  logic       I_CLK               , 
    input  logic       I_RST_N             ,
    input  logic       I_ENA_Q             ,
    input  logic       I_ENA_K             ,
    input  logic       I_ENA_V             ,
    input  logic       I_ENA_O             ,
    input  logic       I_WEA_O             ,
    input  logic [5:0] I_SEL_Q_LINE        ,//sel,choose line 0~63
    input  logic [2:0] I_SEL_Q_COL         ,//sel,choose column 0~7
    input  logic [5:0] I_SEL_K_LINE        ,//sel,choose line 0~63
    input  logic [2:0] I_SEL_K_COL         ,//sel,choose column 0~7
    input  logic [5:0] I_SEL_V_LINE        ,//sel,choose line 0~63
    input  logic [2:0] I_SEL_V_COL         ,//sel,choose column 0~7
    input  logic [5:0] I_SEL_O_LINE        ,//sel,choose line 0~63
    input  logic [2:0] I_SEL_O_COL         ,//sel,choose column 0~7
    input  logic [15:0] I_MAT   [0:15][0:15],
    output logic       O_VLD_Q             ,
    output logic       O_VLD_K             ,
    output logic       O_VLD_V             ,
    output logic       O_VLD_O             ,
    output logic [15:0] O_MAT_Q [0:15][0:15],
    output logic [15:0] O_MAT_K [0:15][0:15],
    output logic [15:0] O_MAT_V [0:15][0:15],
    output logic [15:0] O_MAT_O [0:15][0:15] 
);

logic          cnt_q;
logic          cnt_k;
logic          cnt_v;
logic          cnt_o;
logic [8:0]    addra_q;
logic [8:0]    addra_k;
logic [8:0]    addra_v;
logic [8:0]    addra_o;
logic [4095:0] dina;
logic [4095:0] dout_q;
logic [4095:0] dout_k;
logic [4095:0] dout_v;
logic [4095:0] dout_o;
assign addra_q = {I_SEL_Q_LINE,I_SEL_Q_COL}; //{[5:0],[2:0]}
assign addra_k = {I_SEL_K_LINE,I_SEL_K_COL}; //{[5:0],[2:0]}
assign addra_v = {I_SEL_V_LINE,I_SEL_V_COL}; //{[5:0],[2:0]}
assign addra_o = {I_SEL_O_LINE,I_SEL_O_COL}; //{[5:0],[2:0]}
bram_ip_q u_ram_q (
  .clka (I_CLK  ), // input wire clka
  .ena  (I_ENA_Q), // input wire ena         (KEEP)
  .wea  (1'b0   ), // input wire  [0 : 0] wea (KEEP)
  .addra(addra_q), // input wire  [8 : 0] addra
  .dina ('b0    ), // input wire  [4095 : 0] dina
  .douta(dout_q )  // output wire [4095 : 0] douta
);
bram_ip_k u_ram_k (
  .clka (I_CLK  ), // input wire clka
  .ena  (I_ENA_K), // input wire ena
  .wea  (1'b0   ), // input wire  [0 : 0] wea
  .addra(addra_k), // input wire  [8 : 0] addra
  .dina ('b0    ), // input wire  [4095 : 0] dina
  .douta(dout_k )  // output wire [4095 : 0] douta
);
bram_ip_v u_ram_v (
  .clka (I_CLK  ), // input wire clka
  .ena  (I_ENA_V), // input wire ena
  .wea  (1'b0   ), // input wire  [0 : 0] wea
  .addra(addra_v), // input wire  [8 : 0] addra
  .dina ('b0    ), // input wire  [4095 : 0] dina
  .douta(dout_v )  // output wire [4095 : 0] douta
);
bram_ip_o u_ram_o (
  .clka (I_CLK  ), // input wire clka
  .ena  (I_ENA_O), // input wire ena
  .wea  (I_WEA_O), // input wire  [0 : 0] wea
  .addra(addra_o), // input wire  [8 : 0] addra
  .dina (dina   ), // input wire  [4095 : 0] dina
  .douta(dout_o )  // output wire [4095 : 0] douta
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
            assign dina[((15-i)*16+(15-j))*16 +: 16] = I_MAT[i][j];
        end
    end
endgenerate

generate
    for(genvar x=0;x<16;x=x+1)begin
        for(genvar y=0;y<16;y=y+1)begin
            assign O_MAT_Q[x][y] = dout_q[((15-x)*16+(15-y))*16 +: 16];
            assign O_MAT_K[x][y] = dout_k[((15-x)*16+(15-y))*16 +: 16];
            assign O_MAT_V[x][y] = dout_v[((15-x)*16+(15-y))*16 +: 16];
            assign O_MAT_O[x][y] = dout_o[((15-x)*16+(15-y))*16 +: 16];
        end
    end
endgenerate

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        cnt_q   <= 1'b0;
        O_VLD_Q <= 1'b0;
    end else if(I_ENA_Q)begin
        cnt_q <= ~cnt_q;
        if(cnt_q == 1'b1)begin
            O_VLD_Q <= 1'b1;
        end else begin
            O_VLD_Q <= 1'b0;
        end
    end else begin
        cnt_q   <= 1'b0;
        O_VLD_Q <= 1'b0;
    end
end
always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        cnt_k   <= 1'b0;
        O_VLD_K <= 1'b0;
    end else if(I_ENA_K)begin
        cnt_k <= ~cnt_k;
        if(cnt_k == 1'b1)begin
            O_VLD_K <= 1'b1;
        end else begin
            O_VLD_K <= 1'b0;
        end
    end else begin
        cnt_k   <= 1'b0;
        O_VLD_K <= 1'b0;
    end
end
always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        cnt_v   <= 1'b0;
        O_VLD_V <= 1'b0;
    end else if(I_ENA_V)begin
        cnt_v <= ~cnt_v;
        if(cnt_v == 1'b1)begin
            O_VLD_V <= 1'b1;
        end else begin
            O_VLD_V <= 1'b0;
        end
    end else begin
        cnt_v   <= 1'b0;
        O_VLD_V <= 1'b0;
    end
end
always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        cnt_o   <= 1'b0;
        O_VLD_O <= 1'b0;
    end else if(I_ENA_O & ~I_WEA_O)begin
        cnt_o <= ~cnt_o;
        if(cnt_o == 1'b1)begin
            O_VLD_O <= 1'b1;
        end else begin
            O_VLD_O <= 1'b0;
        end
    end else begin
        cnt_o   <= 1'b0;
        O_VLD_O <= 1'b0;
    end
end
endmodule