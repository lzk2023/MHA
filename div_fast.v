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
wire [(D_W-2)*2+13-1:0] divisor_pos  = (divisor_msb ? (~I_DIVISOR[D_W-2:0]+1):I_DIVISOR[D_W-2:0]) << (D_W-3+13);//除数绝对值
wire [D_W-1+13:0] quotient_full;
reg [(D_W-2)*2+13-1:0] divisor_pos_shift;
reg [D_W-2+13:0] quotient;
reg [D_W-2+13:0] remainder;

assign quotient_msb = dividend_msb ^ divisor_msb;
assign quotient_full[D_W-2+13:0] = (I_DIVIDEND==0) ? 0 : (quotient_msb ? ~quotient + 1 : quotient);
assign quotient_full[D_W-1+13] = (I_DIVIDEND==0) ? 0 : quotient_msb;
assign O_QUOTIENT = {quotient_full[D_W-1+13],quotient_full[D_W-2:0]};

integer i;
always@(*)begin
    remainder = dividend_pos;
    for(i=D_W-2+13;i>=0;i=i-1)begin
        if(i>0)begin
            if(remainder - divisor_pos_shift > 0)begin
                quotient[i] = 1;
                remainder = remainder-divisor_pos_shift;
            end else begin
                quotient[i] = 0;
                remainder = remainder;
            end
            divisor_pos_shift = divisor_pos_shift >> 1;
        end else begin
            if(remainder - divisor_pos_shift > 0)begin
                quotient[i] = 1;
                remainder = remainder-divisor_pos_shift;
            end else begin
                quotient[i] = 0;
                remainder = remainder;
            end
            divisor_pos_shift = divisor_pos_shift >> 1;
        end
    end
end
endmodule
