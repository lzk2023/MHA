`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: lzk
// 
// Create Date: 2024/10/31 10:05:11
// Design Name: 
// Module Name: PE
// Project Name: MHA
// Target Devices: 
// Tool Versions: 
// Description: pipeline multiplier,
//              data 16 bits,for 1 signal bit,2 int bits and 13 fraction bits
//              data format:16'b0_00_00000_0000_0000
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module PE#(
    parameter D_W = 8
)
(
    input  logic           I_CLK       ,
    input  logic           I_ASYN_RSTN ,
    input  logic [D_W-1:0] I_X         ,//input x(from left)
    input  logic [D_W-1:0] I_W         ,//input weight(load)
    input  logic [D_W-1:0] I_D         ,//input data(from up)
    input  logic           I_LOAD_LEFT ,
    input  logic           I_LOAD_UP   ,
    output logic [D_W-1:0] O_X         ,//output x(right shift)
    output logic [D_W-1:0] O_W         ,
    output logic [D_W-1:0] O_D         ,//output data(down shift)
    output logic           O_LOAD_RIGHT,
    output logic           O_LOAD_DOWN 
);

logic [2*D_W-1:0] o_mul_out  ;
logic             load_signal;

assign load_signal = I_LOAD_LEFT | I_LOAD_UP;

always_ff@(posedge I_CLK or negedge I_ASYN_RSTN)begin
    if (!I_ASYN_RSTN) begin
        O_X     <= 'b0;
        O_W     <= 'b0;
        O_D     <= 'b0;
        O_LOAD_RIGHT <= 0;
        O_LOAD_DOWN  <= 0;
    end else if(load_signal)begin
        O_X     <= I_X;
        O_W     <= I_W;
        if(o_mul_out[4])begin//round
            O_D     <= I_D + {o_mul_out[15],o_mul_out[11:5]} + 1;//O_D <= 0 + I_X x I_W;
        end else begin
            O_D     <= I_D + {o_mul_out[15],o_mul_out[11:5]};
        end
        O_LOAD_RIGHT <= 1;
        O_LOAD_DOWN  <= 1;
    end else begin
        O_X     <= I_X;
        O_W     <= O_W;
        if(o_mul_out[4])begin//round
            O_D     <= I_D + {o_mul_out[15],o_mul_out[11:5]} + 1;   //D_W==8
        end else begin
            O_D     <= I_D + {o_mul_out[15],o_mul_out[11:5]};   //D_W==8
        end
        O_LOAD_RIGHT <= 0;
        O_LOAD_DOWN  <= 0;
    end
end

mul_fast #(
    .IN_DW(D_W)
)u_mul_16(
    .I_IN1    (I_X),
    .I_IN2    (O_W),
    .O_MUL_OUT(o_mul_out)
);
endmodule