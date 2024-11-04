`timescale 1ns/1ps

module tb_multiplier_16(

);
reg         I_CLK      ;
reg         I_RST_N    ;
reg         I_VLD      ;
reg  [15:0] I_M1       ;
reg  [15:0] I_M2       ;
reg  [15:0] I_M1_C     ;
reg  [15:0] I_M2_C     ;
wire        O_VLD      ;
wire        O_MUL_BUSY ;
wire [15:0] O_PRODUCT  ;
wire [31:0] PROD_COMP_32  ;
wire [15:0] PROD_COMP_16  ;
reg correct_flag      ;
multiplier_16 u_dut_mul_16(
.I_CLK    (I_CLK    ),
.I_RST_N  (I_RST_N  ),
.I_VLD    (I_VLD    ),//input valid
.I_M1     (I_M1     ),//multiplicand(琚箻鏁?)
.I_M2     (I_M2     ),//multiplier  (涔樻暟)
.O_VLD    (O_VLD    ),//output valid
.O_MUL_BUSY(O_MUL_BUSY),
.O_PRODUCT(O_PRODUCT) //product     (绉?)
);

always #5 I_CLK = ~I_CLK;
//initial begin
//    $dumpfile("tb_mul16.vcd");
//    $dumpvars(0,tb_multiplier_16);
//end

initial begin
    I_CLK     = 0;
    I_RST_N   = 0;
    I_VLD     = 0;
    I_M1      = 0;
    I_M2      = 0;
    I_M1_C    = 0;
    I_M2_C    = 0;
    #50
    I_RST_N   = 1;
    #50
    
    while(1)begin
    I_M1      = $random;
    I_M2      = $random;
    I_M1_C    = I_M1;
    I_M2_C    = I_M2;
    I_VLD     = 1;
    #10
    I_M1      = 0;
    I_M2      = 0;
    I_VLD     = 0;
    #45
    I_M1_C    = 0;
    I_M2_C    = 0;
    #10;
    end
    ///////////////
    
end

//initial begin
//    #10000
//    $finish;
//end
assign PROD_COMP_32 = $signed(I_M1_C) * $signed(I_M2_C);
assign PROD_COMP_16 = {PROD_COMP_32[31],PROD_COMP_32[27:13]};
always@(*)begin
    if(O_VLD & O_PRODUCT == PROD_COMP_16)begin
        correct_flag <= 1;
    end else begin
        correct_flag <= 0;
    end
end
always@(posedge I_CLK)begin
    if(O_VLD & O_PRODUCT != PROD_COMP_16)begin
        $finish;
    end
end
endmodule