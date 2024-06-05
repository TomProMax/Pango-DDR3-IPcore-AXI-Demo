`timescale 1ns / 1ps

module ddr3_axi_test #(
    parameter MEM_ROW_ADDR_WIDTH = 15,
    parameter MEM_COL_ADDR_WIDTH = 10,
    parameter MEM_BADDR_WIDTH    = 3,
    parameter MEM_DQ_WIDTH       = 32,
    parameter MEM_DM_WIDTH       = MEM_DQ_WIDTH / 8,
    parameter MEM_DQS_WIDTH      = MEM_DQ_WIDTH / 8,
    parameter CTRL_ADDR_WIDTH    = MEM_ROW_ADDR_WIDTH + MEM_BADDR_WIDTH + MEM_COL_ADDR_WIDTH
) (
    input  wire                          ref_clk,
    input  wire                          rst_board,
    output wire                          mem_rst_n,
    output wire                          mem_ck,
    output wire                          mem_ck_n,
    output wire                          mem_cke,
    output wire                          mem_cs_n,
    output wire                          mem_ras_n,
    output wire                          mem_cas_n,
    output wire                          mem_we_n,
    output wire                          mem_odt,
    output wire [MEM_ROW_ADDR_WIDTH-1:0] mem_a,
    output wire [   MEM_BADDR_WIDTH-1:0] mem_ba,
    inout  wire [     MEM_DQS_WIDTH-1:0] mem_dqs,
    inout  wire [     MEM_DQS_WIDTH-1:0] mem_dqs_n,
    inout  wire [      MEM_DQ_WIDTH-1:0] mem_dq,
    output wire [      MEM_DM_WIDTH-1:0] mem_dm
);

  /*************************参数****************************/
  parameter MEM_SPACE_AW = CTRL_ADDR_WIDTH;
  parameter TH_1S = 27'd50_000_000;
  parameter TH_4MS = 27'd200_000;
  parameter REM_DQS_WIDTH = 4 - MEM_DQS_WIDTH;
  /*************************网表****************************/
  //ddr3
  wire                        resetn;
  wire                        core_clk_rst_n;
  wire                        core_clk;

  wire [ CTRL_ADDR_WIDTH-1:0] w_m_axi_awaddr;
  wire                        w_m_axi_awuser_ap;
  wire [                 3:0] w_m_axi_awuser_id;
  wire [                 3:0] w_m_axi_awlen;
  wire                        w_m_axi_awready;
  wire                        w_m_axi_awvalid;

  wire [  MEM_DQ_WIDTH*8-1:0] w_m_axi_wdata;
  wire [MEM_DQ_WIDTH*8/8-1:0] w_m_axi_wstrb;
  wire                        w_m_axi_wready;
  wire                        w_m_axi_wusero_id;
  wire                        w_m_axi_wusero_last;

  wire [ CTRL_ADDR_WIDTH-1:0] w_m_axi_araddr;
  wire                        w_m_axi_aruser_ap;
  wire [                 3:0] w_m_axi_aruser_id;
  wire [                 3:0] w_m_axi_arlen;
  wire                        w_m_axi_arready;
  wire                        w_m_axi_arvalid;

  wire [  MEM_DQ_WIDTH*8-1:0] w_m_axi_rdata;
  wire [                 3:0] w_m_axi_rid;
  wire                        w_m_axi_rlast;
  wire                        w_m_axi_rvalid;

  //rst
  assign resetn            = rst_board;
  //ddr3
  assign w_m_axi_awuser_ap = 'd0;
  assign w_m_axi_awuser_id = 'd0;
  assign w_m_axi_wstrb     = {MEM_DQ_WIDTH{1'd1}};
  assign w_m_axi_wusero_id = 'd0;
  assign w_m_axi_aruser_ap = 'd0;
  assign w_m_axi_aruser_id = 'd0;
  assign w_m_axi_rid       = 'd0;

  /*************************例化*****************************/
  //复位逻辑产生
  ipsxb_rst_sync_v1_1 u_core_clk_rst_sync (
      .clk       (core_clk),
      .rst_n     (resetn),
      .sig_async (1'b1),
      .sig_synced(core_clk_rst_n)
  );


  ddr3_ip #(
      .MEM_ROW_WIDTH   (MEM_ROW_ADDR_WIDTH),
      .MEM_COLUMN_WIDTH(MEM_COL_ADDR_WIDTH),
      .MEM_BANK_WIDTH  (MEM_BADDR_WIDTH),
      .MEM_DQ_WIDTH    (MEM_DQ_WIDTH),
      .MEM_DM_WIDTH    (MEM_DM_WIDTH),
      .MEM_DQS_WIDTH   (MEM_DQS_WIDTH),
      .CTRL_ADDR_WIDTH (CTRL_ADDR_WIDTH)
  ) u_ddr3_ip (
      //sys_interface
      .ref_clk                (ref_clk),
      .resetn                 (resetn),
      .ddr_init_done          (ddr_init_done),
      .ddrphy_clkin           (core_clk),
      .pll_lock               (pll_lock),
      //axi_interface
      .axi_awaddr             (w_m_axi_awaddr),
      .axi_awuser_ap          (w_m_axi_awuser_ap),
      .axi_awuser_id          (w_m_axi_awuser_id),
      .axi_awlen              (w_m_axi_awlen),
      .axi_awready            (w_m_axi_awready),
      .axi_awvalid            (w_m_axi_awvalid),
      .axi_wdata              (w_m_axi_wdata),
      .axi_wstrb              (w_m_axi_wstrb),
      .axi_wready             (w_m_axi_wready),
      .axi_wusero_id          (w_m_axi_wusero_id),
      .axi_wusero_last        (w_m_axi_wusero_last),
      .axi_araddr             (w_m_axi_araddr),
      .axi_aruser_ap          (w_m_axi_aruser_ap),
      .axi_aruser_id          (w_m_axi_aruser_id),
      .axi_arlen              (w_m_axi_arlen),
      .axi_arready            (w_m_axi_arready),
      .axi_arvalid            (w_m_axi_arvalid),
      .axi_rdata              (w_m_axi_rdata),
      .axi_rid                (w_m_axi_rid),
      .axi_rlast              (w_m_axi_rlast),
      .axi_rvalid             (w_m_axi_rvalid),
      //debug_interface
      .apb_clk                (1'b0),
      .apb_rst_n              (1'b0),
      .apb_sel                (1'b0),
      .apb_enable             (1'b0),
      .apb_addr               (8'd0),
      .apb_write              (1'b0),
      .apb_ready              (),
      .apb_wdata              (16'd0),
      .apb_rdata              (),
      .apb_int                (),
      .debug_data             (debug_data),
      .debug_slice_state      (debug_slice_state),
      .debug_calib_ctrl       (debug_calib_ctrl),
      .ck_dly_set_bin         (ck_dly_set_bin),
      .force_ck_dly_en        (force_ck_dly_en),
      .force_ck_dly_set_bin   (force_ck_dly_set_bin),
      .dll_step               (dll_step),
      .dll_lock               (dll_lock),
      .init_read_clk_ctrl     (init_read_clk_ctrl),
      .init_slip_step         (init_slip_step),
      .force_read_clk_ctrl    (force_read_clk_ctrl),
      .ddrphy_gate_update_en  (ddrphy_gate_update_en),
      .update_com_val_err_flag(update_com_val_err_flag),
      .rd_fake_stop           (rd_fake_stop),
      //hard_interface
      .mem_rst_n              (mem_rst_n),
      .mem_ck                 (mem_ck),
      .mem_ck_n               (mem_ck_n),
      .mem_cke                (mem_cke),
      .mem_cs_n               (mem_cs_n),
      .mem_ras_n              (mem_ras_n),
      .mem_cas_n              (mem_cas_n),
      .mem_we_n               (mem_we_n),
      .mem_odt                (mem_odt),
      .mem_a                  (mem_a),
      .mem_ba                 (mem_ba),
      .mem_dqs                (mem_dqs),
      .mem_dqs_n              (mem_dqs_n),
      .mem_dq                 (mem_dq),
      .mem_dm                 (mem_dm)
  );

  ddr3_ctrl #(
      .CTRL_ADDR_WIDTH(CTRL_ADDR_WIDTH),
      .MEM_DQ_WIDTH   (MEM_DQ_WIDTH),
      .MEM_SPACE_AW   (MEM_SPACE_AW)
  ) ddr3_ctrl (
      //sys
      .core_clk           (core_clk),
      .core_clk_rst_n     (core_clk_rst_n),
      .ddrc_init_done     (ddr_init_done),
      //axi
      .o_m_axi_awaddr     (w_m_axi_awaddr),
      .o_m_axi_awlen      (w_m_axi_awlen),
      .i_m_axi_awready    (w_m_axi_awready),
      .o_m_axi_awvalid    (w_m_axi_awvalid),
      .o_m_axi_wdata      (w_m_axi_wdata),
      .i_m_axi_wready     (w_m_axi_wready),
      .i_m_axi_wusero_last(w_m_axi_wusero_last),
      .o_m_axi_araddr     (w_m_axi_araddr),
      .o_m_axi_arlen      (w_m_axi_arlen),
      .i_m_axi_arready    (w_m_axi_arready),
      .o_m_axi_arvalid    (w_m_axi_arvalid),
      .i_m_axi_rdata      (w_m_axi_rdata),
      .i_m_axi_rlast      (w_m_axi_rlast),
      .i_m_axi_rvalid     (w_m_axi_rvalid)
  );


endmodule

