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

module SA_wrapper#(
    parameter D_W   = 8,  //Data_Width
    parameter M_DIM = 128, //X_C == W_R == M_DIM,dimention of the 2 multiply matrix.
    parameter SA_R  = 16,  //SA_ROW,     SA.shape = (SA_R,SA_C)
    parameter SA_C  = 16   //SA_COLUMN
) (
    input  logic           I_CLK                              ,
    input  logic           I_ASYN_RSTN                        ,
    input  logic           I_SYNC_RSTN                        ,
    input  logic           I_START_FLAG                       ,//                                               SA_C    
    input  logic [D_W-1:0] I_X_MATRIX   [0:SA_R-1][0:M_DIM-1] ,//input x(from left)        matrix x:     x|<-------------->|
    input  logic [D_W-1:0] I_W_MATRIX   [0:M_DIM-1][0:SA_C-1] ,//input weight(from up)                   |
    output logic           O_OUT_VLD                          ,//                                   SA_R |
    output logic           O_PE_SHIFT                         ,//  OUT.shape = (X_R,SA_C)                |
    output logic [D_W-1:0] O_OUT        [0:SA_R-1][0:SA_C-1]   //                                        x
);

enum logic  [2:0] {
    S_IDLE = 3'b001,
    S_CALC = 3'b010,
    S_END  = 3'b100 
} state;

logic [D_W-1:0] input_x  [0:SA_R-1];
logic [D_W-1:0] input_w  [0:SA_C-1];
logic [D_W-1:0] x_vector [0:SA_R-1];
logic [D_W-1:0] w_vector [0:SA_C-1];
logic           matshift_over      ;

logic [9:0]     count                       ;//15+16-1=30 clk,out_vld == 1
logic [D_W-1:0] in_x_ff [0:SA_R-1][0:SA_R-1];
logic [D_W-1:0] in_w_ff [0:SA_C-1][0:SA_C-1];


always_ff@(posedge I_CLK or negedge I_ASYN_RSTN)begin
    if(!I_ASYN_RSTN | !I_SYNC_RSTN)begin
        count <= 'b0;
    end else if(matshift_over)begin
        if(count < 10'd31)begin //31==16*2-1
            count <= count + 1;
        end else begin
            count <= count;
        end
    end else begin
        count <= 0;
    end
end

always_ff@(posedge I_CLK or negedge I_ASYN_RSTN)begin
    if(!I_ASYN_RSTN | !I_SYNC_RSTN)begin
        state     <= S_IDLE;
        O_OUT_VLD <= 0;
    end else begin
        case(state)
            S_IDLE:begin
                if(I_START_FLAG)begin
                    state <= S_CALC;
                    O_OUT_VLD <= 0;
                end else begin
                    state <= state;
                    O_OUT_VLD <= O_OUT_VLD;
                end
            end
            S_CALC:begin
                if(count == 10'd31)begin//31==16*2-1
                    state <= S_END;
                    O_OUT_VLD <= 1;
                end else begin
                    state <= state;
                    O_OUT_VLD <= 0;
                end
            end
            S_END :begin
                state <= S_END;
                O_OUT_VLD <= 1;
            end
        endcase
    end
end

generate
    for(genvar i=0;i<SA_R;i=i+1)begin
        assign input_x[i] = in_x_ff[i][0];
        for(genvar j=0;j<i+1;j=j+1)begin
            if(j == i)begin
                always_ff@(posedge I_CLK or negedge I_ASYN_RSTN)begin
                    if(!I_ASYN_RSTN | !I_SYNC_RSTN)begin
                        in_x_ff[i][j] <= 'b0;
                    end else if(O_PE_SHIFT)begin
                        in_x_ff[i][j] <= x_vector[i];
                    end else begin
                        in_x_ff[i][j] <= in_x_ff[i][j];
                    end
                end
            end else begin
                always_ff@(posedge I_CLK or negedge I_ASYN_RSTN)begin
                    if(!I_ASYN_RSTN | !I_SYNC_RSTN)begin
                        in_x_ff[i][j] <= 'b0;
                    end else if(O_PE_SHIFT)begin
                        in_x_ff[i][j] <= in_x_ff[i][j+1];
                    end else begin
                        in_x_ff[i][j] <= in_x_ff[i][j];
                    end
                end
            end
        end
    end
endgenerate

generate
    for(genvar i=0;i<SA_C;i=i+1)begin
        assign input_w[i] = in_w_ff[i][0];
        for(genvar j=0;j<i+1;j=j+1)begin
            if(j == i)begin
                always_ff@(posedge I_CLK or negedge I_ASYN_RSTN)begin
                    if(!I_ASYN_RSTN | !I_SYNC_RSTN)begin
                        in_w_ff[i][j] <= 'b0;
                    end else if(O_PE_SHIFT)begin
                        in_w_ff[i][j] <= w_vector[i];
                    end else begin
                        in_w_ff[i][j] <= in_w_ff[i][j];
                    end
                end
            end else begin
                always_ff@(posedge I_CLK or negedge I_ASYN_RSTN)begin
                    if(!I_ASYN_RSTN | !I_SYNC_RSTN)begin
                        in_w_ff[i][j] <= 'b0;
                    end else if(O_PE_SHIFT)begin
                        in_w_ff[i][j] <= in_w_ff[i][j+1];
                    end else begin
                        in_w_ff[i][j] <= in_w_ff[i][j];
                    end
                end
            end
        end
    end
endgenerate

SA_mat_manager#(
    .D_W  (D_W  ),
    .X_R  (SA_R ),
    .M_DIM(M_DIM),//X_C == W_R == M_DIM,dimention of the 2 multiply matrix.
    .W_C  (SA_C )
)u_dut_SA_mat_manager(
    .I_CLK      (I_CLK        ),
    .I_ASYN_RSTN(I_ASYN_RSTN  ),
    .I_SYNC_RSTN(I_SYNC_RSTN  ),
    .I_PE_SHIFT (O_PE_SHIFT   ),
    .I_START    (I_START_FLAG ),
    .I_X_MATRIX (I_X_MATRIX   ),
    .I_W_MATRIX (I_W_MATRIX   ),
    .O_OVER     (matshift_over),
    .O_X_VECTOR (x_vector     ),
    .O_W_VECTOR (w_vector     )
);

SA #(
    .D_W         (D_W         ),
    .SA_R        (SA_R        ),
    .SA_C        (SA_C        )
) u_SA (
    .I_CLK       (I_CLK       ),
    .I_ASYN_RSTN (I_ASYN_RSTN ),
    .I_SYNC_RSTN (I_SYNC_RSTN ),
    .I_START_FLAG(I_START_FLAG),
    .I_X         (input_x     ),//input x(from left)
    .I_W         (input_w     ),//input weight(from up)
    .O_SHIFT     (O_PE_SHIFT  ),//PE shift,O_SHIFT <= 1
    .O_OUT       (O_OUT       ) //output data(keep),
);
endmodule