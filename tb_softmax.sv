`timescale 1ns/1ps
module tb_softmax();
    localparam D_W = 16;
    localparam DIM = 4;
    bit                 clk  ;
    bit                 rst_n;
    bit                 start;
    bit   [D_W*DIM-1:0] data ;
    logic               out_vld ;
    logic [D_W*DIM-1:0] out_data;
    real                out_data_real[4];
    real                out_data_compare[4];
    
    task float_outdata();
        real sum;
        out_data_real [0] = $signed(out_data[0 +: 16]) ;
        out_data_real [1] = $signed(out_data[16 +: 16]);
        out_data_real [2] = $signed(out_data[32 +: 16]);
        out_data_real [3] = $signed(out_data[48 +: 16]);
        out_data_real [0] = out_data_real [0]/8192;
        out_data_real [1] = out_data_real [1]/8192;
        out_data_real [2] = out_data_real [2]/8192;
        out_data_real [3] = out_data_real [3]/8192;
        
        out_data_compare [0] = $signed(data[0 +: 16]) ;
        out_data_compare [1] = $signed(data[16 +: 16]);
        out_data_compare [2] = $signed(data[32 +: 16]);
        out_data_compare [3] = $signed(data[48 +: 16]);
        sum = $exp(out_data_compare [0] / 8192) + $exp(out_data_compare [1] / 8192) + $exp(out_data_compare [2] / 8192) + $exp(out_data_compare [3] / 8192);
        out_data_compare [0] = $exp(out_data_compare [0] / 8192) / sum;
        out_data_compare [1] = $exp(out_data_compare [1] / 8192) / sum;
        out_data_compare [2] = $exp(out_data_compare [2] / 8192) / sum;
        out_data_compare [3] = $exp(out_data_compare [3] / 8192) / sum;
        
    endtask
    softmax#(  
    .D_W(D_W),
    .DIM(DIM) //dimention
    )u_dut_softmax(
    .I_CLK  (clk  ),
    .I_RST_N(rst_n),
    .I_START(start),//keep when calculate
    .I_DATA (data ),
    .O_VLD  (out_vld ),
    .O_DATA (out_data)
    );
    always #5 clk = ~clk;
    initial begin
        #100
        rst_n = 1;
        start = 1;
        data = {16'b1_00_00000_0000_0000,//-4
                16'b1_00_10000_0000_0000,//-3.5
                16'b1_01_00000_0000_0000,//-3
                16'b1_01_10000_0000_0000};//-2.5
        @(posedge out_vld)
        #1 
        float_outdata();
        start = 0;
        #50000
        $finish;
    end
endmodule