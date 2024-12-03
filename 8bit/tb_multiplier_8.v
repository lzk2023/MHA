`timescale 1ns/1ps

module tb_multiplier_8(

);
reg  [7:0] I_M1       ;
reg  [7:0] I_M2       ;
wire [7:0] O_PRODUCT  ;
wire [15:0] PROD_COMP_16  ;
wire [7:0] PROD_COMP_8  ;
reg correct_flag      ;
multiplier_8 u_dut_mul8(
    .I_IN1   (I_M1),
    .I_IN2   (I_M2),
    .O_OUT_8 (O_PRODUCT),
    .O_OUT_16()
);

initial begin
    $dumpfile("vcd_mul8.vcd");
    $dumpvars(0,tb_multiplier_8);
end

initial begin
    I_M1      = 0;
    I_M2      = 0;
    #100
    while(1)begin
    I_M1      = $random;
    I_M2      = $random;
    #10
    if($time > 1000) begin
        $finish;
    end
    end
    ///////////////
    
end

assign PROD_COMP_16 = $signed(I_M1) * $signed(I_M2);
assign PROD_COMP_8  = {PROD_COMP_16[15],PROD_COMP_16[13:7]};
always@(*)begin
    if(O_PRODUCT == PROD_COMP_8)begin
        correct_flag = 1;
    end else begin
        correct_flag = 0;
    end
end
//always@(posedge I_CLK)begin
//    if(O_VLD & O_PRODUCT != PROD_COMP_16)begin
//        $finish;
//    end
//end
endmodule
