`timescale 1ns/1ps
module tb_divider_ip_test();
bit          aclk                  ;
bit          aresetn               ;
bit          s_axis_divisor_tvalid ;
bit   [15:0] s_axis_divisor_tdata  ;
bit          s_axis_dividend_tvalid;
bit   [23:0] s_axis_dividend_tdata ;

logic        m_axis_dout_tvalid    ;
logic [39:0] m_axis_dout_tdata     ;
logic [15:0] dividend              ;
div_16b_8frac u_dut_divider (
  .aclk                  (aclk                  ), // input wire aclk
  .aresetn               (aresetn               ), // input wire aresetn
  .s_axis_divisor_tvalid (s_axis_divisor_tvalid ), // input wire s_axis_divisor_tvalid
  .s_axis_divisor_tdata  (s_axis_divisor_tdata  ), // input wire [15 : 0] s_axis_divisor_tdata
  .s_axis_dividend_tvalid(s_axis_dividend_tvalid), // input wire s_axis_dividend_tvalid
  .s_axis_dividend_tdata (s_axis_dividend_tdata ), // input wire [23 : 0] s_axis_dividend_tdata
  .m_axis_dout_tvalid    (m_axis_dout_tvalid    ), // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata     (m_axis_dout_tdata     )  // output wire [39 : 0] m_axis_dout_tdata
);
always #5 aclk = ~aclk;
assign s_axis_dividend_tdata = {dividend,8'b0};
initial begin
    #100
    aresetn = 1;
    @(posedge aclk)
    s_axis_divisor_tvalid  <= 1;
    s_axis_dividend_tvalid <= 1;
    s_axis_divisor_tdata   <= 16'b0_01_10000_0000_0000;
    dividend               <= 16'b0_00_01000_0000_0000;
    #3000
    $finish;
end
endmodule