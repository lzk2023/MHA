`timescale 1ns / 1ps
module safe_softmax#(                        //safe_softmax
    parameter D_W = 8,
    parameter NUM = 16 //word number
)(
    input  logic           I_CLK            ,
    input  logic           I_RST_N          ,
    input  logic           I_START          ,//keep when calculate
    input  logic [D_W-1:0] I_DATA [0:NUM-1] ,
    input  logic [D_W-1:0] I_X_MAX          ,
    input  logic [15:0]    I_EXP_SUM        ,//data:0_000_0000_0000_0000
    output logic [D_W-1:0] O_X_MAX          ,
    output logic [15:0]    O_EXP_SUM        ,//data:0_000_0000_0000_0000 1bit signal,10bits int,5bits frac
    output logic           O_VLD            ,
    output logic [D_W-1:0] O_DATA [0:NUM-1]
);

enum logic [3:0] {
    S_IDLE = 4'b0001,
    S_ADD  = 4'b0010,
    S_DIV  = 4'b0100,
    S_END  = 4'b1000 
} state;

logic [15:0] sel_16_max;
logic [15:0] data_x_max;
logic [15:0] data_e_x [0:NUM-1];
logic [15:0] data_e_x_ff [0:NUM-1];
logic [23:0] data_e_x_ff_sum;//extend 8 bits,2^10 = 1024
logic [15:0] quotient [0:NUM-1];
//reg  [D_W-1+2:0] data_sum;//data_max extend
logic  [15:0] data_sum;
logic  [1:0]  add_div_cnt;
logic  [NUM-1:0] div_vld ;
logic         div_vld_all;
logic         div_start;
logic [15:0] in_exp_16bit [0:NUM-1]; 

logic [15:0] exp_m_old_sub_m_new;
logic [47:0] mul_out_47;

assign O_X_MAX = data_x_max;
assign O_EXP_SUM = data_e_x_ff_sum[23:8];

sel_max#(
    .D_W(16)
)u_sel_max(
    .I_DATA(I_DATA),
    .O_MAX (sel_16_max)
);

assign data_x_max = ($signed(sel_16_max) > $signed(I_X_MAX)) ? sel_16_max : I_X_MAX;

integer j;
integer k;

generate
    if(D_W == 8)begin
        for(genvar i=0;i<NUM;i=i+1)begin
            assign in_exp_16bit[i] = {I_DATA[i],8'b0} - {data_x_max,8'b0};
            safe_softmax_exp #(
                .D_W(16)
            )u_exp_x_16bit(         //data format:16bit
                .I_X  (in_exp_16bit[i]) ,
                .O_EXP(data_e_x[i])
            );

            div_fast #(
                .D_W     (16),
                .FRAC_BIT(13),   //fraction bits
                .USE_IN_SOFTMAX(1)
            )u_fast_divider_8bit(
                .I_CLK      (I_CLK    ),
                .I_RST_N    (I_RST_N  ),
                .I_DIV_START(div_start),//开始标志,计算时应保持
                .I_DIVIDEND (data_e_x[i]),
                .I_DIVISOR  (data_sum   ),
                .O_QUOTIENT (quotient[i]),
                .O_VLD      (div_vld[i]) 
            );
        end
    end else begin //D_W == 16
        for(genvar i=0;i<NUM;i=i+1)begin
            safe_softmax_exp #(
                .D_W(D_W)
            )u_exp_x_16bit(         //data format:16bit
                .I_X  (I_DATA[i] - data_x_max) ,
                .O_EXP(data_e_x[i])
            );

            div_fast #(
                .D_W     (D_W),
                .FRAC_BIT(13),    //fraction bits
                .USE_IN_SOFTMAX(1)
            )u_fast_divider_16bit(
                .I_CLK      (I_CLK    ),
                .I_RST_N    (I_RST_N  ),
                .I_DIV_START(div_start),//开始标志,计算时应保持
                .I_DIVIDEND (data_e_x[i]),
                .I_DIVISOR  (data_sum   ),
                .O_QUOTIENT (quotient[i]),
                .O_VLD      (div_vld[i]) 
            );
        end
    end
endgenerate

assign div_vld_all = & div_vld;

safe_softmax_exp #(
    .D_W(16)
)u_exp_x_cal_li(         //data format:16bit
    .I_X  (I_X_MAX - O_X_MAX) ,
    .O_EXP(exp_m_old_sub_m_new)
);

//mul_fast #(
//    .IN_DW(24)
//)u_mul_in_exp(
//    .I_IN1     ({I_EXP_SUM,8'b0}),
//    .I_IN2     ({exp_m_old_sub_m_new[15],8'b0,exp_m_old_sub_m_new[14:0]}),
//    .O_MUL_OUT (mul_out_47)
//);
assign mul_out_47 = $signed({I_EXP_SUM,8'b0}) * $signed({exp_m_old_sub_m_new[15],8'b0,exp_m_old_sub_m_new[14:0]});
always_comb begin
    data_e_x_ff_sum = {mul_out_47[47],mul_out_47[35:13]};//li_new = li_old*e^(m_i-1 - m_i) + e^(x-mi)
    for(j=0;j<NUM;j=j+1)begin
        data_e_x_ff_sum = data_e_x_ff_sum + {data_e_x_ff[j][15],8'd0,data_e_x_ff[j][14:0]};//opt timing
    end
end

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        state       <= S_IDLE;
        div_start   <= 0;
        data_sum    <= 0;
        data_e_x_ff <= '{default:'b0};
        add_div_cnt <= 0;
        O_VLD       <= 0;
        O_DATA      <= '{default:'b0};
    end else begin
        case(state)
            S_IDLE :begin
                div_start <= 0;
                data_sum  <= 0;
                data_e_x_ff <= '{default:'b0};
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
                    if(add_div_cnt < 1)begin
                        add_div_cnt <= add_div_cnt + 1;
                        data_e_x_ff <= data_e_x;
                    end else begin
                        state <= S_DIV;
                        div_start <= 1;
                        add_div_cnt <= 0;
                        data_sum <= data_e_x_ff_sum[23:8];
                    end
                end else begin
                    state <= S_IDLE;
                    add_div_cnt <= 0;
                    data_sum <= 0;
                    data_e_x_ff <= '{default:0};
                end
            end
            S_DIV  :begin
                if(I_START)begin
                    if(add_div_cnt < 1)begin
                        if(div_vld_all)begin
                            add_div_cnt <= add_div_cnt + 1;
                            O_DATA <= quotient;//
                        end else begin
                            add_div_cnt <= add_div_cnt;
                        end
                    end else begin
                        state <= S_END;
                        div_start <= 0;
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