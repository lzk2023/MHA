`timescale 1ns/1ps

module tb_multiplier(

);
bit          I_CLK         ;
bit          I_ASYN_RSTN   ;
bit          I_SYNC_RSTN   ;
bit          I_VLD         ;
bit  [15:0]  I_M1          ;
bit  [15:0]  I_M2          ;
bit  [15:0]  I_M1_C        ;
bit  [15:0]  I_M2_C        ;
logic        O_VLD         ;
logic [15:0] O_PRODUCT     ;
logic [31:0]   PROD_COMP_32  ;
logic [15:0]   PROD_COMP_16  ;
bit          correct_flag  ;
multiplier u_dut_mul_16(
    .I_CLK      (I_CLK     ),
    .I_ASYN_RSTN(I_ASYN_RSTN),
    .I_SYNC_RSTN(I_SYNC_RSTN),
    .I_VLD      (I_VLD     ),//input valid
    .I_M1       (I_M1      ),//multiplicand(被乘数)
    .I_M2       (I_M2      ),//multiplier  (乘数)
    .O_VLD      (O_VLD     ),//output valid
    .O_PRODUCT  (O_PRODUCT ) //product     (积)
);

always #5 I_CLK = ~I_CLK;
//initial begin
//    $dumpfile("tb_mul16.vcd");
//    $dumpvars(0,tb_multiplier_16);
//end

initial begin
    I_CLK       = 0;
    I_ASYN_RSTN = 0;
    I_SYNC_RSTN = 1;
    I_VLD       = 0;
    I_M1        = 0;
    I_M2        = 0;
    I_M1_C      = 0;
    I_M2_C      = 0;
    #50
    I_ASYN_RSTN = 1;
    #50
    while(1)begin
        #1
        I_M1      = $random;
        I_M2      = $random;
        I_VLD     = 1;
        #10
        I_M1_C    = I_M1;
        I_M2_C    = I_M2;
        @(posedge O_VLD);
    end
end

initial begin
    #10000
    $finish;
end

assign PROD_COMP_32 = $signed(I_M1_C) * $signed(I_M2_C);
assign PROD_COMP_16 = {PROD_COMP_32[31],PROD_COMP_32[27:13]};
always@(posedge O_VLD)begin
    #1
    assert (O_PRODUCT == PROD_COMP_16) $display("the mul value is right!");
    else $error("the mul value is incorrect! O_PRODUCT = %0h,compare = %0h",O_PRODUCT,PROD_COMP_16);
end

always@(posedge I_CLK)begin
    if(O_VLD)begin
        if(O_PRODUCT == PROD_COMP_16)begin
            correct_flag <= 1;
        end else begin
            correct_flag <= 0;
        end
    end else begin
        correct_flag <= correct_flag;
    end
end
endmodule
