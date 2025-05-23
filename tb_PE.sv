`timescale 1ns / 1ps

module tb_PE(

);
bit         I_CLK       ;
bit         I_ASYN_RSTN ;
bit         I_VLD       ;
bit [7:0]   I_X         ;
bit [7:0]   I_W         ;
bit [7:0]   I_D         ;
bit         I_LOAD_LEFT  ;
bit         I_LOAD_UP    ;

bit [15:0]  o_comp_16   ;
bit [7:0]   o_comp_8    ;
bit [7:0]   o_comp_d    ;
bit         correct     ;

logic [7:0] O_X         ;
logic [7:0] O_W         ;
logic [7:0] O_D         ;
logic        O_LOAD_RIGHT ;
logic        O_LOAD_DOWN  ;

PE u_PE(
    .I_CLK      (I_CLK      ),
    .I_ASYN_RSTN(I_ASYN_RSTN),
    .I_VLD      (I_VLD      ),
    .I_X        (I_X        ),//input x(load)
    .I_W        (I_W        ),//input weight(from up)
    .I_D        (I_D        ),
    .I_LOAD_LEFT (I_LOAD_LEFT ),
    .I_LOAD_UP   (I_LOAD_UP   ),
    .O_X        (O_X        ),//output x(right shift)
    .O_W        (O_W        ),//debug
    .O_D        (O_D        ),//output data(down shift)
    .O_LOAD_RIGHT(O_LOAD_RIGHT),
    .O_LOAD_DOWN (O_LOAD_DOWN )
);

always #5 I_CLK = ~I_CLK;
initial begin
    I_CLK       = 0;
    I_ASYN_RSTN = 0;
    I_VLD       = 0;
    I_X         = 0;
    I_W         = 0;
    #100
    I_ASYN_RSTN = 1;
    I_W         = 8'd123; 
    I_LOAD_LEFT  = 1;
    #10
    I_LOAD_LEFT  = 0;
    #10000
    $finish;
end
initial begin
    @(negedge I_LOAD_LEFT)
    while(1)begin
        I_X   = $random;
        I_D   = $random;
        I_VLD = 1;
        o_comp_16 = $signed(I_X) * $signed(O_W);
        if(o_comp_16[4])
            o_comp_8 = $signed({o_comp_16[15],o_comp_16[11:5]}) + 1;
        else 
            o_comp_8 = $signed({o_comp_16[15],o_comp_16[11:5]});
        o_comp_d = o_comp_8 + I_D;
        @(negedge I_CLK);
    end
end

always@(posedge I_CLK)begin
    #1
    if(O_D == o_comp_d)begin
        correct <= 1;
    end else begin
        correct <= 0;
    end
end
endmodule
