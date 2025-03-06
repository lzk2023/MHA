`timescale 1ns / 1ps
module softmax#(                        //safe_softmax
    parameter D_W = 8,
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

logic [D_W-1:0] data_e_x [0:NUM-1];
logic [D_W-1:0] data_e_x_ff [0:NUM-1];
logic [D_W-1:0] data_e_x_ff_sum;
logic [D_W-1:0] quotient [0:NUM-1];
//reg  [D_W-1+2:0] data_sum;//data_max extend
logic  [D_W-1:0] data_sum;
logic  [1:0]    add_div_cnt;

integer j;

//divider#(
//    .D_W(D_W)
//)u_divider(
//    .I_CLK      (I_CLK    ),
//    .I_RST_N    (I_RST_N  ),
//    .I_DIV_START(div_start),//开始标志,计算时应保持
//    .I_DIVIDEND (data_e_x ),//被除数,计算时应保持
//    .I_DIVISOR  (data_sum ),//除数,计算时应保持
//    .O_QUOTIENT (quotient ),//商
//    .O_OUT_VLD  (div_vld)  
//);
generate
    if(D_W == 8)begin
        for(genvar i=0;i<NUM;i=i+1)begin
            Exp_x #(
                .D_W(D_W)
            )u_exp_x_8bit(         //data format:16bit
                .I_X  (I_DATA[i]) ,
                .O_EXP(data_e_x[i])
            );

            div_fast #(
                .D_W     (D_W),
                .FRAC_BIT(5)    //fraction bits
            )u_fast_divider_8bit(
                .I_DIVIDEND(data_e_x[i]),
                .I_DIVISOR (data_sum),
                .O_QUOTIENT(quotient[i])
            );
        end
    end else begin //D_W == 16
        for(genvar i=0;i<NUM;i=i+1)begin
            Exp_x #(
                .D_W(D_W)
            )u_exp_x_16bit(         //data format:16bit
                .I_X  (I_DATA[i]) ,
                .O_EXP(data_e_x[i])
            );

            div_fast #(
                .D_W     (D_W),
                .FRAC_BIT(13)    //fraction bits
            )u_fast_divider_16bit(
                .I_DIVIDEND(data_e_x[i]),
                .I_DIVISOR (data_sum),
                .O_QUOTIENT(quotient[i])
            );
        end
    end
endgenerate

always_comb begin
    data_e_x_ff_sum = 0;
    for(j=0;j<NUM;j=j+1)begin
        data_e_x_ff_sum = data_e_x_ff_sum + data_e_x_ff[j];//opt timing
    end
end

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        state       <= S_IDLE;
        data_sum    <= 0;
        data_e_x_ff <= '{default:'b0};
        add_div_cnt <= 0;
        O_VLD       <= 0;
        O_DATA      <= '{default:'b0};
    end else begin
        case(state)
            S_IDLE :begin
                data_sum <= 0;
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
                        add_div_cnt <= 0;
                        data_sum <= data_e_x_ff_sum;
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
                        //if(div_vld)begin
                        if(1)begin
                            add_div_cnt <= add_div_cnt + 1;
                            O_DATA <= quotient;
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