`timescale 1ns/1ps
module tb_rst_protect();

bit I_CLK;
bit I_RST_N;
logic O_PROTECTED_RSTN;

logic data_test_asyn;
logic data_test_sync;

rst_protect u_rst_protect(
    .I_CLK           (I_CLK           ),
    .I_RST_N         (I_RST_N         ),
    .O_PROTECTED_RSTN(O_PROTECTED_RSTN)
);

always #5 I_CLK = ~I_CLK;

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        data_test_asyn <= 0;
    end else begin
        data_test_asyn <= 1;
    end
end

always_ff@(posedge I_CLK or negedge O_PROTECTED_RSTN)begin
    if(!I_RST_N)begin
        data_test_sync <= 0;
    end else begin
        data_test_sync <= 1;
    end
end
initial begin
    I_RST_N = 1;
    #57
    I_RST_N = 0;
    #56
    I_RST_N = 1;
    #100
    $finish;
end
endmodule