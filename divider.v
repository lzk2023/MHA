`timescale 1ns/1ps
////////////////////////////////
//试商法除法器，位宽可自定义
////////////////////////////////
module divider#(
    parameter D_W = 16
)(
    input            I_CLK      ,
    input            I_RST_N    ,
    input            I_DIV_START,//开始标志,计算时应保持
    input  [D_W-1:0] I_DIVIDEND ,//被除数,计算时应保持
    input  [D_W-1:0] I_DIVISOR  ,//除数,计算时应保持
    output [D_W-1:0] O_QUOTIENT ,//商
    output           O_OUT_VLD    
);
localparam S_IDLE  = 4'b0001;
localparam S_START = 4'b0010;
localparam S_CALC  = 4'b0100;
localparam S_END   = 4'b1000;
localparam K_W     = $clog2(D_W-1+13);

wire              dividend_msb = I_DIVIDEND[D_W-1]  ;//被除数最高位
wire [D_W-2+13:0] dividend_pos = (dividend_msb ? (~I_DIVIDEND[D_W-2:0]+1):I_DIVIDEND[D_W-2:0]) << 13;//被除数绝对值
wire              divisor_msb  = I_DIVISOR[D_W-1]   ;//除数最高位
wire [D_W-2:0]    divisor_pos  = divisor_msb ? (~I_DIVISOR[D_W-2:0]+1):I_DIVISOR[D_W-2:0];//除数绝对值
wire [D_W-2+13:0]    div_sub;
wire [D_W-1+13:0] quotient_full;

reg [3:0]         state          ;
reg [D_W-2+13:0]  dividend_pos_ff;
reg [D_W-2+13:0]  quotient_ff    ;
reg [K_W-1:0]     k              ;

assign div_sub = dividend_pos_ff-divisor_pos;
assign quotient_full[D_W-2+13:0] = (quotient_ff == 0) ? 0 : 
                            quotient_full[D_W-1+13] ? ~quotient_ff+1 : quotient_ff;
assign quotient_full[D_W-1+13] = (quotient_ff == 0) ? 0 : dividend_msb ^ divisor_msb;
assign O_OUT_VLD = (state == S_END) ? 1'b1 : 1'b0;
assign O_QUOTIENT = {quotient_full[D_W-1+13],quotient_full[D_W-2:0]};
always@(posedge I_CLK or negedge I_RST_N)begin //FSM
    if(!I_RST_N)begin
        dividend_pos_ff <= 'b0   ;
        quotient_ff     <= 'b0   ;
        k               <= D_W-2+13 ;
        state           <= S_IDLE;
    end else begin
        case(state)
        S_IDLE :begin
            dividend_pos_ff <= 'b0  ;
            quotient_ff     <= 'b0  ;
            k               <= D_W-2+13;
            if(I_DIV_START)begin
                state <= S_START;
            end else begin
                state <= state;
            end
        end
        S_START:begin
            if(I_DIV_START)begin
                dividend_pos_ff <= {{(D_W-2+13){1'b0}},dividend_pos[k]};
                quotient_ff <= 'b0;
                state <= S_CALC;
            end else begin
                state <= S_IDLE;
            end
        end
        S_CALC :begin
            if(I_DIV_START)begin
                if(dividend_pos_ff >= divisor_pos)begin
                    quotient_ff[k] <= 1;
                    if(k != 0)begin
                        dividend_pos_ff <= {div_sub[D_W-3+13:0],dividend_pos[k-1]};
                        k <= k-1;
                    end else begin
                        state <= S_END;
                    end
                end else begin
                    quotient_ff[k] <= 0;
                    if(k != 0)begin
                        dividend_pos_ff <= {dividend_pos_ff[D_W-3+13:0],dividend_pos[k-1]};
                        k <= k-1;
                    end else begin
                        state <= S_END;
                    end
                end
            end else begin
                state <= S_IDLE;
            end
        end
        S_END  :begin
            dividend_pos_ff <= 'b0   ;
            quotient_ff     <= 'b0   ;
            k               <= D_W-2+13 ;
            state           <= S_IDLE;
        end
        default:begin
            dividend_pos_ff <= 'b0   ;
            quotient_ff     <= 'b0   ;
            k               <= D_W-2+13 ;
            state           <= S_IDLE;
        end
        endcase
    end
end
endmodule
