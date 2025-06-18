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

enum logic [2:0] {
    S_IDLE      = 3'b000,
    S_SELMAX    = 3'b001,
    S_CAL_EXP_M = 3'b011,
    S_SUM       = 3'b010,
    S_ADD       = 3'b110,
    S_DIV       = 3'b111,
    S_END       = 3'b101
} state;

logic        sel_max_ena;
logic        sel_max_vld;
logic [15:0] sel_16_max;
logic [15:0] data_x_max;
logic [15:0] data_e_x [0:NUM-1];
logic [23:0] data_e_x_sum_ff;//extend 8 bits,2^10 = 1024
logic [4:0]  cnt_sum;
logic        cnt    ;
logic [15:0] quotient [0:NUM-1];
logic  [15:0] data_sum;
logic  [1:0]  add_div_cnt;
logic  [NUM-1:0] div_vld ;
logic         div_vld_all;
logic         div_start;
logic [15:0] in_exp_16bit [0:NUM-1]; 

logic [15:0] exp_m_old_sub_m_new;
logic [15:0] exp_m_old_sub_m_new_ff;
logic [31:0] mul_out_48;

assign O_X_MAX = data_x_max;
assign O_EXP_SUM = data_e_x_sum_ff[23:8];

sel_max#(
    .D_W(16)
)u_sel_max(
    .I_CLK  (I_CLK      ),
    .I_RST_N(I_RST_N    ),
    .I_ENA  (sel_max_ena),
    .I_DATA (I_DATA     ),
    .O_VLD  (sel_max_vld),
    .O_MAX  (sel_16_max )
);

integer j;
integer k;

generate
    if(D_W == 8)begin
        for(genvar i=0;i<NUM;i=i+1)begin
            assign in_exp_16bit[i] = {I_DATA[i],8'b0} - {data_x_max,8'b0};
            safe_softmax_exp_pipe #(
                .D_W(16)
            )u_exp_x_16bit(         //data format:16bit
                .I_CLK  (I_CLK          ),
                .I_RST_N(I_RST_N        ),
                .I_X    (in_exp_16bit[i]),
                .O_EXP  (data_e_x[i]    )
            );

            divider #(
                .D_W           (D_W),
                .USE_IN_SOFTMAX(1  )
            )dut_divider(
                .I_CLK      (I_CLK           ),
                .I_RST_N    (I_RST_N         ),
                .I_DIV_START(div_start       ),//开始标志,计算时应保持
                .I_DIVIDEND (data_e_x[i]     ),//被除数,计算时应保持
                .I_DIVISOR  (data_sum        ),//除数,计算时应保持
                .O_QUOTIENT (quotient[i]     ),//商
                .O_VLD      (div_vld[i]      )  
            );
        end
    end else begin //D_W == 16
        for(genvar i=0;i<NUM;i=i+1)begin
            safe_softmax_exp_pipe #(
                .D_W(D_W)
            )u_exp_x_16bit(         //data format:16bit
                .I_CLK  (I_CLK          ),
                .I_RST_N(I_RST_N        ),
                .I_X  (I_DATA[i] - data_x_max) ,
                .O_EXP(data_e_x[i])
            );

            divider #(
                .D_W           (D_W),
                .USE_IN_SOFTMAX(1  )
            )dut_divider(
                .I_CLK      (I_CLK           ),
                .I_RST_N    (I_RST_N         ),
                .I_DIV_START(div_start       ),//开始标志,计算时应保持
                .I_DIVIDEND (data_e_x[i]     ),//被除数,计算时应保持
                .I_DIVISOR  (data_sum        ),//除数,计算时应保持
                .O_QUOTIENT (quotient[i]     ),//商
                .O_VLD      (div_vld[i]      )  
            );
        end
    end
endgenerate

assign div_vld_all = & div_vld;

safe_softmax_exp_pipe #(
    .D_W(16)
)u_exp_x_cal_li(         //data format:16bit
    .I_CLK   (I_CLK              ),
    .I_RST_N (I_RST_N            ),
    .I_X     (I_X_MAX - O_X_MAX  ) ,
    .O_EXP   (exp_m_old_sub_m_new)
);

mul_fast #(
    .IN_DW(16)
)u_mul_in_exp(
    .I_IN1     (I_EXP_SUM),
    .I_IN2     ({exp_m_old_sub_m_new_ff[15],8'b0,exp_m_old_sub_m_new_ff[14:8]}),
    .O_MUL_OUT (mul_out_48)
);
//DSP:assign mul_out_48 = $signed({I_EXP_SUM,8'b0}) * $signed({exp_m_old_sub_m_new_ff[15],8'b0,exp_m_old_sub_m_new_ff[14:0]});

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        state                  <= S_IDLE;
        sel_max_ena            <= 'b0   ;
        data_x_max             <= 'b0   ;
        div_start              <= 'b0   ;
        data_sum               <= 'b0   ;
        data_e_x_sum_ff        <= 'b0   ;
        exp_m_old_sub_m_new_ff <= 'b0   ;
        cnt_sum                <= 'b0   ;
        cnt                    <= 'b0   ;
        add_div_cnt            <= 'b0   ;
        O_VLD                  <= 'b0   ;
        O_DATA                 <= '{default:'b0};
    end else begin
        case(state)
            S_IDLE      :begin
                div_start <= 0;
                data_sum  <= 0;
                add_div_cnt  <= 0;
                O_VLD       <= 0;
                O_DATA      <= '{default:'b0};
                if(I_START)begin
                    state       <= S_SELMAX;
                    sel_max_ena <= 1'b1;
                end else begin
                    state <= state;
                end
            end
            S_SELMAX    :begin
                if(sel_max_vld)begin
                    state      <= S_CAL_EXP_M;
                    if($signed(sel_16_max) > $signed(I_X_MAX))begin
                        data_x_max <= sel_16_max;
                    end else begin
                        data_x_max <= I_X_MAX;
                    end
                end else begin
                    state       <= state;
                    sel_max_ena <= 1'b0 ;
                end
            end
            S_CAL_EXP_M :begin
                if(cnt == 1'b1)begin
                    state <= S_SUM;
                    cnt   <= 1'b0;
                    exp_m_old_sub_m_new_ff <= exp_m_old_sub_m_new;
                end else begin
                    state <= state;
                    cnt   <= 1'b1;
                end
            end
            S_SUM       :begin
                if(cnt_sum == 5'd16)begin
                    state   <= S_ADD;
                    data_e_x_sum_ff <= data_e_x_sum_ff + {data_e_x[cnt_sum-1][15],8'd0,data_e_x[cnt_sum-1][14:0]};
                    cnt_sum <= 'd0;
                end else if(cnt_sum == 5'd0)begin
                    state           <= state;
                    data_e_x_sum_ff <= {mul_out_48[31],mul_out_48[19:5],8'b0};
                    cnt_sum         <= cnt_sum + 1;
                end else begin
                    state   <= state;
                    data_e_x_sum_ff <= data_e_x_sum_ff + {data_e_x[cnt_sum-1][15],8'd0,data_e_x[cnt_sum-1][14:0]};
                    cnt_sum <= cnt_sum + 1;
                end
            end
            S_ADD       :begin
                if(I_START)begin
                    if(add_div_cnt < 1)begin
                        add_div_cnt <= add_div_cnt + 1;
                    end else begin
                        state <= S_DIV;
                        div_start <= 1;
                        add_div_cnt <= 0;
                        data_sum <= data_e_x_sum_ff[23:8];
                    end
                end else begin
                    state <= S_IDLE;
                    add_div_cnt <= 0;
                    data_sum <= 0;
                end
            end
            S_DIV       :begin
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
            S_END       :begin
                state <= S_IDLE;
                O_VLD <= 1;
            end
        endcase
    end
end
endmodule