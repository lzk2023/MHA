`timescale 1ns/1ps
////////////////////////////////
//试商法除法器，位宽可自定义（正数）
////////////////////////////////
module divider_pos#(
    parameter D_W            = 16,
    parameter USE_IN_SOFTMAX = 0
)(
    input  logic           I_CLK      ,
    input  logic           I_RST_N    ,
    input  logic           I_DIV_START,//开始标志,计算时应保持
    input  logic [D_W-1:0] I_DIVIDEND ,//被除数,计算时应保持
    input  logic [D_W-1:0] I_DIVISOR  ,//除数,计算时应保持
    output logic [D_W-1:0] O_QUOTIENT ,//商
    output logic           O_VLD    
);
localparam K_W     = $clog2(D_W-1+13);
enum logic [3:0] {
    S_IDLE  = 4'b0001,
    S_START = 4'b0010,
    S_CALC  = 4'b0100,
    S_END   = 4'b1000 
} state;

logic [D_W-2+13:0] dividend_pos ;
logic [D_W-2:0]    divisor_pos  ;
logic [D_W-2+13:0] div_sub;


logic [D_W-2+13:0]  dividend_pos_ff;
logic [D_W-2+13:0]  quotient_ff    ;
logic [K_W-1:0]     k              ;

generate
    if(USE_IN_SOFTMAX == 0)begin
        assign dividend_pos = (I_DIVIDEND[D_W-2:0]) << 13;//被除数绝对值
    end else begin
        assign dividend_pos = (I_DIVIDEND[D_W-2:0]) << 13 - 8;//被除数绝对值
    end
endgenerate
assign divisor_pos = I_DIVISOR[D_W-2:0];//除数绝对值

assign div_sub = dividend_pos_ff-divisor_pos;
assign O_VLD = (state == S_END) ? 1'b1 : 1'b0;
assign O_QUOTIENT = {1'b0,quotient_ff[D_W-2:0]};
always_ff@(posedge I_CLK or negedge I_RST_N)begin //FSM
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
