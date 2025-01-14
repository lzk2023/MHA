`timescale 1ns/1ps
module tb_divider();
localparam D_W = 16;
logic           I_CLK      ;
logic           I_RST_N    ;
logic           I_DIV_START;
logic [D_W-1:0] I_DIVIDEND ;
logic [D_W-1:0] I_DIVISOR  ;
logic [D_W-1:0] O_QUOTIENT ;
logic           O_OUT_VLD  ;

logic           correct    ;
logic [D_W-1:0] q_compare  ;
divider #(
    .D_W (D_W)
)dut_divider(
    .I_CLK      (I_CLK      ),
    .I_RST_N    (I_RST_N    ),
    .I_DIV_START(I_DIV_START),//�?始标�?,计算时应保持
    .I_DIVIDEND (I_DIVIDEND ),//被除�?,计算时应保持
    .I_DIVISOR  (I_DIVISOR  ),//除数,计算时应保持
    .O_QUOTIENT (O_QUOTIENT ),//�?
    .O_OUT_VLD  (O_OUT_VLD  )  
);
assign q_compare = $signed(I_DIVIDEND)/$signed(I_DIVISOR);
//initial begin
//    $dumpfile("vcd_divider.vcd");
//    $dumpvars(0,tb_divider);
//end
initial begin
    forever #5 I_CLK = ~I_CLK;
end
initial begin
    I_CLK       = 0;
    I_RST_N     = 0;
    I_DIV_START = 0;
    I_DIVIDEND  = 0;
    I_DIVISOR   = 0;
    correct     = 0;
    #100
    I_RST_N     = 1;
    I_DIV_START = 1;
    I_DIVIDEND  = $random;
    I_DIVISOR   = $random;
    #20000
    $finish;
end
initial begin
    while(1)begin
        wait(O_OUT_VLD == 1);
        I_DIV_START = 0;
        #1;
        if(O_QUOTIENT == q_compare)begin
            correct = 1;
        end else begin
            correct = 0;
            $display("the quotient is incorrect! fail time is %0d",$time);
        end
        wait(O_OUT_VLD == 0);
        I_DIV_START = 1;
        I_DIVIDEND  = $random;
        I_DIVISOR   = $random;
    end
end
endmodule
