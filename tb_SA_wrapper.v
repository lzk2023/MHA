`timescale 1ns/1ps

module tb_SA_wrapper(

);
localparam S   = 2;
localparam X_R = 2;

reg                      I_CLK        ;
reg                      I_RST_N      ;
reg                      I_START_FLAG ;
reg   [(S*X_R*16)-1:0]   I_X          ;
reg   [(S*64*16)-1:0]    I_W          ;
  
wire                     O_OUT_VLD    ;
wire  [(X_R*64*16)-1:0]  O_OUT        ;

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

initial begin
    I_CLK        = 0;
    I_RST_N      = 0;
    I_START_FLAG = 0;
    I_X          = 0;
    I_W          = 0;
    #100
    I_RST_N      = 1;
    #100
    I_START_FLAG = 1;
    I_X          = {16'b0_10_00000_0000_0000,16'b0_01_10000_0000_0000,
                    16'b0_01_00000_0000_0000,16'b0_00_10000_0000_0000};
    I_W          = {16'b0_00_10000_0000_0000,16'b0_01_00000_0000_0000,{62{16'b0_01_00000_0000_0000}},
                    16'b0_01_10000_0000_0000,16'b0_10_00000_0000_0000,{62{16'b0_01_00000_0000_0000}}};
    #10
    I_START_FLAG = 0;
end

always@(posedge I_CLK)begin
    if(u_dut_SA_top.end_flag)begin
        $finish;
    end
end
endmodule