`timescale 1ns/1ps
module tb_div_fast();
localparam D_W = 16;
localparam FRAC_BIT = 13;
bit  [D_W-1:0] I_DIVIDEND ;
bit  [D_W-1:0] I_DIVISOR  ;
logic [D_W-1:0] O_QUOTIENT ;

bit           correct    ;
bit [D_W-1+13:0] q_compare_full;
bit [D_W-1:0] q_compare;
bit [D_W-1+13:0] dividend_full;
div_fast#(
    .D_W(D_W),
    .FRAC_BIT(FRAC_BIT)
)u_dut_div_fast(
    .I_DIVIDEND(I_DIVIDEND),
    .I_DIVISOR (I_DIVISOR ),
    .O_QUOTIENT(O_QUOTIENT)
);
assign dividend_full = I_DIVIDEND << 13;
assign q_compare_full = $signed(dividend_full)/$signed(I_DIVISOR);
assign q_compare = {q_compare_full[D_W-1+13],q_compare_full[D_W-2:0]};

initial begin
    I_DIVIDEND  = 0;
    I_DIVISOR   = 0;
    correct     = 0;
    #2000
    $finish;
end
initial begin
    while(1)begin
        #10;
        if(O_QUOTIENT == q_compare)begin
            correct = 1;
        end else begin
            correct = 0;
            $display("the quotient is incorrect! fail time is %0d",$time);
        end
        I_DIVIDEND  = $random;
        I_DIVISOR   = $random;
    end
end
endmodule
