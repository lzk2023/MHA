`timescale 1ns/1ps
module full_adder(
    input  logic I_A,
    input  logic I_B,
    input  logic I_C,
    output logic O_S,
    output logic O_C
);
assign O_S = I_A ^ I_B ^ I_C;
assign O_C = (I_A & I_B) | ((I_A ^ I_B) & I_C);
endmodule