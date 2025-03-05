`timescale 1ns / 1ps
module softmax#(                        //safe_softmax
    parameter D_W = 16,
    parameter NUM = 16 //word number
)(
    input  logic           I_CLK            ,
    input  logic           I_RST_N          ,
    input  logic           I_START          ,//keep when calculate
    input  logic [D_W-1:0] I_DATA [0:NUM-1] ,
    output logic           O_VLD            ,
    output logic [D_W-1:0] O_DATA [0:NUM-1]
);

enum logic [3:0] {
    S_IDLE = 4'b0001,
    S_ADD  = 4'b0010,
    S_DIV  = 4'b0100,
    S_END  = 4'b1000 
} state;

logic [D_W-1:0] data_e_x;
logic [D_W-1:0] quotient;
logic           div_vld ;
//reg  [D_W-1+2:0] data_sum;//data_max extend
logic  [D_W-1:0] data_sum;
logic  [15:0]    add_div_cnt;
logic           div_start;
logic [D_W-1:0] in_ex_sel;

assign div_start = (state==S_DIV) ? 1'b1 : 1'b0;
assign in_ex_sel = (add_div_cnt == NUM) ? 0 : I_DATA[add_div_cnt];

Exp_x u_exp_x_16bit(         //data format:16bit
.I_X  (in_ex_sel) ,
.O_EXP(data_e_x)
);

divider#(
    .D_W(D_W)
)u_divider(
.I_CLK      (I_CLK    ),
.I_RST_N    (I_RST_N  ),
.I_DIV_START(div_start),//开始标志,计算时应保持
.I_DIVIDEND (data_e_x ),//被除数,计算时应保持
.I_DIVISOR  (data_sum ),//除数,计算时应保持
.O_QUOTIENT (quotient ),//商
.O_OUT_VLD  (div_vld)  
);

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        state       <= S_IDLE;
        data_sum    <= 0;
        add_div_cnt <= 0;
        O_VLD       <= 0;
        O_DATA      <= '{default:'b0};
    end else begin
        case(state)
            S_IDLE :begin
                data_sum <= 0;
                add_div_cnt  <= 0;
                O_VLD       <= 0;
                O_DATA      <= '{default:'b0};
                if(I_START)begin
                    state    <= S_ADD;
                end else begin
                    state <= state;
                end
            end
            S_ADD  :begin
                if(I_START)begin
                    if(add_div_cnt < NUM)begin
                        add_div_cnt  <= add_div_cnt + 1;
                        data_sum <= $signed(data_sum) + $signed(data_e_x);
                    end else begin
                        state <= S_DIV;
                        add_div_cnt <= 0;
                    end
                end else begin
                    state <= S_IDLE;
                    add_div_cnt <= 0;
                    data_sum <= 0;
                end
            end
            S_DIV  :begin
                if(I_START)begin
                    if(add_div_cnt < NUM)begin
                        if(div_vld)begin
                            add_div_cnt <= add_div_cnt + 1;
                            O_DATA[add_div_cnt] <= quotient;
                        end else begin
                            add_div_cnt <= add_div_cnt;
                        end
                    end else begin
                        state <= S_END;
                        add_div_cnt <= 0;
                    end
                end else begin
                    state <= S_IDLE;
                    add_div_cnt <= 0;
                end
            end
            S_END  :begin
                state <= S_IDLE;
                O_VLD <= 1;
            end
        endcase
    end
end
endmodule