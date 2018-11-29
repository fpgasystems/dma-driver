`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2013 02:22:48 PM
// Design Name: 
// Module Name: mem_inf
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//`define WC64


module mem_inf #( 
    parameter C0_SIMULATION          =  "FALSE",
    parameter C1_SIMULATION           = "FALSE",
    parameter C0_SIM_BYPASS_INIT_CAL  = "OFF",
    parameter C1_SIM_BYPASS_INIT_CAL = "OFF"
)
(
input               clk156_25,
input               reset156_25_n,
//ddr3 pins
//SODIMM 0
   // Inouts
inout [71:0]        c0_ddr3_dq,
inout [8:0]         c0_ddr3_dqs_n,
inout [8:0]         c0_ddr3_dqs_p,
// Outputs
output [15:0]       c0_ddr3_addr,
output [2:0]        c0_ddr3_ba,
output              c0_ddr3_ras_n,
output              c0_ddr3_cas_n,
output              c0_ddr3_we_n,
output              c0_ddr3_reset_n,
output [1:0]        c0_ddr3_ck_p,
output [1:0]        c0_ddr3_ck_n,
output [1:0]        c0_ddr3_cke,
output [1:0]        c0_ddr3_cs_n,
output [1:0]        c0_ddr3_odt,
output              c0_ui_clk,
output              c0_init_calib_complete,
//CLOCKS and reset
input               c0_sys_clk_p,
input               c0_sys_clk_n,
input               clk_ref_p,
input               clk_ref_n,
input               c1_sys_clk_p,
input               c1_sys_clk_n,
input sys_rst,
//SODIMM 1
inout [71:0]        c1_ddr3_dq,
inout [8:0]         c1_ddr3_dqs_n,
inout [8:0]         c1_ddr3_dqs_p,
// Outputs
output [15:0]       c1_ddr3_addr,
output [2:0]        c1_ddr3_ba,
output              c1_ddr3_ras_n,
output              c1_ddr3_cas_n,
output              c1_ddr3_we_n,
output              c1_ddr3_reset_n,
output [1:0]        c1_ddr3_ck_p,
output [1:0]        c1_ddr3_ck_n,
output [1:0]        c1_ddr3_cke,
output [1:0]        c1_ddr3_cs_n,
output [1:0]        c1_ddr3_odt,
//ui outputs
output              c1_ui_clk,
output              c1_init_calib_complete,
//memory 0 read path
input               s_axis_mem0_read_cmd_tvalid,
output              s_axis_mem0_read_cmd_tready,
input[71:0]         s_axis_mem0_read_cmd_tdata,
//read status
output              m_axis_mem0_read_sts_tvalid,
input               m_axis_mem0_read_sts_tready,
output[7:0]         m_axis_mem0_read_sts_tdata,
//read stream
output[511:0]       m_axis_mem0_read_tdata,
output[63:0]        m_axis_mem0_read_tkeep,
output              m_axis_mem0_read_tlast,
output              m_axis_mem0_read_tvalid,
input               m_axis_mem0_read_tready,

//memory 0 write path
input               s_axis_mem0_write_cmd_tvalid,
output              s_axis_mem0_write_cmd_tready,
input[71:0]         s_axis_mem0_write_cmd_tdata,
//write status
output              m_axis_mem0_write_sts_tvalid,
input               m_axis_mem0_write_sts_tready,
output[7:0]         m_axis_mem0_write_sts_tdata,
//write stream
input[1023:0]       s_axis_mem0_write_tdata,
input[127:0]        s_axis_mem0_write_tkeep,
input               s_axis_mem0_write_tlast,
input               s_axis_mem0_write_tvalid,
output              s_axis_mem0_write_tready,

//memory 1 read path
input               s_axis_mem1_read_cmd_tvalid,
output              s_axis_mem1_read_cmd_tready,
input[71:0]         s_axis_mem1_read_cmd_tdata,
//read status
output              m_axis_mem1_read_sts_tvalid,
input               m_axis_mem1_read_sts_tready,
output[7:0]         m_axis_mem1_read_sts_tdata,
//read stream
output[511:0]        m_axis_mem1_read_tdata,
output[63:0]         m_axis_mem1_read_tkeep,
output              m_axis_mem1_read_tlast,
output              m_axis_mem1_read_tvalid,
input               m_axis_mem1_read_tready,

//memory 1 write path
input               s_axis_mem1_write_cmd_tvalid,
output              s_axis_mem1_write_cmd_tready,
input[71:0]         s_axis_mem1_write_cmd_tdata,
//write status
output              m_axis_mem1_write_sts_tvalid,
input               m_axis_mem1_write_sts_tready,
output[7:0]         m_axis_mem1_write_sts_tdata,
//write stream
input[1023:0]        s_axis_mem1_write_tdata,
input[127:0]         s_axis_mem1_write_tkeep,
input               s_axis_mem1_write_tlast,
input               s_axis_mem1_write_tvalid,
output              s_axis_mem1_write_tready

);

localparam C0_C_S_AXI_ID_WIDTH = 1;
localparam C0_C_S_AXI_ADDR_WIDTH = 32;
localparam C0_C_S_AXI_DATA_WIDTH = 512;
localparam C1_C_S_AXI_ID_WIDTH = 1;
localparam C1_C_S_AXI_ADDR_WIDTH = 32;
localparam C1_C_S_AXI_DATA_WIDTH = 512;

 // user interface signals
wire                                    c0_ui_clk_sync_rst;
wire                                    c0_mmcm_locked;
reg                                     c0_aresetn_r; 
// Slave Interface Write Address Ports
wire [C0_C_S_AXI_ID_WIDTH-1:0]          c0_s_axi_awid;
wire [C0_C_S_AXI_ADDR_WIDTH-1:0]        c0_s_axi_awaddr;
wire [7:0]                              c0_s_axi_awlen;
wire [2:0]                              c0_s_axi_awsize;
wire [1:0]                              c0_s_axi_awburst;
wire [0:0]                              c0_s_axi_awlock;
wire [3:0]                              c0_s_axi_awcache;
wire [2:0]                              c0_s_axi_awprot;
wire                                    c0_s_axi_awvalid;
wire                                    c0_s_axi_awready;
 // Slave Interface Write Data Ports
wire [C0_C_S_AXI_DATA_WIDTH-1:0]        c0_s_axi_wdata;
wire [(C0_C_S_AXI_DATA_WIDTH/8)-1:0]    c0_s_axi_wstrb;
wire                                    c0_s_axi_wlast;
wire                                    c0_s_axi_wvalid;
wire                                    c0_s_axi_wready;
 // Slave Interface Write Response Ports
wire                                    c0_s_axi_bready;
wire [C0_C_S_AXI_ID_WIDTH-1:0]          c0_s_axi_bid;
wire [1:0]                              c0_s_axi_bresp;
wire                                    c0_s_axi_bvalid;
 // Slave Interface Read Address Ports
wire [C0_C_S_AXI_ID_WIDTH-1:0]          c0_s_axi_arid;
wire [C0_C_S_AXI_ADDR_WIDTH-1:0]        c0_s_axi_araddr;
wire [7:0]                              c0_s_axi_arlen;
wire [2:0]                              c0_s_axi_arsize;
wire [1:0]                              c0_s_axi_arburst;
wire [0:0]                              c0_s_axi_arlock;
wire [3:0]                              c0_s_axi_arcache;
wire [2:0]                              c0_s_axi_arprot;
wire                                    c0_s_axi_arvalid;
wire                                    c0_s_axi_arready;
 // Slave Interface Read Data Ports
wire                                    c0_s_axi_rready;
wire [C0_C_S_AXI_ID_WIDTH-1:0]          c0_s_axi_rid;
wire [C0_C_S_AXI_DATA_WIDTH-1:0]        c0_s_axi_rdata;
wire [1:0]                              c0_s_axi_rresp;
wire                                    c0_s_axi_rlast;
wire                                    c0_s_axi_rvalid;
// user interface signals
wire                                    c1_ui_clk_sync_rst;
wire                                    c1_mmcm_locked;
reg                                     c1_aresetn_r;
// Slave Interface Write Address Ports
wire [C1_C_S_AXI_ID_WIDTH-1:0]          c1_s_axi_awid;
wire [C1_C_S_AXI_ADDR_WIDTH-1:0]        c1_s_axi_awaddr;
wire [7:0]                              c1_s_axi_awlen;
wire [2:0]                              c1_s_axi_awsize;
wire [1:0]                              c1_s_axi_awburst;
wire [0:0]                              c1_s_axi_awlock;
wire [3:0]                              c1_s_axi_awcache;
wire [2:0]                              c1_s_axi_awprot;
wire                                    c1_s_axi_awvalid;
wire                                    c1_s_axi_awready;
// Slave Interface Write Data Ports
wire [C1_C_S_AXI_DATA_WIDTH-1:0]        c1_s_axi_wdata;
wire [(C1_C_S_AXI_DATA_WIDTH/8)-1:0]    c1_s_axi_wstrb;
wire                                    c1_s_axi_wlast;
wire                                    c1_s_axi_wvalid;
wire                                    c1_s_axi_wready;
// Slave Interface Write Response Ports
wire                                    c1_s_axi_bready;
wire [C1_C_S_AXI_ID_WIDTH-1:0]          c1_s_axi_bid;
wire [1:0]                              c1_s_axi_bresp;
wire                                    c1_s_axi_bvalid;
// Slave Interface Read Address Ports
wire [C1_C_S_AXI_ID_WIDTH-1:0]          c1_s_axi_arid;
wire [C1_C_S_AXI_ADDR_WIDTH-1:0]        c1_s_axi_araddr;
wire [7:0]                              c1_s_axi_arlen;
wire [2:0]                              c1_s_axi_arsize;
wire [1:0]                              c1_s_axi_arburst;
wire [0:0]                              c1_s_axi_arlock;
wire [3:0]                              c1_s_axi_arcache;
wire [2:0]                              c1_s_axi_arprot;
wire                                    c1_s_axi_arvalid;
wire                                    c1_s_axi_arready;
// Slave Interface Read Data Ports
wire                                    c1_s_axi_rready;
wire [C1_C_S_AXI_ID_WIDTH-1:0]          c1_s_axi_rid;
wire [C1_C_S_AXI_DATA_WIDTH-1:0]        c1_s_axi_rdata;
wire [1:0]                              c1_s_axi_rresp;
wire                                    c1_s_axi_rlast;
wire                                    c1_s_axi_rvalid;

mig_7series_0 u_mig_7series_0 (
  // Memory interface ports
  .c0_ddr3_addr                         (c0_ddr3_addr),            // output [15:0]        c0_ddr3_addr
  .c0_ddr3_ba                           (c0_ddr3_ba),              // output [2:0]        c0_ddr3_ba
  .c0_ddr3_cas_n                        (c0_ddr3_cas_n),           // output            c0_ddr3_cas_n
  .c0_ddr3_ck_n                         (c0_ddr3_ck_n),            // output [1:0]        c0_ddr3_ck_n
  .c0_ddr3_ck_p                         (c0_ddr3_ck_p),            // output [1:0]        c0_ddr3_ck_p
  .c0_ddr3_cke                          (c0_ddr3_cke),             // output [1:0]        c0_ddr3_cke
  .c0_ddr3_ras_n                        (c0_ddr3_ras_n),           // output            c0_ddr3_ras_n
  .c0_ddr3_reset_n                      (c0_ddr3_reset_n),         // output            c0_ddr3_reset_n
  .c0_ddr3_we_n                         (c0_ddr3_we_n),            // output            c0_ddr3_we_n
  .c0_ddr3_dq                           (c0_ddr3_dq),              // inout [71:0]        c0_ddr3_dq
  .c0_ddr3_dqs_n                        (c0_ddr3_dqs_n),           // inout [8:0]        c0_ddr3_dqs_n
  .c0_ddr3_dqs_p                        (c0_ddr3_dqs_p),           // inout [8:0]        c0_ddr3_dqs_p
  .c0_init_calib_complete               (c0_init_calib_complete),  // output            init_calib_complete
    
  .c0_ddr3_cs_n                         (c0_ddr3_cs_n),            // output [1:0]        c0_ddr3_cs_n
  .c0_ddr3_odt                          (c0_ddr3_odt),             // output [1:0]        c0_ddr3_odt
  // Application interface ports        
  .c0_ui_clk                            (c0_ui_clk),               // output            c0_ui_clk
  .c0_ui_clk_sync_rst                   (c0_ui_clk_sync_rst),      // output            c0_ui_clk_sync_rst
  .c0_mmcm_locked                       (c0_mmcm_locked),          // output            c0_mmcm_locked
  .c0_aresetn                           (c0_aresetn_r),            // input            c0_aresetn
  .c0_app_sr_req                        (0),                       // input            c0_app_sr_req
  .c0_app_ref_req                       (0),                       // input            c0_app_ref_req
  .c0_app_zq_req                        (0),                       // input            c0_app_zq_req
  .c0_app_sr_active                     (),        // output            c0_app_sr_active
  .c0_app_ref_ack                       (),          // output            c0_app_ref_ack
  .c0_app_zq_ack                        (),           // output            c0_app_zq_ack
  // Slave Interface Write Address Ports
  .c0_s_axi_awid                        (c0_s_axi_awid),           // input [0:0]            c0_s_axi_awid
  .c0_s_axi_awaddr                      ({1'b0, c0_s_axi_awaddr[31:0]}),  // input [32:0]            c0_s_axi_awaddr
  .c0_s_axi_awlen                       (c0_s_axi_awlen),          // input [7:0]            c0_s_axi_awlen
  .c0_s_axi_awsize                      (c0_s_axi_awsize),         // input [2:0]            c0_s_axi_awsize
  .c0_s_axi_awburst                     (c0_s_axi_awburst),        // input [1:0]            c0_s_axi_awburst
  .c0_s_axi_awlock                      (0),                       // input [0:0]            c0_s_axi_awlock
  .c0_s_axi_awcache                     (0),                       // input [3:0]            c0_s_axi_awcache
  .c0_s_axi_awprot                      (0),                       // input [2:0]            c0_s_axi_awprot
  .c0_s_axi_awqos                       (0),                       // input [3:0]            c0_s_axi_awqos
  .c0_s_axi_awvalid                     (c0_s_axi_awvalid),        // input            c0_s_axi_awvalid
  .c0_s_axi_awready                     (c0_s_axi_awready),        // output            c0_s_axi_awready
  // Slave Interface Write Data Ports
  .c0_s_axi_wdata                       (c0_s_axi_wdata),          // input [511:0]            c0_s_axi_wdata
  .c0_s_axi_wstrb                       (c0_s_axi_wstrb),          // input [63:0]            c0_s_axi_wstrb
  .c0_s_axi_wlast                       (c0_s_axi_wlast),          // input            c0_s_axi_wlast
  .c0_s_axi_wvalid                      (c0_s_axi_wvalid),         // input            c0_s_axi_wvalid
  .c0_s_axi_wready                      (c0_s_axi_wready),         // output            c0_s_axi_wready
  // Slave Interface Write Response Ports
  .c0_s_axi_bid                         (c0_s_axi_bid),            // output [0:0]            c0_s_axi_bid
  .c0_s_axi_bresp                       (c0_s_axi_bresp),          // output [1:0]            c0_s_axi_bresp
  .c0_s_axi_bvalid                      (c0_s_axi_bvalid),         // output            c0_s_axi_bvalid
  .c0_s_axi_bready                      (c0_s_axi_bready),         // input            c0_s_axi_bready
  // Slave Interface Read Address Ports
  .c0_s_axi_arid                        (c0_s_axi_arid),           // input [0:0]            c0_s_axi_arid
  .c0_s_axi_araddr                      ({1'b0, c0_s_axi_araddr[31:0]}),  // input [32:0]            c0_s_axi_araddr
  .c0_s_axi_arlen                       (c0_s_axi_arlen),          // input [7:0]            c0_s_axi_arlen
  .c0_s_axi_arsize                      (c0_s_axi_arsize),         // input [2:0]            c0_s_axi_arsize
  .c0_s_axi_arburst                     (c0_s_axi_arburst),        // input [1:0]            c0_s_axi_arburst
  .c0_s_axi_arlock                      (0),                       // input [0:0]            c0_s_axi_arlock
  .c0_s_axi_arcache                     (0),                       // input [3:0]            c0_s_axi_arcache
  .c0_s_axi_arprot                      (0),                       // input [2:0]            c0_s_axi_arprot
  .c0_s_axi_arqos                       (0),                       // input [3:0]            c0_s_axi_arqos
  .c0_s_axi_arvalid                     (c0_s_axi_arvalid),        // input            c0_s_axi_arvalid
  .c0_s_axi_arready                     (c0_s_axi_arready),        // output            c0_s_axi_arready
  // Slave Interface Read Data Ports
  .c0_s_axi_rid                         (c0_s_axi_rid),            // output [0:0]            c0_s_axi_rid
  .c0_s_axi_rdata                       (c0_s_axi_rdata),          // output [511:0]            c0_s_axi_rdata
  .c0_s_axi_rresp                       (c0_s_axi_rresp),          // output [1:0]            c0_s_axi_rresp
  .c0_s_axi_rlast                       (c0_s_axi_rlast),          // output            c0_s_axi_rlast
  .c0_s_axi_rvalid                      (c0_s_axi_rvalid),         // output            c0_s_axi_rvalid
  .c0_s_axi_rready                      (c0_s_axi_rready),         // input            c0_s_axi_rready
  // AXI CTRL port
  .c0_s_axi_ctrl_awvalid                (0),                       // input            c0_s_axi_ctrl_awvalid
  .c0_s_axi_ctrl_awready                (),   // output            c0_s_axi_ctrl_awready
  .c0_s_axi_ctrl_awaddr                 (0),                       // input [31:0]            c0_s_axi_ctrl_awaddr
  // Slave Interface Write Data Ports   
  .c0_s_axi_ctrl_wvalid                 (0),                       // input            c0_s_axi_ctrl_wvalid
  .c0_s_axi_ctrl_wready                 (),    // output            c0_s_axi_ctrl_wready
  .c0_s_axi_ctrl_wdata                  (0),                       // input [31:0]            c0_s_axi_ctrl_wdata
  // Slave Interface Write Response Ports
  .c0_s_axi_ctrl_bvalid                 (),    // output            c0_s_axi_ctrl_bvalid
  .c0_s_axi_ctrl_bready                 (1),                       // input            c0_s_axi_ctrl_bready
  .c0_s_axi_ctrl_bresp                  (),     // output [1:0]            c0_s_axi_ctrl_bresp
  // Slave Interface Read Address Ports
  .c0_s_axi_ctrl_arvalid                (0),                       // input            c0_s_axi_ctrl_arvalid
  .c0_s_axi_ctrl_arready                (),   // output            c0_s_axi_ctrl_arready
  .c0_s_axi_ctrl_araddr                 (0),                       // input [31:0]            c0_s_axi_ctrl_araddr
  // Slave Interface Read Data Ports
  .c0_s_axi_ctrl_rvalid                 (),    // output            c0_s_axi_ctrl_rvalid
  .c0_s_axi_ctrl_rready                 (1),                       // input            c0_s_axi_ctrl_rready
  .c0_s_axi_ctrl_rdata                  (),     // output [31:0]            c0_s_axi_ctrl_rdata
  .c0_s_axi_ctrl_rresp                  (),     // output [1:0]            c0_s_axi_ctrl_rresp
  // Interrupt output
  .c0_interrupt                         (),                        // output            c0_interrupt
  .c0_app_ecc_multiple_err              (), // output [7:0]            c0_app_ecc_multiple_err
  // System Clock Ports
  .c0_sys_clk_p                         (c0_sys_clk_p),           // input                c0_sys_clk_p
  .c0_sys_clk_n                         (c0_sys_clk_n),           // input                c0_sys_clk_n
  // Reference Clock Ports
  .clk_ref_p                            (clk_ref_p),                  // input                clk_ref_p
  .clk_ref_n                            (clk_ref_n),                  // input                clk_ref_n
  // Memory interface ports
  .c1_ddr3_addr                         (c1_ddr3_addr),            // output [15:0]        c1_ddr3_addr
  .c1_ddr3_ba                           (c1_ddr3_ba),              // output [2:0]        c1_ddr3_ba
  .c1_ddr3_cas_n                        (c1_ddr3_cas_n),           // output            c1_ddr3_cas_n
  .c1_ddr3_ck_n                         (c1_ddr3_ck_n),            // output [1:0]        c1_ddr3_ck_n
  .c1_ddr3_ck_p                         (c1_ddr3_ck_p),            // output [1:0]        c1_ddr3_ck_p
  .c1_ddr3_cke                          (c1_ddr3_cke),             // output [1:0]        c1_ddr3_cke
  .c1_ddr3_ras_n                        (c1_ddr3_ras_n),           // output            c1_ddr3_ras_n
  .c1_ddr3_reset_n                      (c1_ddr3_reset_n),         // output            c1_ddr3_reset_n
  .c1_ddr3_we_n                         (c1_ddr3_we_n),            // output            c1_ddr3_we_n
  .c1_ddr3_dq                           (c1_ddr3_dq),              // inout [71:0]        c1_ddr3_dq
  .c1_ddr3_dqs_n                        (c1_ddr3_dqs_n),           // inout [8:0]        c1_ddr3_dqs_n
  .c1_ddr3_dqs_p                        (c1_ddr3_dqs_p),           // inout [8:0]        c1_ddr3_dqs_p
  .c1_init_calib_complete               (c1_init_calib_complete),  // output            init_calib_complete
    
  .c1_ddr3_cs_n                         (c1_ddr3_cs_n),            // output [1:0]        c1_ddr3_cs_n
  .c1_ddr3_odt                          (c1_ddr3_odt),             // output [1:0]        c1_ddr3_odt
  // Application interface ports
  .c1_ui_clk                            (c1_ui_clk),               // output            c1_ui_clk
  .c1_ui_clk_sync_rst                   (c1_ui_clk_sync_rst),      // output            c1_ui_clk_sync_rst
  .c1_mmcm_locked                       (c1_mmcm_locked),          // output            c1_mmcm_locked
  .c1_aresetn                           (c1_aresetn_r),            // input            c1_aresetn
  .c1_app_sr_req                        (0),                       // input            c1_app_sr_req
  .c1_app_ref_req                       (0),                       // input            c1_app_ref_req
  .c1_app_zq_req                        (0),                       // input            c1_app_zq_req
  .c1_app_sr_active                     (),        // output            c1_app_sr_active
  .c1_app_ref_ack                       (),          // output            c1_app_ref_ack
  .c1_app_zq_ack                        (),           // output            c1_app_zq_ack
  // Slave Interface Write Address Ports
  .c1_s_axi_awid                        (c1_s_axi_awid),           // input [0:0]            c1_s_axi_awid
  .c1_s_axi_awaddr                      ({1'b0, c1_s_axi_awaddr[31:0]}),  // input [32:0]            c1_s_axi_awaddr
  .c1_s_axi_awlen                       (c1_s_axi_awlen),          // input [7:0]            c1_s_axi_awlen
  .c1_s_axi_awsize                      (c1_s_axi_awsize),         // input [2:0]            c1_s_axi_awsize
  .c1_s_axi_awburst                     (c1_s_axi_awburst),        // input [1:0]            c1_s_axi_awburst
  .c1_s_axi_awlock                      (0),                       // input [0:0]            c1_s_axi_awlock
  .c1_s_axi_awcache                     (0),                       // input [3:0]            c1_s_axi_awcache
  .c1_s_axi_awprot                      (0),                       // input [2:0]            c1_s_axi_awprot
  .c1_s_axi_awqos                       (0),                       // input [3:0]            c1_s_axi_awqos
  .c1_s_axi_awvalid                     (c1_s_axi_awvalid),        // input            c1_s_axi_awvalid
  .c1_s_axi_awready                     (c1_s_axi_awready),        // output            c1_s_axi_awready
  // Slave Interface Write Data Ports
  .c1_s_axi_wdata                       (c1_s_axi_wdata),          // input [511:0]            c1_s_axi_wdata
  .c1_s_axi_wstrb                       (c1_s_axi_wstrb),          // input [63:0]            c1_s_axi_wstrb
  .c1_s_axi_wlast                       (c1_s_axi_wlast),          // input            c1_s_axi_wlast
  .c1_s_axi_wvalid                      (c1_s_axi_wvalid),         // input            c1_s_axi_wvalid
  .c1_s_axi_wready                      (c1_s_axi_wready),         // output            c1_s_axi_wready
  // Slave Interface Write Response Ports
  .c1_s_axi_bid                         (c1_s_axi_bid),            // output [0:0]            c1_s_axi_bid
  .c1_s_axi_bresp                       (c1_s_axi_bresp),          // output [1:0]            c1_s_axi_bresp
  .c1_s_axi_bvalid                      (c1_s_axi_bvalid),         // output            c1_s_axi_bvalid
  .c1_s_axi_bready                      (c1_s_axi_bready),         // input            c1_s_axi_bready
  // Slave Interface Read Address Ports
  .c1_s_axi_arid                        (c1_s_axi_arid),           // input [0:0]            c1_s_axi_arid
  .c1_s_axi_araddr                      ({1'b0, c1_s_axi_araddr[31:0]}),  // input [32:0]            c1_s_axi_araddr
  .c1_s_axi_arlen                       (c1_s_axi_arlen),          // input [7:0]            c1_s_axi_arlen
  .c1_s_axi_arsize                      (c1_s_axi_arsize),         // input [2:0]            c1_s_axi_arsize
  .c1_s_axi_arburst                     (c1_s_axi_arburst),        // input [1:0]            c1_s_axi_arburst
  .c1_s_axi_arlock                      (0),                       // input [0:0]            c1_s_axi_arlock
  .c1_s_axi_arcache                     (0),                       // input [3:0]            c1_s_axi_arcache
  .c1_s_axi_arprot                      (0),                       // input [2:0]            c1_s_axi_arprot
  .c1_s_axi_arqos                       (0),                       // input [3:0]            c1_s_axi_arqos
  .c1_s_axi_arvalid                     (c1_s_axi_arvalid),        // input            c1_s_axi_arvalid
  .c1_s_axi_arready                     (c1_s_axi_arready),        // output            c1_s_axi_arready
  // Slave Interface Read Data Ports
  .c1_s_axi_rid                         (c1_s_axi_rid),            // output [0:0]            c1_s_axi_rid
  .c1_s_axi_rdata                       (c1_s_axi_rdata),          // output [511:0]            c1_s_axi_rdata
  .c1_s_axi_rresp                       (c1_s_axi_rresp),          // output [1:0]            c1_s_axi_rresp
  .c1_s_axi_rlast                       (c1_s_axi_rlast),          // output            c1_s_axi_rlast
  .c1_s_axi_rvalid                      (c1_s_axi_rvalid),         // output            c1_s_axi_rvalid
  .c1_s_axi_rready                      (c1_s_axi_rready),         // input            c1_s_axi_rready
  // AXI CTRL port
  .c1_s_axi_ctrl_awvalid                (0),                       // input            c1_s_axi_ctrl_awvalid
  .c1_s_axi_ctrl_awready                (),   // output            c1_s_axi_ctrl_awready
  .c1_s_axi_ctrl_awaddr                 (0),                       // input [31:0]            c1_s_axi_ctrl_awaddr
  // Slave Interface Write Data Ports
  .c1_s_axi_ctrl_wvalid                 (0),                       // input            c1_s_axi_ctrl_wvalid
  .c1_s_axi_ctrl_wready                 (),    // output            c1_s_axi_ctrl_wready
  .c1_s_axi_ctrl_wdata                  (0),                       // input [31:0]            c1_s_axi_ctrl_wdata
  // Slave Interface Write Response Ports
  .c1_s_axi_ctrl_bvalid                 (),    // output            c1_s_axi_ctrl_bvalid
  .c1_s_axi_ctrl_bready                 (1),                       // input            c1_s_axi_ctrl_bready
  .c1_s_axi_ctrl_bresp                  (),     // output [1:0]            c1_s_axi_ctrl_bresp
  // Slave Interface Read Address Ports
  .c1_s_axi_ctrl_arvalid                (0),                       // input            c1_s_axi_ctrl_arvalid
  .c1_s_axi_ctrl_arready                (),   // output            c1_s_axi_ctrl_arready
  .c1_s_axi_ctrl_araddr                 (0),                       // input [31:0]            c1_s_axi_ctrl_araddr
  // Slave Interface Read Data Ports
  .c1_s_axi_ctrl_rvalid                 (),    // output            c1_s_axi_ctrl_rvalid
  .c1_s_axi_ctrl_rready                 (1),                       // input            c1_s_axi_ctrl_rready
  .c1_s_axi_ctrl_rdata                  (),     // output [31:0]            c1_s_axi_ctrl_rdata
  .c1_s_axi_ctrl_rresp                  (),     // output [1:0]            c1_s_axi_ctrl_rresp
  // Interrupt output
  .c1_interrupt                         (),                        // output            c1_interrupt
  .c1_app_ecc_multiple_err              (), // output [7:0]            c1_app_ecc_multiple_err
  // System Clock Ports
  .c1_sys_clk_p                         (c1_sys_clk_p),           // input                c1_sys_clk_p
  .c1_sys_clk_n                         (c1_sys_clk_n),           // input                c1_sys_clk_n
  .sys_rst                              (sys_rst)                     // input sys_rst
  );

always @(posedge c0_ui_clk)
    c0_aresetn_r <= ~c0_ui_clk_sync_rst & c0_mmcm_locked;
    
always @(posedge c1_ui_clk)
    c1_aresetn_r <= ~c1_ui_clk_sync_rst & c1_mmcm_locked;
    
/*
 * CLOCK CROSSING
 */
wire        axis_mem0_slice_to_cc_write_tvalid;
wire        axis_mem0_slice_to_cc_write_tready;
wire[1023:0] axis_mem0_slice_to_cc_write_tdata;
wire[127:0]  axis_mem0_slice_to_cc_write_tkeep;
wire        axis_mem0_slice_to_cc_write_tlast;

wire        axis_mem0_cc_to_slice_write_tvalid;
wire        axis_mem0_cc_to_slice_write_tready;
wire[1023:0] axis_mem0_cc_to_slice_write_tdata;
wire[127:0]  axis_mem0_cc_to_slice_write_tkeep;
wire        axis_mem0_cc_to_slice_write_tlast;


wire        axis_mem0_slice_to_dm_write_tvalid;
wire        axis_mem0_slice_to_dm_write_tready;
wire[511:0] axis_mem0_slice_to_dm_write_tdata;
wire[63:0]  axis_mem0_slice_to_dm_write_tkeep;
wire        axis_mem0_slice_to_dm_write_tlast;

wire        axis_mem0_dm_to_cc_read_tvalid;
wire        axis_mem0_dm_to_cc_read_tready;
wire[511:0] axis_mem0_dm_to_cc_read_tdata;
wire[63:0]  axis_mem0_dm_to_cc_read_tkeep;
wire        axis_mem0_dm_to_cc_read_tlast;

wire        axis_mem0_slice_to_dm_write_cmd_tvalid;
wire        axis_mem0_slice_to_dm_write_cmd_tready;
wire[71:0]  axis_mem0_slice_to_dm_write_cmd_tdata;

wire        axis_mem0_slice_to_dm_write_sts_tvalid;
wire        axis_mem0_slice_to_dm_write_sts_tready;
wire[7:0]   axis_mem0_slice_to_dm_write_sts_tdata;

//write cmd
//axis_register_slice_72 m1_cmd_slice (
axis_data_fifo_72 m0_cmd_fifo (
  //.aclk(clk156_25),                    // input wire aclk
  //.aresetn(reset156_25_n),              // input wire aresetn
  .s_axis_aclk(clk156_25),
  .s_axis_aresetn(reset156_25_n),
  .s_axis_tvalid(s_axis_mem0_write_cmd_tvalid),  // input wire s_axis_tvalid
  .s_axis_tready(s_axis_mem0_write_cmd_tready),  // output wire s_axis_tready
  .s_axis_tdata(s_axis_mem0_write_cmd_tdata),    // input wire [95 : 0] s_axis_tdata
  //.m_axis_aclk(clk156_25),
  //.m_axis_aresetn(reset156_25_n),
  .m_axis_tvalid(axis_mem0_slice_to_dm_write_cmd_tvalid),  // output wire m_axis_tvalid
  .m_axis_tready(axis_mem0_slice_to_dm_write_cmd_tready),  // input wire m_axis_tready
  .m_axis_tdata(axis_mem0_slice_to_dm_write_cmd_tdata),    // output wire [95 : 0] m_axis_tdata
  .axis_data_count(),
  .axis_wr_data_count(),
  .axis_rd_data_count()
);

//write status
axis_register_slice_64 m0_status_slice (
  .aclk(clk156_25),                    // input wire aclk
  .aresetn(reset156_25_n),              // input wire aresetn
  .s_axis_tvalid(axis_mem0_slice_to_dm_write_sts_tvalid),  // input wire s_axis_tvalid
  .s_axis_tready(axis_mem0_slice_to_dm_write_sts_tready),  // output wire s_axis_tready
  .s_axis_tdata(axis_mem0_slice_to_dm_write_sts_tdata),    // input wire [95 : 0] s_axis_tdata
  .s_axis_tkeep(8'h0),
  .s_axis_tlast(1'b0),
  .m_axis_tvalid(m_axis_mem0_write_sts_tvalid),  // output wire m_axis_tvalid
  .m_axis_tready(m_axis_mem0_write_sts_tready),  // input wire m_axis_tready
  .m_axis_tdata(m_axis_mem0_write_sts_tdata)    // output wire [95 : 0] m_axis_tdata
);

//axis_register_slice_512 m0_write_slice_to_cc (
axis_data_fifo_1024 m0_write_fifo_to_cc (
//TODO
  //.aclk(clk156_25),                    // input wire aclk
  //.aresetn(reset156_25_n),              // input wire aresetn
  .s_axis_aclk(clk156_25),
  .s_axis_aresetn(reset156_25_n),
  .s_axis_tvalid(s_axis_mem0_write_tvalid),  // input wire s_axis_tvalid
  .s_axis_tready(s_axis_mem0_write_tready),  // output wire s_axis_tready
  .s_axis_tdata(s_axis_mem0_write_tdata),    // input wire [511 : 0] s_axis_tdata
  .s_axis_tkeep(s_axis_mem0_write_tkeep),    // input wire [63 : 0] s_axis_tkeep
  .s_axis_tlast(s_axis_mem0_write_tlast),    // input wire s_axis_tlast
  .m_axis_tvalid(axis_mem0_slice_to_cc_write_tvalid),  // output wire m_axis_tvalid
  .m_axis_tready(axis_mem0_slice_to_cc_write_tready),  // input wire m_axis_tready
  .m_axis_tdata(axis_mem0_slice_to_cc_write_tdata),    // output wire [511 : 0] m_axis_tdata
  .m_axis_tkeep(axis_mem0_slice_to_cc_write_tkeep),    // output wire [63 : 0] m_axis_tkeep
  .m_axis_tlast(axis_mem0_slice_to_cc_write_tlast),    // output wire m_axis_tlast
  .axis_data_count(),
  .axis_wr_data_count(),
  .axis_rd_data_count()
);

axis_clock_converter_1024 axis_clock_converter_mem0 (
   .s_axis_aclk(clk156_25),        // input wire s_axis_aclk
   .s_axis_aresetn(reset156_25_n),  // input wire s_axis_aresetn
   .s_axis_tvalid(axis_mem0_slice_to_cc_write_tvalid),    // input wire s_axis_tvalid
   .s_axis_tready(axis_mem0_slice_to_cc_write_tready),    // output wire s_axis_tready
   .s_axis_tdata(axis_mem0_slice_to_cc_write_tdata),      // input wire [511 : 0] s_axis_tdata
   .s_axis_tkeep(axis_mem0_slice_to_cc_write_tkeep),      // input wire [63 : 0] s_axis_tkeep
   .s_axis_tlast(axis_mem0_slice_to_cc_write_tlast),      // input wire s_axis_tlast
   
   .m_axis_aclk(c0_ui_clk),        // input wire m_axis_aclk
   .m_axis_aresetn(c0_aresetn_r),  // input wire m_axis_aresetn
   .m_axis_tvalid(axis_mem0_cc_to_slice_write_tvalid),    // output wire m_axis_tvalid
   .m_axis_tready(axis_mem0_cc_to_slice_write_tready),    // input wire m_axis_tready
   .m_axis_tdata(axis_mem0_cc_to_slice_write_tdata),      // output wire [511 : 0] m_axis_tdata
   .m_axis_tkeep(axis_mem0_cc_to_slice_write_tkeep),      // output wire [63 : 0] m_axis_tkeep
   .m_axis_tlast(axis_mem0_cc_to_slice_write_tlast)      // output wire m_axis_tlast
 );
 
 
 `ifdef WC64
 assign axis_mem0_slice_to_dm_write_tvalid = axis_mem0_cc_to_slice_write_tvalid;
 assign axis_mem0_cc_to_slice_write_tready = axis_mem0_slice_to_dm_write_tready;
 assign axis_mem0_slice_to_dm_write_tdata = axis_mem0_cc_to_slice_write_tdata;
 assign axis_mem0_slice_to_dm_write_tkeep = axis_mem0_cc_to_slice_write_tkeep;
 assign axis_mem0_slice_to_dm_write_tlast = axis_mem0_cc_to_slice_write_tlast;
 `else
 //axis_register_slice_1024 m0_write_slice_to_dm (
 axis_1024_to_512_converter m0_write_converter_to_dm (
   .aclk(c0_ui_clk),                    // input wire aclk
   .aresetn(c0_aresetn_r),              // input wire aresetn
   .s_axis_tvalid(axis_mem0_cc_to_slice_write_tvalid),  // input wire s_axis_tvalid
   .s_axis_tready(axis_mem0_cc_to_slice_write_tready),  // output wire s_axis_tready
   .s_axis_tdata(axis_mem0_cc_to_slice_write_tdata),    // input wire [511 : 0] s_axis_tdata
   .s_axis_tkeep(axis_mem0_cc_to_slice_write_tkeep),    // input wire [63 : 0] s_axis_tkeep
   .s_axis_tlast(axis_mem0_cc_to_slice_write_tlast),    // input wire s_axis_tlast
   .m_axis_tvalid(axis_mem0_slice_to_dm_write_tvalid),  // output wire m_axis_tvalid
   .m_axis_tready(axis_mem0_slice_to_dm_write_tready),  // input wire m_axis_tready
   .m_axis_tdata(axis_mem0_slice_to_dm_write_tdata),    // output wire [511 : 0] m_axis_tdata
   .m_axis_tkeep(axis_mem0_slice_to_dm_write_tkeep),    // output wire [63 : 0] m_axis_tkeep
   .m_axis_tlast(axis_mem0_slice_to_dm_write_tlast)    // output wire m_axis_tlast
 );
 `endif
 
  axis_data_fifo_512_cc axis_read_data_fifo_mem0 (
   .s_axis_aclk(c0_ui_clk),                // input wire s_axis_aclk
   .s_axis_aresetn(c0_aresetn_r),          // input wire s_axis_aresetn
   .s_axis_tvalid(axis_mem0_dm_to_cc_read_tvalid),            // input wire s_axis_tvalid
   .s_axis_tready(axis_mem0_dm_to_cc_read_tready),            // output wire s_axis_tready
   .s_axis_tdata(axis_mem0_dm_to_cc_read_tdata),              // input wire [255 : 0] s_axis_tdata
   .s_axis_tkeep(axis_mem0_dm_to_cc_read_tkeep),              // input wire [31 : 0] s_axis_tkeep
   .s_axis_tlast(axis_mem0_dm_to_cc_read_tlast),              // input wire s_axis_tlast
   
   .m_axis_aclk(clk156_25),                // input wire m_axis_aclk
   .m_axis_aresetn(reset156_25_n),          // input wire m_axis_aresetn
   .m_axis_tvalid(m_axis_mem0_read_tvalid),            // output wire m_axis_tvalid
   .m_axis_tready(m_axis_mem0_read_tready),            // input wire m_axis_tready
   .m_axis_tdata(m_axis_mem0_read_tdata),              // output wire [255 : 0] m_axis_tdata
   .m_axis_tkeep(m_axis_mem0_read_tkeep),              // output wire [31 : 0] m_axis_tkeep
   .m_axis_tlast(m_axis_mem0_read_tlast),              // output wire m_axis_tlast
   
   .axis_data_count(),        // output wire [31 : 0] axis_data_count
   .axis_wr_data_count(),  // output wire [31 : 0] axis_wr_data_count
   .axis_rd_data_count()  // output wire [31 : 0] axis_rd_data_count
 );


wire        axis_mem1_slice_to_cc_write_tvalid;
wire        axis_mem1_slice_to_cc_write_tready;
wire[1023:0] axis_mem1_slice_to_cc_write_tdata;
wire[127:0]  axis_mem1_slice_to_cc_write_tkeep;
wire        axis_mem1_slice_to_cc_write_tlast;

wire        axis_mem1_cc_to_slice_write_tvalid;
wire        axis_mem1_cc_to_slice_write_tready;
wire[1023:0] axis_mem1_cc_to_slice_write_tdata;
wire[127:0]  axis_mem1_cc_to_slice_write_tkeep;
wire        axis_mem1_cc_to_slice_write_tlast;

wire        axis_mem1_slice_to_dm_write_tvalid;
wire        axis_mem1_slice_to_dm_write_tready;
wire[511:0] axis_mem1_slice_to_dm_write_tdata;
wire[63:0]  axis_mem1_slice_to_dm_write_tkeep;
wire        axis_mem1_slice_to_dm_write_tlast;

wire        axis_mem1_dm_to_cc_read_tvalid;
wire        axis_mem1_dm_to_cc_read_tready;
wire[511:0] axis_mem1_dm_to_cc_read_tdata;
wire[63:0]  axis_mem1_dm_to_cc_read_tkeep;
wire        axis_mem1_dm_to_cc_read_tlast;

wire        axis_mem1_slice_to_dm_write_cmd_tvalid;
wire        axis_mem1_slice_to_dm_write_cmd_tready;
wire[71:0]  axis_mem1_slice_to_dm_write_cmd_tdata;


wire        axis_mem1_slice_to_dm_write_sts_tvalid;
wire        axis_mem1_slice_to_dm_write_sts_tready;
wire[7:0]   axis_mem1_slice_to_dm_write_sts_tdata;

//write cmd
//axis_register_slice_72 m1_cmd_slice (
axis_data_fifo_72 m1_cmd_fifo (
  //.aclk(clk156_25),                    // input wire aclk
  //.aresetn(reset156_25_n),              // input wire aresetn
  .s_axis_aclk(clk156_25),
  .s_axis_aresetn(reset156_25_n),
  .s_axis_tvalid(s_axis_mem1_write_cmd_tvalid),  // input wire s_axis_tvalid
  .s_axis_tready(s_axis_mem1_write_cmd_tready),  // output wire s_axis_tready
  .s_axis_tdata(s_axis_mem1_write_cmd_tdata),    // input wire [95 : 0] s_axis_tdata
  //.m_axis_aclk(clk156_25),
  //.m_axis_aresetn(reset156_25_n),
  .m_axis_tvalid(axis_mem1_slice_to_dm_write_cmd_tvalid),  // output wire m_axis_tvalid
  .m_axis_tready(axis_mem1_slice_to_dm_write_cmd_tready),  // input wire m_axis_tready
  .m_axis_tdata(axis_mem1_slice_to_dm_write_cmd_tdata),    // output wire [95 : 0] m_axis_tdata
  .axis_data_count(),
  .axis_wr_data_count(),
  .axis_rd_data_count()
);

//write status
axis_register_slice_64 m1_status_slice (
  .aclk(clk156_25),                    // input wire aclk
  .aresetn(reset156_25_n),              // input wire aresetn
  .s_axis_tvalid(axis_mem1_slice_to_dm_write_sts_tvalid),  // input wire s_axis_tvalid
  .s_axis_tready(axis_mem1_slice_to_dm_write_sts_tready),  // output wire s_axis_tready
  .s_axis_tdata(axis_mem1_slice_to_dm_write_sts_tdata),    // input wire [95 : 0] s_axis_tdata
  .s_axis_tkeep(8'h0),
  .s_axis_tlast(1'b0),
  .m_axis_tvalid(m_axis_mem1_write_sts_tvalid),  // output wire m_axis_tvalid
  .m_axis_tready(m_axis_mem1_write_sts_tready),  // input wire m_axis_tready
  .m_axis_tdata(m_axis_mem1_write_sts_tdata)    // output wire [95 : 0] m_axis_tdata
);

//write data
//axis_register_slice_512 m1_write_slice_to_cc (
axis_data_fifo_1024 m1_write_fifo_to_cc (
  //.aclk(clk156_25),                    // input wire aclk
  //.aresetn(reset156_25_n),              // input wire aresetn
  .s_axis_aclk(clk156_25),
  .s_axis_aresetn(reset156_25_n),  
  .s_axis_tvalid(s_axis_mem1_write_tvalid),  // input wire s_axis_tvalid
  .s_axis_tready(s_axis_mem1_write_tready),  // output wire s_axis_tready
  .s_axis_tdata(s_axis_mem1_write_tdata),    // input wire [511 : 0] s_axis_tdata
  .s_axis_tkeep(s_axis_mem1_write_tkeep),    // input wire [63 : 0] s_axis_tkeep
  .s_axis_tlast(s_axis_mem1_write_tlast),    // input wire s_axis_tlast
  .m_axis_tvalid(axis_mem1_slice_to_cc_write_tvalid),  // output wire m_axis_tvalid
  .m_axis_tready(axis_mem1_slice_to_cc_write_tready),  // input wire m_axis_tready
  .m_axis_tdata(axis_mem1_slice_to_cc_write_tdata),    // output wire [511 : 0] m_axis_tdata
  .m_axis_tkeep(axis_mem1_slice_to_cc_write_tkeep),    // output wire [63 : 0] m_axis_tkeep
  .m_axis_tlast(axis_mem1_slice_to_cc_write_tlast),    // output wire m_axis_tlast
  .axis_data_count(),
  .axis_wr_data_count(),
  .axis_rd_data_count()
);

axis_clock_converter_1024 axis_clock_converter_mem1 (
   .s_axis_aclk(clk156_25),        // input wire s_axis_aclk
   .s_axis_aresetn(reset156_25_n),  // input wire s_axis_aresetn
   .s_axis_tvalid(axis_mem1_slice_to_cc_write_tvalid),    // input wire s_axis_tvalid
   .s_axis_tready(axis_mem1_slice_to_cc_write_tready),    // output wire s_axis_tready
   .s_axis_tdata(axis_mem1_slice_to_cc_write_tdata),      // input wire [511 : 0] s_axis_tdata
   .s_axis_tkeep(axis_mem1_slice_to_cc_write_tkeep),      // input wire [63 : 0] s_axis_tkeep
   .s_axis_tlast(axis_mem1_slice_to_cc_write_tlast),      // input wire s_axis_tlast
   
   .m_axis_aclk(c1_ui_clk),        // input wire m_axis_aclk
   .m_axis_aresetn(c1_aresetn_r),  // input wire m_axis_aresetn
   .m_axis_tvalid(axis_mem1_cc_to_slice_write_tvalid),    // output wire m_axis_tvalid
   .m_axis_tready(axis_mem1_cc_to_slice_write_tready),    // input wire m_axis_tready
   .m_axis_tdata(axis_mem1_cc_to_slice_write_tdata),      // output wire [511 : 0] m_axis_tdata
   .m_axis_tkeep(axis_mem1_cc_to_slice_write_tkeep),      // output wire [63 : 0] m_axis_tkeep
   .m_axis_tlast(axis_mem1_cc_to_slice_write_tlast)      // output wire m_axis_tlast
 );
 
`ifdef WC64
assign axis_mem1_slice_to_dm_write_tvalid = axis_mem1_cc_to_slice_write_tvalid;
assign axis_mem1_cc_to_slice_write_tready = axis_mem1_slice_to_dm_write_tready;
assign axis_mem1_slice_to_dm_write_tdata = axis_mem1_cc_to_slice_write_tdata;
assign axis_mem1_slice_to_dm_write_tkeep = axis_mem1_cc_to_slice_write_tkeep;
assign axis_mem1_slice_to_dm_write_tlast = axis_mem1_cc_to_slice_write_tlast;
`else
 //axis_register_slice_1024 m1_write_slice_to_dm (
 axis_1024_to_512_converter m1_write_converter_to_dm (
   .aclk(c1_ui_clk),                    // input wire aclk
   .aresetn(c1_aresetn_r),              // input wire aresetn
   .s_axis_tvalid(axis_mem1_cc_to_slice_write_tvalid),  // input wire s_axis_tvalid
   .s_axis_tready(axis_mem1_cc_to_slice_write_tready),  // output wire s_axis_tready
   .s_axis_tdata(axis_mem1_cc_to_slice_write_tdata),    // input wire [511 : 0] s_axis_tdata
   .s_axis_tkeep(axis_mem1_cc_to_slice_write_tkeep),    // input wire [63 : 0] s_axis_tkeep
   .s_axis_tlast(axis_mem1_cc_to_slice_write_tlast),    // input wire s_axis_tlast
   .m_axis_tvalid(axis_mem1_slice_to_dm_write_tvalid),  // output wire m_axis_tvalid
   .m_axis_tready(axis_mem1_slice_to_dm_write_tready),  // input wire m_axis_tready
   .m_axis_tdata(axis_mem1_slice_to_dm_write_tdata),    // output wire [511 : 0] m_axis_tdata
   .m_axis_tkeep(axis_mem1_slice_to_dm_write_tkeep),    // output wire [63 : 0] m_axis_tkeep
   .m_axis_tlast(axis_mem1_slice_to_dm_write_tlast)    // output wire m_axis_tlast
 );
`endif
 
  axis_data_fifo_512_cc axis_read_data_fifo_mem1 (
   .s_axis_aclk(c1_ui_clk),                // input wire s_axis_aclk
   .s_axis_aresetn(c1_aresetn_r),          // input wire s_axis_aresetn
   .s_axis_tvalid(axis_mem1_dm_to_cc_read_tvalid),            // input wire s_axis_tvalid
   .s_axis_tready(axis_mem1_dm_to_cc_read_tready),            // output wire s_axis_tready
   .s_axis_tdata(axis_mem1_dm_to_cc_read_tdata),              // input wire [255 : 0] s_axis_tdata
   .s_axis_tkeep(axis_mem1_dm_to_cc_read_tkeep),              // input wire [31 : 0] s_axis_tkeep
   .s_axis_tlast(axis_mem1_dm_to_cc_read_tlast),              // input wire s_axis_tlast
   
   .m_axis_aclk(clk156_25),                // input wire m_axis_aclk
   .m_axis_aresetn(reset156_25_n),          // input wire m_axis_aresetn
   .m_axis_tvalid(m_axis_mem1_read_tvalid),            // output wire m_axis_tvalid
   .m_axis_tready(m_axis_mem1_read_tready),            // input wire m_axis_tready
   .m_axis_tdata(m_axis_mem1_read_tdata),              // output wire [255 : 0] m_axis_tdata
   .m_axis_tkeep(m_axis_mem1_read_tkeep),              // output wire [31 : 0] m_axis_tkeep
   .m_axis_tlast(m_axis_mem1_read_tlast),              // output wire m_axis_tlast
   
   .axis_data_count(),        // output wire [31 : 0] axis_data_count
   .axis_wr_data_count(),  // output wire [31 : 0] axis_wr_data_count
   .axis_rd_data_count()  // output wire [31 : 0] axis_rd_data_count
 );


/*
 * DATA MOVERS
 */

assign c0_s_axi_arid = 1'b0;
assign c0_s_axi_awid = 1'b0;

wire m0_s2mm_err;
wire m0_mm2s_err;

axi_partitioner_datamover datamover_mem0 (
    .m_axi_mm2s_aclk(c0_ui_clk),// : IN STD_LOGIC;
    .m_axi_mm2s_aresetn(c0_aresetn_r), //: IN STD_LOGIC;
    .mm2s_err(m0_mm2s_err), //: OUT STD_LOGIC;
    .m_axis_mm2s_cmdsts_aclk(clk156_25), //: IN STD_LOGIC;
    .m_axis_mm2s_cmdsts_aresetn(reset156_25_n), //: IN STD_LOGIC;
    .s_axis_mm2s_cmd_tvalid(s_axis_mem0_read_cmd_tvalid), //: IN STD_LOGIC;
    .s_axis_mm2s_cmd_tready(s_axis_mem0_read_cmd_tready), //: OUT STD_LOGIC;
    .s_axis_mm2s_cmd_tdata(s_axis_mem0_read_cmd_tdata), //: IN STD_LOGIC_VECTOR(71 DOWNTO 0);
    .m_axis_mm2s_sts_tvalid(m_axis_mem0_read_sts_tvalid), //: OUT STD_LOGIC;
    .m_axis_mm2s_sts_tready(m_axis_mem0_read_sts_tready), //: IN STD_LOGIC;
    .m_axis_mm2s_sts_tdata(m_axis_mem0_read_sts_tdata), //: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    .m_axis_mm2s_sts_tkeep(), //: OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    .m_axis_mm2s_sts_tlast(), //: OUT STD_LOGIC;
    //.m_axi_mm2s_arid(c0_s_axi_arid), //: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    .m_axi_mm2s_araddr(c0_s_axi_araddr), //: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    .m_axi_mm2s_arlen(c0_s_axi_arlen), //: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    .m_axi_mm2s_arsize(c0_s_axi_arsize), //: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    .m_axi_mm2s_arburst(c0_s_axi_arburst), //: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    .m_axi_mm2s_arprot(), //: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    .m_axi_mm2s_arcache(), //: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    .m_axi_mm2s_aruser(), //: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    .m_axi_mm2s_arvalid(c0_s_axi_arvalid), //: OUT STD_LOGIC;
    .m_axi_mm2s_arready(c0_s_axi_arready), //: IN STD_LOGIC;
    .m_axi_mm2s_rdata(c0_s_axi_rdata), //: IN STD_LOGIC_VECTOR(511 DOWNTO 0);
    .m_axi_mm2s_rresp(c0_s_axi_rresp), //: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    .m_axi_mm2s_rlast(c0_s_axi_rlast), //: IN STD_LOGIC;
    .m_axi_mm2s_rvalid(c0_s_axi_rvalid), //: IN STD_LOGIC;
    .m_axi_mm2s_rready(c0_s_axi_rready), //: OUT STD_LOGIC;
    .m_axis_mm2s_tdata(axis_mem0_dm_to_cc_read_tdata), //: OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    .m_axis_mm2s_tkeep(axis_mem0_dm_to_cc_read_tkeep), //: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    .m_axis_mm2s_tlast(axis_mem0_dm_to_cc_read_tlast), //: OUT STD_LOGIC;
    .m_axis_mm2s_tvalid(axis_mem0_dm_to_cc_read_tvalid), //: OUT STD_LOGIC;
    .m_axis_mm2s_tready(axis_mem0_dm_to_cc_read_tready), //: IN STD_LOGIC;
    .m_axi_s2mm_aclk(c0_ui_clk), //: IN STD_LOGIC;
    .m_axi_s2mm_aresetn(c0_aresetn_r), //: IN STD_LOGIC;
    .s2mm_err(m0_s2mm_err), //: OUT STD_LOGIC;
    .m_axis_s2mm_cmdsts_awclk(clk156_25), //: IN STD_LOGIC;
    .m_axis_s2mm_cmdsts_aresetn(reset156_25_n), //: IN STD_LOGIC;
    .s_axis_s2mm_cmd_tvalid(axis_mem0_slice_to_dm_write_cmd_tvalid), //: IN STD_LOGIC;
    .s_axis_s2mm_cmd_tready(axis_mem0_slice_to_dm_write_cmd_tready), //: OUT STD_LOGIC;
    .s_axis_s2mm_cmd_tdata(axis_mem0_slice_to_dm_write_cmd_tdata), //: IN STD_LOGIC_VECTOR(71 DOWNTO 0);
    .m_axis_s2mm_sts_tvalid(axis_mem0_slice_to_dm_write_sts_tvalid), //: OUT STD_LOGIC;
    .m_axis_s2mm_sts_tready(axis_mem0_slice_to_dm_write_sts_tready), //: IN STD_LOGIC;
    .m_axis_s2mm_sts_tdata(axis_mem0_slice_to_dm_write_sts_tdata), //: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    .m_axis_s2mm_sts_tkeep(), //: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    .m_axis_s2mm_sts_tlast(), //: OUT STD_LOGIC;
    //.m_axi_s2mm_awid(c0_s_axi_awid), //: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    .m_axi_s2mm_awaddr(c0_s_axi_awaddr), //: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    .m_axi_s2mm_awlen(c0_s_axi_awlen), //: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    .m_axi_s2mm_awsize(c0_s_axi_awsize), //: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    .m_axi_s2mm_awburst(c0_s_axi_awburst), //: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    .m_axi_s2mm_awprot(), //: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    .m_axi_s2mm_awcache(), //: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    .m_axi_s2mm_awuser(), //: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    .m_axi_s2mm_awvalid(c0_s_axi_awvalid), //: OUT STD_LOGIC;
    .m_axi_s2mm_awready(c0_s_axi_awready), //: IN STD_LOGIC;
    .m_axi_s2mm_wdata(c0_s_axi_wdata), //: OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
    .m_axi_s2mm_wstrb(c0_s_axi_wstrb), //: OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    .m_axi_s2mm_wlast(c0_s_axi_wlast), //: OUT STD_LOGIC;
    .m_axi_s2mm_wvalid(c0_s_axi_wvalid), //: OUT STD_LOGIC;
    .m_axi_s2mm_wready(c0_s_axi_wready), //: IN STD_LOGIC;
    .m_axi_s2mm_bresp(c0_s_axi_bresp), //: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    .m_axi_s2mm_bvalid(c0_s_axi_bvalid), //: IN STD_LOGIC;
    .m_axi_s2mm_bready(c0_s_axi_bready), //: OUT STD_LOGIC;
    .s_axis_s2mm_tdata(axis_mem0_slice_to_dm_write_tdata), //: IN STD_LOGIC_VECTOR(511 DOWNTO 0);
    .s_axis_s2mm_tkeep(axis_mem0_slice_to_dm_write_tkeep), //: IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    .s_axis_s2mm_tlast(axis_mem0_slice_to_dm_write_tlast), //: IN STD_LOGIC;
    .s_axis_s2mm_tvalid(axis_mem0_slice_to_dm_write_tvalid), //: IN STD_LOGIC;
    .s_axis_s2mm_tready(axis_mem0_slice_to_dm_write_tready) //: OUT STD_LOGIC;
);

assign c1_s_axi_arid = 1'b0;
assign c1_s_axi_awid = 1'b0;

wire m1_s2mm_err;
wire m1_mm2s_err;



axi_partitioner_datamover datamover_mem1 (
    .m_axi_mm2s_aclk(c1_ui_clk),// : IN STD_LOGIC;
    .m_axi_mm2s_aresetn(c1_aresetn_r), //: IN STD_LOGIC;
    .mm2s_err(m1_mm2s_err), //: OUT STD_LOGIC;
    .m_axis_mm2s_cmdsts_aclk(clk156_25), //: IN STD_LOGIC;
    .m_axis_mm2s_cmdsts_aresetn(reset156_25_n), //: IN STD_LOGIC;
    .s_axis_mm2s_cmd_tvalid(s_axis_mem1_read_cmd_tvalid), //: IN STD_LOGIC;
    .s_axis_mm2s_cmd_tready(s_axis_mem1_read_cmd_tready), //: OUT STD_LOGIC;
    .s_axis_mm2s_cmd_tdata(s_axis_mem1_read_cmd_tdata), //: IN STD_LOGIC_VECTOR(71 DOWNTO 0);
    .m_axis_mm2s_sts_tvalid(m_axis_mem1_read_sts_tvalid), //: OUT STD_LOGIC;
    .m_axis_mm2s_sts_tready(m_axis_mem1_read_sts_tready), //: IN STD_LOGIC;
    .m_axis_mm2s_sts_tdata(m_axis_mem1_read_sts_tdata), //: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    .m_axis_mm2s_sts_tkeep(), //: OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    .m_axis_mm2s_sts_tlast(), //: OUT STD_LOGIC;
    //.m_axi_mm2s_arid(c1_s_axi_arid), //: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    .m_axi_mm2s_araddr(c1_s_axi_araddr), //: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    .m_axi_mm2s_arlen(c1_s_axi_arlen), //: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    .m_axi_mm2s_arsize(c1_s_axi_arsize), //: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    .m_axi_mm2s_arburst(c1_s_axi_arburst), //: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    .m_axi_mm2s_arprot(), //: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    .m_axi_mm2s_arcache(), //: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    .m_axi_mm2s_aruser(), //: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    .m_axi_mm2s_arvalid(c1_s_axi_arvalid), //: OUT STD_LOGIC;
    .m_axi_mm2s_arready(c1_s_axi_arready), //: IN STD_LOGIC;
    .m_axi_mm2s_rdata(c1_s_axi_rdata), //: IN STD_LOGIC_VECTOR(511 DOWNTO 0);
    .m_axi_mm2s_rresp(c1_s_axi_rresp), //: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    .m_axi_mm2s_rlast(c1_s_axi_rlast), //: IN STD_LOGIC;
    .m_axi_mm2s_rvalid(c1_s_axi_rvalid), //: IN STD_LOGIC;
    .m_axi_mm2s_rready(c1_s_axi_rready), //: OUT STD_LOGIC;
    .m_axis_mm2s_tdata(axis_mem1_dm_to_cc_read_tdata), //: OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    .m_axis_mm2s_tkeep(axis_mem1_dm_to_cc_read_tkeep), //: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    .m_axis_mm2s_tlast(axis_mem1_dm_to_cc_read_tlast), //: OUT STD_LOGIC;
    .m_axis_mm2s_tvalid(axis_mem1_dm_to_cc_read_tvalid), //: OUT STD_LOGIC;
    .m_axis_mm2s_tready(axis_mem1_dm_to_cc_read_tready), //: IN STD_LOGIC;
    .m_axi_s2mm_aclk(c1_ui_clk), //: IN STD_LOGIC;
    .m_axi_s2mm_aresetn(c1_aresetn_r), //: IN STD_LOGIC;
    .s2mm_err(m1_s2mm_err), //: OUT STD_LOGIC;
    .m_axis_s2mm_cmdsts_awclk(clk156_25), //: IN STD_LOGIC;
    .m_axis_s2mm_cmdsts_aresetn(reset156_25_n), //: IN STD_LOGIC;
    .s_axis_s2mm_cmd_tvalid(axis_mem1_slice_to_dm_write_cmd_tvalid), //: IN STD_LOGIC;
    .s_axis_s2mm_cmd_tready(axis_mem1_slice_to_dm_write_cmd_tready), //: OUT STD_LOGIC;
    .s_axis_s2mm_cmd_tdata(axis_mem1_slice_to_dm_write_cmd_tdata), //: IN STD_LOGIC_VECTOR(71 DOWNTO 0);
    .m_axis_s2mm_sts_tvalid(axis_mem1_slice_to_dm_write_sts_tvalid), //: OUT STD_LOGIC;
    .m_axis_s2mm_sts_tready(axis_mem1_slice_to_dm_write_sts_tready), //: IN STD_LOGIC;
    .m_axis_s2mm_sts_tdata(axis_mem1_slice_to_dm_write_sts_tdata), //: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    .m_axis_s2mm_sts_tkeep(), //: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    .m_axis_s2mm_sts_tlast(), //: OUT STD_LOGIC;
    //.m_axi_s2mm_awid(c1_s_axi_awid), //: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    .m_axi_s2mm_awaddr(c1_s_axi_awaddr), //: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    .m_axi_s2mm_awlen(c1_s_axi_awlen), //: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    .m_axi_s2mm_awsize(c1_s_axi_awsize), //: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    .m_axi_s2mm_awburst(c1_s_axi_awburst), //: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    .m_axi_s2mm_awprot(), //: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    .m_axi_s2mm_awcache(), //: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    .m_axi_s2mm_awuser(), //: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    .m_axi_s2mm_awvalid(c1_s_axi_awvalid), //: OUT STD_LOGIC;
    .m_axi_s2mm_awready(c1_s_axi_awready), //: IN STD_LOGIC;
    .m_axi_s2mm_wdata(c1_s_axi_wdata), //: OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
    .m_axi_s2mm_wstrb(c1_s_axi_wstrb), //: OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    .m_axi_s2mm_wlast(c1_s_axi_wlast), //: OUT STD_LOGIC;
    .m_axi_s2mm_wvalid(c1_s_axi_wvalid), //: OUT STD_LOGIC;
    .m_axi_s2mm_wready(c1_s_axi_wready), //: IN STD_LOGIC;
    .m_axi_s2mm_bresp(c1_s_axi_bresp), //: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    .m_axi_s2mm_bvalid(c1_s_axi_bvalid), //: IN STD_LOGIC;
    .m_axi_s2mm_bready(c1_s_axi_bready), //: OUT STD_LOGIC;
    .s_axis_s2mm_tdata(axis_mem1_slice_to_dm_write_tdata), //: IN STD_LOGIC_VECTOR(511 DOWNTO 0);
    .s_axis_s2mm_tkeep(axis_mem1_slice_to_dm_write_tkeep), //: IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    .s_axis_s2mm_tlast(axis_mem1_slice_to_dm_write_tlast), //: IN STD_LOGIC;
    .s_axis_s2mm_tvalid(axis_mem1_slice_to_dm_write_tvalid), //: IN STD_LOGIC;
    .s_axis_s2mm_tready(axis_mem1_slice_to_dm_write_tready) //: OUT STD_LOGIC;
);

`default_nettype wire
endmodule
