`timescale 1ns/1ps
module half_adder(
    input  I_A,
    input  I_B,
    output O_S,
    output O_C
);
assign O_S = I_A ^ I_B;
assign O_C = I_A & I_B;
endmodule