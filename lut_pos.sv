`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/18 09:33:12
// Design Name: 
// Module Name: lut_pos
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


module lut_pos#(
    parameter D_W = 16        //support data width = 16 or 8 bits
)(
    input  logic [D_W-4:0]   vi      ,
    output logic [D_W-1:0]  result  
);
generate 
    if(D_W == 8)begin
        localparam ln_2 = 6'd22;
        localparam ln_2_mul_sqrt2 = 6'd31;
        logic [11:0] mul_2_full;
        logic [11:0] mul_3_full;
        logic [7:0]  mul_2;//    ln2*x
        logic [7:0]  mul_3;//    sqrt(2)*ln2*x

        //assign mul_2_full = ln_2 * vi;
        assign mul_2 = {3'b000,mul_2_full[9:5]};
        //assign mul_3_full = ln_2_mul_sqrt2 * vi;
        assign mul_3 = {3'b000,mul_3_full[9:5]};
        mul_fast #(
            .IN_DW(6)
        )u_mul_1(
            .I_IN1     ({1'b0,vi}),
            .I_IN2     (ln_2 ),
            .O_MUL_OUT (mul_2_full)//assign mul_2_full = ln_2 * vi;
        );

        mul_fast #(
            .IN_DW(6)
        )u_mul_2(
            .I_IN1     ({1'b0,vi}),
            .I_IN2     (ln_2_mul_sqrt2 ),//assign mul_3_full = ln_2_mul_sqrt2 * vi;
            .O_MUL_OUT (mul_3_full)
        );

        always_comb begin
            if(vi <= 6'd8) begin    //2^x = 1 + ln2*x                         (-0.25<x<0.25)
                result <= 8'b0_01_00000 + mul_2;
            end
            else if(vi > 6'd8 & vi < 6'b0_11111) begin//2^x = sqrt(2) + sqrt(2)*ln2*(x-0.5)     (0.25<x<1)
                result <= 8'd30 + mul_3;
            end
            else begin
                result <= 8'b0_01_00000; //error
            end
        end
/////////////////////////////////////////////////////////////////////////////////////////////////////////        
//data_width == 16
/////////////////////////////////////////////////////////////////////////////////////////////////////////
    end else begin
        localparam ln_2 = 14'd5678;
        localparam ln_2_mul_sqrt2 = 14'd8030;
        logic [25:0] mul_2_full;
        logic [25:0] mul_3_full;
        logic [15:0] mul_2;//    ln2*x
        logic [15:0] mul_3;//    sqrt(2)*ln2*x

        //assign mul_2_full = ln_2 * vi;
        assign mul_2 = {3'b000,mul_2_full[25:13]};
        //assign mul_3_full = ln_2_mul_sqrt2 * vi;
        assign mul_3 = {3'b000,mul_3_full[25:13]};
        mul_fast #(
            .IN_DW(14)
        )u_mul_1(
            .I_IN1     ({1'b0,vi}),
            .I_IN2     (ln_2 ),
            .O_MUL_OUT (mul_2_full)//assign mul_2_full = ln_2 * vi;
        );

        mul_fast #(
            .IN_DW(14)
        )u_mul_2(
            .I_IN1     ({1'b0,vi}),
            .I_IN2     (ln_2_mul_sqrt2 ),//assign mul_3_full = ln_2_mul_sqrt2 * vi;
            .O_MUL_OUT (mul_3_full)
        );

        always_comb begin
            if(vi < 13'd2166) begin    //2^x = 1 + ln2*x                         (-0.235595703125<x<0.264404296875)
                result <= 16'b0_01_00000_0000_0000 + mul_2;
            end
            else if(vi > 13'd2166 & vi < 13'b1_1111_1111_1111) begin//2^x = sqrt(2) + sqrt(2)*ln2*(x-0.5)     (0.264404296875<x<1)
                result <= 16'd7570 + mul_3;
            end
            else begin
                result <= 16'b0_01_00000_0000_0000; //error
            end
        end
    end
endgenerate
endmodule