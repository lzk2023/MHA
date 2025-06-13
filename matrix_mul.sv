`timescale 1ns/1ps
module matrix_mul(
    input  logic [15:0] I_MAT [0:15][0:15],
    input  logic [15:0] I_VEC [0:15]      ,
    output logic [15:0] O_MAT [0:15][0:15]
);
logic [31:0] mat_o_mul [0:15][0:15];
generate
    for(genvar x=0;x<SA_R;x=x+1)begin:gen_mat_mul
        for(genvar y=0;y<SA_C;y=y+1)begin
            assign mat_o_mul[i][j] = I_MAT[i][j] * I_VEC[i];
            assign O_MAT[i][j] = mat_o_mul[i][j][12] ? {mat_o_mul[i][j][31],mat_o_mul[i][j][27:13]} + 1:{mat_o_mul[i][j][31],mat_o_mul[i][j][27:13]};
        end
    end
endgenerate

endmodule