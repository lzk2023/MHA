`timescale 1ns/1ps
module tb_bram_manager();
bit       I_CLK              ;
bit       I_RST_N            ;
bit       I_VLD_PULSE        ;
bit [5:0] I_SEL              ;
logic       O_VLD            ;  
logic [7:0] O_MAT [0:15][0:127];
bram_manager u_dut(
    .I_CLK       (I_CLK       ), 
    .I_RST_N     (I_RST_N     ), 
    .I_VLD_PULSE (I_VLD_PULSE ),
    .I_SEL       (I_SEL       ),//sel,64
    .O_VLD       (O_VLD       ),
    .O_MAT       (O_MAT       )
);
always #5 I_CLK = ~I_CLK;
initial begin
    #100
    I_RST_N = 1;
    I_VLD_PULSE = 1;
    I_SEL = 0;
    #10
    I_VLD_PULSE = 0;
    #200
    I_VLD_PULSE = 1;
    I_SEL = 1;
    #10
    I_VLD_PULSE = 0;
    #200
    $finish;
end
endmodule