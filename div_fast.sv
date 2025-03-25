`timescale 1ns/1ps
module div_fast#(
    parameter D_W = 16,
    parameter FRAC_BIT = 13,    //fraction bits
    parameter USE_IN_SOFTMAX = 0
)(
    input  logic           I_CLK      ,
    input  logic           I_RST_N    ,
    input  logic           I_DIV_START,
    input  logic [D_W-1:0] I_DIVIDEND ,
    input  logic [D_W-1:0] I_DIVISOR  ,
    output logic [D_W-1:0] O_QUOTIENT ,
    output logic           O_VLD      
);
logic              dividend_msb;//被除数最高位
logic [D_W-2+FRAC_BIT:0] dividend_pos;//被除数绝对值 扩13位（小数位数量）
logic              divisor_msb;//除数最高位
logic [D_W-2:0] divisor_pos;//除数绝对值
logic [D_W-1+FRAC_BIT:0] quotient_full;
logic [D_W-2+FRAC_BIT:0] quotient;

logic [(D_W-1+FRAC_BIT)*2-1:0]      temp_dividend;
logic [(D_W-1)+(D_W-1+FRAC_BIT)-1:0]temp_divisor ;
logic [(D_W-1+FRAC_BIT)*2-1:0]      temp_dividend_ff;
logic [(D_W-1)+(D_W-1+FRAC_BIT)-1:0]temp_divisor_ff ;

logic [1:0] count;
enum logic [1:0]{
    S_IDLE = 2'b00,
    S_DIV  = 2'b01,
    S_OUT  = 2'b10
}state;

assign dividend_msb = I_DIVIDEND[D_W-1]  ;//被除数最高位
generate
    if(USE_IN_SOFTMAX == 1)begin
        assign dividend_pos = (dividend_msb ? (~I_DIVIDEND[D_W-2:0]+1):I_DIVIDEND[D_W-2:0]) << FRAC_BIT-5;//被除数绝对值 扩13-5位（小数位数量）
    end else begin
        assign dividend_pos = (dividend_msb ? (~I_DIVIDEND[D_W-2:0]+1):I_DIVIDEND[D_W-2:0]) << FRAC_BIT;//被除数绝对值 扩13位（小数位数量）
    end
endgenerate
assign divisor_msb  = I_DIVISOR[D_W-1]   ;//除数最高位
assign divisor_pos = (divisor_msb ? (~I_DIVISOR[D_W-2:0]+1):I_DIVISOR[D_W-2:0]);//除数绝对值
assign quotient = temp_dividend[D_W-2+FRAC_BIT:0];

assign quotient_msb = dividend_msb ^ divisor_msb;
assign quotient_full[D_W-2+FRAC_BIT:0] = (I_DIVIDEND==0) ? 0 : (quotient_msb ? ~quotient + 1 : quotient);
assign quotient_full[D_W-1+FRAC_BIT] = (I_DIVIDEND==0) ? 0 : quotient_msb;
assign O_QUOTIENT = {quotient_full[D_W-1+FRAC_BIT],quotient_full[D_W-2:0]};

integer i;
always_comb begin
    temp_dividend = temp_dividend_ff;
    temp_divisor  = temp_divisor_ff ;
    for(i=0;i<7;i=i+1)begin   //orginal: i<D_W-1+FRAC_BIT
        temp_dividend = {temp_dividend,1'b0};
        if(temp_dividend >= temp_divisor)begin
            temp_dividend = temp_dividend - temp_divisor + 1'b1;
        end else begin
            temp_dividend = temp_dividend;
        end
    end
end

always_ff @(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        state <= S_IDLE;
        temp_dividend_ff <= 0;
        temp_divisor_ff  <= 0;
        count <= 0;
        O_VLD <= 0;
    end else begin
        case(state)
            S_IDLE:begin
                if(I_DIV_START)begin
                    state <= S_DIV;
                    temp_dividend_ff <= {{(D_W-1+FRAC_BIT){1'b0}},dividend_pos};
                    temp_divisor_ff  <= {divisor_pos,{(D_W-1+FRAC_BIT){1'b0}}};
                    count <= 0;
                    O_VLD <= 0;
                end else begin
                    state <= S_IDLE;
                    temp_dividend_ff <= 0;
                    temp_divisor_ff  <= 0;
                    count <= 0;
                    O_VLD <= 0;
                end
            end
            S_DIV:begin
                if(I_DIV_START)begin
                    if(count < 2'b10)begin
                        state <= S_DIV;
                        temp_dividend_ff <= temp_dividend;
                        temp_divisor_ff  <= temp_divisor ;
                        count <= count + 1;
                        O_VLD <= 0;
                    end else begin                             //count > 2'b11
                        state <= S_OUT;
                        temp_dividend_ff <= temp_dividend;
                        temp_divisor_ff  <= temp_divisor ;
                        count <= 0;
                        O_VLD <= 1;
                    end
                end else begin
                    state <= S_IDLE;
                    temp_dividend_ff <= 0;
                    temp_divisor_ff  <= 0;
                    count <= 0;
                    O_VLD <= 0;
                end
            end
            S_OUT:begin
                state <= S_IDLE;
                temp_dividend_ff <= 0;
                temp_divisor_ff  <= 0;
                count <= 0;
                O_VLD <= 0;
            end
        endcase
    end
end
endmodule
