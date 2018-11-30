`timescale 1ns / 1ps
`default_nettype none

//import OStypes::*;
`include "os_types.svh"

`define USE_DDR

module os #(
    parameter AXI_ID_WIDTH = 1,
    parameter NUM_DDR_CHANNELS = 2 //TODO move
) (
    input wire      pcie_clk,
    input wire      pcie_aresetn,
    input wire[NUM_DDR_CHANNELS-1:0]    mem_clk,
    input wire[NUM_DDR_CHANNELS-1:0]    mem_aresetn,
    input wire      net_clk,
    input wire      net_aresetn,

    //Axi Lite Control Interface
    input  wire  [31:0] s_axil_awaddr,
    input  wire         s_axil_awvalid,
    output wire         s_axil_awready,
    input  wire  [31:0] s_axil_wdata,
    input  wire   [3:0] s_axil_wstrb,
    input  wire         s_axil_wvalid,
    output wire         s_axil_wready,
    output wire   [1:0] s_axil_bresp,
    output wire         s_axil_bvalid,
    input  wire         s_axil_bready,
    input  wire  [31:0] s_axil_araddr,
    input  wire         s_axil_arvalid,
    output wire         s_axil_arready,
    output wire  [31:0] s_axil_rdata,
    output wire   [1:0] s_axil_rresp,
    output wire         s_axil_rvalid,
    input  wire         s_axil_rready,

    //DDR
    input wire          ddr3_calib_complete,
    //input wire[NUM_DDR_CHANNELS-1:0]                mem_clk,
    //input wire[NUM_DDR_CHANNELS-1:0]                mem_aresetn,
    // Slave Interface Write Address Ports
    output logic [AXI_ID_WIDTH-1:0]                 m_axi_awid  [NUM_DDR_CHANNELS-1:0],
    output logic [31:0]                             m_axi_awaddr    [NUM_DDR_CHANNELS-1:0],
    output logic [7:0]                              m_axi_awlen [NUM_DDR_CHANNELS-1:0],
    output logic [2:0]                              m_axi_awsize    [NUM_DDR_CHANNELS-1:0],
    output logic [1:0]                              m_axi_awburst   [NUM_DDR_CHANNELS-1:0],
    output logic [0:0]                              m_axi_awlock    [NUM_DDR_CHANNELS-1:0],
    output logic [3:0]                              m_axi_awcache   [NUM_DDR_CHANNELS-1:0],
    output logic [2:0]                              m_axi_awprot    [NUM_DDR_CHANNELS-1:0],
    output logic[NUM_DDR_CHANNELS-1:0]                                    m_axi_awvalid,
    input wire[NUM_DDR_CHANNELS-1:0]                                      m_axi_awready,
    // Slave Interface Write Data Ports
    output logic [511:0]                            m_axi_wdata [NUM_DDR_CHANNELS-1:0],
    output logic [63:0]                             m_axi_wstrb [NUM_DDR_CHANNELS-1:0],
    output logic[NUM_DDR_CHANNELS-1:0]                                    m_axi_wlast,
    output logic[NUM_DDR_CHANNELS-1:0]                                    m_axi_wvalid,
    input wire[NUM_DDR_CHANNELS-1:0]                                      m_axi_wready,
    // Slave Interface Write Response Ports
    output logic[NUM_DDR_CHANNELS-1:0]                                    m_axi_bready,
    input wire [AXI_ID_WIDTH-1:0]                   m_axi_bid   [NUM_DDR_CHANNELS-1:0],
    input wire [1:0]                                m_axi_bresp [NUM_DDR_CHANNELS-1:0],
    input wire[NUM_DDR_CHANNELS-1:0]                                      m_axi_bvalid,
    // Slave Interface Read Address Ports
    output logic [AXI_ID_WIDTH-1:0]                 m_axi_arid  [NUM_DDR_CHANNELS-1:0],
    output logic [31:0]                             m_axi_araddr    [NUM_DDR_CHANNELS-1:0],
    output logic [7:0]                              m_axi_arlen [NUM_DDR_CHANNELS-1:0],
    output logic [2:0]                              m_axi_arsize    [NUM_DDR_CHANNELS-1:0],
    output logic [1:0]                              m_axi_arburst   [NUM_DDR_CHANNELS-1:0],
    output logic [0:0]                              m_axi_arlock    [NUM_DDR_CHANNELS-1:0],
    output logic [3:0]                              m_axi_arcache   [NUM_DDR_CHANNELS-1:0],
    output logic [2:0]                              m_axi_arprot    [NUM_DDR_CHANNELS-1:0],
    output logic[NUM_DDR_CHANNELS-1:0]                                    m_axi_arvalid,
    input wire[NUM_DDR_CHANNELS-1:0]                                      m_axi_arready,
    // Slave Interface Read Data Ports
    output logic[NUM_DDR_CHANNELS-1:0]                                    m_axi_rready,
    input wire [AXI_ID_WIDTH-1:0]                   m_axi_rid   [NUM_DDR_CHANNELS-1:0],
    input wire [511:0]                              m_axi_rdata [NUM_DDR_CHANNELS-1:0],
    input wire [1:0]                                m_axi_rresp [NUM_DDR_CHANNELS-1:0],
    input wire[NUM_DDR_CHANNELS-1:0]                                      m_axi_rlast,
    input wire[NUM_DDR_CHANNELS-1:0]                                      m_axi_rvalid,

    /*mem_cmd.master[NUM_DDR_CHANNELS-1:0]            m_axis_ddr_write_cmd,
    mem_cmd.master[NUM_DDR_CHANNELS-1:0]            m_axis_ddr_read_cmd,
    axi_stream.master[NUM_DDR_CHANNELS-1:0]         m_axis_ddr_write_data,
    axi_stream.slave[NUM_DDR_CHANNELS-1:0]          s_axi_ddr_read_data,
    mem_status.slave[NUM_DDR_CHANNELS-1:0]          s_axis_ddr_write_status,
    mem_status.slave[NUM_DDR_CHANNELS-1:0]          s_axis_ddr_read_status,
*/
    /* DMA */
    // AXI Stream Interface
    axi_stream.master       m_axis_dma_c2h,
    /*output logic        m_axis_c2h_tvalid_0,
    input wire          m_axis_c2h_tready_0,
    //output axi_word_512 m_axis_c2h_tdata_0,
    output logic[511:0] m_axis_c2h_tdata_0,
    output logic[63:0]  m_axis_c2h_tkeep_0,
    output logic        m_axis_c2h_tlast_0,*/

    axi_stream.slave    s_axis_dma_h2c,
    /*input wire          s_axis_h2c_tvalid_0,
    output logic        s_axis_h2c_tready_0,
    //input axi_word_512  s_axis_h2c_tdata_0,
    input wire[511:0]   s_axis_h2c_tdata_0,
    input wire[63:0]    s_axis_h2c_tkeep_0,
    input wire          s_axis_h2c_tlast_0,*/

    // Descriptor Bypass
    input wire          c2h_dsc_byp_ready_0,
    //input wire[63:0]    c2h_dsc_byp_src_addr_0,
    output logic[63:0]  c2h_dsc_byp_addr_0,
    output logic[31:0]  c2h_dsc_byp_len_0,
    //input wire[15:0]    c2h_dsc_byp_ctl_0,
    output logic        c2h_dsc_byp_load_0,
    
    input wire          h2c_dsc_byp_ready_0,
    output logic[63:0]  h2c_dsc_byp_addr_0,
    //input wire[63:0]    h2c_dsc_byp_dst_addr_0,
    output logic[31:0]  h2c_dsc_byp_len_0,
    //input wire[15:0]    h2c_dsc_byp_ctl_0,
    output logic        h2c_dsc_byp_load_0,
    
    input wire[7:0]     c2h_sts_0,
    input wire[7:0]     h2c_sts_0

    /*mem_cmd.master[NUM_DDR_CHANNELS-1:0]            m_axis_dma_write_cmd,
    mem_cmd.master[NUM_DDR_CHANNELS-1:0]            m_axis_dma_read_cmd,
    axi_stream.master[NUM_DDR_CHANNELS-1:0]         m_axis_dma_write_data,
    axi_stream.slave[NUM_DDR_CHANNELS-1:0]          s_axi_dma_read_data,*/

    //Network



);


// Memory Signals

axis_mem_cmd    axis_mem_read_cmd[NUM_DDR_CHANNELS]();
axi_stream      axis_mem_read_data[NUM_DDR_CHANNELS]();
axis_mem_status axis_mem_read_status[NUM_DDR_CHANNELS](); 

axis_mem_cmd    axis_mem_write_cmd[NUM_DDR_CHANNELS]();
axi_stream      axis_mem_write_data[NUM_DDR_CHANNELS]();
axis_mem_status axis_mem_write_status[NUM_DDR_CHANNELS]();

/*
 * User Role
 */
benchmark_role user_role(
    .net_clk(net_clk),
    .net_aresetn(net_aresetn),

    .pcie_clk(pcie_clk),
    .pcie_aresetn(pcie_aresetn),

    /* CONTROL INTERFACE */
    // LITE interface
    //-- AXI Master Write Address Channel
    .s_axil_awaddr(axil_to_modules_awaddr[AxilPortUserRole]),              // output wire [31 : 0] m_axil_awaddr
    .s_axil_awprot(),              // output wire [2 : 0] m_axil_awprot
    .s_axil_awvalid(axil_to_modules_awvalid[AxilPortUserRole]),            // output wire m_axil_awvalid
    .s_axil_awready(axil_to_modules_awready[AxilPortUserRole]),            // input wire m_axil_awready
    //-- AXI Master Write Data Channel
    .s_axil_wdata(axil_to_modules_wdata[AxilPortUserRole]),                // output wire [31 : 0] m_axil_wdata
    .s_axil_wstrb(axil_to_modules_wstrb[AxilPortUserRole]),                // output wire [3 : 0] m_axil_wstrb
    .s_axil_wvalid(axil_to_modules_wvalid[AxilPortUserRole]),              // output wire m_axil_wvalid
    .s_axil_wready(axil_to_modules_wready[AxilPortUserRole]),              // input wire m_axil_wready
    //-- AXI Master Write Response Channel
    .s_axil_bvalid(axil_to_modules_bvalid[AxilPortUserRole]),              // input wire m_axil_bvalid
    .s_axil_bresp(axil_to_modules_bresp[AxilPortUserRole]),                // input wire [1 : 0] m_axil_bresp
    .s_axil_bready(axil_to_modules_bready[AxilPortUserRole]),              // output wire m_axil_bready
    //-- AXI Master Read Address Channel
    .s_axil_araddr(axil_to_modules_araddr[AxilPortUserRole]),              // output wire [31 : 0] m_axil_araddr
    .s_axil_arprot(),              // output wire [2 : 0] m_axil_arprot
    .s_axil_arvalid(axil_to_modules_arvalid[AxilPortUserRole]),            // output wire m_axil_arvalid
    .s_axil_arready(axil_to_modules_arready[AxilPortUserRole]),            // input wire m_axil_arready
    .s_axil_rdata(axil_to_modules_rdata[AxilPortUserRole]),                // input wire [31 : 0] m_axil_rdata
    //-- AXI Master Read Data Channel
    .s_axil_rresp(axil_to_modules_rresp[AxilPortUserRole]),                // input wire [1 : 0] m_axil_rresp
    .s_axil_rvalid(axil_to_modules_rvalid[AxilPortUserRole]),              // input wire m_axil_rvalid
    .s_axil_rready(axil_to_modules_rready[AxilPortUserRole]),              // output wire m_axil_rready

    /* MEMORY INTERFACE */
    .m_axis_mem_read_cmd(axis_mem_read_cmd),
    .m_axis_mem_write_cmd(axis_mem_write_cmd),
    .s_axis_mem_read_data(axis_mem_read_data),
    .m_axis_mem_write_data(axis_mem_write_data),
    .s_axis_mem_read_status(axis_mem_read_status),
    .s_axis_mem_write_status(axis_mem_write_status),

    /*.m_axis_mem0_read_cmd_tvalid(axis_user_read_mem0_cmd_tvalid),
    .m_axis_mem0_read_cmd_tready(axis_user_read_mem0_cmd_tready),
    .m_axis_mem0_read_cmd_tdata(axis_user_read_mem0_cmd_tdata),
    .m_axis_mem0_write_cmd_tvalid(axis_user_write_mem0_cmd_tvalid),
    .m_axis_mem0_write_cmd_tready(axis_user_write_mem0_cmd_tready),
    .m_axis_mem0_write_cmd_tdata(axis_user_write_mem0_cmd_tdata),


    .s_axis_mem0_read_data_tvalid(axis_user_read_mem0_data_tvalid),
    .s_axis_mem0_read_data_tready(axis_user_read_mem0_data_tready),
    .s_axis_mem0_read_data_tdata(axis_user_read_mem0_data_tdata),
    .s_axis_mem0_read_data_tkeep(axis_user_read_mem0_data_tkeep),
    .s_axis_mem0_read_data_tlast(axis_user_read_mem0_data_tlast),


    .m_axis_mem0_write_data_tvalid(axis_user_write_mem0_data_tvalid),
    .m_axis_mem0_write_data_tready(axis_user_write_mem0_data_tready),
    .m_axis_mem0_write_data_tdata(axis_user_write_mem0_data_tdata),
    .m_axis_mem0_write_data_tkeep(axis_user_write_mem0_data_tkeep),
    .m_axis_mem0_write_data_tlast(axis_user_write_mem0_data_tlast),

    .s_axis_mem0_write_sts_tvalid(axis_user_write_mem0_status_tvalid),
    .s_axis_mem0_write_sts_tready(axis_user_write_mem0_status_tready),
    .s_axis_mem0_write_sts_tdata(axis_user_write_mem0_status_tdata),


    .m_axis_mem1_read_cmd_tvalid(axis_user_read_mem1_cmd_tvalid),
    .m_axis_mem1_read_cmd_tready(axis_user_read_mem1_cmd_tready),
    .m_axis_mem1_read_cmd_tdata(axis_user_read_mem1_cmd_tdata),
    .m_axis_mem1_write_cmd_tvalid(axis_user_write_mem1_cmd_tvalid),
    .m_axis_mem1_write_cmd_tready(axis_user_write_mem1_cmd_tready),
    .m_axis_mem1_write_cmd_tdata(axis_user_write_mem1_cmd_tdata),


    .s_axis_mem1_read_data_tvalid(axis_user_read_mem1_data_tvalid),
    .s_axis_mem1_read_data_tready(axis_user_read_mem1_data_tready),
    .s_axis_mem1_read_data_tdata(axis_user_read_mem1_data_tdata),
    .s_axis_mem1_read_data_tkeep(axis_user_read_mem1_data_tkeep),
    .s_axis_mem1_read_data_tlast(axis_user_read_mem1_data_tlast),


    .m_axis_mem1_write_data_tvalid(axis_user_write_mem1_data_tvalid),
    .m_axis_mem1_write_data_tready(axis_user_write_mem1_data_tready),
    .m_axis_mem1_write_data_tdata(axis_user_write_mem1_data_tdata),
    .m_axis_mem1_write_data_tkeep(axis_user_write_mem1_data_tkeep),
    .m_axis_mem1_write_data_tlast(axis_user_write_mem1_data_tlast),

    .s_axis_mem1_write_sts_tvalid(axis_user_write_mem1_status_tvalid),
    .s_axis_mem1_write_sts_tready(axis_user_write_mem1_status_tready),
    .s_axis_mem1_write_sts_tdata(axis_user_write_mem1_status_tdata),*/

    /* DMA INTERFACE */
    .m_axis_dma_read_cmd_tvalid(axis_dma_read_cmd_tvalid),
    .m_axis_dma_read_cmd_tready(axis_dma_read_cmd_tready),
    .m_axis_dma_read_cmd_tdata(axis_dma_read_cmd_tdata),
    .m_axis_dma_write_cmd_tvalid(axis_dma_write_cmd_tvalid),
    .m_axis_dma_write_cmd_tready(axis_dma_write_cmd_tready),
    .m_axis_dma_write_cmd_tdata(axis_dma_write_cmd_tdata),

    .s_axis_dma_read_data_tvalid(axis_dma_read_data_tvalid),
    .s_axis_dma_read_data_tready(axis_dma_read_data_tready),
    .s_axis_dma_read_data_tdata(axis_dma_read_data_tdata),
    .s_axis_dma_read_data_tkeep(axis_dma_read_data_tkeep),
    .s_axis_dma_read_data_tlast(axis_dma_read_data_tlast),

    .m_axis_dma_write_data_tvalid(axis_dma_write_data_tvalid),
    .m_axis_dma_write_data_tready(axis_dma_write_data_tready),
    .m_axis_dma_write_data_tdata(axis_dma_write_data_tdata),
    .m_axis_dma_write_data_tkeep(axis_dma_write_data_tkeep),
    .m_axis_dma_write_data_tlast(axis_dma_write_data_tlast)

);

//Axi Lite Signals
localparam AxilPortUserRole = 0; //TODO enum
localparam AxilPortDMA = 1;
localparam AxilPortDDR0 = 2;
localparam AxilPortDDR1 = 3;

localparam NUM_AXIL_MODULES = 4;
wire [31: 0] axil_to_modules_awaddr    [NUM_AXIL_MODULES-1:0];
(* mark_debug = "true" *)wire[NUM_AXIL_MODULES-1:0]  axil_to_modules_awvalid;
(* mark_debug = "true" *)wire[NUM_AXIL_MODULES-1:0] axil_to_modules_awready;
 
//data write
wire [31: 0]   axil_to_modules_wdata    [NUM_AXIL_MODULES-1:0];
wire [3: 0] axil_to_modules_wstrb   [NUM_AXIL_MODULES-1:0];
(* mark_debug = "true" *)wire[NUM_AXIL_MODULES-1:0] axil_to_modules_wvalid;
(* mark_debug = "true" *)wire[NUM_AXIL_MODULES-1:0] axil_to_modules_wready;
 
//write response (handhake)
wire [1:0] axil_to_modules_bresp    [NUM_AXIL_MODULES-1:0];
wire[NUM_AXIL_MODULES-1:0] axil_to_modules_bvalid;
wire[NUM_AXIL_MODULES-1:0] axil_to_modules_bready;
 
//address read
wire [31: 0] axil_to_modules_araddr    [NUM_AXIL_MODULES-1:0];
(* mark_debug = "true" *)wire[NUM_AXIL_MODULES-1:0] axil_to_modules_arvalid;
(* mark_debug = "true" *)wire[NUM_AXIL_MODULES-1:0] axil_to_modules_arready;
 
//data read
wire [31: 0] axil_to_modules_rdata  [NUM_AXIL_MODULES-1:0];
wire [1:0] axil_to_modules_rresp    [NUM_AXIL_MODULES-1:0];
(* mark_debug = "true" *)wire[NUM_AXIL_MODULES-1:0] axil_to_modules_rvalid;
(* mark_debug = "true" *)wire[NUM_AXIL_MODULES-1:0] axil_to_modules_rready;




/*(* mark_debug = "true" *)wire        axis_user_read_mem0_cmd_tvalid;
(* mark_debug = "true" *)wire        axis_user_read_mem0_cmd_tready;
wire[95:0]  axis_user_read_mem0_cmd_tdata;
(* mark_debug = "true" *)wire        axis_user_write_mem0_cmd_tvalid;
(* mark_debug = "true" *)wire        axis_user_write_mem0_cmd_tready;
wire[95:0]  axis_user_write_mem0_cmd_tdata;

(* mark_debug = "true" *)wire        axis_user_read_mem0_data_tvalid; //TODO switch mem0 and read
(* mark_debug = "true" *)wire        axis_user_read_mem0_data_tready;
wire[511:0] axis_user_read_mem0_data_tdata;
wire[63:0]  axis_user_read_mem0_data_tkeep;
(* mark_debug = "true" *)wire        axis_user_read_mem0_data_tlast;

(* mark_debug = "true" *)wire        axis_user_write_mem0_data_tvalid; //TODO switch mem0 and read
(* mark_debug = "true" *)wire        axis_user_write_mem0_data_tready;
wire[511:0] axis_user_write_mem0_data_tdata;
wire[63:0]  axis_user_write_mem0_data_tkeep;
wire        axis_user_write_mem0_data_tlast;

(* mark_debug = "true" *)wire        axis_user_write_mem0_status_tvalid;
(* mark_debug = "true" *)wire        axis_user_write_mem0_status_tready;
wire[7:0]  axis_user_write_mem0_status_tdata;

(* mark_debug = "true" *)wire        axis_user_read_mem1_cmd_tvalid;
(* mark_debug = "true" *)wire        axis_user_read_mem1_cmd_tready;
wire[95:0]  axis_user_read_mem1_cmd_tdata;
(* mark_debug = "true" *)wire        axis_user_write_mem1_cmd_tvalid;
(* mark_debug = "true" *)wire        axis_user_write_mem1_cmd_tready;
wire[95:0]  axis_user_write_mem1_cmd_tdata;

(* mark_debug = "true" *)wire        axis_user_read_mem1_data_tvalid; //TODO switch mem0 and read
(* mark_debug = "true" *)wire        axis_user_read_mem1_data_tready;
wire[511:0] axis_user_read_mem1_data_tdata;
wire[63:0]  axis_user_read_mem1_data_tkeep;
wire        axis_user_read_mem1_data_tlast;

(* mark_debug = "true" *)wire        axis_user_write_mem1_data_tvalid; //TODO switch mem0 and read
(* mark_debug = "true" *)wire        axis_user_write_mem1_data_tready;
wire[511:0] axis_user_write_mem1_data_tdata;
wire[63:0]  axis_user_write_mem1_data_tkeep;
wire        axis_user_write_mem1_data_tlast;

(* mark_debug = "true" *)wire        axis_user_write_mem1_status_tvalid;
(* mark_debug = "true" *)wire        axis_user_write_mem1_status_tready;
wire[7:0]  axis_user_write_mem1_status_tdata;
*/


//DMA Signals

(* mark_debug = "true" *)wire        axis_dma_read_cmd_tvalid;
(* mark_debug = "true" *)wire        axis_dma_read_cmd_tready;
wire[95:0]  axis_dma_read_cmd_tdata;

wire[47:0] axis_dma_read_cmd_addr;
assign axis_dma_read_cmd_addr = axis_dma_read_cmd_tdata[47:0];


(* mark_debug = "true" *)wire        axis_dma_write_cmd_tvalid;
(* mark_debug = "true" *)wire        axis_dma_write_cmd_tready;
wire[95:0]  axis_dma_write_cmd_tdata;

wire[47:0] axis_dma_write_cmd_addr;
assign axis_dma_write_cmd_addr = axis_dma_write_cmd_tdata[47:0];

wire        axis_dma_write_data_tvalid;
wire        axis_dma_write_data_tready;
wire[511:0] axis_dma_write_data_tdata;
wire[63:0]  axis_dma_write_data_tkeep;
wire        axis_dma_write_data_tlast;

wire        axis_dma_read_data_tvalid;
wire        axis_dma_read_data_tready;
wire[511:0] axis_dma_read_data_tdata;
wire[63:0]  axis_dma_read_data_tkeep;
wire        axis_dma_read_data_tlast;


/*
 * Memory Interface
 */
`ifdef USE_DDR
//TODO move
localparam DDR_CHANNEL0 = 0;
localparam DDR_CHANNEL1 = 1;


mem_single_inf  mem_inf_inst0(
.user_clk(net_clk),
.user_aresetn(ddr3_calib_complete),
.pcie_clk(pcie_clk), //TODO remove
.pcie_aresetn(pcie_aresetn),
.mem_clk(mem_clk[DDR_CHANNEL0]),
.mem_aresetn(mem_aresetn[DDR_CHANNEL0]),

/* USER INTERFACE */
//memory read commands
.s_axis_mem_read_cmd(axis_mem_read_cmd[DDR_CHANNEL0]),
/*.s_axis_mem_read_cmd_tvalid(axis_user_read_mem0_cmd_tvalid),
.s_axis_mem_read_cmd_tready(axis_user_read_mem0_cmd_tready),
.s_axis_mem_read_cmd_tdata(axis_user_read_mem0_cmd_tdata),*/
//memory read status
.m_axis_mem_read_status(axis_mem_read_status[DDR_CHANNEL0]),
/*.m_axis_mem_read_sts_tvalid(),
.m_axis_mem_read_sts_tready(1'b1),
.m_axis_mem_read_sts_tdata(),*/
//memory read stream
.m_axis_mem_read_data(axis_mem_read_data[DDR_CHANNEL0]),
/*.m_axis_mem_read_tvalid(axis_user_read_mem0_data_tvalid),
.m_axis_mem_read_tready(axis_user_read_mem0_data_tready),
.m_axis_mem_read_tdata(axis_user_read_mem0_data_tdata),
.m_axis_mem_read_tkeep(axis_user_read_mem0_data_tkeep),
.m_axis_mem_read_tlast(axis_user_read_mem0_data_tlast),*/

//memory write commands
.s_axis_mem_write_cmd(axis_mem_write_cmd[DDR_CHANNEL0]),
/*.s_axis_mem_write_cmd_tvalid(axis_user_write_mem0_cmd_tvalid),
.s_axis_mem_write_cmd_tready(axis_user_write_mem0_cmd_tready),
.s_axis_mem_write_cmd_tdata(axis_user_write_mem0_cmd_tdata),*/
//memory rite status
.m_axis_mem_write_status(axis_mem_write_status[DDR_CHANNEL0]),
/*.m_axis_mem_write_sts_tvalid(axis_user_write_mem0_status_tvalid),
.m_axis_mem_write_sts_tready(axis_user_write_mem0_status_tready),
.m_axis_mem_write_sts_tdata(axis_user_write_mem0_status_tdata),*/
//memory write stream
.s_axis_mem_write_data(axis_mem_write_data[DDR_CHANNEL0]),
/*.s_axis_mem_write_tvalid(axis_user_write_mem0_data_tvalid),
.s_axis_mem_write_tready(axis_user_write_mem0_data_tready),
.s_axis_mem_write_tdata(axis_user_write_mem0_data_tdata),
.s_axis_mem_write_tkeep(axis_user_write_mem0_data_tkeep),
.s_axis_mem_write_tlast(axis_user_write_mem0_data_tlast),*/

/* CONTROL INTERFACE */
// LITE interface
//-- AXI Master Write Address Channel
.s_axil_awaddr(axil_to_modules_awaddr[AxilPortDDR0]),              // output wire [31 : 0] m_axil_awaddr
.s_axil_awprot(),              // output wire [2 : 0] m_axil_awprot
.s_axil_awvalid(axil_to_modules_awvalid[AxilPortDDR0]),            // output wire m_axil_awvalid
.s_axil_awready(axil_to_modules_awready[AxilPortDDR0]),            // input wire m_axil_awready
//-- AXI Master Write Data Channel
.s_axil_wdata(axil_to_modules_wdata[AxilPortDDR0]),                // output wire [31 : 0] m_axil_wdata
.s_axil_wstrb(axil_to_modules_wstrb[AxilPortDDR0]),                // output wire [3 : 0] m_axil_wstrb
.s_axil_wvalid(axil_to_modules_wvalid[AxilPortDDR0]),              // output wire m_axil_wvalid
.s_axil_wready(axil_to_modules_wready[AxilPortDDR0]),              // input wire m_axil_wready
//-- AXI Master Write Response Channel
.s_axil_bvalid(axil_to_modules_bvalid[AxilPortDDR0]),              // input wire m_axil_bvalid
.s_axil_bresp(axil_to_modules_bresp[AxilPortDDR0]),                // input wire [1 : 0] m_axil_bresp
.s_axil_bready(axil_to_modules_bready[AxilPortDDR0]),              // output wire m_axil_bready
//-- AXI Master Read Address Channel
.s_axil_araddr(axil_to_modules_araddr[AxilPortDDR0]),              // output wire [31 : 0] m_axil_araddr
.s_axil_arprot(),              // output wire [2 : 0] m_axil_arprot
.s_axil_arvalid(axil_to_modules_arvalid[AxilPortDDR0]),            // output wire m_axil_arvalid
.s_axil_arready(axil_to_modules_arready[AxilPortDDR0]),            // input wire m_axil_arready
.s_axil_rdata(axil_to_modules_rdata[AxilPortDDR0]),                // input wire [31 : 0] m_axil_rdata
//-- AXI Master Read Data Channel
.s_axil_rresp(axil_to_modules_rresp[AxilPortDDR0]),                // input wire [1 : 0] m_axil_rresp
.s_axil_rvalid(axil_to_modules_rvalid[AxilPortDDR0]),              // input wire m_axil_rvalid
.s_axil_rready(axil_to_modules_rready[AxilPortDDR0]),              // output wire m_axil_rready


/* DRIVER INTERFACE */
.m_axi_awid(m_axi_awid[DDR_CHANNEL0]),
.m_axi_awaddr(m_axi_awaddr[DDR_CHANNEL0]),
.m_axi_awlen(m_axi_awlen[DDR_CHANNEL0]),
.m_axi_awsize(m_axi_awsize[DDR_CHANNEL0]),
.m_axi_awburst(m_axi_awburst[DDR_CHANNEL0]),
.m_axi_awlock(m_axi_awlock[DDR_CHANNEL0]),
.m_axi_awcache(m_axi_awcache[DDR_CHANNEL0]),
.m_axi_awprot(m_axi_awprot[DDR_CHANNEL0]),
.m_axi_awvalid(m_axi_awvalid[DDR_CHANNEL0]),
.m_axi_awready(m_axi_awready[DDR_CHANNEL0]),

.m_axi_wdata(m_axi_wdata[DDR_CHANNEL0]),
.m_axi_wstrb(m_axi_wstrb[DDR_CHANNEL0]),
.m_axi_wlast(m_axi_wlast[DDR_CHANNEL0]),
.m_axi_wvalid(m_axi_wvalid[DDR_CHANNEL0]),
.m_axi_wready(m_axi_wready[DDR_CHANNEL0]),

.m_axi_bready(m_axi_bready[DDR_CHANNEL0]),
.m_axi_bid(m_axi_bid[DDR_CHANNEL0]),
.m_axi_bresp(m_axi_bresp[DDR_CHANNEL0]),
.m_axi_bvalid(m_axi_bvalid[DDR_CHANNEL0]),

.m_axi_arid(m_axi_arid[DDR_CHANNEL0]),
.m_axi_araddr(m_axi_araddr[DDR_CHANNEL0]),
.m_axi_arlen(m_axi_arlen[DDR_CHANNEL0]),
.m_axi_arsize(m_axi_arsize[DDR_CHANNEL0]),
.m_axi_arburst(m_axi_arburst[DDR_CHANNEL0]),
.m_axi_arlock(m_axi_arlock[DDR_CHANNEL0]),
.m_axi_arcache(m_axi_arcache[DDR_CHANNEL0]),
.m_axi_arprot(m_axi_arprot[DDR_CHANNEL0]),
.m_axi_arvalid(m_axi_arvalid[DDR_CHANNEL0]),
.m_axi_arready(m_axi_arready[DDR_CHANNEL0]),

.m_axi_rready(m_axi_rready[DDR_CHANNEL0]),
.m_axi_rid(m_axi_rid[DDR_CHANNEL0]),
.m_axi_rdata(m_axi_rdata[DDR_CHANNEL0]),
.m_axi_rresp(m_axi_rresp[DDR_CHANNEL0]),
.m_axi_rlast(m_axi_rlast[DDR_CHANNEL0]),
.m_axi_rvalid(m_axi_rvalid[DDR_CHANNEL0])
);

mem_single_inf  mem_inf_inst1(
.user_clk(net_clk),
.user_aresetn(ddr3_calib_complete),
.pcie_clk(pcie_clk),
.pcie_aresetn(pcie_aresetn), //TODO remove
.mem_clk(mem_clk[DDR_CHANNEL1]),
.mem_aresetn(mem_aresetn[DDR_CHANNEL1]),


/* USER INTERFACE */
.s_axis_mem_read_cmd(axis_mem_read_cmd[DDR_CHANNEL1]),
/*.s_axis_mem_read_cmd_tvalid(axis_user_read_mem0_cmd_tvalid),
.s_axis_mem_read_cmd_tready(axis_user_read_mem0_cmd_tready),
.s_axis_mem_read_cmd_tdata(axis_user_read_mem0_cmd_tdata),*/
//memory read status
.m_axis_mem_read_status(axis_mem_read_status[DDR_CHANNEL1]),
/*.m_axis_mem_read_sts_tvalid(),
.m_axis_mem_read_sts_tready(1'b1),
.m_axis_mem_read_sts_tdata(),*/
//memory read stream
.m_axis_mem_read_data(axis_mem_read_data[DDR_CHANNEL1]),
/*.m_axis_mem_read_tvalid(axis_user_read_mem0_data_tvalid),
.m_axis_mem_read_tready(axis_user_read_mem0_data_tready),
.m_axis_mem_read_tdata(axis_user_read_mem0_data_tdata),
.m_axis_mem_read_tkeep(axis_user_read_mem0_data_tkeep),
.m_axis_mem_read_tlast(axis_user_read_mem0_data_tlast),*/

//memory write commands
.s_axis_mem_write_cmd(axis_mem_write_cmd[DDR_CHANNEL1]),
/*.s_axis_mem_write_cmd_tvalid(axis_user_write_mem0_cmd_tvalid),
.s_axis_mem_write_cmd_tready(axis_user_write_mem0_cmd_tready),
.s_axis_mem_write_cmd_tdata(axis_user_write_mem0_cmd_tdata),*/
//memory rite status
.m_axis_mem_write_status(axis_mem_write_status[DDR_CHANNEL1]),
/*.m_axis_mem_write_sts_tvalid(axis_user_write_mem0_status_tvalid),
.m_axis_mem_write_sts_tready(axis_user_write_mem0_status_tready),
.m_axis_mem_write_sts_tdata(axis_user_write_mem0_status_tdata),*/
//memory write stream
.s_axis_mem_write_data(axis_mem_write_data[DDR_CHANNEL1]),
/*.s_axis_mem_write_tvalid(axis_user_write_mem0_data_tvalid),
.s_axis_mem_write_tready(axis_user_write_mem0_data_tready),
.s_axis_mem_write_tdata(axis_user_write_mem0_data_tdata),
.s_axis_mem_write_tkeep(axis_user_write_mem0_data_tkeep),
.s_axis_mem_write_tlast(axis_user_write_mem0_data_tlast),*/

//memory read commands
/*.s_axis_mem_read_cmd_tvalid(axis_user_read_mem1_cmd_tvalid),
.s_axis_mem_read_cmd_tready(axis_user_read_mem1_cmd_tready),
.s_axis_mem_read_cmd_tdata(axis_user_read_mem1_cmd_tdata),
//memory read status
.m_axis_mem_read_sts_tvalid(),
.m_axis_mem_read_sts_tready(1'b1),
.m_axis_mem_read_sts_tdata(),
//memory read stream
.m_axis_mem_read_tvalid(axis_user_read_mem1_data_tvalid),
.m_axis_mem_read_tready(axis_user_read_mem1_data_tready),
.m_axis_mem_read_tdata(axis_user_read_mem1_data_tdata),
.m_axis_mem_read_tkeep(axis_user_read_mem1_data_tkeep),
.m_axis_mem_read_tlast(axis_user_read_mem1_data_tlast),

//memory write commands
.s_axis_mem_write_cmd_tvalid(axis_user_write_mem1_cmd_tvalid),
.s_axis_mem_write_cmd_tready(axis_user_write_mem1_cmd_tready),
.s_axis_mem_write_cmd_tdata(axis_user_write_mem1_cmd_tdata),
//memory rite status
.m_axis_mem_write_sts_tvalid(axis_user_write_mem1_status_tvalid),
.m_axis_mem_write_sts_tready(axis_user_write_mem1_status_tready),
.m_axis_mem_write_sts_tdata(axis_user_write_mem1_status_tdata),
//memory write stream
.s_axis_mem_write_tvalid(axis_user_write_mem1_data_tvalid),
.s_axis_mem_write_tready(axis_user_write_mem1_data_tready),
.s_axis_mem_write_tdata(axis_user_write_mem1_data_tdata),
.s_axis_mem_write_tkeep(axis_user_write_mem1_data_tkeep),
.s_axis_mem_write_tlast(axis_user_write_mem1_data_tlast),*/

/* CONTROL INTERFACE */
// LITE interface
//-- AXI Master Write Address Channel
.s_axil_awaddr(axil_to_modules_awaddr[AxilPortDDR1]),              // output wire [31 : 0] m_axil_awaddr
.s_axil_awprot(),              // output wire [2 : 0] m_axil_awprot
.s_axil_awvalid(axil_to_modules_awvalid[AxilPortDDR1]),            // output wire m_axil_awvalid
.s_axil_awready(axil_to_modules_awready[AxilPortDDR1]),            // input wire m_axil_awready
//-- AXI Master Write Data Channel
.s_axil_wdata(axil_to_modules_wdata[AxilPortDDR1]),                // output wire [31 : 0] m_axil_wdata
.s_axil_wstrb(axil_to_modules_wstrb[AxilPortDDR1]),                // output wire [3 : 0] m_axil_wstrb
.s_axil_wvalid(axil_to_modules_wvalid[AxilPortDDR1]),              // output wire m_axil_wvalid
.s_axil_wready(axil_to_modules_wready[AxilPortDDR1]),              // input wire m_axil_wready
//-- AXI Master Write Response Channel
.s_axil_bvalid(axil_to_modules_bvalid[AxilPortDDR1]),              // input wire m_axil_bvalid
.s_axil_bresp(axil_to_modules_bresp[AxilPortDDR1]),                // input wire [1 : 0] m_axil_bresp
.s_axil_bready(axil_to_modules_bready[AxilPortDDR1]),              // output wire m_axil_bready
//-- AXI Master Read Address Channel
.s_axil_araddr(axil_to_modules_araddr[AxilPortDDR1]),              // output wire [31 : 0] m_axil_araddr
.s_axil_arprot(),              // output wire [2 : 0] m_axil_arprot
.s_axil_arvalid(axil_to_modules_arvalid[AxilPortDDR1]),            // output wire m_axil_arvalid
.s_axil_arready(axil_to_modules_arready[AxilPortDDR1]),            // input wire m_axil_arready
.s_axil_rdata(axil_to_modules_rdata[AxilPortDDR1]),                // input wire [31 : 0] m_axil_rdata
//-- AXI Master Read Data Channel
.s_axil_rresp(axil_to_modules_rresp[AxilPortDDR1]),                // input wire [1 : 0] m_axil_rresp
.s_axil_rvalid(axil_to_modules_rvalid[AxilPortDDR1]),              // input wire m_axil_rvalid
.s_axil_rready(axil_to_modules_rready[AxilPortDDR1]),              // output wire m_axil_rready



/* DRIVER INTERFACE */
.m_axi_awid(m_axi_awid[DDR_CHANNEL1]),
.m_axi_awaddr(m_axi_awaddr[DDR_CHANNEL1]),
.m_axi_awlen(m_axi_awlen[DDR_CHANNEL1]),
.m_axi_awsize(m_axi_awsize[DDR_CHANNEL1]),
.m_axi_awburst(m_axi_awburst[DDR_CHANNEL1]),
.m_axi_awlock(m_axi_awlock[DDR_CHANNEL1]),
.m_axi_awcache(m_axi_awcache[DDR_CHANNEL1]),
.m_axi_awprot(m_axi_awprot[DDR_CHANNEL1]),
.m_axi_awvalid(m_axi_awvalid[DDR_CHANNEL1]),
.m_axi_awready(m_axi_awready[DDR_CHANNEL1]),

.m_axi_wdata(m_axi_wdata[DDR_CHANNEL1]),
.m_axi_wstrb(m_axi_wstrb[DDR_CHANNEL1]),
.m_axi_wlast(m_axi_wlast[DDR_CHANNEL1]),
.m_axi_wvalid(m_axi_wvalid[DDR_CHANNEL1]),
.m_axi_wready(m_axi_wready[DDR_CHANNEL1]),

.m_axi_bready(m_axi_bready[DDR_CHANNEL1]),
.m_axi_bid(m_axi_bid[DDR_CHANNEL1]),
.m_axi_bresp(m_axi_bresp[DDR_CHANNEL1]),
.m_axi_bvalid(m_axi_bvalid[DDR_CHANNEL1]),

.m_axi_arid(m_axi_arid[DDR_CHANNEL1]),
.m_axi_araddr(m_axi_araddr[DDR_CHANNEL1]),
.m_axi_arlen(m_axi_arlen[DDR_CHANNEL1]),
.m_axi_arsize(m_axi_arsize[DDR_CHANNEL1]),
.m_axi_arburst(m_axi_arburst[DDR_CHANNEL1]),
.m_axi_arlock(m_axi_arlock[DDR_CHANNEL1]),
.m_axi_arcache(m_axi_arcache[DDR_CHANNEL1]),
.m_axi_arprot(m_axi_arprot[DDR_CHANNEL1]),
.m_axi_arvalid(m_axi_arvalid[DDR_CHANNEL1]),
.m_axi_arready(m_axi_arready[DDR_CHANNEL1]),

.m_axi_rready(m_axi_rready[DDR_CHANNEL1]),
.m_axi_rid(m_axi_rid[DDR_CHANNEL1]),
.m_axi_rdata(m_axi_rdata[DDR_CHANNEL1]),
.m_axi_rresp(m_axi_rresp[DDR_CHANNEL1]),
.m_axi_rlast(m_axi_rlast[DDR_CHANNEL1]),
.m_axi_rvalid(m_axi_rvalid[DDR_CHANNEL1])
);
`else
//TODO
`endif

 
/*
 * DMA Interface
 */
/*wire        axis_c2h_tvalid_0;
wire        axis_c2h_tready_0;
wire[511:0] axis_c2h_tdata_0;
wire[63:0]  axis_c2h_tkeep_0;
wire        axis_c2h_tlast_0;

wire        axis_h2c_tvalid_0;
wire        axis_h2c_tready_0;
wire[511:0] axis_h2c_tdata_0;
wire[63:0]  axis_h2c_tkeep_0;
wire        axis_h2c_tlast_0;

wire        c2h_dsc_byp_load_0;
wire        c2h_dsc_byp_ready_0;
wire[63:0]  c2h_dsc_byp_addr_0;
wire[31:0]  c2h_dsc_byp_len_0;

wire        h2c_dsc_byp_load_0;
wire        h2c_dsc_byp_ready_0;
wire[63:0]  h2c_dsc_byp_addr_0;
wire[31:0]  h2c_dsc_byp_len_0;*/

dma_inf dma_interface (
    .pcie_clk(pcie_clk),
    .pcie_aresetn(pcie_aresetn),
    .user_clk(net_clk),
    .user_aresetn(net_aresetn),

    /* USER INTERFACE */
    .s_axis_dma_read_cmd_tvalid     (axis_dma_read_cmd_tvalid),
    .s_axis_dma_read_cmd_tready     (axis_dma_read_cmd_tready),
    .s_axis_dma_read_cmd_tdata      (axis_dma_read_cmd_tdata),
    .s_axis_dma_write_cmd_tvalid    (axis_dma_write_cmd_tvalid),
    .s_axis_dma_write_cmd_tready    (axis_dma_write_cmd_tready),
    .s_axis_dma_write_cmd_tdata     (axis_dma_write_cmd_tdata),

    .m_axis_dma_read_data_tvalid    (axis_dma_read_data_tvalid),
    .m_axis_dma_read_data_tready    (axis_dma_read_data_tready),
    .m_axis_dma_read_data_tdata     (axis_dma_read_data_tdata),
    .m_axis_dma_read_data_tkeep     (axis_dma_read_data_tkeep),
    .m_axis_dma_read_data_tlast     (axis_dma_read_data_tlast),

    .s_axis_dma_write_data_tvalid   (axis_dma_write_data_tvalid),
    .s_axis_dma_write_data_tready   (axis_dma_write_data_tready),
    .s_axis_dma_write_data_tdata    (axis_dma_write_data_tdata),
    .s_axis_dma_write_data_tkeep    (axis_dma_write_data_tkeep),
    .s_axis_dma_write_data_tlast    (axis_dma_write_data_tlast),


    /* DRIVER INTERFACE */
    // LITE interface
    //-- AXI Master Write Address Channel
    .s_axil_awaddr(axil_to_modules_awaddr[AxilPortDMA]),              // output wire [31 : 0] m_axil_awaddr
    .s_axil_awprot(),              // output wire [2 : 0] m_axil_awprot
    .s_axil_awvalid(axil_to_modules_awvalid[AxilPortDMA]),            // output wire m_axil_awvalid
    .s_axil_awready(axil_to_modules_awready[AxilPortDMA]),            // input wire m_axil_awready
    //-- AXI Master Write Data Channel
    .s_axil_wdata(axil_to_modules_wdata[AxilPortDMA]),                // output wire [31 : 0] m_axil_wdata
    .s_axil_wstrb(axil_to_modules_wstrb[AxilPortDMA]),                // output wire [3 : 0] m_axil_wstrb
    .s_axil_wvalid(axil_to_modules_wvalid[AxilPortDMA]),              // output wire m_axil_wvalid
    .s_axil_wready(axil_to_modules_wready[AxilPortDMA]),              // input wire m_axil_wready
    //-- AXI Master Write Response Channel
    .s_axil_bvalid(axil_to_modules_bvalid[AxilPortDMA]),              // input wire m_axil_bvalid
    .s_axil_bresp(axil_to_modules_bresp[AxilPortDMA]),                // input wire [1 : 0] m_axil_bresp
    .s_axil_bready(axil_to_modules_bready[AxilPortDMA]),              // output wire m_axil_bready
    //-- AXI Master Read Address Channel
    .s_axil_araddr(axil_to_modules_araddr[AxilPortDMA]),              // output wire [31 : 0] m_axil_araddr
    .s_axil_arprot(),              // output wire [2 : 0] m_axil_arprot
    .s_axil_arvalid(axil_to_modules_arvalid[AxilPortDMA]),            // output wire m_axil_arvalid
    .s_axil_arready(axil_to_modules_arready[AxilPortDMA]),            // input wire m_axil_arready
    .s_axil_rdata(axil_to_modules_rdata[AxilPortDMA]),                // input wire [31 : 0] m_axil_rdata
    //-- AXI Master Read Data Channel
    .s_axil_rresp(axil_to_modules_rresp[AxilPortDMA]),                // input wire [1 : 0] m_axil_rresp
    .s_axil_rvalid(axil_to_modules_rvalid[AxilPortDMA]),              // input wire m_axil_rvalid
    .s_axil_rready(axil_to_modules_rready[AxilPortDMA]),              // output wire m_axil_rready
    
    .m_axis_c2h_tvalid_0(m_axis_dma_c2h.valid),
    .m_axis_c2h_tready_0(m_axis_dma_c2h.ready),
    .m_axis_c2h_tdata_0(m_axis_dma_c2h.data),
    .m_axis_c2h_tkeep_0(m_axis_dma_c2h.keep),
    .m_axis_c2h_tlast_0(m_axis_dma_c2h.last),

    .s_axis_h2c_tvalid_0(s_axis_dma_h2c.valid),
    .s_axis_h2c_tready_0(s_axis_dma_h2c.ready),
    .s_axis_h2c_tdata_0(s_axis_dma_h2c.data),
    .s_axis_h2c_tkeep_0(s_axis_dma_h2c.keep),
    .s_axis_h2c_tlast_0(s_axis_dma_h2c.last),

    .c2h_dsc_byp_load_0(c2h_dsc_byp_load_0),
    .c2h_dsc_byp_ready_0(c2h_dsc_byp_ready_0),
    .c2h_dsc_byp_addr_0(c2h_dsc_byp_addr_0),
    .c2h_dsc_byp_len_0(c2h_dsc_byp_len_0),

    .h2c_dsc_byp_load_0(h2c_dsc_byp_load_0),
    .h2c_dsc_byp_ready_0(h2c_dsc_byp_ready_0),
    .h2c_dsc_byp_addr_0(h2c_dsc_byp_addr_0),
    .h2c_dsc_byp_len_0(h2c_dsc_byp_len_0),

    .c2h_sts_0(c2h_sts_0),
    .h2c_sts_0(h2c_sts_0)

);

 
 /*
 * Axi Lite Controller Interconnect
 */
//TODO add prot signals??
 axil_interconnect_done_right axi_controller_interconnect_inst (
    .aclk(pcie_clk),
    .aresetn(pcie_aresetn),
    .s_axil_awaddr  (s_axil_awaddr[31:0]),
    .s_axil_awprot  (),
    .s_axil_awvalid (s_axil_awvalid),
    .s_axil_awready (s_axil_awready),
    .s_axil_wdata   (s_axil_wdata[31:0]),    // block fifo for AXI lite only 31 bits.
    .s_axil_wstrb   (s_axil_wstrb[3:0]),
    .s_axil_wvalid  (s_axil_wvalid),
    .s_axil_wready  (s_axil_wready),
    .s_axil_bresp   (s_axil_bresp),
    .s_axil_bvalid  (s_axil_bvalid),
    .s_axil_bready  (s_axil_bready),
    .s_axil_araddr  (s_axil_araddr[31:0]),
    .s_axil_arprot  (),
    .s_axil_arvalid (s_axil_arvalid),
    .s_axil_arready (s_axil_arready),
    .s_axil_rdata   (s_axil_rdata),   // block ram for AXI Lite is only 31 bits
    .s_axil_rresp   (s_axil_rresp),
    .s_axil_rvalid  (s_axil_rvalid),
    .s_axil_rready  (s_axil_rready),

    .m_axil_awaddr(axil_to_modules_awaddr),              // output wire [31 : 0] m_axil_awaddr
    .m_axil_awprot(),              // output wire [2 : 0] m_axil_awprot
    .m_axil_awvalid(axil_to_modules_awvalid),            // output wire m_axil_awvalid
    .m_axil_awready(axil_to_modules_awready),            // input wire m_axil_awready
    .m_axil_wdata(axil_to_modules_wdata),                // output wire [31 : 0] m_axil_wdata
    .m_axil_wstrb(axil_to_modules_wstrb),                // output wire [3 : 0] m_axil_wstrb
    .m_axil_wvalid(axil_to_modules_wvalid),              // output wire m_axil_wvalid
    .m_axil_wready(axil_to_modules_wready),              // input wire m_axil_wready
    .m_axil_bvalid(axil_to_modules_bvalid),              // input wire m_axil_bvalid
    .m_axil_bresp(axil_to_modules_bresp),                // input wire [1 : 0] m_axil_bresp
    .m_axil_bready(axil_to_modules_bready),              // output wire m_axil_bready
    .m_axil_araddr(axil_to_modules_araddr),              // output wire [31 : 0] m_axil_araddr
    .m_axil_arprot(),              // output wire [2 : 0] m_axil_arprot
    .m_axil_arvalid(axil_to_modules_arvalid),            // output wire m_axil_arvalid
    .m_axil_arready(axil_to_modules_arready),            // input wire m_axil_arready
    .m_axil_rdata(axil_to_modules_rdata),                // input wire [31 : 0] m_axil_rdata
    .m_axil_rresp(axil_to_modules_rresp),                // input wire [1 : 0] m_axil_rresp
    .m_axil_rvalid(axil_to_modules_rvalid),              // input wire m_axil_rvalid
    .m_axil_rready(axil_to_modules_rready)              // output wire m_axil_rready

);
   
endmodule
`default_nettype wire