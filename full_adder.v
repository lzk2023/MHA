`timescale 1ns/1ps
module full_adder(
    input  I_A,
    input  I_B,
    input  I_C,
    output O_S,
    output O_C
);
assign O_S = I_A ^ I_B ^ I_C;
assign O_C = (I_A & I_B) | ((I_A ^ I_B) & I_C);
endmodule