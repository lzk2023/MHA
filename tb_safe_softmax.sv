`timescale 1ns/1ps
module tb_safe_softmax();
    localparam D_W = 8;
    localparam NUM = 16;
    bit                 clk  ;
    bit                 rst_n;
    bit                 start;
    bit   [D_W-1:0] data [0:NUM-1];
    logic               out_vld ;
    logic [D_W-1:0] out_data[0:NUM-1];
    real                out_data_real[16];
    real                out_data_compare[16];

    integer div;
    integer i,j;
    
    task float_outdata();
        real sum;
        if(D_W == 16)begin
            div = 8192;
        end else begin
            div = 32;
        end
        sum = 0;
        for(i=0;i<NUM;i=i+1)begin
            out_data_real [i] = $signed(out_data[i]);
            out_data_real [i] = out_data_real [i]/div;
            out_data_compare [i] = $signed(data[i]);
            sum = sum + $exp(out_data_compare [i] / div);
        end
        for(j=0;j<NUM;j=j+1)begin
            out_data_compare [j] = $exp(out_data_compare [j] / div) / sum;
        end
    endtask
    safe_softmax#(  
    .D_W(D_W),
    .NUM(NUM) //dimention
    )u_dut_safe_softmax(
    .I_CLK    (clk  ),
    .I_RST_N  (rst_n),
    .I_START  (start),//keep when calculate
    .I_DATA   (data ),
    .I_X_MAX  (8'd0),
    .I_EXP_SUM(16'd0),//0_0000000_0000_0000,1 signal bit,7int bit,8frac bit
    .O_X_MAX  (),
    .O_EXP_SUM(),
    .O_VLD    (out_vld ),
    .O_DATA   (out_data)
    );
    always #5 clk = ~clk;
    initial begin
        #100
        rst_n = 1;
        start = 1;
        if(D_W == 16)begin
            data = {
                16'b0_11_11000_0000_0000,//3.75
                16'b0_11_10000_0000_0000,//3.5
                16'b0_11_01000_0000_0000,//3.25
                16'b0_11_00000_0000_0000,//3
                16'b0_10_11000_0000_0000,//2.75
                16'b0_10_10000_0000_0000,//2.5
                16'b0_10_01000_0000_0000,//2.25
                16'b0_10_00000_0000_0000,//2
                16'b0_01_11000_0000_0000,//1.75
                16'b0_01_10000_0000_0000,//1.5
                16'b0_01_01000_0000_0000,//1.25
                16'b0_01_00000_0000_0000,//1
                16'b0_00_11000_0000_0000,//0.75
                16'b0_00_10000_0000_0000,//0.5
                16'b0_00_01000_0000_0000,//0.25
                16'b0_00_00000_0000_0000 //0
                };//-2.5
        end else begin
            data = {
                8'b0_11_11000,//3.75
                8'b0_11_10000,//3.5
                8'b0_11_01000,//3.25
                8'b0_11_00000,//3
                8'b0_10_11000,//2.75
                8'b0_10_10000,//2.5
                8'b0_10_01000,//2.25
                8'b0_10_00000,//2
                8'b0_01_11000,//1.75
                8'b0_01_10000,//1.5
                8'b0_01_01000,//1.25
                8'b0_01_00000,//1
                8'b0_00_11000,//0.75
                8'b0_00_10000,//0.5
                8'b0_00_01000,//0.25
                8'b0_00_00000 //0
                };//-2.5
        end
        @(posedge out_vld)
        #1 
        float_outdata();
        start = 0;
        #1000
        $finish;
    end
endmodule