`timescale 1ns/1ps

module tb_SA_wrapper_8bit(

);
localparam S   = 2;
localparam X_R = 2;

reg                      I_CLK        ;
reg                      I_RST_N      ;
reg                      I_START_FLAG ;
reg   [(S*X_R*8)-1:0]   I_X          ;
reg   [(S*64*8)-1:0]    I_W          ;
  
wire                     O_OUT_VLD    ;
wire  [(X_R*64*8)-1:0]  O_OUT        ;

reg [7:0] X_MATRIX [0:X_R-1][0:S-1] ;
reg [7:0] W_MATRIX [0:S-1][0:63]    ;

//integer k;
//integer l;
//generate 
//    for(genvar i=0;i<X_R;i=i+1)begin
//        for(genvar j=0;j<S;j=j+1)begin
//           assign I_X[(i*S+j)*8+:8]= X_MATRIX[i][j];
//        end
//    end
//endgenerate
//
//generate 
//    for(genvar i=0;i<S;i=i+1)begin
//        for(genvar j=0;j<64;j=j+1)begin
//           assign I_W[(i*64+j)*8+:8]= W_MATRIX[i][j];
//        end
//    end
//endgenerate

SA_wrapper_8bit#(
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
    $dumpfile("vcd_SA_wrapper_8bit.vcd");
    $dumpvars(0,tb_SA_wrapper_8bit);
end

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
    I_X          = {8'b0_10_00000,8'b0_01_10000,
                    8'b0_01_00000,8'b0_00_10000};
    I_W          = {8'b0_10_00000,8'b0_01_10000,{62{8'b0_00_00000}},
                    8'b0_01_00000,8'b0_00_10000,{62{8'b0_00_00000}}};
    #10
    I_START_FLAG = 0;
    #3000
    $finish;
end

//always@(posedge I_CLK)begin
//    if(u_dut_SA_top.end_flag)begin
//        $finish;
//    end
//end
endmodule
