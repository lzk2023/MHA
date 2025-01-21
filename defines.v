////format:(D_W,ROW,COLUMN,VARIABLE,ARRAY)
`define VARIABLE_TO_MATRIX(D_W,ROW,COLUMN,VARIABLE,ARRAY) \
    generate \
        for(genvar i=0;i<ROW;i=i+1)begin \
            for(genvar j=0;j<COLUMN;j=j+1)begin \
                assign ARRAY[i][j] = VARIABLE[(i*COLUMN+j)*D_W +: D_W]; \
            end \
        end \
    endgenerate
////format:(D_W,ROW,COLUMN,VARIABLE,ARRAY)
`define MATRIX_TO_VARIABLE(D_W,ROW,COLUMN,VARIABLE,ARRAY) \
    generate \
        for(genvar i=0;i<ROW;i=i+1)begin \
            for(genvar j=0;j<COLUMN;j=j+1)begin \
                assign VARIABLE[(i*COLUMN+j)*D_W +: D_W] = ARRAY[i][j]; \
            end \
        end \
    endgenerate