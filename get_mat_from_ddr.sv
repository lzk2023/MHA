`timescale 1ns/1ps

module get_mat_from_ddr(
    input  logic        I_CLK_P            , //PL_CLK0_P ,AE5
    input  logic        I_CLK_N            , //PL_CLK0_N ,AF5
    input  logic        I_RST_N            , 
    output logic        O_VLD              ,
    output logic [7:0]  O_MAT [0:15][0:127],

    output logic [16:0] c0_ddr4_adr        ,
);

ddr4_0 your_instance_name (
  .c0_init_calib_complete   (c0_init_calib_complete   ), // output wire c0_init_calib_complete
  .dbg_clk                  (                         ), // output wire dbg_clk
  .c0_sys_clk_p             (I_CLK_P                  ), // input wire c0_sys_clk_p
  .c0_sys_clk_n             (I_CLK_N                  ), // input wire c0_sys_clk_n
  .dbg_bus                  (                         ), // output wire [511 : 0] dbg_bus
  .c0_ddr4_adr              (c0_ddr4_adr              ), // output wire [16 : 0] c0_ddr4_adr
  .c0_ddr4_ba               (c0_ddr4_ba               ), // output wire [1 : 0] c0_ddr4_ba
  .c0_ddr4_cke              (c0_ddr4_cke              ), // output wire [0 : 0] c0_ddr4_cke
  .c0_ddr4_cs_n             (c0_ddr4_cs_n             ), // output wire [0 : 0] c0_ddr4_cs_n
  .c0_ddr4_dm_dbi_n         (c0_ddr4_dm_dbi_n         ), // inout wire [1 : 0] c0_ddr4_dm_dbi_n
  .c0_ddr4_dq               (c0_ddr4_dq               ), // inout wire [15 : 0] c0_ddr4_dq
  .c0_ddr4_dqs_c            (c0_ddr4_dqs_c            ), // inout wire [1 : 0] c0_ddr4_dqs_c
  .c0_ddr4_dqs_t            (c0_ddr4_dqs_t            ), // inout wire [1 : 0] c0_ddr4_dqs_t
  .c0_ddr4_odt              (c0_ddr4_odt              ), // output wire [0 : 0] c0_ddr4_odt
  .c0_ddr4_bg               (c0_ddr4_bg               ), // output wire [0 : 0] c0_ddr4_bg
  .c0_ddr4_reset_n          (c0_ddr4_reset_n          ), // output wire c0_ddr4_reset_n
  .c0_ddr4_act_n            (c0_ddr4_act_n            ), // output wire c0_ddr4_act_n
  .c0_ddr4_ck_c             (c0_ddr4_ck_c             ), // output wire [0 : 0] c0_ddr4_ck_c
  .c0_ddr4_ck_t             (c0_ddr4_ck_t             ), // output wire [0 : 0] c0_ddr4_ck_t
  .c0_ddr4_ui_clk           (c0_ddr4_ui_clk           ), // output wire c0_ddr4_ui_clk
  .c0_ddr4_ui_clk_sync_rst  (c0_ddr4_ui_clk_sync_rst  ), // output wire c0_ddr4_ui_clk_sync_rst

  //app interface
  .c0_ddr4_app_en           (c0_ddr4_app_en           ), // input wire c0_ddr4_app_en
  .c0_ddr4_app_hi_pri       (c0_ddr4_app_hi_pri       ), // input wire c0_ddr4_app_hi_pri
  .c0_ddr4_app_wdf_end      (c0_ddr4_app_wdf_end      ), // input wire c0_ddr4_app_wdf_end
  .c0_ddr4_app_wdf_wren     (c0_ddr4_app_wdf_wren     ), // input wire c0_ddr4_app_wdf_wren
  .c0_ddr4_app_rd_data_end  (c0_ddr4_app_rd_data_end  ), // output wire c0_ddr4_app_rd_data_end
  .c0_ddr4_app_rd_data_valid(c0_ddr4_app_rd_data_valid), // output wire c0_ddr4_app_rd_data_valid
  .c0_ddr4_app_rdy          (c0_ddr4_app_rdy          ), // output wire c0_ddr4_app_rdy
  .c0_ddr4_app_wdf_rdy      (c0_ddr4_app_wdf_rdy      ), // output wire c0_ddr4_app_wdf_rdy
  .c0_ddr4_app_addr         (c0_ddr4_app_addr         ), // input wire [28 : 0] c0_ddr4_app_addr
  .c0_ddr4_app_cmd          (c0_ddr4_app_cmd          ), // input wire [2 : 0] c0_ddr4_app_cmd
  .c0_ddr4_app_wdf_data     (c0_ddr4_app_wdf_data     ), // input wire [127 : 0] c0_ddr4_app_wdf_data
  .c0_ddr4_app_wdf_mask     (c0_ddr4_app_wdf_mask     ), // input wire [15 : 0] c0_ddr4_app_wdf_mask
  .c0_ddr4_app_rd_data      (c0_ddr4_app_rd_data      ), // output wire [127 : 0] c0_ddr4_app_rd_data
  .sys_rst                  (I_RST_N                  )  // input wire sys_rst
);
endmodule