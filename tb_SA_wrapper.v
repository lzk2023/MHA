`timescale 1ns/1ps

module tb_SA_wrapper(

);
localparam S   = 64;
localparam X_R = 2;

reg                      I_CLK        ;
reg                      I_RST_N      ;
reg                      I_START_FLAG ;
wire   [(S*X_R*16)-1:0]   I_X          ;
wire   [(S*64*16)-1:0]    I_W          ;
  
wire                     O_OUT_VLD    ;
wire  [(X_R*64*16)-1:0]  O_OUT        ;

reg [15:0] X_MATRIX [0:X_R-1][0:S-1] ;
reg [15:0] W_MATRIX [0:S-1][0:63]    ;

integer k;
integer l;
generate 
    for(genvar i=0;i<X_R;i=i+1)begin
        for(genvar j=0;j<S;j=j+1)begin
           assign I_X[(i*S+j)*16+:16]= X_MATRIX[i][j];
        end
    end
endgenerate

generate 
    for(genvar i=0;i<S;i=i+1)begin
        for(genvar j=0;j<64;j=j+1)begin
           assign I_W[(i*64+j)*16+:16]= W_MATRIX[i][j];
        end
    end
endgenerate

SA_wrapper#(
.S           (S            ),  //W_ROW,     W.shape = (S,64)
.X_R         (X_R          )   //X_ROW,     X.shape = (X_R,S)
) u_dut_SA_top(
.I_CLK       (I_CLK        ),
.I_RST_N     (I_RST_N      ),
.I_START_FLAG(I_START_FLAG ),//                                                
.I_X         (I_X          ),//input x(from left)     
.I_W         (I_W          ),//input weight(from ddr)             
.O_OUT_VLD   (O_OUT_VLD    ),//                                   
.O_OUT       (O_OUT        ) //OUT.shape = (X_R,64)               
);           

always #5 I_CLK = ~I_CLK;

function [15:0] mul_16;
    input [15:0] a;
    input [15:0] b;
    reg [31:0] c;
    begin
        c = $signed(a) * $signed(b);
        mul_16 = {c[31],c[27:13]};
    end
endfunction

initial begin
    I_CLK        = 0;
    I_RST_N      = 0;
    I_START_FLAG = 0;
    //I_X          = 0;
    //I_W          = 0;
    #100
    I_RST_N      = 1;
    #100
    I_START_FLAG = 1;
    for(k=0;k<X_R;k=k+1)begin
        for(l=0;l<S;l=l+1)begin
          // X_MATRIX[k][l] = $random %65535;
          X_MATRIX[k][l] = 16'b0_01_10000_0000_0000;
        end
    end
    for(k=0;k<S;k=k+1)begin
        for(l=0;l<64;l=l+1)begin
          // W_MATRIX[k][l] = $random %65535;
          W_MATRIX[k][l] = 16'b0_01_10000_0000_0000;
        end
    end
    //I_X          = {16'b0_10_00000_0000_0000,16'b0_01_10000_0000_0000,
    //                16'b0_01_00000_0000_0000,16'b0_00_10000_0000_0000};
    //I_W          = {16'b0_10_00000_0000_0000,16'b0_01_10000_0000_0000,{62{16'b0_00_00000_0000_0000}},
    //                16'b0_01_00000_0000_0000,16'b0_00_10000_0000_0000,{62{16'b0_00_00000_0000_0000}}};
    #10
    I_START_FLAG = 0;
end

always@(posedge I_CLK)begin
    if(u_dut_SA_top.end_flag)begin
        $finish;
    end
end
endmodule
