`timescale 1ns/1ps
module rst_protect(
    input  logic I_CLK           ,
    input  logic I_RST_N         ,
    output logic O_PROTECTED_RSTN
);
logic rst_n_delay0;

always_ff@(posedge I_CLK)begin
    rst_n_delay0 <= I_RST_N;
end
assign O_PROTECTED_RSTN = I_RST_N & rst_n_delay0;
endmodule