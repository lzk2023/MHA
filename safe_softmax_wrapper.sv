`timescale 1ns/1ps
module safe_softmax_wrapper#(
    parameter D_W = 8
)(
    input  logic           I_CLK                 ,
    input  logic           I_RST_N               ,
    input  logic           I_START               ,//keep when calculate
    input  logic [D_W-1:0] I_DATA    [0:15][0:15],
    input  logic [D_W-1:0] I_X_MAX   [0:15]      ,
    input  logic [15:0]    I_EXP_SUM [0:15]      ,//data:0_000_0000_0000_0000
    output logic [D_W-1:0] O_X_MAX   [0:15]      ,
    output logic [15:0]    O_EXP_SUM [0:15]      ,//data:0_000_0000_0000_0000 1bit signal,10bits int,5bits frac
    output logic           O_VLD                 ,
    output logic [D_W-1:0] O_DATA    [0:15][0:15]
);
generate
    for(genvar i=0;i<16;i=i+1)begin
        if(i==0)begin
            safe_softmax#(  
                .D_W(D_W),
                .NUM(16) //dimention
            )u_softmax(
                .I_CLK      (I_CLK          ),
                .I_RST_N    (I_RST_N        ),
                .I_START    (I_START  ),//keep when calculate
                .I_DATA     (I_DATA[i][0:15]),
                .I_X_MAX    (I_X_MAX  [i]      ),
                .I_EXP_SUM  (I_EXP_SUM[i]      ),
                .O_X_MAX    (O_X_MAX  [i]      ),
                .O_EXP_SUM  (O_EXP_SUM[i]      ),
                .O_VLD      (O_VLD),
                .O_DATA     (O_DATA[i][0:15])
            );
        end else begin
            safe_softmax#(  
                .D_W(D_W),
                .NUM(16) //dimention
            )u_softmax(
                .I_CLK      (I_CLK          ),
                .I_RST_N    (I_RST_N        ),
                .I_START    (I_START        ),//keep when calculate
                .I_DATA     (I_DATA[i][0:15]),
                .I_X_MAX    (I_X_MAX  [i]      ),
                .I_EXP_SUM  (I_EXP_SUM[i]      ),
                .O_X_MAX    (O_X_MAX  [i]      ),
                .O_EXP_SUM  (O_EXP_SUM[i]      ),
                .O_VLD      (),
                .O_DATA     (O_DATA[i][0:15])
            );
        end
    end
endgenerate
endmodule