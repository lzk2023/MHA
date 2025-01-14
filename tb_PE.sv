`timescale 1ns / 1ps

module tb_PE(

);
reg         I_CLK       ;
reg         I_RST_N     ;
reg         I_X_VLD     ;
reg [15:0]  I_X         ;
reg         I_W_VLD     ;
reg [15:0]  I_W         ;
reg         I_D_VLD     ;
reg [15:0]  I_D         ;

reg [31:0] o_comp_32;
reg [15:0] o_comp_16;

wire        O_X_VLD     ;
wire [15:0] O_X         ;
wire        O_MUL_DONE  ;
wire        O_OUT_VLD   ;
wire [15:0] O_OUT       ;

PE u_PE(
.I_CLK     (I_CLK     ),
.I_RST_N   (I_RST_N   ),
.I_X_VLD   (I_X_VLD   ),
.I_X       (I_X       ),//input x(from left)
.I_W_VLD   (I_W_VLD   ),
.I_W       (I_W       ),//input weight(from ddr)
.I_D_VLD   (I_D_VLD   ),
.I_D       (I_D       ),//input data(from up)
.O_X_VLD   (O_X_VLD   ),
.O_X       (O_X       ),//output x(right shift)
.O_MUL_DONE(O_MUL_DONE),//multiply done,next clk add,I_D_VLD <=0
.O_OUT_VLD (O_OUT_VLD ),
.O_OUT     (O_OUT     )//output data(down shift)
);

always #5 I_CLK = ~I_CLK;
initial begin
    I_CLK   = 0;
    I_RST_N = 0;
    I_X_VLD = 0;
    I_X     = 0;
    I_W_VLD = 0;
    I_W     = 0;
    I_D_VLD = 0;
    I_D     = 0;
    #100
    I_RST_N = 1;
    #100
    I_X = $random;
    I_W = $random;
    I_D = $random;
    I_X_VLD =   1;
    I_W_VLD =   1;
    I_D_VLD =   1;
    //#10
    //I_X = $random;
    //I_W = $random;
    //I_D = $random;
    //#50
    //I_X = $random;
    //I_W = $random;
    //I_D = $random;
    //#30
    //I_X = $random;
    //I_W = $random;
    //I_D = $random;
    //#10;
end

always@(posedge I_CLK)begin
    if(O_MUL_DONE)begin
        o_comp_32  = $signed(I_X) * $signed(I_W);
        o_comp_16  = $signed({o_comp_32[31],o_comp_32[27:13]}) + $signed(I_D);
        I_X_VLD <=   0;
        I_W_VLD <=   0;
        I_D_VLD <=   0;
        #10
        I_X = $random;
        I_W = $random;
        I_D = $random;
        I_X_VLD =   1;
        I_W_VLD =   1;
        I_D_VLD =   1;
    end
end

always@(posedge I_CLK)begin
    if(O_OUT_VLD)begin
        if(o_comp_16 != O_OUT)begin
            $finish;
        end else begin
        end
    end
end
endmodule
