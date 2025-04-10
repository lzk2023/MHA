`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/11 09:16:18
// Design Name: 
// Module Name: Exp_x
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Exp_x #(
    parameter D_W = 16
)(
    input  logic [D_W-1:0] I_X    ,
    output logic [D_W-1:0] O_EXP
);
generate
    if(D_W == 8)begin
        logic [15:0] mul_out;
        logic [8:0] uivi;
        logic [7:0] uivi_ab;//absolute value
        logic [2:0] ui;
        logic [4:0] vi;
        logic        uivi_msb;
        logic [7:0] p_2_vi;
        logic [7:0] n_2_vi;
        mul_fast #(
            .IN_DW(8)
        )u_mul_in_loge(
            .I_IN1     (I_X      ),
            .I_IN2     (8'd46    ),//1.442695040889*2^5//
            .O_MUL_OUT (mul_out  )
        );
        assign uivi = mul_out[4] ? ({mul_out[15],mul_out[12:5]} + 1) : {mul_out[15],mul_out[12:5]};//[16:0]expand 1 bit
        assign uivi_ab = (uivi_msb) ? ~uivi[7:0] + 1'b1 : uivi[7:0];
        assign uivi_msb = uivi[8];
        assign ui = uivi_ab[7:5];
        assign vi = uivi_ab[4:0];
        always_comb begin
            if($signed(I_X) >= $signed(8'd44))begin//I_X >= ln4
                O_EXP = 8'b0_11_11111;
            end else begin
                if(!uivi_msb)begin
                    O_EXP = p_2_vi << ui;
                end else begin
                    O_EXP = n_2_vi >> ui;
                end
            end
        end
        lut_pos #(
            .D_W(D_W)
        )u_lut_p(
            .vi    (vi),
            .result(p_2_vi)
        );
        lut_neg #(
            .D_W(D_W)
        )u_lut_n(
            .vi    (vi),
            .result(n_2_vi)
        );
/////////////////////////////////////////////////////////////////////////////////////////////////////////        
//data_width == 16
/////////////////////////////////////////////////////////////////////////////////////////////////////////
    end else begin
        logic [31:0] mul_out;
        logic [16:0] uivi;
        logic [15:0] uivi_ab;//absolute value
        logic [2:0]  ui;
        logic [12:0] vi;
        logic        uivi_msb;
        logic [15:0] p_2_vi;
        logic [15:0] n_2_vi;
        mul_fast #(
            .IN_DW(16)
        )u_mul_in_loge(
            .I_IN1     (I_X      ),
            .I_IN2     (16'd11819),//1.442695040889*2^13//
            .O_MUL_OUT (mul_out  )
        );
        assign uivi = mul_out[12] ? ({mul_out[31],mul_out[28:13]} + 1) : {mul_out[31],mul_out[28:13]};//[16:0]expand 1 bit
        assign uivi_ab = (uivi_msb) ? ~uivi[15:0] + 1'b1 : uivi[15:0];
        assign uivi_msb = uivi[16];
        assign ui = uivi_ab[15:13];
        assign vi = uivi_ab[12:0];
        always_comb begin
            if($signed(I_X) >= $signed(16'd11357))begin//I_X >= ln4
                O_EXP = 16'b0_11_11111_1111_1111;
            end else begin
                if(!uivi_msb)begin
                    O_EXP = p_2_vi << ui;
                end else begin
                    O_EXP = n_2_vi >> ui;
                end
            end
        end
        lut_pos #(
            .D_W(D_W)
        )u_lut_p(
            .vi    (vi),
            .result(p_2_vi)
        );
        lut_neg #(
            .D_W(D_W)
        )u_lut_n(
            .vi    (vi),
            .result(n_2_vi)
        );
    end
endgenerate
endmodule