`timescale 1ns / 1ps

module tb_PE(

);
bit         I_CLK       ;
bit         I_RST_N     ;
bit         I_VLD       ;
bit [15:0]  I_X         ;
bit [15:0]  I_W         ;

bit [31:0]  o_comp_32   ;
bit [15:0]  o_comp_16   ;
bit [15:0]  o_comp_d    ;
bit         correct     ;

logic        O_VLD       ;
logic [15:0] O_X         ;
logic [15:0] O_W         ;
logic [15:0] O_D         ;

PE u_PE(
    .I_CLK     (I_CLK     ),
    .I_RST_N   (I_RST_N   ),
    .I_VLD     (I_VLD     ),
    .I_X       (I_X       ),//input x(from left)
    .I_W       (I_W       ),//input weight(from up)
    .O_VLD     (O_VLD     ),
    .O_X       (O_X       ),//output x(right shift)
    .O_W       (O_W       ),
    .O_D       (O_D       ) //output data(down shift)
);

always #5 I_CLK = ~I_CLK;
initial begin
    I_CLK   = 0;
    I_RST_N = 0;
    I_VLD   = 0;
    I_X     = 0;
    I_W     = 0;
    #100
    I_RST_N = 1;
    #10000
    $finish;
end
initial begin
    @(posedge I_RST_N)
    while(1)begin
        I_X   = $random;
        I_W   = $random;
        I_VLD =   1;
        o_comp_32 = $signed(I_X) * $signed(I_W);
        o_comp_16 = $signed({o_comp_32[31],o_comp_32[27:13]});
        o_comp_d  =o_comp_16 + o_comp_d;
        @(negedge O_VLD);
    end
end

always@(posedge I_CLK)begin
    if(O_VLD)begin
        if(O_D == o_comp_d)begin
            correct <= 1;
        end else begin
            correct <= 0;
        end
    end else begin
        correct <= correct;
    end
end
endmodule
