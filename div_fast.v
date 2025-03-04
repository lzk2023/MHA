`timescale 1ns/1ps
module div_fast#(
    parameter D_W = 16
)(
    input  [D_W-1:0] I_DIVIDEND,
    input  [D_W-1:0] I_DIVISOR ,
    output [D_W-1:0] O_QUOTIENT
);
wire              dividend_msb = I_DIVIDEND[D_W-1]  ;//被除数最高位
wire [D_W-2+13:0] dividend_pos = (dividend_msb ? (~I_DIVIDEND[D_W-2:0]+1):I_DIVIDEND[D_W-2:0]) << 13;//被除数绝对值 扩13位（小数位数量）
wire              divisor_msb  = I_DIVISOR[D_W-1]   ;//除数最高位
wire [D_W-2:0] divisor_pos = (divisor_msb ? (~I_DIVISOR[D_W-2:0]+1):I_DIVISOR[D_W-2:0]);//除数绝对值
wire [D_W-1+13:0] quotient_full;
wire [D_W-2+13:0] quotient = temp_dividend[D_W-2+13:0];

reg [(D_W-1+13)*2-1:0] temp_dividend;
reg [(D_W-1)+(D_W-1+13)-1:0]temp_divisor;

assign quotient_msb = dividend_msb ^ divisor_msb;
assign quotient_full[D_W-2+13:0] = (I_DIVIDEND==0) ? 0 : (quotient_msb ? ~quotient + 1 : quotient);
assign quotient_full[D_W-1+13] = (I_DIVIDEND==0) ? 0 : quotient_msb;
assign O_QUOTIENT = {quotient_full[D_W-1+13],quotient_full[D_W-2:0]};

integer i;
always@(*)begin
    temp_dividend = {{(D_W-1+13){1'b0}},dividend_pos};
    temp_divisor = {divisor_pos,{(D_W-1+13){1'b0}}};
    for(i=0;i<D_W-1+13;i=i+1)begin
        temp_dividend = {temp_dividend,1'b0};
        if(temp_dividend >= temp_divisor)begin
            temp_dividend = temp_dividend - temp_divisor + 1'b1;
        end else begin
            temp_dividend = temp_dividend;
        end
    end
end
endmodule
