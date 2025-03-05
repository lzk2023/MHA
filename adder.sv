`timescale 1ns/1ps
module adder#(
    parameter W = 16
)(
    input  logic [W-1:0] I_IN1,
    input  logic [W-1:0] I_IN2,
    output logic [W:0]   O_OUT
);
logic [W-1:0] carry;
generate
    for(genvar i=0;i<W;i=i+1)begin
        if(i==0)begin
            half_adder hadder_bit(
                .I_A(I_IN1[i]),
                .I_B(I_IN2[i]),
                .O_S(O_OUT[i]),
                .O_C(carry[i])
            );
        end else begin
            full_adder fadder_bit(
                .I_A(I_IN1[i]),
                .I_B(I_IN2[i]),
                .I_C(carry[i-1]),
                .O_S(O_OUT[i]),
                .O_C(carry[i])
            );
        end
    end
endgenerate
assign O_OUT[W] = carry[W-1];
endmodule