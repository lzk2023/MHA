`timescale 1ns/1ps
module half_adder(
    input  logic I_A,
    input  logic I_B,
    output logic O_S,
    output logic O_C
);
assign O_S = I_A ^ I_B;
assign O_C = I_A & I_B;
endmodule