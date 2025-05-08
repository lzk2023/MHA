`timescale 1ns/1ps
module matrix_add#(
    parameter D_W  = 8,
    parameter SA_R = 16,
    parameter SA_C = 16
)(
    input  [D_W-1:0] I_MAT_1 [0:SA_R-1][0:SA_C-1],
    input  [D_W-1:0] I_MAT_2 [0:SA_R-1][0:SA_C-1],
    output [D_W-1:0] O_MAT_O [0:SA_R-1][0:SA_C-1]
);
generate
    for(genvar i=0;i<SA_R;i=i+1)begin
        for(genvar j=0;j<SA_C;j=j+1)begin
            assign O_MAT_O[i][j] = I_MAT_1[i][j] + I_MAT_2[i][j];
        end
    end
endgenerate
endmodule