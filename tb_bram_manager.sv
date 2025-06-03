`timescale 1ns/1ps
module tb_bram_manager();
bit         I_CLK               ;
bit         I_RST_N             ;
bit         I_ENA_Q             ;
bit         I_ENA_K             ;
bit         I_ENA_V             ;
bit         I_ENA_O             ;
bit         I_WEA_O             ;
bit [5:0]   I_SEL_LINE          ;
bit [2:0]   I_SEL_COL           ;
bit [7:0]   I_MAT [0:15][0:15]  ;
logic       O_VLD_Q             ;
logic       O_VLD_K             ;
logic       O_VLD_V             ;
logic       O_VLD_O             ;
logic [7:0] O_MAT_Q [0:15][0:15];
logic [7:0] O_MAT_K [0:15][0:15];
logic [7:0] O_MAT_V [0:15][0:15];
logic [7:0] O_MAT_O [0:15][0:15];
bram_manager u_dut(
    .I_CLK        (I_CLK     ), 
    .I_RST_N      (I_RST_N   ), 
    .I_ENA_Q      (I_ENA_Q   ),
    .I_ENA_K      (I_ENA_K   ),
    .I_ENA_V      (I_ENA_V   ),
    .I_ENA_O      (I_ENA_O   ),
    .I_WEA_O      (I_WEA_O   ),
    .I_SEL_Q_LINE (I_SEL_LINE),
    .I_SEL_Q_COL  (I_SEL_COL ),
    .I_SEL_K_LINE (I_SEL_LINE),
    .I_SEL_K_COL  (I_SEL_COL ),
    .I_SEL_V_LINE (I_SEL_LINE),
    .I_SEL_V_COL  (I_SEL_COL ),
    .I_SEL_O_LINE (I_SEL_LINE),
    .I_SEL_O_COL  (I_SEL_COL ),
    .I_MAT        (I_MAT     ),
    .O_VLD_Q      (O_VLD_Q   ),
    .O_VLD_K      (O_VLD_K   ),
    .O_VLD_V      (O_VLD_V   ),
    .O_VLD_O      (O_VLD_O   ),
    .O_MAT_Q      (O_MAT_Q   ),
    .O_MAT_K      (O_MAT_K   ),
    .O_MAT_V      (O_MAT_V   ),
    .O_MAT_O      (O_MAT_O   ) 
);
always #5 I_CLK = ~I_CLK;
//initial begin
//    #100
//    I_RST_N = 1;
//    I_SEL_LINE = 6'b1;
//    I_SEL_COL  = 3'b0;
//    I_ENA_Q = 1'b1;
//    I_ENA_O = 1'b1;
//    wait(O_VLD_Q)
//    @(posedge I_CLK)
//    I_ENA_Q = 1'b0;
//    I_ENA_O = 1'b0;
//    @(posedge I_CLK)
//    I_ENA_K <= 1'b1;
//    I_ENA_V <= 1'b1;
//    wait(O_VLD_K)
//    @(posedge I_CLK)
//    I_ENA_K <= 1'b0;
//    I_ENA_V <= 1'b0;
//
//    @(posedge I_CLK)
//    I_ENA_O  <= 1'b1;
//    I_WEA_O  <= 1'b1;
//    I_MAT <= '{
//        '{16{8'h55}},
//        '{16{8'h66}},
//        '{16{8'h77}},
//        '{16{8'h88}},
//
//        '{16{8'h55}},
//        '{16{8'h66}},
//        '{16{8'h77}},
//        '{16{8'h88}},
//
//        '{16{8'h55}},
//        '{16{8'h66}},
//        '{16{8'h77}},
//        '{16{8'h88}},
//
//        '{16{8'h55}},
//        '{16{8'h66}},
//        '{16{8'h77}},
//        '{16{8'h88}}
//    };
//
//    @(posedge I_CLK)
//    I_ENA_O  <= 1'b0;
//    I_WEA_O  <= 1'b0;
//    @(posedge I_CLK)
//    I_ENA_O  <= 1'b1;
//    wait(O_VLD_O)
//    @(posedge I_CLK)
//    I_ENA_O  <= 1'b0;
//    #200
//    $finish;
//end
initial begin
    #100
    I_RST_N = 1;
    I_SEL_LINE = 6'd2;
    I_SEL_COL  = 3'd0;
    I_ENA_O = 1'b1;
    I_WEA_O = 1'b1;
    I_MAT = '{
        '{16{8'h55}},
        '{16{8'h55}},
        '{16{8'h55}},
        '{16{8'h55}},
        '{16{8'h55}},
        '{16{8'h55}},
        '{16{8'h55}},
        '{16{8'h55}},
        '{16{8'h55}},
        '{16{8'h55}},
        '{16{8'h55}},
        '{16{8'h55}},
        '{16{8'h55}},
        '{16{8'h55}},
        '{16{8'h55}},
        '{16{8'h55}}
    };
    @(posedge I_CLK)
    I_SEL_LINE <= 6'd2;
    I_SEL_COL  <= 3'd1;
    I_MAT <= '{
        '{16{8'h66}},
        '{16{8'h66}},
        '{16{8'h66}},
        '{16{8'h66}},
        '{16{8'h66}},
        '{16{8'h66}},
        '{16{8'h66}},
        '{16{8'h66}},
        '{16{8'h66}},
        '{16{8'h66}},
        '{16{8'h66}},
        '{16{8'h66}},
        '{16{8'h66}},
        '{16{8'h66}},
        '{16{8'h66}},
        '{16{8'h66}}
    };
    @(posedge I_CLK)
    I_SEL_LINE <= 6'd2;
    I_SEL_COL  <= 3'd2;
    I_MAT <= '{
        '{16{8'h77}},
        '{16{8'h77}},
        '{16{8'h77}},
        '{16{8'h77}},
        '{16{8'h77}},
        '{16{8'h77}},
        '{16{8'h77}},
        '{16{8'h77}},
        '{16{8'h77}},
        '{16{8'h77}},
        '{16{8'h77}},
        '{16{8'h77}},
        '{16{8'h77}},
        '{16{8'h77}},
        '{16{8'h77}},
        '{16{8'h77}}
    };
    @(posedge I_CLK)
    I_SEL_LINE <= 6'd2;
    I_SEL_COL  <= 3'd3;
    I_MAT <= '{
        '{16{8'h88}},
        '{16{8'h88}},
        '{16{8'h88}},
        '{16{8'h88}},
        '{16{8'h88}},
        '{16{8'h88}},
        '{16{8'h88}},
        '{16{8'h88}},
        '{16{8'h88}},
        '{16{8'h88}},
        '{16{8'h88}},
        '{16{8'h88}},
        '{16{8'h88}},
        '{16{8'h88}},
        '{16{8'h88}},
        '{16{8'h88}}
    };
    @(posedge I_CLK)
    I_ENA_O <= 1'b1;
    I_WEA_O <= 1'b0;
    I_SEL_LINE <= 6'd2;
    I_SEL_COL  <= 3'd0;
    wait(O_VLD_O)
    @(posedge I_CLK)
    I_SEL_LINE <= 6'd2;
    I_SEL_COL  <= 3'd1;

    wait(O_VLD_O)
    @(posedge I_CLK)
    I_SEL_LINE <= 6'd2;
    I_SEL_COL  <= 3'd2;

    wait(O_VLD_O)
    @(posedge I_CLK)
    I_SEL_LINE <= 6'd2;
    I_SEL_COL  <= 3'd3;

    wait(O_VLD_O)
    #100
    $finish;
end
endmodule