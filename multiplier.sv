`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: lzk
// 
// Create Date: 2024/10/31 10:05:11
// Design Name: 
// Module Name: multiplier
// Project Name: MHA
// Target Devices: 
// Tool Versions: 
// Description: pipeline multiplier for 16 bits,

// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module multiplier#(
    parameter D_W = 16
)(
    input  logic            I_CLK      ,
    input  logic            I_ASYN_RSTN,
    input  logic            I_SYNC_RSTN,
    input  logic            I_VLD      ,//input valid
    input  logic [D_W-1:0]  I_M1       ,//multiplicand(被乘数)
    input  logic [D_W-1:0]  I_M2       ,//multiplier  (乘数)
    output logic            O_VLD      ,//output valid
    output logic [D_W-1:0]  O_PRODUCT   //product     (积)
);

enum logic [2:0] {
    S_IDLE = 3'b001,
    S_CAL  = 3'b010,
    S_END  = 3'b100
} state;

logic [D_W*2-1:0]       prod_shift ;
logic [D_W*2-1:0]       prod_32    ;
logic [D_W*2-1:0]       m1_reg_sft;


logic [D_W*2-1:0]       product_reg;//16 bits * 16bits
logic [D_W*2-1:0]       m1_reg     ;
logic [D_W-2:0]         m2_reg     ;//reg input(absolute value)  寄存输入数据
logic                   m2_msb     ;
logic [$clog2(D_W)-1:0] mul_cycle  ;//
generate
    if(D_W == 16)begin
        assign O_PRODUCT = {prod_32[31],prod_32[27:13]};
    end else if(D_W == 8)begin
        assign O_PRODUCT = {prod_32[15],prod_32[11:5]};
    end 
endgenerate

assign prod_32 = product_reg - (m2_msb ? m1_reg : 0);//select output 选择输出
always_ff@(posedge I_CLK or negedge I_ASYN_RSTN)begin
    if(!I_ASYN_RSTN | !I_SYNC_RSTN)begin
        state      <= S_IDLE;
        m1_reg     <= 'b0;
        m2_reg     <= 'b0;
        m2_msb     <= 'b0;
        mul_cycle  <=   0;
        O_VLD      <=   0;
    end else begin
        case(state)
            S_IDLE : begin
                if(I_VLD)begin
                    state      <= S_CAL;
                    m1_reg     <= {{D_W{I_M1[D_W-1]}},I_M1};
                    m2_reg     <= I_M2[D_W-2:0]  ;
                    m2_msb     <= I_M2[D_W-1]    ;
                    mul_cycle  <=           0    ;
                    O_VLD      <= 0;
                end else begin
                    state      <= state;
                    m1_reg     <= 'b0;
                    m2_reg     <= 'b0;
                    m2_msb     <= 'b0;
                    mul_cycle  <=   0;
                    O_VLD      <=   0;
                end
            end
            S_CAL  : begin
                if(mul_cycle < D_W-2)begin
                    state      <= state;
                    m1_reg     <= m1_reg_sft   ;                          
                    m2_reg     <= m2_reg >> 1   ;
                    m2_msb     <= m2_msb        ;
                    mul_cycle  <= mul_cycle + 1 ;
                end else begin
                    state      <= S_END;
                    O_VLD      <= 1;
                    m1_reg     <= m1_reg_sft   ;                          
                    m2_reg     <= m2_reg >> 1   ;
                    m2_msb     <= m2_msb        ;
                    mul_cycle  <= mul_cycle + 1 ;
                end 
            end
            S_END  : begin
                state     <= S_IDLE;
                m1_reg    <= 'b0;
                m2_reg    <= 'b0;
                m2_msb    <= 'b0;
                mul_cycle <=   0;
                O_VLD     <= 0;
            end
        endcase
    end
end

always_ff@(posedge I_CLK or negedge I_ASYN_RSTN)begin
    if(!I_ASYN_RSTN | !I_SYNC_RSTN)begin
        product_reg <= 'b0;
    end else if(state == S_CAL)begin
        product_reg <= product_reg + prod_shift;  //add shift 累加移位结果   
    end else begin
        product_reg <= 'b0;
    end
end
mul_shift #(
    .D_W(D_W)
)u_mul_shift1(
    .I_IN1(m1_reg),
    .I_IN2(m2_reg[0]),
    .O_OUT(prod_shift),
    .O_SFT1(m1_reg_sft)
    );
endmodule