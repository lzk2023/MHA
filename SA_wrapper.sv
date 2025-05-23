`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: lzk
// 
// Create Date: 2024/10/31 10:05:11
// Design Name: 
// Module Name: SA_wrapper
// Project Name: MHA
// Target Devices: 
// Tool Versions: 
// Description: Systolic Array,5clk update PE.
//              input shift(left to right),output maintain,weight shift(up to down).
//              data 16 bits,for 1 signal bit,2 int bits and 13 fraction bits
//              data format:16'b0_00_00000_0000_0000
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//                                               SA_C    
//input x(from left)        matrix x:     x|<-------------->| //X_C == W_R == M_DIM,dimention of the 2 multiply matrix.
//input weight(from up)                   |
//                                   SA_R |
//  OUT.shape = (X_R,SA_C)                |
//                                        x
//////////////////////////////////////////////////////////////////////////////////

module SA_wrapper#(
    parameter D_W   = 8 , //Data_Width
    parameter SA_R  = 16, //SA_ROW,     SA.shape = (SA_R,SA_C)
    parameter SA_C  = 16  //SA_COLUMN
) (
    input  logic           I_CLK                                  ,
    input  logic           I_RST_N                                ,
    input  logic           I_LOAD_FLAG                            ,
    input  logic [D_W-1:0] I_X_MATRIX         [0:SA_R-1][0:SA_C-1],
    input  logic [D_W-1:0] I_W_MATRIX         [0:SA_R-1][0:SA_C-1],
    output logic           O_INPUT_FIFO_EMPTY [0:SA_R-1]          ,
    output logic           O_OUTPUT_FIFO_FULL [0:SA_C-1]          ,
    output logic           O_LOAD_WEIGHT_VLD                      ,
    output logic           O_OUT_VLD                              ,
    output logic [D_W-1:0] O_OUT              [0:SA_R-1][0:SA_C-1] 
);

logic [D_W-1:0] input_x       [0:SA_R-1];
logic           input_fifo_en [0:SA_R-1];
logic [D_W-1:0] output_d      [0:SA_C-1];
logic           output_fifo_en[0:SA_C-1];
logic           output_fifo_load_ff     ;
logic [D_W-1:0] last_weight_ff [0:SA_R-1][0:SA_C-1];

logic [D_W-1:0] output_fifo_data [0:SA_R-1][0:SA_C-1];
logic [D_W-1:0] out_data_transpose [0:SA_R-1][0:SA_C-1];
always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        last_weight_ff <= '{default:'b0};
    end else if(O_LOAD_WEIGHT_VLD)begin
        last_weight_ff <= I_W_MATRIX;
    end else begin
        last_weight_ff <= last_weight_ff;
    end
end

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        output_fifo_load_ff <= 1'b0;
    end else begin
        output_fifo_load_ff <= input_fifo_en[SA_R-1];
    end
end

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        out_data_transpose <= '{default:0};
    end else begin
        for(integer i=0;i<SA_R;i=i+1)begin
            if(O_OUTPUT_FIFO_FULL[i])begin
                out_data_transpose[i] <= output_fifo_data[i];
            end else begin
                out_data_transpose[i] <= out_data_transpose[i];
            end
        end
    end
end
always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        O_OUT_VLD <= 1'b0;
    end else if(O_OUTPUT_FIFO_FULL[SA_C-1])begin
        O_OUT_VLD <= 1'b1;
    end else begin
        O_OUT_VLD <= 1'b0;
    end
end
generate
    for(genvar i=0;i<SA_R;i=i+1)begin
        for(genvar j=0;j<SA_C;j=j+1)begin
            assign O_OUT[i][j] = out_data_transpose[j][i];
        end
    end
endgenerate

always_ff@(posedge I_CLK or negedge I_RST_N)begin
    if(!I_RST_N)begin
        O_LOAD_WEIGHT_VLD <= 1'b0;
    end else if(I_LOAD_FLAG)begin
        O_LOAD_WEIGHT_VLD <= 1'b0;
    end else if(input_fifo_en[SA_R-3])begin
        O_LOAD_WEIGHT_VLD <= 1'b1;
    end else begin
        O_LOAD_WEIGHT_VLD <= 1'b0;
    end
end

generate
    for(genvar i=0;i<SA_R;i=i+1)begin:SA_INPUT_FIFO_GEN
        if(i==0)begin
            SA_input_fifo#(
            .DATA_WIDTH(8 ),
            .FIFO_DEPTH(16)
        )u_SA_input_fifo(
            .I_CLK      (I_CLK      ),
            .I_RST_N    (I_RST_N    ),
            .I_LOAD_EN  (I_LOAD_FLAG),
            .I_LOAD_DATA(I_X_MATRIX[i]),
            .O_DATA     (input_x[i] ),
            .O_LOAD_EN  (input_fifo_en[i]  ),
            .O_EMPTY    (O_INPUT_FIFO_EMPTY[i])
        );
        end else if(i==SA_R-1)begin
            SA_input_fifo#(
            .DATA_WIDTH(8 ),
            .FIFO_DEPTH(16)
        )u_SA_input_fifo(
            .I_CLK      (I_CLK      ),
            .I_RST_N    (I_RST_N    ),
            .I_LOAD_EN  (input_fifo_en[i-1]),
            .I_LOAD_DATA(I_X_MATRIX[i]),
            .O_DATA     (input_x[i] ),
            .O_LOAD_EN  (input_fifo_en[i]  ),
            .O_EMPTY    (O_INPUT_FIFO_EMPTY[i])
        );
        end else begin
            SA_input_fifo#(
            .DATA_WIDTH(8 ),
            .FIFO_DEPTH(16)
        )u_SA_input_fifo(
            .I_CLK      (I_CLK      ),
            .I_RST_N    (I_RST_N    ),
            .I_LOAD_EN  (input_fifo_en[i-1]),
            .I_LOAD_DATA(I_X_MATRIX[i]),
            .O_DATA     (input_x[i] ),
            .O_LOAD_EN  (input_fifo_en[i]  ),
            .O_EMPTY    (O_INPUT_FIFO_EMPTY[i])
        );
        end
    end
endgenerate

generate
    for(genvar j=0;j<SA_C;j=j+1)begin:SA_OUTPUT_FIFO_GEN
        if(j==0)begin
            SA_output_fifo#(
                .DATA_WIDTH(8 ),
                .FIFO_DEPTH(16)
            )u_SA_output_fifo(
                .I_CLK      (I_CLK      ),
                .I_RST_N    (I_RST_N    ),
                .I_PUSH_EN  (output_fifo_load_ff  ),
                .I_PUSH_DATA(output_d[j]),
                .O_ALL_DATA (output_fifo_data[j] ),
                .O_POP_DATA ( ),
                .O_PUSH_EN  (output_fifo_en[j]),
                .O_FULL     (O_OUTPUT_FIFO_FULL[j]     )
            );
        end else if(j==SA_C-1)begin
            SA_output_fifo#(
                .DATA_WIDTH(8 ),
                .FIFO_DEPTH(16)
            )u_SA_output_fifo(
                .I_CLK      (I_CLK      ),
                .I_RST_N    (I_RST_N    ),
                .I_PUSH_EN  (output_fifo_en[j-1]),
                .I_PUSH_DATA(output_d[j]),
                .O_ALL_DATA (output_fifo_data[j] ),
                .O_POP_DATA ( ),
                .O_PUSH_EN  (output_fifo_en[j]),
                .O_FULL     (O_OUTPUT_FIFO_FULL[j]     )
            );
        end else begin
            SA_output_fifo#(
                .DATA_WIDTH(8 ),
                .FIFO_DEPTH(16)
            )u_SA_output_fifo(
                .I_CLK      (I_CLK      ),
                .I_RST_N    (I_RST_N    ),
                .I_PUSH_EN  (output_fifo_en[j-1]),
                .I_PUSH_DATA(output_d[j]),
                .O_ALL_DATA (output_fifo_data[j] ),
                .O_POP_DATA ( ),
                .O_PUSH_EN  (output_fifo_en[j]),
                .O_FULL     (O_OUTPUT_FIFO_FULL[j]     )
            );
        end
    end
endgenerate

SA #(
    .D_W          (D_W       ),
    .SA_R         (SA_R      ),
    .SA_C         (SA_C      )
) u_SA (
    .I_CLK        (I_CLK     ),
    .I_RST_N      (I_RST_N   ),
    .I_LOAD_SIGNAL(I_LOAD_FLAG),
    .I_X          (input_x   ),//input x(from left)
    .I_W          (I_W_MATRIX),//input weight(from up)
    .I_W_LAST     (last_weight_ff  ),
    .O_D          (output_d  ) //output data(keep),
);
endmodule