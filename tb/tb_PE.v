`timescale 1ns/1ps

module tb_PE(

);

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
.O_MUL_DONE(O_MUL_DONE),//multiply done,next clk add,ID_VLD <=0
.O_OUT_VLD (O_OUT_VLD ),
.O_OUT     (O_OUT     )//output data(down shift)
);
initial begin

end
endmodule