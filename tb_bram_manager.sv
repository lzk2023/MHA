`timescale 1ns/1ps
module tb_bram_manager();
bit         I_CLK              ;
bit         I_RST_N            ;
bit         I_RD_ENA           ;
bit         I_WR_ENA           ;
bit [1:0]   I_SEL_MAT          ;
bit [5:0]   I_SEL_LINE         ;
bit [2:0]   I_SEL_COL          ;
bit [7:0]   I_SEL              ;
bit [7:0]   I_MAT [0:15][0:15] ;
logic       O_VLD              ;  
logic [7:0] O_MAT [0:15][0:15] ;
logic       O_WR_DONE          ;
bram_manager u_dut(
    .I_CLK          (I_CLK          ), 
    .I_RST_N        (I_RST_N        ), 
    .I_RD_ENA       (I_RD_ENA       ),
    .I_WR_ENA       (I_WR_ENA       ),
    .I_SEL_MAT      (I_SEL_MAT      ),
    .I_SEL_LINE     (I_SEL_LINE     ),
    .I_SEL_COL      (I_SEL_COL      ),
    .I_MAT          (I_MAT          ),
    .O_VLD          (O_VLD          ),
    .O_MAT          (O_MAT          ),
    .O_WR_DONE      (O_WR_DONE      )
);
always #5 I_CLK = ~I_CLK;
initial begin
    #100
    I_RST_N = 1;
    I_RD_ENA = 1;
    I_SEL_MAT  = 2'b00;//Q
    I_SEL_LINE = 6'b1;
    I_SEL_COL  = 3'b0;

    wait(O_VLD)
    @(posedge I_CLK)
    I_RD_ENA = 0;
    @(posedge I_CLK)
    I_RD_ENA = 1;
    I_SEL_MAT = 2'b01;//K
    
    #10
    wait(O_VLD)
    @(posedge I_CLK)
    I_RD_ENA = 0;
    @(posedge I_CLK)
    I_RD_ENA = 1;
    I_SEL_MAT = 2'b10;//V
    
    #10
    wait(O_VLD)
    @(posedge I_CLK)
    I_RD_ENA = 0;
    @(posedge I_CLK)
    I_RD_ENA = 1;
    I_SEL_MAT = 2'b11;//O

    #10
    wait(O_VLD)
    @(posedge I_CLK)
    I_RD_ENA = 0;
    @(posedge I_CLK)
    I_WR_ENA = 1;
    I_SEL_MAT = 2'b11;//O
    I_MAT = '{
        '{16{8'h55}},
        '{16{8'h66}},
        '{16{8'h77}},
        '{16{8'h88}},

        '{16{8'h55}},
        '{16{8'h66}},
        '{16{8'h77}},
        '{16{8'h88}},

        '{16{8'h55}},
        '{16{8'h66}},
        '{16{8'h77}},
        '{16{8'h88}},

        '{16{8'h55}},
        '{16{8'h66}},
        '{16{8'h77}},
        '{16{8'h88}}
    };
    #10
    wait(O_WR_DONE)
    @(posedge I_CLK)
    I_WR_ENA = 0;
    @(posedge I_CLK)
    I_RD_ENA = 1;
    I_SEL_MAT = 2'b11;//O
    
    #10
    wait(O_VLD)
    @(posedge I_CLK)
    I_RD_ENA = 0;
    #200
    $finish;
end
endmodule