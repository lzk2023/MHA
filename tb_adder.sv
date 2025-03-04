`timescale 1ns/1ps
module tb_adder();

bit   [15:0] adder_in1;
bit   [15:0] adder_in2;
logic [16:0] adder_out;
logic [16:0] compare_o;
adder#(
    .W(16)
)u_dut_adder(
    .I_IN1(adder_in1),
    .I_IN2(adder_in2),
    .O_OUT(adder_out)
);

initial begin
    adder_in1 = 0;
    adder_in2 = 0;
    compare_o = 0;
    #100
        while(1)begin
            #10
                adder_in1 = $random();
                adder_in2 = $random();
                compare_o = adder_in1 + adder_in2;
        end
end

always@(compare_o)begin
    #1
    if(compare_o != adder_out)begin
        $finish;
    end
end

initial begin
    #5000
        $finish;
end
endmodule