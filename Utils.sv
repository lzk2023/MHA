package Utils;

function  bit [7:0] mul_signed8(
    input bit [7:0] a,
    input bit [7:0] b
    );
    bit [15:0] c;
    c = $signed(a)*$signed(b);
    if(c[4])begin
        mul_signed8 = {c[15],c[11:5]} + 1;
    end else begin
        mul_signed8 = {c[15],c[11:5]};
    end
endfunction

task mul_matrix_16_16(
    input  bit [7:0] a [0:15][0:15],
    input  bit [7:0] b [0:15][0:15],
    output bit [7:0] c [0:15][0:15]
    );
    for(int i=0;i<16;i=i+1)begin
        for(int j=0;j<16;j=j+1)begin
            c[i][j] = 8'd0;
            for(int k=0;k<16;k=k+1)begin
                c[i][j] = c[i][j] + mul_signed8(a[i][k],b[k][j]);
            end
        end
    end
endtask

task add_matrix_16_16(
    input  bit [7:0] a [0:15][0:15],
    input  bit [7:0] b [0:15][0:15],
    output bit [7:0] c [0:15][0:15]
);
    for(int i=0;i<16;i=i+1)begin
        for(int j=0;j<16;j=j+1)begin
            c[i][j] = a[i][j] + b[i][j];
        end
    end
endtask
endpackage