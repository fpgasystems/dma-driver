/*
 * Copyright (c) 2018, Systems Group, ETH Zurich
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
`timescale 1ns / 1ps
`default_nettype none

`define USE_DDR

module dma_example_top
(
    input  wire [1-1:0] gt_rxp_in,
    input  wire [1-1:0] gt_rxn_in,
    output wire [1-1:0] gt_txp_out,
    output wire [1-1:0] gt_txn_out,

    input wire             sys_reset,
    input wire             gt_refclk_p,
    input wire             gt_refclk_n,
    input wire             dclk_p,
    input wire             dclk_n,

    //156.25MHz user clock
    //input wire             uclk_p,
    //input wire             uclk_n,
    
    // PCI Express slot PERST# reset signal
    input wire                           perst_n, //TODO rename pcie_rstn
    // PCIe differential reference clock input
    input wire                           pcie_clk_p,
    input wire                           pcie_clk_n,
    // PCIe differential transmit output
    output wire  [7:0]                   pcie_tx_p,
    output wire  [7:0]                   pcie_tx_n,
    // PCIe differential receive output
    input wire   [7:0]                   pcie_rx_p,
    input wire   [7:0]                   pcie_rx_n,
    
`ifdef USE_DDR    
    //DDR0
    input wire                   c0_sys_clk_p,
    input wire                   c0_sys_clk_n,
    output wire                  c0_ddr4_act_n,
    output wire[16:0]            c0_ddr4_adr,
    output wire[1:0]            c0_ddr4_ba,
    output wire[0:0]            c0_ddr4_bg,
    output wire[0:0]            c0_ddr4_cke,
    output wire[0:0]            c0_ddr4_odt,
    output wire[0:0]            c0_ddr4_cs_n,
    output wire[0:0]                 c0_ddr4_ck_t,
    output wire[0:0]                c0_ddr4_ck_c,
    output wire                 c0_ddr4_reset_n,
    inout  wire[8:0]            c0_ddr4_dm_dbi_n, //9:0 with native interface
    inout  wire[71:0]            c0_ddr4_dq, //79:0 with native interface
    inout  wire[8:0]            c0_ddr4_dqs_t, //9:0 with native interface
    inout  wire[8:0]            c0_ddr4_dqs_c, //9:0 with native interface
    
    //DDR1
    input wire                   c1_sys_clk_p,
    input wire                   c1_sys_clk_n,
    output wire                  c1_ddr4_act_n,
    output wire[16:0]            c1_ddr4_adr,
    output wire[1:0]            c1_ddr4_ba,
    output wire[0:0]            c1_ddr4_bg,
    output wire[0:0]            c1_ddr4_cke,
    output wire[0:0]            c1_ddr4_odt,
    output wire[0:0]            c1_ddr4_cs_n,
    output wire[0:0]                 c1_ddr4_ck_t,
    output wire[0:0]                c1_ddr4_ck_c,
    output wire                 c1_ddr4_reset_n,
    inout  wire[8:0]            c1_ddr4_dm_dbi_n, //9:0 with native interface
    inout  wire[71:0]            c1_ddr4_dq, //79:0 with native interface
    inout  wire[8:0]            c1_ddr4_dqs_t, //9:0 with native interface
    inout  wire[8:0]            c1_ddr4_dqs_c, //9:0 with native interface
`endif
    
    //buttons
    input wire              button_center,
    input wire              button_north,
    input wire              button_west,
    input wire              button_south,
    input wire              button_east,
    
    input wire[3:0]         gpio_switch,
    output wire [7:0]       led
);

(* mark_debug = "true" *)wire sys_reset_n;
wire net_clk;
(* mark_debug = "true" *)wire net_aresetn;
(* mark_debug = "true" *)wire network_init;

(* mark_debug = "true" *)wire [2:0] gt_loopback_in_0; 
(* mark_debug = "true" *)wire[3:0] user_rx_reset;
(* mark_debug = "true" *)wire[3:0] user_tx_reset;
(* mark_debug = "true" *)wire gtpowergood_out;

(* mark_debug = "true" *) wire sys_reset_debug;
assign sys_reset_debug = sys_reset;

wire user_clk;
wire user_aresetn;

//// For other GT loopback options please change the value appropriately
//// For example, for internal loopback gt_loopback_in[2:0] = 3'b010;
//// For more information and settings on loopback, refer GT Transceivers user guide

  wire dclk;
     IBUFDS #(
     .DQS_BIAS("FALSE")  // (FALSE, TRUE)
  )
  dclk_BUFG_inst (
     .O(dclk),   // 1-bit output: Buffer output
     .I(dclk_p),   // 1-bit input: Diff_p buffer input (connect directly to top-level port)
     .IB(dclk_n)  // 1-bit input: Diff_n buffer input (connect directly to top-level port)
  );

  /*wire uclk;
     IBUFDS #(
     .DQS_BIAS("FALSE")  // (FALSE, TRUE)
  )
  uclk_BUFG_inst (
     .O(uclk),   // 1-bit output: Buffer output
     .I(uclk_p),   // 1-bit input: Diff_p buffer input (connect directly to top-level port)
     .IB(uclk_n)  // 1-bit input: Diff_n buffer input (connect directly to top-level port)
  );*/

BUFG bufg_aresetn(
   .I(network_init),
   .O(net_aresetn)
);



assign led[0] = gtpowergood_out;
assign led[1] = network_init;

// PCIe signals
(* mark_debug = "true" *)wire pcie_lnk_up;
wire pcie_ref_clk;
wire pcie_ref_clk_gt;



/*
 * Network Signals
 */
wire        axis_net_rx_data_tvalid;
wire        axis_net_rx_data_tready;
wire[63:0]  axis_net_rx_data_tdata;
wire[7:0]   axis_net_rx_data_tkeep;
wire        axis_net_rx_data_tlast;

wire        axis_net_tx_data_tvalid;
wire        axis_net_tx_data_tready;
wire[63:0]  axis_net_tx_data_tdata;
wire[7:0]   axis_net_tx_data_tkeep;
wire        axis_net_tx_data_tlast;




/*
 * Memory Read and Write Signals
 */

wire        axis_dma_read_cmd_tvalid;
wire        axis_dma_read_cmd_tready;
wire[95:0]  axis_dma_read_cmd_tdata;

wire[47:0] axis_dma_read_cmd_addr;
assign axis_dma_read_cmd_addr = axis_dma_read_cmd_tdata[47:0];


wire        axis_dma_write_cmd_tvalid;
wire        axis_dma_write_cmd_tready;
wire[95:0]  axis_dma_write_cmd_tdata;

wire[47:0] axis_dma_write_cmd_addr;
assign axis_dma_write_cmd_addr = axis_dma_write_cmd_tdata[47:0];
  
assign axis_net_rx_data_tready = 1'b1;
assign axis_net_tx_data_tvalid = 1'b0;
  

network_module network_module_inst
(
    .dclk (dclk),
    .net_clk(net_clk),
    .sys_reset (sys_reset),
    .aresetn(net_aresetn),
    .network_init_done(network_init),
    
    .gt_refclk_p(gt_refclk_p),
    .gt_refclk_n(gt_refclk_n),
    
    .gt_rxp_in(gt_rxp_in),
    .gt_rxn_in(gt_rxn_in),
    .gt_txp_out(gt_txp_out),
    .gt_txn_out(gt_txn_out),
    
    .user_rx_reset(user_rx_reset),
    .user_tx_reset(user_tx_reset),
    .gtpowergood_out(gtpowergood_out),
    
    //master 0
     .m_axis_0_tvalid(axis_net_rx_data_tvalid),
     .m_axis_0_tready(axis_net_rx_data_tready),
     .m_axis_0_tdata(axis_net_rx_data_tdata),
     .m_axis_0_tkeep(axis_net_rx_data_tkeep),
     .m_axis_0_tlast(axis_net_rx_data_tlast),
         
     //slave 0
     .s_axis_0_tvalid(axis_net_tx_data_tvalid),
     .s_axis_0_tready(axis_net_tx_data_tready),
     .s_axis_0_tdata(axis_net_tx_data_tdata),
     .s_axis_0_tkeep(axis_net_tx_data_tkeep),
     .s_axis_0_tlast(axis_net_tx_data_tlast)
    
     //master 1
     /*.m_axis_1_tvalid(axis_net_rx_data_tvalid[1]),
     .m_axis_1_tready(axis_net_rx_data_tready[1]),
     .m_axis_1_tdata(axis_net_rx_data_tdata[1]),
     .m_axis_1_tkeep(axis_net_rx_data_tkeep[1]),
     .m_axis_1_tlast(axis_net_rx_data_tlast[1]),
         
     //slave 1
     .s_axis_1_tvalid(axis_net_tx_data_tvalid[1]),
     .s_axis_1_tready(axis_net_tx_data_tready[1]),
     .s_axis_1_tdata(axis_net_tx_data_tdata[1]),
     .s_axis_1_tkeep(axis_net_tx_data_tkeep[1]),
     .s_axis_1_tlast(axis_net_tx_data_tlast[1]),
    
      //master 2
     .m_axis_2_tvalid(axis_net_rx_data_tvalid[2]),
     .m_axis_2_tready(axis_net_rx_data_tready[2]),
     .m_axis_2_tdata(axis_net_rx_data_tdata[2]),
     .m_axis_2_tkeep(axis_net_rx_data_tkeep[2]),
     .m_axis_2_tlast(axis_net_rx_data_tlast[2]),
         
     //slave 2
     .s_axis_2_tvalid(axis_net_tx_data_tvalid[2]),
     .s_axis_2_tready(axis_net_tx_data_tready[2]),
     .s_axis_2_tdata(axis_net_tx_data_tdata[2]),
     .s_axis_2_tkeep(axis_net_tx_data_tkeep[2]),
     .s_axis_2_tlast(axis_net_tx_data_tlast[2]),
      
     //master 3
     .m_axis_3_tvalid(axis_net_rx_data_tvalid[3]),
     .m_axis_3_tready(axis_net_rx_data_tready[3]),
     .m_axis_3_tdata(axis_net_rx_data_tdata[3]),
     .m_axis_3_tkeep(axis_net_rx_data_tkeep[3]),
     .m_axis_3_tlast(axis_net_rx_data_tlast[3]),
         
     //slave 3
     .s_axis_3_tvalid(axis_net_tx_data_tvalid[3]),
     .s_axis_3_tready(axis_net_tx_data_tready[3]),
     .s_axis_3_tdata(axis_net_tx_data_tdata[3]),
     .s_axis_3_tkeep(axis_net_tx_data_tkeep[3]),
     .s_axis_3_tlast(axis_net_tx_data_tlast[3])*/

);




/*
 * Clock Crossing for IP addreass & Board number
 */
/*axis_clock_converter_32 axis_clock_converter_ip_address (
   .s_axis_aresetn(pcie_aresetn),  // input wire s_axis_aresetn
   .s_axis_aclk(pcie_clk),        // input wire s_axis_aclk
   .s_axis_tvalid(set_ip_addr_valid),    // input wire s_axis_tvalid
   .s_axis_tready(),    // output wire s_axis_tready
   .s_axis_tdata(set_ip_addr_data),
   
   .m_axis_aclk(anet_clk),        // input wire m_axis_aclk
   .m_axis_aresetn(anet_resetn),  // input wire m_axis_aresetn
   .m_axis_tvalid(net_ip_address_valid),    // output wire m_axis_tvalid
   .m_axis_tready(1'b1),    // input wire m_axis_tready
   .m_axis_tdata(net_ip_address_data)      // output wire [159 : 0] m_axis_tdata
 );
 
axis_clock_converter_32 axis_clock_converter_board_number (
    .s_axis_aresetn(pcie_aresetn),  // input wire s_axis_aresetn
    .s_axis_aclk(pcie_clk),        // input wire s_axis_aclk
    .s_axis_tvalid(set_board_number_valid),    // input wire s_axis_tvalid
    .s_axis_tready(),    // output wire s_axis_tready
    .s_axis_tdata(set_board_number_data),
    
    .m_axis_aclk(aclk),        // input wire m_axis_aclk
    .m_axis_aresetn(aresetn),  // input wire m_axis_aresetn
    .m_axis_tvalid(net_board_number_valid),    // output wire m_axis_tvalid
    .m_axis_tready(1'b1),    // input wire m_axis_tready
    .m_axis_tdata(net_board_number_data)      // output wire [159 : 0] m_axis_tdata
  );

wire set_ip_addr_valid;
wire [31:0] set_ip_addr_data;
wire net_ip_address_valid;
wire[31:0] net_ip_address_data;
reg[31:0] local_ip_address;

wire set_board_number_valid;
wire[3:0] set_board_number_data;
wire net_board_number_valid;
wire[3:0] net_board_number_data;
reg[3:0] board_number;

always @(posedge anet_clk) begin
    if (~net_aresetn) begin
        local_ip_address <= 32'hD1D4010B;
        board_number <= 0;
    end
    else begin
        if (net_ip_address_valid) begin
            local_ip_address[7:0] <= net_ip_address_data[31:24];
            local_ip_address[15:8] <= net_ip_address_data[23:16];
            local_ip_address[23:16] <= net_ip_address_data[15:8];
            local_ip_address[31:24] <= net_ip_address_data[7:0];
        end
        if (net_board_number_valid) begin
            board_number <= net_board_number_data;
        end
    end
end*/


wire c0_init_calib_complete;
wire c1_init_calib_complete;

// PCIe usser clock & reset
wire pcie_clk;
(* mark_debug = "true" *)wire pcie_aresetn;


//wire c0_ui_clk;
(* mark_debug = "true" *)wire ddr3_calib_complete; //TODO rename
(* mark_debug = "true" *)wire init_calib_complete;
//wire toeTX_compare_error, ht_compare_error, upd_compare_error;

//reg rst_n_r1, rst_n_r2, rst_n_r3;
//reg reset156_25_n_r1, reset156_25_n_r2, reset156_25_n_r3;

//registers for crossing clock domains (from 233MHz to 156.25MHz)
reg c0_init_calib_complete_r1, c0_init_calib_complete_r2;
reg c1_init_calib_complete_r1, c1_init_calib_complete_r2;


localparam  LED_CTR_WIDTH           = 26;
reg     [LED_CTR_WIDTH-1:0]           l0_ctr;
reg     [LED_CTR_WIDTH-1:0]           l1_ctr;
reg     [LED_CTR_WIDTH-1:0]           l2_ctr;
reg     [LED_CTR_WIDTH-1:0]           l3_ctr;

always @(posedge net_clk)
begin
    l0_ctr <= l0_ctr + {{(LED_CTR_WIDTH-1){1'b0}}, 1'b1};
end

`ifdef USE_DDR
always @(posedge mem0_clk)
begin
    l1_ctr <= l1_ctr + {{(LED_CTR_WIDTH-1){1'b0}}, 1'b1};
end
`endif
/*always @(posedge clk_ref_200)
begin
    l2_ctr <= l2_ctr + {{(LED_CTR_WIDTH-1){1'b0}}, 1'b1};
end*/
always @(posedge pcie_clk)
begin
    l3_ctr <= l3_ctr + {{(LED_CTR_WIDTH-1){1'b0}}, 1'b1};
end



/*assign led[0] = network_init & pok_dram & init_calib_complete;
assign led[1] = pcie_lnk_up;*/
assign led[2] = l0_ctr[LED_CTR_WIDTH-1];
assign led[3] = l3_ctr[LED_CTR_WIDTH-1];
assign led[4] = perst_n & net_aresetn;
assign led[5] = l1_ctr[LED_CTR_WIDTH-1];

   
   /*always @(posedge aclk) begin
        reset156_25_n_r1 <= perst_n & pok_dram & network_init;
        reset156_25_n_r2 <= reset156_25_n_r1;
        aresetn <= reset156_25_n_r2;
   end*/
  
always @(posedge user_clk) //TODO change to user_clk 
    if (~user_aresetn) begin
        c0_init_calib_complete_r1 <= 1'b0;
        c0_init_calib_complete_r2 <= 1'b0;
        c1_init_calib_complete_r1 <= 1'b0;
        c1_init_calib_complete_r2 <= 1'b0;
    end
    else begin
        c0_init_calib_complete_r1 <= c0_init_calib_complete;
        c0_init_calib_complete_r2 <= c0_init_calib_complete_r1;
        c1_init_calib_complete_r1 <= c1_init_calib_complete;
        c1_init_calib_complete_r2 <= c1_init_calib_complete_r1;
    end

assign ddr3_calib_complete = c0_init_calib_complete_r2 & c1_init_calib_complete_r2;
assign init_calib_complete = ddr3_calib_complete;



/*
 * User Role
 */
//address write
/*typedef enum {
    AxilPortUserRole    = 0,
    AxilPortDMA         = 1,
    AxilPortDDR0        = 2,
    AxilPortDDR1        = 3,
} AxilPort;*/
localparam AxilPortUserRole = 0; //TODO enum
localparam AxilPortDMA = 1;
localparam AxilPortDDR0 = 2;
localparam AxilPortDDR1 = 3;

localparam NUM_AXIL_MODULES = 2;
(* mark_debug = "true" *)wire [31: 0] axil_to_modules_awaddr    [NUM_AXIL_MODULES-1:0];
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
(* mark_debug = "true" *)wire [31: 0] axil_to_modules_araddr    [NUM_AXIL_MODULES-1:0];
(* mark_debug = "true" *)wire[NUM_AXIL_MODULES-1:0] axil_to_modules_arvalid;
(* mark_debug = "true" *)wire[NUM_AXIL_MODULES-1:0] axil_to_modules_arready;
 
//data read
wire [31: 0] axil_to_modules_rdata  [NUM_AXIL_MODULES-1:0];
wire [1:0] axil_to_modules_rresp    [NUM_AXIL_MODULES-1:0];
(* mark_debug = "true" *)wire[NUM_AXIL_MODULES-1:0] axil_to_modules_rvalid;
(* mark_debug = "true" *)wire[NUM_AXIL_MODULES-1:0] axil_to_modules_rready;


benchmark_role user_role(
    .net_clk(net_clk),
    .net_aresetn(net_aresetn),
    .pcie_clk(pcie_clk),
    .pcie_aresetn(pcie_aresetn),

    .user_clk(user_clk),
    .user_aresetn(user_aresetn),
    
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
    .m_axis_mem0_read_cmd_tvalid(axis_user_read_mem0_cmd_tvalid),
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
    .s_axis_mem1_write_sts_tdata(axis_user_write_mem1_status_tdata),

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





/*
 * DMA Test Bench
 */
/* wire axis_bench_cmd_valid;
 reg axis_bench_cmd_ready;
wire[192:0] axis_bench_cmd_data;
 
 /*wire axis_pcie_bench_cmd_valid;
 wire axis_pcie_bench_cmd_ready;
 wire[192:0] axis_pcie_bench_cmd_data;*/
 
 /*wire        axis_bench_read_cmd_TVALID;
 wire        axis_bench_read_cmd_TREADY;
 wire[95:0]  axis_bench_read_cmd_TDATA;
wire        axis_bench_write_cmd_TVALID;
 wire        axis_bench_write_cmd_TREADY;
 wire[95:0]  axis_bench_write_cmd_TDATA;
 
wire   axis_bench_write_data_tvalid;
wire   axis_bench_write_data_tready;
wire[511:0]   axis_bench_write_data_tdata;
wire[63:0]  axis_bench_write_data_tkeep;
wire   axis_bench_write_data_tlast;

wire   axis_bench_read_data_tvalid;
wire   axis_bench_read_data_tready;
wire[511:0]   axis_bench_read_data_tdata;
wire[63:0]  axis_bench_read_data_tkeep;
wire   axis_bench_read_data_tlast;
 
wire execution_cycles_valid;
wire[63:0] execution_cycles_data;
reg[63:0] dma_bench_execution_cycles;
wire[63:0] pcie_dma_bench_execution_cycles;

reg[47:0] dmaBenchBaseAddr;
reg[47:0] dmaBenchMemorySize;
reg[31:0] dmaBenchNumberOfAccesses;
reg[31:0] dmaBenchChunkLength;
reg[31:0] dmaBenchStrideLength;
reg dmaBenchIsWrite;
reg dmaBenchStart;

reg[63:0] debug_cycle_counter;
reg runBench;

always @(posedge pcie_clk) begin
    if (~pcie_aresetn) begin
        axis_bench_cmd_ready <= 0;
        runBench <= 0;
    end
    else begin
        dmaBenchStart <= 0;
        axis_bench_cmd_ready <= 1;
        if (axis_bench_cmd_valid && axis_bench_cmd_ready) begin
            dmaBenchBaseAddr <= axis_bench_cmd_data[47:0];
            dmaBenchMemorySize <= axis_bench_cmd_data[95:48];
            dmaBenchNumberOfAccesses <= axis_bench_cmd_data[127:96];
            dmaBenchChunkLength <= axis_bench_cmd_data[159:128];
            dmaBenchStrideLength <= axis_bench_cmd_data[191:160];
            dmaBenchIsWrite <= axis_bench_cmd_data[192];
            dmaBenchStart <= 1;
            dma_bench_execution_cycles <= 0;
            debug_cycle_counter <= 0;
            runBench <= 1;
        end
        if (runBench) begin
            debug_cycle_counter <= debug_cycle_counter + 1;
        end
        if (execution_cycles_valid) begin
            dma_bench_execution_cycles <= execution_cycles_data;
            runBench <= 0;
        end
    end
end
 
dma_bench_ip dma_bench_inst(
 .m_axis_read_cmd_TVALID(axis_bench_read_cmd_TVALID),
 .m_axis_read_cmd_TREADY(axis_bench_read_cmd_TREADY),
 .m_axis_read_cmd_TDATA(axis_bench_read_cmd_TDATA),
 .m_axis_write_cmd_TVALID(axis_bench_write_cmd_TVALID),
 .m_axis_write_cmd_TREADY(axis_bench_write_cmd_TREADY),
 .m_axis_write_cmd_TDATA(axis_bench_write_cmd_TDATA),
 .m_axis_write_data_TVALID(axis_bench_write_data_tvalid),
 .m_axis_write_data_TREADY(axis_bench_write_data_tready),
 .m_axis_write_data_TDATA(axis_bench_write_data_tdata),
 .m_axis_write_data_TKEEP(axis_bench_write_data_tkeep),
 .m_axis_write_data_TLAST(axis_bench_write_data_tlast),
 .s_axis_read_data_TVALID(axis_bench_read_data_tvalid),
 .s_axis_read_data_TREADY(axis_bench_read_data_tready),
 .s_axis_read_data_TDATA(axis_bench_read_data_tdata),
 .s_axis_read_data_TKEEP(axis_bench_read_data_tkeep),
 .s_axis_read_data_TLAST(axis_bench_read_data_tlast),
 .aresetn(pcie_aresetn),
 .aclk(pcie_clk),
 .regBaseAddr_V({16'h00, dmaBenchBaseAddr}),
 .memorySize_V({16'h00, dmaBenchMemorySize}),
 .numberOfAccesses_V(dmaBenchNumberOfAccesses),
 .chunkLength_V(dmaBenchChunkLength),
 .strideLength_V(dmaBenchStrideLength),
 .isWrite_V(dmaBenchIsWrite),
 .start_V(dmaBenchStart),
 .regExecutionCycles_V(execution_cycles_data),
 .regExecutionCycles_V_ap_vld(execution_cycles_valid)
 );*/



/*
 * TLB wires
 */

/*wire axis_tlb_interface_valid;
wire axis_tlb_interface_ready;
wire[135:0] axis_tlb_interface_data;

wire        axis_dma_read_cmd_to_clk_tvalid;
wire        axis_dma_read_cmd_to_clk_tready;
wire[95:0]  axis_dma_read_cmd_to_clk_tdata;
wire        axis_dma_write_cmd_to_clk_tvalid;
wire        axis_dma_write_cmd_to_clk_tready;
wire[95:0]  axis_dma_write_cmd_to_clk_tdata;


wire        axis_pcie_dma_read_cmd_tvalid;
wire         axis_pcie_dma_read_cmd_tready;
wire[95:0]  axis_pcie_dma_read_cmd_tdata;
wire        axis_pcie_dma_write_cmd_tvalid;
wire         axis_pcie_dma_write_cmd_tready;
wire[95:0]  axis_pcie_dma_write_cmd_tdata;



//PCIe clock
wire        axis_dma_write_width_tvalid;
wire        axis_dma_write_width_tready;
wire[511:0] axis_dma_write_width_tdata;
wire[63:0]  axis_dma_write_width_tkeep;
wire        axis_dma_write_width_tlast;*/

wire        axis_dma_write_data_tvalid;
wire        axis_dma_write_data_tready;
wire[512:0] axis_dma_write_data_tdata;
wire[63:0]  axis_dma_write_data_tkeep;
wire        axis_dma_write_data_tlast;


//PCIe clock
wire        axis_dma_read_data_tvalid;
wire        axis_dma_read_data_tready;
wire[512:0] axis_dma_read_data_tdata;
wire[63:0]  axis_dma_read_data_tkeep;
wire        axis_dma_read_data_tlast;


/*wire axis_write_data_boundary_to_cc_tvalid;
wire axis_write_data_boundary_to_cc_tready;
wire[511:0] axis_write_data_boundary_to_cc_tdata;
wire[63:0] axis_write_data_boundary_to_cc_tkeep;
wire axis_write_data_boundary_to_cc_tlast;

//read
assign axis_dma_read_cmd_tvalid = axis_bench_read_cmd_TVALID;
assign axis_bench_read_cmd_TREADY = axis_dma_read_cmd_tready;
assign axis_dma_read_cmd_tdata = axis_bench_read_cmd_TDATA;

mem_write_cmd_page_boundary_check_512_ip mem_write_cmd_page_boundary_check_inst (
  .regBaseVaddr_V({16'h0000, regBaseVaddrBoundCheck}),          // input wire [63 : 0] regBaseVaddr_V
  .m_axis_cmd_TVALID(axis_dma_write_cmd_tvalid),    // output wire m_axis_cmd_TVALID
  .m_axis_cmd_TREADY(axis_dma_write_cmd_tready),    // input wire m_axis_cmd_TREADY
  .m_axis_cmd_TDATA(axis_dma_write_cmd_tdata),      // output wire [95 : 0] m_axis_cmd_TDATA
  .m_axis_data_TVALID(axis_write_data_boundary_to_cc_tvalid),  // output wire m_axis_data_TVALID
  .m_axis_data_TREADY(axis_write_data_boundary_to_cc_tready),  // input wire m_axis_data_TREADY
  .m_axis_data_TDATA(axis_write_data_boundary_to_cc_tdata),    // output wire [63 : 0] m_axis_data_TDATA
  .m_axis_data_TKEEP(axis_write_data_boundary_to_cc_tkeep),    // output wire [7 : 0] m_axis_data_TKEEP
  .m_axis_data_TLAST(axis_write_data_boundary_to_cc_tlast),    // output wire [0 : 0] m_axis_data_TLAST
  .s_axis_cmd_TVALID(axis_bench_write_cmd_TVALID),    // input wire s_axis_cmd_TVALID
  .s_axis_cmd_TREADY(axis_bench_write_cmd_TREADY),    // output wire s_axis_cmd_TREADY
  .s_axis_cmd_TDATA(axis_bench_write_cmd_TDATA),      // input wire [95 : 0] s_axis_cmd_TDATA
  .s_axis_data_TVALID(axis_bench_write_data_tvalid),  // input wire s_axis_data_TVALID
  .s_axis_data_TREADY(axis_bench_write_data_tready),  // output wire s_axis_data_TREADY
  .s_axis_data_TDATA(axis_bench_write_data_tdata),    // input wire [63 : 0] s_axis_data_TDATA
  .s_axis_data_TKEEP(axis_bench_write_data_tkeep),    // input wire [7 : 0] s_axis_data_TKEEP
  .s_axis_data_TLAST(axis_bench_write_data_tlast),    // input wire [0 : 0] s_axis_data_TLAST
  .aclk(pcie_clk),                              // input wire aclk
  .aresetn(pcie_aresetn)                        // input wire aresetn
);

assign axis_bench_read_data_tvalid = axis_dma_read_data_tvalid;
assign axis_dma_read_data_tready = axis_bench_read_data_tready;
assign axis_bench_read_data_tdata = axis_dma_read_data_tdata;
assign axis_bench_read_data_tkeep = axis_dma_read_data_tkeep;
assign axis_bench_read_data_tlast = axis_dma_read_data_tlast;*/


IBUFDS_GTE4 pcie_ibuf_inst (
    .O(pcie_ref_clk_gt),         // 1-bit output: Refer to Transceiver User Guide
    .ODIV2(pcie_ref_clk),            // 1-bit output: Refer to Transceiver User Guide
    .CEB(1'b0),          // 1-bit input: Refer to Transceiver User Guide
    .I(pcie_clk_p),        // 1-bit input: Refer to Transceiver User Guide
    .IB(pcie_clk_n)        // 1-bit input: Refer to Transceiver User Guide
);

/*
 * Memory Interface
 */


(* mark_debug = "true" *)wire        axis_user_read_mem0_cmd_tvalid;
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


`ifdef USE_DDR
localparam C0_C_S_AXI_ID_WIDTH = 1;
localparam C0_C_S_AXI_ADDR_WIDTH = 32;
localparam C0_C_S_AXI_DATA_WIDTH = 512;

wire mem0_clk;
wire mem0_aresetn;
wire mem1_clk;
wire mem1_aresetn;

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

// Slave Interface Write Address Ports
wire [C0_C_S_AXI_ID_WIDTH-1:0]          c1_s_axi_awid;
wire [C0_C_S_AXI_ADDR_WIDTH-1:0]        c1_s_axi_awaddr;
wire [7:0]                              c1_s_axi_awlen;
wire [2:0]                              c1_s_axi_awsize;
wire [1:0]                              c1_s_axi_awburst;
wire [0:0]                              c1_s_axi_awlock;
wire [3:0]                              c1_s_axi_awcache;
wire [2:0]                              c1_s_axi_awprot;
wire                                    c1_s_axi_awvalid;
wire                                    c1_s_axi_awready;
 // Slave Interface Write Data Ports
wire [C0_C_S_AXI_DATA_WIDTH-1:0]        c1_s_axi_wdata;
wire [(C0_C_S_AXI_DATA_WIDTH/8)-1:0]    c1_s_axi_wstrb;
wire                                    c1_s_axi_wlast;
wire                                    c1_s_axi_wvalid;
wire                                    c1_s_axi_wready;
 // Slave Interface Write Response Ports
wire                                    c1_s_axi_bready;
wire [C0_C_S_AXI_ID_WIDTH-1:0]          c1_s_axi_bid;
wire [1:0]                              c1_s_axi_bresp;
wire                                    c1_s_axi_bvalid;
 // Slave Interface Read Address Ports
wire [C0_C_S_AXI_ID_WIDTH-1:0]          c1_s_axi_arid;
wire [C0_C_S_AXI_ADDR_WIDTH-1:0]        c1_s_axi_araddr;
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
wire [C0_C_S_AXI_ID_WIDTH-1:0]          c1_s_axi_rid;
wire [C0_C_S_AXI_DATA_WIDTH-1:0]        c1_s_axi_rdata;
wire [1:0]                              c1_s_axi_rresp;
wire                                    c1_s_axi_rlast;
wire                                    c1_s_axi_rvalid;



mem_single_inf  mem_inf_inst0(
.user_clk(user_clk),
.user_aresetn(ddr3_calib_complete),
.mem_clk(mem0_clk),
.mem_aresetn(mem0_aresetn),
.pcie_clk(pcie_clk),
.pcie_aresetn(pcie_aresetn),

/* USER INTERFACE */
//memory read commands
.s_axis_mem_read_cmd_tvalid(axis_user_read_mem0_cmd_tvalid),
.s_axis_mem_read_cmd_tready(axis_user_read_mem0_cmd_tready),
.s_axis_mem_read_cmd_tdata(axis_user_read_mem0_cmd_tdata),
//memory read status
.m_axis_mem_read_sts_tvalid(),
.m_axis_mem_read_sts_tready(1'b1),
.m_axis_mem_read_sts_tdata(),
//memory read stream
.m_axis_mem_read_tvalid(axis_user_read_mem0_data_tvalid),
.m_axis_mem_read_tready(axis_user_read_mem0_data_tready),
.m_axis_mem_read_tdata(axis_user_read_mem0_data_tdata),
.m_axis_mem_read_tkeep(axis_user_read_mem0_data_tkeep),
.m_axis_mem_read_tlast(axis_user_read_mem0_data_tlast),

//memory write commands
.s_axis_mem_write_cmd_tvalid(axis_user_write_mem0_cmd_tvalid),
.s_axis_mem_write_cmd_tready(axis_user_write_mem0_cmd_tready),
.s_axis_mem_write_cmd_tdata(axis_user_write_mem0_cmd_tdata),
//memory rite status
.m_axis_mem_write_sts_tvalid(axis_user_write_mem0_status_tvalid),
.m_axis_mem_write_sts_tready(axis_user_write_mem0_status_tready),
.m_axis_mem_write_sts_tdata(axis_user_write_mem0_status_tdata),
//memory write stream
.s_axis_mem_write_tvalid(axis_user_write_mem0_data_tvalid),
.s_axis_mem_write_tready(axis_user_write_mem0_data_tready),
.s_axis_mem_write_tdata(axis_user_write_mem0_data_tdata),
.s_axis_mem_write_tkeep(axis_user_write_mem0_data_tkeep),
.s_axis_mem_write_tlast(axis_user_write_mem0_data_tlast),

/* CONTROL INTERFACE */
// LITE interface
//-- AXI Master Write Address Channel
/*.s_axil_awaddr(axil_to_modules_awaddr[AxilPortDDR0]),              // output wire [31 : 0] m_axil_awaddr
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
.m_axi_awid(c0_s_axi_awid),
.m_axi_awaddr(c0_s_axi_awaddr),
.m_axi_awlen(c0_s_axi_awlen),
.m_axi_awsize(c0_s_axi_awsize),
.m_axi_awburst(c0_s_axi_awburst),
.m_axi_awlock(c0_s_axi_awlock),
.m_axi_awcache(c0_s_axi_awcache),
.m_axi_awprot(c0_s_axi_awprot),
.m_axi_awvalid(c0_s_axi_awvalid),
.m_axi_awready(c0_s_axi_awready),

.m_axi_wdata(c0_s_axi_wdata),
.m_axi_wstrb(c0_s_axi_wstrb),
.m_axi_wlast(c0_s_axi_wlast),
.m_axi_wvalid(c0_s_axi_wvalid),
.m_axi_wready(c0_s_axi_wready),

.m_axi_bready(c0_s_axi_bready),
.m_axi_bid(c0_s_axi_bid),
.m_axi_bresp(c0_s_axi_bresp),
.m_axi_bvalid(c0_s_axi_bvalid),

.m_axi_arid(c0_s_axi_arid),
.m_axi_araddr(c0_s_axi_araddr),
.m_axi_arlen(c0_s_axi_arlen),
.m_axi_arsize(c0_s_axi_arsize),
.m_axi_arburst(c0_s_axi_arburst),
.m_axi_arlock(c0_s_axi_arlock),
.m_axi_arcache(c0_s_axi_arcache),
.m_axi_arprot(c0_s_axi_arprot),
.m_axi_arvalid(c0_s_axi_arvalid),
.m_axi_arready(c0_s_axi_arready),

.m_axi_rready(c0_s_axi_rready),
.m_axi_rid(c0_s_axi_rid),
.m_axi_rdata(c0_s_axi_rdata),
.m_axi_rresp(c0_s_axi_rresp),
.m_axi_rlast(c0_s_axi_rlast),
.m_axi_rvalid(c0_s_axi_rvalid)
);

mem_single_inf  mem_inf_inst1(
.user_clk(user_clk),
.user_aresetn(ddr3_calib_complete),
.mem_clk(mem1_clk),
.mem_aresetn(mem1_aresetn),
.pcie_clk(pcie_clk),
.pcie_aresetn(pcie_aresetn),

/* USER INTERFACE */
//memory read commands
.s_axis_mem_read_cmd_tvalid(axis_user_read_mem1_cmd_tvalid),
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
.s_axis_mem_write_tlast(axis_user_write_mem1_data_tlast),

/* CONTROL INTERFACE */
// LITE interface
//-- AXI Master Write Address Channel
/*.s_axil_awaddr(axil_to_modules_awaddr[AxilPortDDR1]),              // output wire [31 : 0] m_axil_awaddr
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
.m_axi_awid(c1_s_axi_awid),
.m_axi_awaddr(c1_s_axi_awaddr),
.m_axi_awlen(c1_s_axi_awlen),
.m_axi_awsize(c1_s_axi_awsize),
.m_axi_awburst(c1_s_axi_awburst),
.m_axi_awlock(c1_s_axi_awlock),
.m_axi_awcache(c1_s_axi_awcache),
.m_axi_awprot(c1_s_axi_awprot),
.m_axi_awvalid(c1_s_axi_awvalid),
.m_axi_awready(c1_s_axi_awready),

.m_axi_wdata(c1_s_axi_wdata),
.m_axi_wstrb(c1_s_axi_wstrb),
.m_axi_wlast(c1_s_axi_wlast),
.m_axi_wvalid(c1_s_axi_wvalid),
.m_axi_wready(c1_s_axi_wready),

.m_axi_bready(c1_s_axi_bready),
.m_axi_bid(c1_s_axi_bid),
.m_axi_bresp(c1_s_axi_bresp),
.m_axi_bvalid(c1_s_axi_bvalid),

.m_axi_arid(c1_s_axi_arid),
.m_axi_araddr(c1_s_axi_araddr),
.m_axi_arlen(c1_s_axi_arlen),
.m_axi_arsize(c1_s_axi_arsize),
.m_axi_arburst(c1_s_axi_arburst),
.m_axi_arlock(c1_s_axi_arlock),
.m_axi_arcache(c1_s_axi_arcache),
.m_axi_arprot(c1_s_axi_arprot),
.m_axi_arvalid(c1_s_axi_arvalid),
.m_axi_arready(c1_s_axi_arready),

.m_axi_rready(c1_s_axi_rready),
.m_axi_rid(c1_s_axi_rid),
.m_axi_rdata(c1_s_axi_rdata),
.m_axi_rresp(c1_s_axi_rresp),
.m_axi_rlast(c1_s_axi_rlast),
.m_axi_rvalid(c1_s_axi_rvalid)
);


mem_driver  mem_driver0_inst(

/* I/O INTERFACE */
// differential iodelayctrl clk (reference clock)
//.clk_ref_p(clk_ref_p),
//.clk_ref_n(clk_ref_n),
// Differential system clocks
.c0_sys_clk_p(c0_sys_clk_p),
.c0_sys_clk_n(c0_sys_clk_n),
.sys_rst(sys_reset),

//ddr4 pins
.c0_ddr4_adr(c0_ddr4_adr),                                // output wire [16 : 0] c0_ddr4_adr
.c0_ddr4_ba(c0_ddr4_ba),                                  // output wire [1 : 0] c0_ddr4_ba
.c0_ddr4_cke(c0_ddr4_cke),                                // output wire [0 : 0] c0_ddr4_cke
.c0_ddr4_cs_n(c0_ddr4_cs_n),                              // output wire [0 : 0] c0_ddr4_cs_n
.c0_ddr4_dm_dbi_n(c0_ddr4_dm_dbi_n),                      // inout wire [8 : 0] c0_ddr4_dm_dbi_n
.c0_ddr4_dq(c0_ddr4_dq),                                  // inout wire [71 : 0] c0_ddr4_dq
.c0_ddr4_dqs_c(c0_ddr4_dqs_c),                            // inout wire [8 : 0] c0_ddr4_dqs_c
.c0_ddr4_dqs_t(c0_ddr4_dqs_t),                            // inout wire [8 : 0] c0_ddr4_dqs_t
.c0_ddr4_odt(c0_ddr4_odt),                                // output wire [0 : 0] c0_ddr4_odt
.c0_ddr4_bg(c0_ddr4_bg),                                  // output wire [0 : 0] c0_ddr4_bg
.c0_ddr4_reset_n(c0_ddr4_reset_n),                        // output wire c0_ddr4_reset_n
.c0_ddr4_act_n(c0_ddr4_act_n),                            // output wire c0_ddr4_act_n
.c0_ddr4_ck_c(c0_ddr4_ck_c),                              // output wire [0 : 0] c0_ddr4_ck_c
.c0_ddr4_ck_t(c0_ddr4_ck_t),                              // output wire [0 : 0] c0_ddr4_ck_t

//.c0_ui_clk(c0_ui_clk),
.c0_init_calib_complete(c0_init_calib_complete),


/* OS INTERFACE */
.mem_clk(mem0_clk),
.mem_aresetn(mem0_aresetn),

.s_axi_awid(c0_s_axi_awid),
.s_axi_awaddr(c0_s_axi_awaddr),
.s_axi_awlen(c0_s_axi_awlen),
.s_axi_awsize(c0_s_axi_awsize),
.s_axi_awburst(c0_s_axi_awburst),
.s_axi_awlock(c0_s_axi_awlock),
.s_axi_awcache(c0_s_axi_awcache),
.s_axi_awprot(c0_s_axi_awprot),
.s_axi_awvalid(c0_s_axi_awvalid),
.s_axi_awready(c0_s_axi_awready),

.s_axi_wdata(c0_s_axi_wdata),
.s_axi_wstrb(c0_s_axi_wstrb),
.s_axi_wlast(c0_s_axi_wlast),
.s_axi_wvalid(c0_s_axi_wvalid),
.s_axi_wready(c0_s_axi_wready),

.s_axi_bready(c0_s_axi_bready),
.s_axi_bid(c0_s_axi_bid),
.s_axi_bresp(c0_s_axi_bresp),
.s_axi_bvalid(c0_s_axi_bvalid),

.s_axi_arid(c0_s_axi_arid),
.s_axi_araddr(c0_s_axi_araddr),
.s_axi_arlen(c0_s_axi_arlen),
.s_axi_arsize(c0_s_axi_arsize),
.s_axi_arburst(c0_s_axi_arburst),
.s_axi_arlock(c0_s_axi_arlock),
.s_axi_arcache(c0_s_axi_arcache),
.s_axi_arprot(c0_s_axi_arprot),
.s_axi_arvalid(c0_s_axi_arvalid),
.s_axi_arready(c0_s_axi_arready),

.s_axi_rready(c0_s_axi_rready),
.s_axi_rid(c0_s_axi_rid),
.s_axi_rdata(c0_s_axi_rdata),
.s_axi_rresp(c0_s_axi_rresp),
.s_axi_rlast(c0_s_axi_rlast),
.s_axi_rvalid(c0_s_axi_rvalid)

);

mem_driver  mem_driver1_inst(

/* I/O INTERFACE */
// differential iodelayctrl clk (reference clock)
//.clk_ref_p(clk_ref_p),
//.clk_ref_n(clk_ref_n),
// Differential system clocks
.c0_sys_clk_p(c1_sys_clk_p),
.c0_sys_clk_n(c1_sys_clk_n),
.sys_rst(sys_reset),

//ddr4 pins
.c0_ddr4_adr(c1_ddr4_adr),                                // output wire [16 : 0] c0_ddr4_adr
.c0_ddr4_ba(c1_ddr4_ba),                                  // output wire [1 : 0] c0_ddr4_ba
.c0_ddr4_cke(c1_ddr4_cke),                                // output wire [0 : 0] c0_ddr4_cke
.c0_ddr4_cs_n(c1_ddr4_cs_n),                              // output wire [0 : 0] c0_ddr4_cs_n
.c0_ddr4_dm_dbi_n(c1_ddr4_dm_dbi_n),                      // inout wire [8 : 0] c0_ddr4_dm_dbi_n
.c0_ddr4_dq(c1_ddr4_dq),                                  // inout wire [71 : 0] c0_ddr4_dq
.c0_ddr4_dqs_c(c1_ddr4_dqs_c),                            // inout wire [8 : 0] c0_ddr4_dqs_c
.c0_ddr4_dqs_t(c1_ddr4_dqs_t),                            // inout wire [8 : 0] c0_ddr4_dqs_t
.c0_ddr4_odt(c1_ddr4_odt),                                // output wire [0 : 0] c0_ddr4_odt
.c0_ddr4_bg(c1_ddr4_bg),                                  // output wire [0 : 0] c0_ddr4_bg
.c0_ddr4_reset_n(c1_ddr4_reset_n),                        // output wire c0_ddr4_reset_n
.c0_ddr4_act_n(c1_ddr4_act_n),                            // output wire c0_ddr4_act_n
.c0_ddr4_ck_c(c1_ddr4_ck_c),                              // output wire [0 : 0] c0_ddr4_ck_c
.c0_ddr4_ck_t(c1_ddr4_ck_t),                              // output wire [0 : 0] c0_ddr4_ck_t

//.c0_ui_clk(c1_ui_clk),
.c0_init_calib_complete(c1_init_calib_complete),


/* OS INTERFACE */
.mem_clk(mem1_clk),
.mem_aresetn(mem1_aresetn),

.s_axi_awid(c1_s_axi_awid),
.s_axi_awaddr(c1_s_axi_awaddr),
.s_axi_awlen(c1_s_axi_awlen),
.s_axi_awsize(c1_s_axi_awsize),
.s_axi_awburst(c1_s_axi_awburst),
.s_axi_awlock(c1_s_axi_awlock),
.s_axi_awcache(c1_s_axi_awcache),
.s_axi_awprot(c1_s_axi_awprot),
.s_axi_awvalid(c1_s_axi_awvalid),
.s_axi_awready(c1_s_axi_awready),

.s_axi_wdata(c1_s_axi_wdata),
.s_axi_wstrb(c1_s_axi_wstrb),
.s_axi_wlast(c1_s_axi_wlast),
.s_axi_wvalid(c1_s_axi_wvalid),
.s_axi_wready(c1_s_axi_wready),

.s_axi_bready(c1_s_axi_bready),
.s_axi_bid(c1_s_axi_bid),
.s_axi_bresp(c1_s_axi_bresp),
.s_axi_bvalid(c1_s_axi_bvalid),

.s_axi_arid(c1_s_axi_arid),
.s_axi_araddr(c1_s_axi_araddr),
.s_axi_arlen(c1_s_axi_arlen),
.s_axi_arsize(c1_s_axi_arsize),
.s_axi_arburst(c1_s_axi_arburst),
.s_axi_arlock(c1_s_axi_arlock),
.s_axi_arcache(c1_s_axi_arcache),
.s_axi_arprot(c1_s_axi_arprot),
.s_axi_arvalid(c1_s_axi_arvalid),
.s_axi_arready(c1_s_axi_arready),

.s_axi_rready(c1_s_axi_rready),
.s_axi_rid(c1_s_axi_rid),
.s_axi_rdata(c1_s_axi_rdata),
.s_axi_rresp(c1_s_axi_rresp),
.s_axi_rlast(c1_s_axi_rlast),
.s_axi_rvalid(c1_s_axi_rvalid)

);

`else

assign axis_user_read_mem0_cmd_tready = 1'b1;
assign axis_user_read_mem0_data_tvalid = 1'b0;
assign axis_user_read_mem0_data_tdata = 0;
assign axis_user_read_mem0_data_tkeep = 0;
assign axis_user_read_mem0_data_tlast = 0;

assign axis_user_write_mem0_cmd_tready = 1'b1;
assign axis_user_write_mem0_data_tready = 1'b1;
assign axis_user_write_mem0_status_tvalid = 1'b0;
assign axis_user_write_mem0_status_tdata = 0;


assign axis_user_read_mem1_cmd_tready = 1'b1;
assign axis_user_read_mem1_data_tvalid = 1'b0;
assign axis_user_read_mem1_data_tdata = 0;
assign axis_user_read_mem1_data_tkeep = 0;
assign axis_user_read_mem1_data_tlast = 0;

assign axis_user_write_mem1_cmd_tready = 1'b1;
assign axis_user_write_mem1_data_tready = 1'b1;
assign axis_user_write_mem1_status_tvalid = 1'b0;
assign axis_user_write_mem1_status_tdata = 0;


`endif





//get Base Addr of TLB for page boundary check
/*reg[63:0] regBaseVaddr;
reg[47:0] regBaseVaddrBoundCheck;
always @(posedge pcie_clk)
begin 
    if (~pcie_aresetn) begin
        //regBaseVaddr <= 0;
    end
    else begin
        if (axis_tlb_interface_valid && axis_tlb_interface_ready && axis_tlb_interface_data[128]) begin
            regBaseVaddr <= axis_tlb_interface_data[63:0];
            regBaseVaddrBoundCheck <= regBaseVaddr;
        end
    end
end


//we now use 512bit width
assign axis_dma_write_data_tvalid = axis_write_data_boundary_to_cc_tvalid;
assign axis_write_data_boundary_to_cc_tready = axis_dma_write_data_tready;
assign axis_dma_write_data_tdata = axis_write_data_boundary_to_cc_tdata;
assign axis_dma_write_data_tkeep = axis_write_data_boundary_to_cc_tkeep;
assign axis_dma_write_data_tlast = axis_write_data_boundary_to_cc_tlast;*/

/*
 * TLB
 */
/*wire tlb_miss_count_valid;
wire[31:0] tlb_miss_count;
wire tlb_page_crossing_count_valid;
wire[31:0] tlb_page_crossing_count;

reg[31:0] tlb_miss_counter;
 reg[31:0] tlb_boundary_crossing_counter;

always @(posedge pcie_clk)
begin 
    if (~pcie_aresetn) begin
        tlb_miss_counter <= 0;
        tlb_boundary_crossing_counter <= 0;
    end
    else begin
        if (tlb_miss_count_valid) begin
            tlb_miss_counter <= tlb_miss_count;
        end
        if (tlb_page_crossing_count_valid) begin
            tlb_boundary_crossing_counter <= tlb_page_crossing_count;
        end
    end
end


assign pcie_dma_bench_execution_cycles = dma_bench_execution_cycles;

 tlb_ip tlb_inst (
   .m_axis_dma_read_cmd_TVALID(axis_dma_read_cmd_to_clk_tvalid),    // output wire m_axis_dma_read_cmd_tvalid
   .m_axis_dma_read_cmd_TREADY(axis_dma_read_cmd_to_clk_tready),    // input wire m_axis_dma_read_cmd_tready
   .m_axis_dma_read_cmd_TDATA(axis_dma_read_cmd_to_clk_tdata),      // output wire [95 : 0] m_axis_dma_read_cmd_tdata
   .m_axis_dma_write_cmd_TVALID(axis_dma_write_cmd_to_clk_tvalid),  // output wire m_axis_dma_write_cmd_tvalid
   .m_axis_dma_write_cmd_TREADY(axis_dma_write_cmd_to_clk_tready),  // input wire m_axis_dma_write_cmd_tready
   .m_axis_dma_write_cmd_TDATA(axis_dma_write_cmd_to_clk_tdata),    // output wire [95 : 0] m_axis_dma_write_cmd_tdata
   .s_axis_mem_read_cmd_TVALID(axis_dma_read_cmd_tvalid),    // input wire s_axis_mem_read_cmd_tvalid
   .s_axis_mem_read_cmd_TREADY(axis_dma_read_cmd_tready),    // output wire s_axis_mem_read_cmd_tready
   .s_axis_mem_read_cmd_TDATA(axis_dma_read_cmd_tdata),      // input wire [111 : 0] s_axis_mem_read_cmd_tdata
   .s_axis_mem_write_cmd_TVALID(axis_dma_write_cmd_tvalid),  // input wire s_axis_mem_write_cmd_tvalid
   .s_axis_mem_write_cmd_TREADY(axis_dma_write_cmd_tready),  // output wire s_axis_mem_write_cmd_tready
   .s_axis_mem_write_cmd_TDATA(axis_dma_write_cmd_tdata),    // input wire [111 : 0] s_axis_mem_write_cmd_tdata
   .s_axis_tlb_interface_TVALID(axis_tlb_interface_valid),  // input wire s_axis_tlb_interface_tvalid
   .s_axis_tlb_interface_TREADY(axis_tlb_interface_ready),  // output wire s_axis_tlb_interface_tready
   .s_axis_tlb_interface_TDATA(axis_tlb_interface_data),    // input wire [135 : 0] s_axis_tlb_interface_tdata
   .aclk(pcie_clk),                                                // input wire aclk
   .aresetn(pcie_aresetn),                                          // input wire aresetn
   .regTlbMissCount_V(tlb_miss_count),                      // output wire [31 : 0] regTlbMissCount_V
   .regTlbMissCount_V_ap_vld(tlb_miss_count_valid),
   .regPageCrossingCount_V(tlb_page_crossing_count),                // output wire [31 : 0] regPageCrossingCount_V
   .regPageCrossingCount_V_ap_vld(tlb_page_crossing_count_valid)  // output wire regPageCrossingCount_V_ap_vld
 );


wire dma_write_fifo_to_clk_tvalid;
wire dma_write_fifo_to_clk_tready;
wire[95:0] dma_write_fifo_to_clk_tdata;

axis_data_fifo_96 axis_dma_write_cmd_fifo (
  .s_axis_aclk(pcie_clk),                    // input wire aclk
  .s_axis_aresetn(pcie_aresetn),              // input wire aresetn
  .s_axis_tvalid(axis_dma_write_cmd_to_clk_tvalid),  // input wire s_axis_tvalid
  .s_axis_tready(axis_dma_write_cmd_to_clk_tready),  // output wire s_axis_tready
  .s_axis_tdata(axis_dma_write_cmd_to_clk_tdata),    // input wire [95 : 0] s_axis_tdata
  .m_axis_tvalid(dma_write_fifo_to_clk_tvalid),  // output wire m_axis_tvalid
  .m_axis_tready(dma_write_fifo_to_clk_tready),  // input wire m_axis_tready
  .m_axis_tdata(dma_write_fifo_to_clk_tdata),    // output wire [95 : 0] m_axis_tdata
  .axis_data_count(),
  .axis_wr_data_count(),
  .axis_rd_data_count()
);

//TODO make clock crossing fifo
assign axis_pcie_dma_write_cmd_tvalid = dma_write_fifo_to_clk_tvalid;
assign dma_write_fifo_to_clk_tready = axis_pcie_dma_write_cmd_tready;
assign axis_pcie_dma_write_cmd_tdata = dma_write_fifo_to_clk_tdata;
assign axis_pcie_dma_read_cmd_tvalid = axis_dma_read_cmd_to_clk_tvalid;
assign axis_dma_read_cmd_to_clk_tready = axis_pcie_dma_read_cmd_tready;
assign axis_pcie_dma_read_cmd_tdata = axis_dma_read_cmd_to_clk_tdata;

/*axis_clock_converter_96 axis_dma_write_cmd_clk_crossing (
  .s_axis_aresetn(aresetn),  // input wire s_axis_aresetn
  .s_axis_aclk(aclk),        // input wire s_axis_aclk
  .s_axis_tvalid(dma_write_fifo_to_clk_tvalid),    // input wire s_axis_tvalid
  .s_axis_tready(dma_write_fifo_to_clk_tready),    // output wire s_axis_tready
  .s_axis_tdata(dma_write_fifo_to_clk_tdata),      // input wire [95 : 0] s_axis_tdata
  
  .m_axis_aresetn(pcie_aresetn),  // input wire m_axis_aresetn
  .m_axis_aclk(pcie_clk),        // input wire m_axis_aclk
  .m_axis_tvalid(axis_pcie_dma_write_cmd_tvalid),    // output wire m_axis_tvalid
  .m_axis_tready(axis_pcie_dma_write_cmd_tready),    // input wire m_axis_tready
  .m_axis_tdata(axis_pcie_dma_write_cmd_tdata)      // output wire [95 : 0] m_axis_tdata
);

axis_clock_converter_96 axis_dma_read_cmd_clk_crossing (
  .s_axis_aresetn(aresetn),  // input wire s_axis_aresetn
  .s_axis_aclk(aclk),        // input wire s_axis_aclk
  .s_axis_tvalid(axis_dma_read_cmd_to_clk_tvalid),    // input wire s_axis_tvalid
  .s_axis_tready(axis_dma_read_cmd_to_clk_tready),    // output wire s_axis_tready
  .s_axis_tdata(axis_dma_read_cmd_to_clk_tdata),      // input wire [95 : 0] s_axis_tdata
  
  .m_axis_aresetn(pcie_aresetn),  // input wire m_axis_aresetn
  .m_axis_aclk(pcie_clk),        // input wire m_axis_aclk
  .m_axis_tvalid(axis_pcie_dma_read_cmd_tvalid),    // output wire m_axis_tvalid
  .m_axis_tready(axis_pcie_dma_read_cmd_tready),    // input wire m_axis_tready
  .m_axis_tdata(axis_pcie_dma_read_cmd_tdata)      // output wire [95 : 0] m_axis_tdata
);*/

/*
 * DMA
 */
//address write
(* mark_debug = "true" *)wire [31: 0] axil_awaddr;
(* mark_debug = "true" *)wire  axil_awvalid;
(* mark_debug = "true" *)wire axil_awready;
 
//data write
wire [31: 0]   axil_wdata;
wire [3: 0] axil_wstrb;
(* mark_debug = "true" *)wire axil_wvalid;
(* mark_debug = "true" *)wire axil_wready;
 
//write response (handhake)
wire [1:0] axil_bresp;
wire axil_bvalid;
wire axil_bready;
 
//address read
(* mark_debug = "true" *)wire [31: 0] axil_araddr;
(* mark_debug = "true" *)wire axil_arvalid;
(* mark_debug = "true" *)wire axil_arready;
 
//data read
wire [31: 0] axil_rdata;
wire [1:0] axil_rresp;
(* mark_debug = "true" *)wire axil_rvalid;
(* mark_debug = "true" *)wire axil_rready;



wire        axis_c2h_tvalid_0;
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
wire[31:0]  h2c_dsc_byp_len_0;

dma_inf dma_interface (
    .pcie_clk(pcie_clk),
    .pcie_aresetn(pcie_aresetn),
    .user_clk(user_clk),
    .user_aresetn(user_aresetn),

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
    
    .m_axis_c2h_tvalid_0(axis_c2h_tvalid_0),
    .m_axis_c2h_tready_0(axis_c2h_tready_0),
    .m_axis_c2h_tdata_0(axis_c2h_tdata_0),
    .m_axis_c2h_tkeep_0(axis_c2h_tkeep_0),
    .m_axis_c2h_tlast_0(axis_c2h_tlast_0),

    .s_axis_h2c_tvalid_0(axis_h2c_tvalid_0),
    .s_axis_h2c_tready_0(axis_h2c_tready_0),
    .s_axis_h2c_tdata_0(axis_h2c_tdata_0),
    .s_axis_h2c_tkeep_0(axis_h2c_tkeep_0),
    .s_axis_h2c_tlast_0(axis_h2c_tlast_0),

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

    /*.m_axis_dma_bench_cmd_valid        (axis_pcie_bench_cmd_valid),
    .m_axis_dma_bench_cmd_ready        (axis_pcie_bench_cmd_ready),
    .m_axis_dma_bench_cmd_data         (axis_pcie_bench_cmd_data),
    .dma_bench_execution_cycles(pcie_dma_bench_execution_cycles)*/

);


/*
 * DMA Driver
 */
wire[7:0] c2h_sts_0;
wire[7:0] h2c_sts_0;

dma_driver dma_driver_inst (
  .sys_clk(pcie_ref_clk),                                              // input wire sys_clk
  .sys_clk_gt(pcie_ref_clk_gt),
  .sys_rst_n(perst_n),                                          // input wire sys_rst_n
  .user_lnk_up(pcie_lnk_up),                                      // output wire user_lnk_up
  .pcie_tx_p(pcie_tx_p),                                      // output wire [7 : 0] pci_exp_txp
  .pcie_tx_n(pcie_tx_n),                                      // output wire [7 : 0] pci_exp_txn
  .pcie_rx_p(pcie_rx_p),                                      // input wire [7 : 0] pci_exp_rxp
  .pcie_rx_n(pcie_rx_n),                                      // input wire [7 : 0] pci_exp_rxn
  .pcie_clk(pcie_clk),                                            // output wire axi_aclk
  .pcie_aresetn(pcie_aresetn),                                      // output wire axi_aresetn
  //.usr_irq_req(1'b0),                                      // input wire [0 : 0] usr_irq_req
  //.usr_irq_ack(),                                      // output wire [0 : 0] usr_irq_ack
  //.msi_enable(),                                        // output wire msi_enable
  //.msi_vector_width(),                            // output wire [2 : 0] msi_vector_width
  
  // LITE interface   
  //-- AXI Master Write Address Channel
  .m_axil_awaddr(axil_awaddr),              // output wire [31 : 0] m_axil_awaddr
  .m_axil_awprot(),              // output wire [2 : 0] m_axil_awprot
  .m_axil_awvalid(axil_awvalid),            // output wire m_axil_awvalid
  .m_axil_awready(axil_awready),            // input wire m_axil_awready
  //-- AXI Master Write Data Channel
  .m_axil_wdata(axil_wdata),                // output wire [31 : 0] m_axil_wdata
  .m_axil_wstrb(axil_wstrb),                // output wire [3 : 0] m_axil_wstrb
  .m_axil_wvalid(axil_wvalid),              // output wire m_axil_wvalid
  .m_axil_wready(axil_wready),              // input wire m_axil_wready
  //-- AXI Master Write Response Channel
  .m_axil_bvalid(axil_bvalid),              // input wire m_axil_bvalid
  .m_axil_bresp(axil_bresp),                // input wire [1 : 0] m_axil_bresp
  .m_axil_bready(axil_bready),              // output wire m_axil_bready
  //-- AXI Master Read Address Channel
  .m_axil_araddr(axil_araddr),              // output wire [31 : 0] m_axil_araddr
  .m_axil_arprot(),              // output wire [2 : 0] m_axil_arprot
  .m_axil_arvalid(axil_arvalid),            // output wire m_axil_arvalid
  .m_axil_arready(axil_arready),            // input wire m_axil_arready
  .m_axil_rdata(axil_rdata),                // input wire [31 : 0] m_axil_rdata
  //-- AXI Master Read Data Channel
  .m_axil_rresp(axil_rresp),                // input wire [1 : 0] m_axil_rresp
  .m_axil_rvalid(axil_rvalid),              // input wire m_axil_rvalid
  .m_axil_rready(axil_rready),              // output wire m_axil_rready
  
  // AXI Stream Interface
  .s_axis_c2h_tvalid_0(axis_c2h_tvalid_0),                      // input wire s_axis_c2h_tvalid_0
  .s_axis_c2h_tready_0(axis_c2h_tready_0),                      // output wire s_axis_c2h_tready_0
  .s_axis_c2h_tdata_0(axis_c2h_tdata_0),                        // input wire [255 : 0] s_axis_c2h_tdata_0
  .s_axis_c2h_tkeep_0(axis_c2h_tkeep_0),                        // input wire [31 : 0] s_axis_c2h_tkeep_0
  .s_axis_c2h_tlast_0(axis_c2h_tlast_0),                        // input wire s_axis_c2h_tlast_0

  .m_axis_h2c_tvalid_0(axis_h2c_tvalid_0),                      // output wire m_axis_h2c_tvalid_0
  .m_axis_h2c_tready_0(axis_h2c_tready_0),                      // input wire m_axis_h2c_tready_0
  .m_axis_h2c_tdata_0(axis_h2c_tdata_0),                        // output wire [255 : 0] m_axis_h2c_tdata_0
  .m_axis_h2c_tkeep_0(axis_h2c_tkeep_0),                        // output wire [31 : 0] m_axis_h2c_tkeep_0
  .m_axis_h2c_tlast_0(axis_h2c_tlast_0),                        // output wire m_axis_h2c_tlast_0

  // Descriptor Bypass
  .c2h_dsc_byp_ready_0    (c2h_dsc_byp_ready_0),
  //.c2h_dsc_byp_src_addr_0 (64'h0),
  .c2h_dsc_byp_addr_0     (c2h_dsc_byp_addr_0),
  .c2h_dsc_byp_len_0      (c2h_dsc_byp_len_0),
  //.c2h_dsc_byp_ctl_0      (16'h13), //was 16'h3
  .c2h_dsc_byp_load_0     (c2h_dsc_byp_load_0),
  
  .h2c_dsc_byp_ready_0    (h2c_dsc_byp_ready_0),
  .h2c_dsc_byp_addr_0     (h2c_dsc_byp_addr_0),
  //.h2c_dsc_byp_dst_addr_0 (64'h0),
  .h2c_dsc_byp_len_0      (h2c_dsc_byp_len_0),
  //.h2c_dsc_byp_ctl_0      (16'h13), //was 16'h3
  .h2c_dsc_byp_load_0     (h2c_dsc_byp_load_0),
  
  .c2h_sts_0(c2h_sts_0),                                          // output wire [7 : 0] c2h_sts_0
  .h2c_sts_0(h2c_sts_0)                                          // output wire [7 : 0] h2c_sts_0
);

/*
 * Axi Lite Controller Interconnect
 */
//TODO add prot signals??
 axil_interconnect_done_right axi_controller_interconnect_inst (
    .aclk(pcie_clk),
    .aresetn(pcie_aresetn),
    .s_axil_awaddr  (axil_awaddr[31:0]),
    .s_axil_awprot  (),
    .s_axil_awvalid (axil_awvalid),
    .s_axil_awready (axil_awready),
    .s_axil_wdata   (axil_wdata[31:0]),    // block fifo for AXI lite only 31 bits.
    .s_axil_wstrb   (axil_wstrb[3:0]),
    .s_axil_wvalid  (axil_wvalid),
    .s_axil_wready  (axil_wready),
    .s_axil_bresp   (axil_bresp),
    .s_axil_bvalid  (axil_bvalid),
    .s_axil_bready  (axil_bready),
    .s_axil_araddr  (axil_araddr[31:0]),
    .s_axil_arprot  (),
    .s_axil_arvalid (axil_arvalid),
    .s_axil_arready (axil_arready),
    .s_axil_rdata   (axil_rdata),   // block ram for AXI Lite is only 31 bits
    .s_axil_rresp   (axil_rresp),
    .s_axil_rvalid  (axil_rvalid),
    .s_axil_rready  (axil_rready),

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
