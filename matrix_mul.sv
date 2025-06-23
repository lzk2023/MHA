`timescale 1ns/1ps
module matrix_mul(
    input  logic        I_CLK             ,
    input  logic        I_RST_N           ,
    input  logic [15:0] I_MAT [0:15][0:15],
    input  logic [15:0] I_VEC [0:15]      ,
    output logic [15:0] O_MAT [0:15][0:15]
);
logic [31:0] mat_o_mul [0:15][0:15];
integer m;
integer n;
generate
    for(genvar i=0;i<16;i=i+1)begin:gen_mat_mul
        for(genvar j=0;j<16;j=j+1)begin
            assign mat_o_mul[i][j] = $signed(I_MAT[i][j]) * $signed(I_VEC[i]);
            //mul_fast#(
            //    .IN_DW(16)
            //)u_mul_fast(
            //    .I_IN1    (I_MAT[i][j]),
            //    .I_IN2    (I_VEC[i]),
            //    .O_MUL_OUT(mat_o_mul[i][j])
            //);
            //assign O_MAT[i][j] = mat_o_mul[i][j][12] ? {mat_o_mul[i][j][31],mat_o_mul[i][j][27:13]} + 1:{mat_o_mul[i][j][31],mat_o_mul[i][j][27:13]};
            //assign O_MAT[i][j] = {mat_o_mul[i][j][31],mat_o_mul[i][j][27:13]};
        end
    end
endgenerate

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        O_MAT <= '{default:0};
    end else begin
        for(n=0;n<16;n=n+1)begin
            for(m=0;m<16;m=m+1)begin
                if(mat_o_mul[n][m][12] == 1)begin
                    O_MAT[n][m] <= {mat_o_mul[n][m][31],mat_o_mul[n][m][27:13]} + 1;
                end else begin
                    O_MAT[n][m] <= {mat_o_mul[n][m][31],mat_o_mul[n][m][27:13]};
                end
            end
        end
    end   
end
endmodule