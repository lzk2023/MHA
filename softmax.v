`timescale 1ns / 1ps
module softmax#(  
    parameter D_W = 16,
    parameter NUM = 16 //word number
)(
    input                    I_CLK  ,
    input                    I_RST_N,
    input                    I_START,//keep when calculate
    input      [D_W*NUM-1:0] I_DATA ,
    output reg               O_VLD  ,
    output reg [D_W*NUM-1:0] O_DATA 
    );
    localparam S_IDLE = 4'b0001;
    localparam S_ADD  = 4'b0010;
    localparam S_DIV  = 4'b0100;
    localparam S_END  = 4'b1000;
    wire [D_W-1:0]   data_e_x;
    wire             div_start = (state==S_DIV) ? 1'b1 : 1'b0;
    wire [D_W-1:0]   quotient;
    wire             div_vld ;
    //reg  [D_W-1+2:0] data_sum;//data_max extend
    reg  [D_W-1:0] data_sum;
    reg  [3:0]       state;
    reg  [5:0]       add_div_cnt;

    Exp_x u_exp_x_16bit(         //data format:16bit
    .I_X  (I_DATA[D_W*add_div_cnt +: D_W]) ,
    .O_EXP(data_e_x)
    );
    divider#(.D_W(D_W))u_divider(
    .I_CLK      (I_CLK    ),
    .I_RST_N    (I_RST_N  ),
    .I_DIV_START(div_start),//开始标志,计算时应保持
    .I_DIVIDEND (data_e_x ),//被除数,计算时应保持
    .I_DIVISOR  (data_sum ),//除数,计算时应保持
    .O_QUOTIENT (quotient ),//商
    .O_OUT_VLD  (div_vld)  
    );
    always@(posedge I_CLK or negedge I_RST_N)begin
        if(!I_RST_N)begin
            state       <= S_IDLE;
            data_sum    <= 0;
            add_div_cnt <= 0;
            O_VLD       <= 0;
            O_DATA      <= 0;
        end else begin
            case(state)
                S_IDLE :begin
                    data_sum <= 0;
                    add_div_cnt  <= 0;
                    O_VLD       <= 0;
                    O_DATA      <= 0;
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
                                O_DATA[D_W*add_div_cnt +: D_W] <= quotient;
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