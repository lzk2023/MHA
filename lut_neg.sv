`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/18 09:35:23
// Design Name: 
// Module Name: lut_neg
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


module lut_neg#(
    parameter D_W = 16  //support data width = 16 or 8 bits
)(
    input  logic [D_W-4:0] vi      ,
    output logic [D_W-1:0] result  
);
generate 
    if(D_W == 8)begin                                             //data_width == 8
        localparam ln_2 = 6'd22;
        localparam ln_2_div_sqrt2 = 6'd16; 
        logic [5:0] vi_neg;
        logic [11:0] mul_1_full;
        logic [11:0] mul_2_full;
        logic [7:0] mul_1;//    1n2/sqrt(2) * x
        logic [7:0] mul_2;//    ln2*x
        
        assign vi_neg = {1'b1,~vi + 1'b1};
        //assign mul_1_full = $signed(ln_2_div_sqrt2) * $signed(vi_neg);
        assign mul_1 = {mul_1_full[11],2'b11,mul_1_full[9:5]};
        //assign mul_2_full = $signed(ln_2) * $signed(vi_neg);
        assign mul_2 = {mul_2_full[11],2'b11,mul_2_full[9:5]};
        mul_fast #(
            .IN_DW(6)
        )u_mul_1(
            .I_IN1     (vi_neg   ),
            .I_IN2     (ln_2_div_sqrt2 ),
            .O_MUL_OUT (mul_1_full)//assign mul_1_full = $signed(ln_2_div_sqrt2) * $signed(vi_neg);
        );
        
        mul_fast #(
            .IN_DW(6)
        )u_mul_2(
            .I_IN1     (vi_neg   ),
            .I_IN2     (ln_2 ),//assign mul_2_full = $signed(ln_2) * $signed(vi_neg);
            .O_MUL_OUT (mul_2_full)
        );
        always_comb begin
            if($signed(vi_neg) > $signed(6'b10_0001) & $signed(vi_neg) < $signed(6'b11_1000)) begin//2^x = 1/sqrt2 + 1n2/sqrt(2) * (x+0.5)        (-1<x<-0.25)
                result <= 8'd30 + mul_1;
            end
            else if($signed(vi_neg) >= $signed(6'b11_1000)) begin    //2^x = 1 + ln2*x                         (-0.25<x<0.25)
                result <= 8'b0_01_00000 + mul_2;
            end
            else begin
                result <= 8'b0_01_00000; //error
            end
        end
/////////////////////////////////////////////////////////////////////////////////////////////////////////        
//data_width == 16
/////////////////////////////////////////////////////////////////////////////////////////////////////////
    end else begin//D_W = 16
        localparam ln_2 = 14'd5678;
        localparam ln_2_div_sqrt2 = 14'd4015;
        logic [13:0] vi_neg;
        logic [27:0] mul_1_full;
        logic [27:0] mul_2_full;
        logic [15:0] mul_1;//    1n2/sqrt(2) * x
        logic [15:0] mul_2;//    ln2*x
        
        assign vi_neg = {1'b1,~vi + 1'b1};
        //assign mul_1_full = $signed(14'd4015) * $signed(vi_neg);
        assign mul_1 = {mul_1_full[27],2'b11,mul_1_full[25:13]};
        //assign mul_2_full = $signed(14'd5678) * $signed(vi_neg);
        assign mul_2 = {mul_2_full[27],2'b11,mul_2_full[25:13]};
        mul_fast #(
            .IN_DW(14)
        )u_mul_1(
            .I_IN1     (vi_neg   ),
            .I_IN2     (ln_2_div_sqrt2 ),
            .O_MUL_OUT (mul_1_full)//assign mul_1_full = $signed(14'd4015) * $signed(vi_neg);
        );
        
        mul_fast #(
            .IN_DW(14)
        )u_mul_2(
            .I_IN1     (vi_neg   ),
            .I_IN2     (ln_2 ),//assign mul_2_full = $signed(14'd5678) * $signed(vi_neg);
            .O_MUL_OUT (mul_2_full)
        );
        always_comb begin
            if($signed(vi_neg) > $signed(14'b10_0000_0000_0001) & $signed(vi_neg) < $signed(14'b11_1000_0111_0110)) begin//2^x = 1/sqrt2 + 1n2/sqrt(2) * (x+0.5)        (-1<x<-0.235595703125)
                result <= 16'd7800 + mul_1;
            end
            else if($signed(vi_neg) > $signed(14'b11_1000_0111_0110)) begin    //2^x = 1 + ln2*x                         (-0.235595703125<x<0.264404296875)
                result <= 16'b0_01_00000_0000_0000 + mul_2;
            end
            else begin
                result <= 16'b0_01_00000_0000_0000; //error
            end
        end
    end
endgenerate

endmodule
