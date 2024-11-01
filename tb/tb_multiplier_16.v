`timescale 1ns/1ps

module tb_multiplier_16(

);
reg         I_CLK      ;
reg         I_RST_N    ;
reg         I_VLD      ;
reg  [15:0] I_M1       ;
reg  [15:0] I_M2       ;
wire        O_VLD      ;
wire [15:0] O_PRODUCT  ;
wire [31:0] PROD_COMP_32  ;
wire [15:0] PROD_COMP_16  ;
wire correct_flag      ;
multiplier_16 u_dut_mul_16(
.I_CLK    (I_CLK    ),
.I_RST_N  (I_RST_N  ),
.I_VLD    (I_VLD    ),//input valid
.I_M1     (I_M1     ),//multiplicand(被乘数)
.I_M2     (I_M2     ),//multiplier  (乘数)
.O_VLD    (O_VLD    ),//output valid
.O_PRODUCT(O_PRODUCT) //product     (积)
);

always #5 I_CLK = ~I_CLK;
initial begin
    $dumpfile("./vcdfiles/tb_multiplier_16.vcd");
    $dumpvars(0,tb_multiplier_16);
end

initial begin
    I_CLK     = 0;
    I_RST_N   = 0;
    I_VLD     = 0;
    I_M1      = 0;
    I_M2      = 0;
    #50
    I_RST_N   = 1;
    #50
    I_M1      = $random;
    I_M2      = $random;
    PROD_COMP_32 = $signed(I_M1) * $signed(I_M2);
    PROD_COMP_16 = {PROD_COMP_32[31],PROD_COMP_32[27:13]}
    if(O_VLD & O_PRODUCT == PROD_COMP_16)begin
        correct_flag = 1;
    end else begin
        correct_flag = 0;
    end
    #100
    $finish;
end

endmodule
