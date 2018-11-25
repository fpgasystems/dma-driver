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

module dma_example_top(
    // 156.25 MHz clock in
    input wire                           xphy_refclk_p,
    input wire                           xphy_refclk_n,
    // Ethernet Tx & Rx Differential Pairs //  
    output wire                          xphy0_txp,
    output wire                          xphy0_txn,
    input wire                           xphy0_rxp,
    input wire                           xphy0_rxn,
    output wire                          xphy1_txp,
    output wire                          xphy1_txn,
    input wire                           xphy1_rxp,
    input wire                           xphy1_rxn,
    
    output wire[1:0]                     sfp_tx_disable,
    output wire                          sfp_on,
    input  wire                          sfp_ready, //used as reset to sfp
    
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
    // Connection to SODIMM-A
    // Inouts
    inout wire [71:0]                    c0_ddr3_dq,
    inout wire [8:0]                     c0_ddr3_dqs_n,
    inout wire [8:0]                     c0_ddr3_dqs_p,
    output wire [15:0]                   c0_ddr3_addr,
    output wire [2:0]                    c0_ddr3_ba,
    output wire                          c0_ddr3_ras_n,
    output wire                          c0_ddr3_cas_n,
    output wire                          c0_ddr3_we_n,
    output wire                          c0_ddr3_reset_n,
    output wire [1:0]                    c0_ddr3_ck_p,
    output wire [1:0]                    c0_ddr3_ck_n,
    output wire [1:0]                    c0_ddr3_cke,
    output wire [1:0]                    c0_ddr3_cs_n,
    output wire [1:0]                    c0_ddr3_odt,
    // Differential system clocks
    input wire                           c0_sys_clk_p,
    input wire                           c0_sys_clk_n,
    // differential iodelayctrl clk (reference clock)
    input wire                           clk_ref_p,
    input wire                           clk_ref_n,
    // Inouts
    inout wire [71:0]                    c1_ddr3_dq,
    inout wire [8:0]                     c1_ddr3_dqs_n,
    inout wire [8:0]                     c1_ddr3_dqs_p,
    output wire [15:0]                   c1_ddr3_addr,
    output wire [2:0]                    c1_ddr3_ba,
    output wire                          c1_ddr3_ras_n,
    output wire                          c1_ddr3_cas_n,
    output wire                          c1_ddr3_we_n,
    output wire                          c1_ddr3_reset_n,
    output wire [1:0]                    c1_ddr3_ck_p,
    output wire [1:0]                    c1_ddr3_ck_n,
    output wire [1:0]                    c1_ddr3_cke,
    output wire [1:0]                    c1_ddr3_cs_n,
    output wire [1:0]                    c1_ddr3_odt,
    // Differential system clocks
    input wire                           c1_sys_clk_p,
    input wire                           c1_sys_clk_n,             
    input wire                           pok_dram, //used as reset to ddr
    output wire[8:0]                     c0_ddr3_dm,
    output wire[8:0]                     c1_ddr3_dm,
    output wire[1:0]                     dram_on,
`endif
    input wire                           usr_sw,
    output wire[5:0]                     led);


// PCIe signals
wire pcie_lnk_up;
wire pcie_ref_clk;
//Network signals    
wire network_init;

(* max_fanout = "64" *)  reg net_aresetn;

assign sfp_on = 1'b1;
`ifdef USE_DDR
assign dram_on = 2'b11;
assign c0_ddr3_dm = 9'h0;
assign c1_ddr3_dm = 9'h0;
`else
wire pok_dram;
assign pok_dram = 1'b1;
`endif
wire net_clk;
wire clk_ref_200;


/*
 * Network Signals
 */
/*wire        AXI_M_Stream_TVALID;
wire        AXI_M_Stream_TREADY;
wire[63:0]  AXI_M_Stream_TDATA;
wire[7:0]   AXI_M_Stream_TKEEP;
wire        AXI_M_Stream_TLAST;
*/
wire        AXI_M_Stream0_TVALID;
wire        AXI_M_Stream0_TREADY;
wire[63:0]  AXI_M_Stream0_TDATA;
wire[7:0]   AXI_M_Stream0_TKEEP;
wire        AXI_M_Stream0_TLAST;

wire        AXI_S_Stream0_TVALID;
wire        AXI_S_Stream0_TREADY;
wire[63:0]  AXI_S_Stream0_TDATA;
wire[7:0]   AXI_S_Stream0_TKEEP;
wire        AXI_S_Stream0_TLAST;

wire        AXI_M_Stream1_TVALID;
wire        AXI_M_Stream1_TREADY;
wire[63:0]  AXI_M_Stream1_TDATA;
wire[7:0]   AXI_M_Stream1_TKEEP;
wire        AXI_M_Stream1_TLAST;

wire        AXI_S_Stream1_TVALID;
wire        AXI_S_Stream1_TREADY;
wire[63:0]  AXI_S_Stream1_TDATA;
wire[7:0]   AXI_S_Stream1_TKEEP;
wire        AXI_S_Stream1_TLAST;

//TODO remove later
assign AXI_M_Stream0_TVALID = 1'b0;
assign AXI_M_Stream0_TDATA = 0;
assign AXI_M_Stream0_TKEEP = 0;
assign AXI_M_Stream0_TLAST = 0;

assign AXI_M_Stream1_TVALID = 1'b0;
assign AXI_M_Stream1_TDATA = 0;
assign AXI_M_Stream1_TKEEP = 0;
assign AXI_M_Stream1_TLAST = 0;

assign AXI_S_Stream0_TREADY = 1'b1;
assign AXI_S_Stream1_TREADY = 1'b1;



/*
 * Memory Read and Write Signals
 */

(* mark_debug = "true" *)wire        axis_dma_read_cmd_tvalid;
(* mark_debug = "true" *)wire        axis_dma_read_cmd_tready;
(* mark_debug = "true" *)wire[95:0]  axis_dma_read_cmd_tdata;

(* mark_debug = "true" *)wire[47:0] axis_dma_read_cmd_addr;
assign axis_dma_read_cmd_addr = axis_dma_read_cmd_tdata[47:0];


(* mark_debug = "true" *)wire        axis_dma_write_cmd_tvalid;
(* mark_debug = "true" *)wire        axis_dma_write_cmd_tready;
(* mark_debug = "true" *)wire[95:0]  axis_dma_write_cmd_tdata;

(* mark_debug = "true" *)wire[47:0] axis_dma_write_cmd_addr;
assign axis_dma_write_cmd_addr = axis_dma_write_cmd_tdata[47:0];


/*
 * 10G Network Interface Module
 */
adm7v3_10g_interface n10g_interface_inst (
.reset(~perst_n | ~sfp_ready),
.aresetn(net_aresetn),
.xphy_refclk_p(xphy_refclk_p),
.xphy_refclk_n(xphy_refclk_n),
.xphy0_txp(xphy0_txp),
.xphy0_txn(xphy0_txn),
.xphy0_rxp(xphy0_rxp),
.xphy0_rxn(xphy0_rxn),
.xphy1_txp(xphy1_txp),
.xphy1_txn(xphy1_txn),
.xphy1_rxp(xphy1_rxp),
.xphy1_rxn(xphy1_rxn),
//master 0
.axis_i_0_tdata(AXI_S_Stream0_TDATA),
.axis_i_0_tvalid(AXI_S_Stream0_TVALID),
.axis_i_0_tlast(AXI_S_Stream0_TLAST),
.axis_i_0_tuser(),
.axis_i_0_tkeep(AXI_S_Stream0_TKEEP),
.axis_i_0_tready(AXI_S_Stream0_TREADY),
//slave 0
.axis_o_0_tdata(AXI_M_Stream0_TDATA),
.axis_o_0_tvalid(AXI_M_Stream0_TVALID),
.axis_o_0_tlast(AXI_M_Stream0_TLAST),
.axis_o_0_tuser(0),
.axis_o_0_tkeep(AXI_M_Stream0_TKEEP),
.axis_o_0_tready(AXI_M_Stream0_TREADY),

//master 1
.axis_i_1_tdata(AXI_S_Stream1_TDATA),
.axis_i_1_tvalid(AXI_S_Stream1_TVALID),
.axis_i_1_tlast(AXI_S_Stream1_TLAST),
.axis_i_1_tuser(),
.axis_i_1_tkeep(AXI_S_Stream1_TKEEP),
.axis_i_1_tready(AXI_S_Stream1_TREADY),
//slave 1
.axis_o_1_tdata(AXI_M_Stream1_TDATA),
.axis_o_1_tvalid(AXI_M_Stream1_TVALID),
.axis_o_1_tlast(AXI_M_Stream1_TLAST),
.axis_o_1_tuser(0),
.axis_o_1_tkeep(AXI_M_Stream1_TKEEP),
.axis_o_1_tready(AXI_M_Stream1_TREADY),  

.sfp_tx_disable(sfp_tx_disable),
.clk156_out(net_clk),
.clk_ref_200_out(clk_ref_200),
.network_reset_done(network_init),
.led());


/*
 * Clock Crossing for IP addreass & Board number
 */
/*axis_clock_converter_32 axis_clock_converter_ip_address (
   .s_axis_aresetn(pcie_aresetn),  // input wire s_axis_aresetn
   .s_axis_aclk(pcie_clk),        // input wire s_axis_aclk
   .s_axis_tvalid(set_ip_addr_valid),    // input wire s_axis_tvalid
   .s_axis_tready(),    // output wire s_axis_tready
   .s_axis_tdata(set_ip_addr_data),
   
   .m_axis_aclk(net_clk),        // input wire m_axis_aclk
   .m_axis_aresetn(net_aresetn),  // input wire m_axis_aresetn
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
    
    .m_axis_aclk(net_clk),        // input wire m_axis_aclk
    .m_axis_aresetn(net_aresetn),  // input wire m_axis_aresetn
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

always @(posedge net_clk) begin
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
wire pcie_aresetn;


wire c0_ui_clk;
wire ddr3_calib_complete, init_calib_complete;
wire toeTX_compare_error, ht_compare_error, upd_compare_error;

reg rst_n_r1, rst_n_r2, rst_n_r3;
reg reset156_25_n_r1, reset156_25_n_r2, reset156_25_n_r3;

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

always @(posedge c0_ui_clk)
begin
    l1_ctr <= l1_ctr + {{(LED_CTR_WIDTH-1){1'b0}}, 1'b1};
end
always @(posedge clk_ref_200)
begin
    l2_ctr <= l2_ctr + {{(LED_CTR_WIDTH-1){1'b0}}, 1'b1};
end
always @(posedge pcie_clk)
begin
    l3_ctr <= l3_ctr + {{(LED_CTR_WIDTH-1){1'b0}}, 1'b1};
end



assign led[0] = network_init & pok_dram & init_calib_complete;
assign led[1] = pcie_lnk_up;
assign led[2] = l0_ctr[LED_CTR_WIDTH-1];
assign led[3] = l3_ctr[LED_CTR_WIDTH-1];
assign led[4] = perst_n & net_aresetn;
///assign led[5] = aresetn;

   
   always @(posedge net_clk) begin
        reset156_25_n_r1 <= perst_n & pok_dram & network_init;
        reset156_25_n_r2 <= reset156_25_n_r1;
        net_aresetn <= reset156_25_n_r2;
   end
  
always @(posedge net_clk) 
    if (~net_aresetn) begin
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

localparam NUM_AXIL_MODULES = 4;
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
 /*wire axis_bench_cmd_valid;
 reg axis_bench_cmd_ready;
wire[192:0] axis_bench_cmd_data;
 
wire axis_pcie_bench_cmd_valid;
wire axis_pcie_bench_cmd_ready;
wire[192:0] axis_pcie_bench_cmd_data;
 
 (* mark_debug = "true" *)wire        axis_bench_read_cmd_tvalid;
 (* mark_debug = "true" *)wire        axis_bench_read_cmd_tready;
 wire[95:0]  axis_bench_read_cmd_tdata;
(* mark_debug = "true" *)wire        axis_bench_write_cmd_tvalid;
 (* mark_debug = "true" *)wire        axis_bench_write_cmd_tready;
 wire[95:0]  axis_bench_write_cmd_tdata;

 (* mark_debug = "true" *)wire        axis_pcie_bench_read_cmd_tvalid;
 (* mark_debug = "true" *)wire        axis_pcie_bench_read_cmd_tready;
 wire[95:0]  axis_pcie_bench_read_cmd_tdata;
(* mark_debug = "true" *)wire        axis_pcie_bench_write_cmd_tvalid;
 (* mark_debug = "true" *)wire        axis_pcie_bench_write_cmd_tready;
 wire[95:0]  axis_pcie_bench_write_cmd_tdata;

 
wire   axis_bench_write_data_tvalid;
wire   axis_bench_write_data_tready;
wire[511:0]   axis_bench_write_data_tdata;
wire[63:0]  axis_bench_write_data_tkeep;
wire   axis_bench_write_data_tlast;

wire   axis_pcie_bench_write_data_tvalid;
wire   axis_pcie_bench_write_data_tready;
wire[511:0]   axis_pcie_bench_write_data_tdata;
wire[63:0]  axis_pcie_bench_write_data_tkeep;
wire   axis_pcie_bench_write_data_tlast;

wire   axis_bench_read_data_tvalid;
wire   axis_bench_read_data_tready;
wire[511:0]   axis_bench_read_data_tdata;
wire[63:0]  axis_bench_read_data_tkeep;
wire   axis_bench_read_data_tlast;
 
 wire   axis_pcie_bench_read_data_tvalid;
wire   axis_pcie_bench_read_data_tready;
wire[511:0]   axis_pcie_bench_read_data_tdata;
wire[63:0]  axis_pcie_bench_read_data_tkeep;
wire   axis_pcie_bench_read_data_tlast;

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

always @(posedge net_clk) begin
    if (~net_aresetn) begin
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
 .m_axis_read_cmd_TVALID(axis_bench_read_cmd_tvalid),
 .m_axis_read_cmd_TREADY(axis_bench_read_cmd_tready),
 .m_axis_read_cmd_TDATA(axis_bench_read_cmd_tdata),
 .m_axis_write_cmd_TVALID(axis_bench_write_cmd_tvalid),
 .m_axis_write_cmd_TREADY(axis_bench_write_cmd_tready),
 .m_axis_write_cmd_TDATA(axis_bench_write_cmd_tdata),
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
 .aresetn(net_aresetn),
 .aclk(net_clk),
 .regBaseAddr_V({16'h00, dmaBenchBaseAddr}),
 .memorySize_V({16'h00, dmaBenchMemorySize}),
 .numberOfAccesses_V(dmaBenchNumberOfAccesses),
 .chunkLength_V(dmaBenchChunkLength),
 .strideLength_V(dmaBenchStrideLength),
 .isWrite_V(dmaBenchIsWrite),
 .start_V(dmaBenchStart),
 .regExecutionCycles_V(execution_cycles_data),
 .regExecutionCycles_V_ap_vld(execution_cycles_valid)
 );


axis_clock_converter_96 dma_bench_read_cmd_cc_inst (
  .s_axis_aresetn(net_aresetn),
  .s_axis_aclk(net_clk),
  .s_axis_tvalid(axis_bench_read_cmd_tvalid),
  .s_axis_tready(axis_bench_read_cmd_tready),
  .s_axis_tdata(axis_bench_read_cmd_tdata),
  
  .m_axis_aresetn(pcie_aresetn),
  .m_axis_aclk(pcie_clk),
  .m_axis_tvalid(axis_pcie_bench_read_cmd_tvalid),
  .m_axis_tready(axis_pcie_bench_read_cmd_tready),
  .m_axis_tdata(axis_pcie_bench_read_cmd_tdata)
);

axis_clock_converter_96 dma_bench_write_cmd_cc_inst (
  .s_axis_aresetn(net_aresetn),
  .s_axis_aclk(net_clk),
  .s_axis_tvalid(axis_bench_write_cmd_tvalid),
  .s_axis_tready(axis_bench_write_cmd_tready),
  .s_axis_tdata(axis_bench_write_cmd_tdata),
  
  .m_axis_aresetn(pcie_aresetn),
  .m_axis_aclk(pcie_clk),
  .m_axis_tvalid(axis_pcie_bench_write_cmd_tvalid),
  .m_axis_tready(axis_pcie_bench_write_cmd_tready),
  .m_axis_tdata(axis_pcie_bench_write_cmd_tdata)
);

//axis_clock_converter_512 dma_bench_read_data_cc_inst (
axis_data_fifo_512_cc dma_bench_read_data_cc_inst (
  .s_axis_aresetn(pcie_aresetn),
  .s_axis_aclk(pcie_clk),
  .s_axis_tvalid(axis_pcie_bench_read_data_tvalid),
  .s_axis_tready(axis_pcie_bench_read_data_tready),
  .s_axis_tdata(axis_pcie_bench_read_data_tdata),
  .s_axis_tkeep(axis_pcie_bench_read_data_tkeep),
  .s_axis_tlast(axis_pcie_bench_read_data_tlast),

  .m_axis_aresetn(net_aresetn),
  .m_axis_aclk(net_clk),
  .m_axis_tvalid(axis_bench_read_data_tvalid),
  .m_axis_tready(axis_bench_read_data_tready),
  .m_axis_tdata(axis_bench_read_data_tdata),
  .m_axis_tkeep(axis_bench_read_data_tkeep),
  .m_axis_tlast(axis_bench_read_data_tlast)
);

//axis_clock_converter_512 dma_bench_write_data_cc_inst (
axis_data_fifo_512_cc dma_bench_write_data_cc_inst (
  .s_axis_aresetn(net_aresetn),
  .s_axis_aclk(net_clk),
  .s_axis_tvalid(axis_bench_write_data_tvalid),
  .s_axis_tready(axis_bench_write_data_tready),
  .s_axis_tdata(axis_bench_write_data_tdata),
  .s_axis_tkeep(axis_bench_write_data_tkeep),
  .s_axis_tlast(axis_bench_write_data_tlast),
  
  .m_axis_aresetn(pcie_aresetn),
  .m_axis_aclk(pcie_clk),
  .m_axis_tvalid(axis_pcie_bench_write_data_tvalid),
  .m_axis_tready(axis_pcie_bench_write_data_tready),
  .m_axis_tdata(axis_pcie_bench_write_data_tdata),
  .m_axis_tkeep(axis_pcie_bench_write_data_tkeep),
  .m_axis_tlast(axis_pcie_bench_write_data_tlast)
);*/

/*
 * TLB wires
 */

/*wire axis_tlb_interface_valid;
wire axis_tlb_interface_ready;
wire[135:0] axis_tlb_interface_data;*/

/*wire        axis_dma_read_cmd_to_tlb_tvalid; //TODO rename
wire        axis_dma_read_cmd_to_tlb_tready;
wire[95:0]  axis_dma_read_cmd_to_tlb_tdata;
wire        axis_dma_write_cmd_to_tlb_tvalid;
wire        axis_dma_write_cmd_to_tlb_tready;
wire[95:0]  axis_dma_write_cmd_to_tlb_tdata;*/


//PCIe clock
/*wire        axis_dma_write_data_to_width_tvalid;
wire        axis_dma_write_data_to_width_tready;
wire[511:0] axis_dma_write_data_to_width_tdata;
wire[63:0]  axis_dma_write_data_to_width_tkeep;
wire        axis_dma_write_data_to_width_tlast;*/

(* mark_debug = "true" *)wire        axis_dma_write_data_tvalid;
(* mark_debug = "true" *)wire        axis_dma_write_data_tready;
wire[511:0] axis_dma_write_data_tdata;
wire[63:0]  axis_dma_write_data_tkeep;
(* mark_debug = "true" *)wire        axis_dma_write_data_tlast;


//PCIe clock
(* mark_debug = "true" *)wire        axis_dma_read_data_tvalid;
(* mark_debug = "true" *)wire        axis_dma_read_data_tready;
wire[511:0] axis_dma_read_data_tdata;
wire[63:0]  axis_dma_read_data_tkeep;
(* mark_debug = "true" *)wire        axis_dma_read_data_tlast;


//read
/*assign axis_dma_read_cmd_to_tlb_tvalid = axis_pcie_bench_read_cmd_tvalid;
assign axis_pcie_bench_read_cmd_tready = axis_dma_read_cmd_to_tlb_tready;
assign axis_dma_read_cmd_to_tlb_tdata = axis_pcie_bench_read_cmd_tdata;

mem_write_cmd_page_boundary_check_512_ip mem_write_cmd_page_boundary_check_inst (
  .regBaseVaddr_V(regBaseVaddrBoundCheck),          // input wire [63 : 0] regBaseVaddr_V
  .m_axis_cmd_TVALID(axis_dma_write_cmd_to_tlb_tvalid),    // output wire m_axis_cmd_TVALID
  .m_axis_cmd_TREADY(axis_dma_write_cmd_to_tlb_tready),    // input wire m_axis_cmd_TREADY
  .m_axis_cmd_TDATA(axis_dma_write_cmd_to_tlb_tdata),      // output wire [95 : 0] m_axis_cmd_TDATA
  .m_axis_data_TVALID(axis_dma_write_data_tvalid),  // output wire m_axis_data_TVALID
  .m_axis_data_TREADY(axis_dma_write_data_tready),  // input wire m_axis_data_TREADY
  .m_axis_data_TDATA(axis_dma_write_data_tdata),    // output wire [63 : 0] m_axis_data_TDATA
  .m_axis_data_TKEEP(axis_dma_write_data_tkeep),    // output wire [7 : 0] m_axis_data_TKEEP
  .m_axis_data_TLAST(axis_dma_write_data_tlast),    // output wire [0 : 0] m_axis_data_TLAST
  .s_axis_cmd_TVALID(axis_pcie_bench_write_cmd_tvalid),    // input wire s_axis_cmd_TVALID
  .s_axis_cmd_TREADY(axis_pcie_bench_write_cmd_tready),    // output wire s_axis_cmd_TREADY
  .s_axis_cmd_TDATA(axis_pcie_bench_write_cmd_tdata),      // input wire [95 : 0] s_axis_cmd_TDATA
  .s_axis_data_TVALID(axis_pcie_bench_write_data_tvalid),  // input wire s_axis_data_TVALID
  .s_axis_data_TREADY(axis_pcie_bench_write_data_tready),  // output wire s_axis_data_TREADY
  .s_axis_data_TDATA(axis_pcie_bench_write_data_tdata),    // input wire [63 : 0] s_axis_data_TDATA
  .s_axis_data_TKEEP(axis_pcie_bench_write_data_tkeep),    // input wire [7 : 0] s_axis_data_TKEEP
  .s_axis_data_TLAST(axis_pcie_bench_write_data_tlast),    // input wire [0 : 0] s_axis_data_TLAST
  .aclk(pcie_clk),                              // input wire aclk
  .aresetn(pcie_aresetn)                        // input wire aresetn
);

wire axis_dma_read_data_width_to_clk_tvalid;
wire axis_dma_read_data_width_to_clk_tready;
wire[511:0] axis_dma_read_data_width_to_clk_tdata;
wire[63:0] axis_dma_read_data_width_to_clk_tkeep;
wire axis_dma_read_data_width_to_clk_tlast;

axis_256_to_512_converter dma_read_data_width_converter (
  .aclk(pcie_clk),                    // input wire aclk
  .aresetn(pcie_aresetn),              // input wire aresetn
  .s_axis_tvalid(axis_dma_read_data_tvalid),  // input wire s_axis_tvalid
  .s_axis_tready(axis_dma_read_data_tready),  // output wire s_axis_tready
  .s_axis_tdata(axis_dma_read_data_tdata),    // input wire [255 : 0] s_axis_tdata
  .s_axis_tkeep(axis_dma_read_data_tkeep),    // input wire [31 : 0] s_axis_tkeep
  .s_axis_tlast(axis_dma_read_data_tlast),    // input wire s_axis_tlast
  .m_axis_tvalid(axis_dma_read_data_width_to_clk_tvalid),  // output wire m_axis_tvalid
  .m_axis_tready(axis_dma_read_data_width_to_clk_tready),  // input wire m_axis_tready
  .m_axis_tdata(axis_dma_read_data_width_to_clk_tdata),    // output wire [511 : 0] m_axis_tdata
  .m_axis_tkeep(axis_dma_read_data_width_to_clk_tkeep),    // output wire [63 : 0] m_axis_tkeep
  .m_axis_tlast(axis_dma_read_data_width_to_clk_tlast)    // output wire m_axis_tlast
);*/

/*assign axis_dma_write_data_tvalid = axis_pcie_bench_write_data_tvalid;
assign axis_pcie_bench_write_data_tready = axis_dma_write_data_tready;
assign axis_dma_write_data_tdata = axis_pcie_bench_write_data_tdata;
assign axis_dma_write_data_tkeep = axis_pcie_bench_write_data_tkeep;
assign axis_dma_write_data_tlast = axis_pcie_bench_write_data_tlast;

assign axis_pcie_bench_read_data_tvalid = axis_dma_read_data_tvalid;
assign axis_dma_read_data_tready = axis_pcie_bench_read_data_tready;
assign axis_pcie_bench_read_data_tdata = axis_dma_read_data_tdata;
assign axis_pcie_bench_read_data_tkeep = axis_dma_read_data_tkeep;
assign axis_pcie_bench_read_data_tlast = axis_dma_read_data_tlast;*/


wire GND_1;

GND GND(.G(GND_1));
       
       
       IBUFDS_GTE2 #(
            .CLKCM_CFG("TRUE"),   // Refer to Transceiver User Guide
            .CLKRCV_TRST("TRUE"), // Refer to Transceiver User Guide
            .CLKSWING_CFG(2'b11)  // Refer to Transceiver User Guide
         )
         IBUFDS_GTE2_inst (
            .O(pcie_ref_clk),         // 1-bit output: Refer to Transceiver User Guide
            .ODIV2(),            // 1-bit output: Refer to Transceiver User Guide
            .CEB(GND_1),          // 1-bit input: Refer to Transceiver User Guide
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
.user_clk(net_clk),
.user_aresetn(ddr3_calib_complete),
.pcie_clk(pcie_clk), //TODO remove
.pcie_aresetn(pcie_aresetn),
.mem_clk(mem0_clk),
.mem_aresetn(mem0_aresetn),

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
.user_clk(net_clk),
.user_aresetn(ddr3_calib_complete),
.pcie_clk(pcie_clk),
.pcie_aresetn(pcie_aresetn), //TODO remove
.mem_clk(mem1_clk),
.mem_aresetn(mem1_aresetn),


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


mem_driver  mem_driver_inst(
//.clk156_25(net_clk),
//.reset233_n(reset233_n), //active low reset signal for 233MHz clock domain
//.reset156_25_n(ddr3_calib_complete),
//.reset156_25_n(ddr3_calib_complete),
//.clk233(clk233),
//.clk200(clk_ref_200),
.sys_rst(perst_n & pok_dram),

/* I/O INTERFACE */
// differential iodelayctrl clk (reference clock)
.clk_ref_p(clk_ref_p),
.clk_ref_n(clk_ref_n),
//SODIMM 0
// Inouts
.c0_ddr3_dq(c0_ddr3_dq),
.c0_ddr3_dqs_n(c0_ddr3_dqs_n),
.c0_ddr3_dqs_p(c0_ddr3_dqs_p),
// Outputs
.c0_ddr3_addr(c0_ddr3_addr),
.c0_ddr3_ba(c0_ddr3_ba),
.c0_ddr3_ras_n(c0_ddr3_ras_n),
.c0_ddr3_cas_n(c0_ddr3_cas_n),
.c0_ddr3_we_n(c0_ddr3_we_n),
.c0_ddr3_reset_n(c0_ddr3_reset_n),
.c0_ddr3_ck_p(c0_ddr3_ck_p),
.c0_ddr3_ck_n(c0_ddr3_ck_n),
.c0_ddr3_cke(c0_ddr3_cke),
.c0_ddr3_cs_n(c0_ddr3_cs_n),
//.c0_ddr3_dm(c0_ddr3_dm),
.c0_ddr3_odt(c0_ddr3_odt),
//.c0_ui_clk(c0_ui_clk),
.c0_init_calib_complete(c0_init_calib_complete),
  // Differential system clocks
.c0_sys_clk_p(c0_sys_clk_p),
.c0_sys_clk_n(c0_sys_clk_n),

//SODIMM 1
// Inouts
.c1_ddr3_dq(c1_ddr3_dq),
.c1_ddr3_dqs_n(c1_ddr3_dqs_n),
.c1_ddr3_dqs_p(c1_ddr3_dqs_p),
// Outputs
.c1_ddr3_addr(c1_ddr3_addr),
.c1_ddr3_ba(c1_ddr3_ba),
.c1_ddr3_ras_n(c1_ddr3_ras_n),
.c1_ddr3_cas_n(c1_ddr3_cas_n),
.c1_ddr3_we_n(c1_ddr3_we_n),
.c1_ddr3_reset_n(c1_ddr3_reset_n),
.c1_ddr3_ck_p(c1_ddr3_ck_p),
.c1_ddr3_ck_n(c1_ddr3_ck_n),
.c1_ddr3_cke(c1_ddr3_cke),
.c1_ddr3_cs_n(c1_ddr3_cs_n),
//.c1_ddr3_dm(c1_ddr3_dm),
.c1_ddr3_odt(c1_ddr3_odt),
//.c1_ui_clk(c1_ui_clk),
.c1_init_calib_complete(c1_init_calib_complete),
  // Differential system clocks
.c1_sys_clk_p(c1_sys_clk_p),
.c1_sys_clk_n(c1_sys_clk_n),


/* OS INTERFACE */
.mem0_clk(mem0_clk),
.mem0_aresetn(mem0_aresetn),

.s0_axi_awid(c0_s_axi_awid),
.s0_axi_awaddr(c0_s_axi_awaddr),
.s0_axi_awlen(c0_s_axi_awlen),
.s0_axi_awsize(c0_s_axi_awsize),
.s0_axi_awburst(c0_s_axi_awburst),
.s0_axi_awlock(c0_s_axi_awlock),
.s0_axi_awcache(c0_s_axi_awcache),
.s0_axi_awprot(c0_s_axi_awprot),
.s0_axi_awvalid(c0_s_axi_awvalid),
.s0_axi_awready(c0_s_axi_awready),

.s0_axi_wdata(c0_s_axi_wdata),
.s0_axi_wstrb(c0_s_axi_wstrb),
.s0_axi_wlast(c0_s_axi_wlast),
.s0_axi_wvalid(c0_s_axi_wvalid),
.s0_axi_wready(c0_s_axi_wready),

.s0_axi_bready(c0_s_axi_bready),
.s0_axi_bid(c0_s_axi_bid),
.s0_axi_bresp(c0_s_axi_bresp),
.s0_axi_bvalid(c0_s_axi_bvalid),

.s0_axi_arid(c0_s_axi_arid),
.s0_axi_araddr(c0_s_axi_araddr),
.s0_axi_arlen(c0_s_axi_arlen),
.s0_axi_arsize(c0_s_axi_arsize),
.s0_axi_arburst(c0_s_axi_arburst),
.s0_axi_arlock(c0_s_axi_arlock),
.s0_axi_arcache(c0_s_axi_arcache),
.s0_axi_arprot(c0_s_axi_arprot),
.s0_axi_arvalid(c0_s_axi_arvalid),
.s0_axi_arready(c0_s_axi_arready),

.s0_axi_rready(c0_s_axi_rready),
.s0_axi_rid(c0_s_axi_rid),
.s0_axi_rdata(c0_s_axi_rdata),
.s0_axi_rresp(c0_s_axi_rresp),
.s0_axi_rlast(c0_s_axi_rlast),
.s0_axi_rvalid(c0_s_axi_rvalid),

.mem1_clk(mem1_clk),
.mem1_aresetn(mem1_aresetn),

.s1_axi_awid(c1_s_axi_awid),
.s1_axi_awaddr(c1_s_axi_awaddr),
.s1_axi_awlen(c1_s_axi_awlen),
.s1_axi_awsize(c1_s_axi_awsize),
.s1_axi_awburst(c1_s_axi_awburst),
.s1_axi_awlock(c1_s_axi_awlock),
.s1_axi_awcache(c1_s_axi_awcache),
.s1_axi_awprot(c1_s_axi_awprot),
.s1_axi_awvalid(c1_s_axi_awvalid),
.s1_axi_awready(c1_s_axi_awready),

.s1_axi_wdata(c1_s_axi_wdata),
.s1_axi_wstrb(c1_s_axi_wstrb),
.s1_axi_wlast(c1_s_axi_wlast),
.s1_axi_wvalid(c1_s_axi_wvalid),
.s1_axi_wready(c1_s_axi_wready),

.s1_axi_bready(c1_s_axi_bready),
.s1_axi_bid(c1_s_axi_bid),
.s1_axi_bresp(c1_s_axi_bresp),
.s1_axi_bvalid(c1_s_axi_bvalid),

.s1_axi_arid(c1_s_axi_arid),
.s1_axi_araddr(c1_s_axi_araddr),
.s1_axi_arlen(c1_s_axi_arlen),
.s1_axi_arsize(c1_s_axi_arsize),
.s1_axi_arburst(c1_s_axi_arburst),
.s1_axi_arlock(c1_s_axi_arlock),
.s1_axi_arcache(c1_s_axi_arcache),
.s1_axi_arprot(c1_s_axi_arprot),
.s1_axi_arvalid(c1_s_axi_arvalid),
.s1_axi_arready(c1_s_axi_arready),

.s1_axi_rready(c1_s_axi_rready),
.s1_axi_rid(c1_s_axi_rid),
.s1_axi_rdata(c1_s_axi_rdata),
.s1_axi_rresp(c1_s_axi_rresp),
.s1_axi_rlast(c1_s_axi_rlast),
.s1_axi_rvalid(c1_s_axi_rvalid)


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
/*reg[47:0] regBaseVaddr;
reg[47:0] regBaseVaddrBoundCheck;
always @(posedge pcie_clk)
begin 
    if (~pcie_aresetn) begin
    end
    else begin
        if (axis_tlb_interface_valid && axis_tlb_interface_ready && axis_tlb_interface_data[128]) begin
            regBaseVaddr <= axis_tlb_interface_data[63:0];
            regBaseVaddrBoundCheck <= regBaseVaddr;
        end
    end
end*/


/*axis_512_to_256_converter pcie_axis_write_data_512_256 (
  .aclk(pcie_clk),                    // input wire aclk
  .aresetn(pcie_aresetn),              // input wire aresetn
  .s_axis_tvalid(axis_dma_write_data_to_width_tvalid),  // input wire s_axis_tvalid
  .s_axis_tready(axis_dma_write_data_to_width_tready),  // output wire s_axis_tready
  .s_axis_tdata(axis_dma_write_data_to_width_tdata),    // input wire [511 : 0] s_axis_tdata
  .s_axis_tkeep(axis_dma_write_data_to_width_tkeep),    // input wire [63 : 0] s_axis_tkeep
  .s_axis_tlast(axis_dma_write_data_to_width_tlast),    // input wire s_axis_tlast
  .m_axis_tvalid(axis_dma_write_data_tvalid),  // output wire m_axis_tvalid
  .m_axis_tready(axis_dma_write_data_tready),  // input wire m_axis_tready
  .m_axis_tdata(axis_dma_write_data_tdata),    // output wire [255 : 0] m_axis_tdata
  .m_axis_tkeep(axis_dma_write_data_tkeep),    // output wire [31 : 0] m_axis_tkeep
  .m_axis_tlast(axis_dma_write_data_tlast)    // output wire m_axis_tlast
);*/


/*axis_clock_converter_200 axis_dma_bench_cmd_clock_converter_inst (
    .s_axis_aresetn(pcie_aresetn),  // input wire s_axis_aresetn
    .s_axis_aclk(pcie_clk),        // input wire s_axis_aclk
    
    .s_axis_tvalid(axis_pcie_bench_cmd_valid),    // input wire s_axis_tvalid
    .s_axis_tready(axis_pcie_bench_cmd_ready),    // output wire s_axis_tready
    .s_axis_tdata(axis_pcie_bench_cmd_data),      // input wire [143 : 0] s_axis_tdata
    
    .m_axis_aclk(net_clk),        // input wire m_axis_aclk
    .m_axis_aresetn(net_aresetn),  // input wire m_axis_aresetn
      
    .m_axis_tvalid(axis_bench_cmd_valid),    // output wire m_axis_tvalid
    .m_axis_tready(axis_bench_cmd_ready),    // input wire m_axis_tready
    .m_axis_tdata(axis_bench_cmd_data)      // output wire [143 : 0] m_axis_tdata
  );*/
 
/*axis_clock_converter_64 axis_dma_bench_cycles_clock_converter_inst (
    .s_axis_aresetn(net_aresetn),  // input wire s_axis_aresetn
    .s_axis_aclk(net_clk),        // input wire s_axis_aclk
    
    .s_axis_tvalid(1'b1),    // input wire s_axis_tvalid
    .s_axis_tready(),    // output wire s_axis_tready
    .s_axis_tdata(dma_bench_execution_cycles),      // input wire [143 : 0] s_axis_tdata
    
    .m_axis_aclk(pcie_clk),        // input wire m_axis_aclk
    .m_axis_aresetn(pcie_aresetn),  // input wire m_axis_aresetn
      
    .m_axis_tvalid(),    // output wire m_axis_tvalid
    .m_axis_tready(1'b1),    // input wire m_axis_tready
    .m_axis_tdata(pcie_dma_bench_execution_cycles)      // output wire [143 : 0] m_axis_tdata
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


//address write
/*(* mark_debug = "true" *)wire [31: 0] pcie_axil_awaddr;
(* mark_debug = "true" *)wire  pcie_axil_awvalid;
wire pcie_axil_awready;
 
//data write
wire [31: 0]   pcie_axil_wdata;
wire [3: 0] pcie_axil_wstrb;
(* mark_debug = "true" *)wire pcie_axil_wvalid;
(* mark_debug = "true" *)wire pcie_axil_wready;
 
//write response (handhake)
wire [1:0] pcie_axil_bresp;
wire pcie_axil_bvalid;
wire pcie_axil_bready;
 
//address read
(* mark_debug = "true" *)wire [31: 0] pcie_axil_araddr;
(* mark_debug = "true" *)wire pcie_axil_arvalid;
(* mark_debug = "true" *)wire pcie_axil_arready;
 
//data read
wire [31: 0] pcie_axil_rdata;
wire [1:0] pcie_axil_rresp;
(* mark_debug = "true" *)wire pcie_axil_rvalid;
(* mark_debug = "true" *)wire pcie_axil_rready;*/

reg led_light;
assign led[5] = pcie_aresetn; //led_light;

always @(posedge pcie_clk)
begin 
    if (~pcie_aresetn) begin
        led_light <= 1'b0;
    end
    else begin
        /*if (pcie_axil_wvalid) begin
            led_light <= ~led_light;
        end*/
    end
end


/*
 * DMA Interface
 */
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


/*    .m0_axil_awaddr(user_axil_awaddr),              // output wire [31 : 0] m_axil_awaddr
    .m0_axil_awprot(),              // output wire [2 : 0] m_axil_awprot
    .m0_axil_awvalid(user_axil_awvalid),            // output wire m_axil_awvalid
    .m0_axil_awready(user_axil_awready),            // input wire m_axil_awready
    .m0_axil_wdata(user_axil_wdata),                // output wire [31 : 0] m_axil_wdata
    .m0_axil_wstrb(user_axil_wstrb),                // output wire [3 : 0] m_axil_wstrb
    .m0_axil_wvalid(user_axil_wvalid),              // output wire m_axil_wvalid
    .m0_axil_wready(user_axil_wready),              // input wire m_axil_wready
    .m0_axil_bvalid(user_axil_bvalid),              // input wire m_axil_bvalid
    .m0_axil_bresp(user_axil_bresp),                // input wire [1 : 0] m_axil_bresp
    .m0_axil_bready(user_axil_bready),              // output wire m_axil_bready
    .m0_axil_araddr(user_axil_araddr),              // output wire [31 : 0] m_axil_araddr
    .m0_axil_arprot(),              // output wire [2 : 0] m_axil_arprot
    .m0_axil_arvalid(user_axil_arvalid),            // output wire m_axil_arvalid
    .m0_axil_arready(user_axil_arready),            // input wire m_axil_arready
    .m0_axil_rdata(user_axil_rdata),                // input wire [31 : 0] m_axil_rdata
    .m0_axil_rresp(user_axil_rresp),                // input wire [1 : 0] m_axil_rresp
    .m0_axil_rvalid(user_axil_rvalid),              // input wire m_axil_rvalid
    .m0_axil_rready(user_axil_rready),              // output wire m_axil_rready


    .m1_axil_awaddr(pcie_axil_awaddr),              // output wire [31 : 0] m_axil_awaddr
    .m1_axil_awprot(),              // output wire [2 : 0] m_axil_awprot
    .m1_axil_awvalid(pcie_axil_awvalid),            // output wire m_axil_awvalid
    .m1_axil_awready(pcie_axil_awready),            // input wire m_axil_awready
    .m1_axil_wdata(pcie_axil_wdata),                // output wire [31 : 0] m_axil_wdata
    .m1_axil_wstrb(pcie_axil_wstrb),                // output wire [3 : 0] m_axil_wstrb
    .m1_axil_wvalid(pcie_axil_wvalid),              // output wire m_axil_wvalid
    .m1_axil_wready(pcie_axil_wready),              // input wire m_axil_wready
    .m1_axil_bvalid(pcie_axil_bvalid),              // input wire m_axil_bvalid
    .m1_axil_bresp(pcie_axil_bresp),                // input wire [1 : 0] m_axil_bresp
    .m1_axil_bready(pcie_axil_bready),              // output wire m_axil_bready
    .m1_axil_araddr(pcie_axil_araddr),              // output wire [31 : 0] m_axil_araddr
    .m1_axil_arprot(),              // output wire [2 : 0] m_axil_arprot
    .m1_axil_arvalid(pcie_axil_arvalid),            // output wire m_axil_arvalid
    .m1_axil_arready(pcie_axil_arready),            // input wire m_axil_arready
    .m1_axil_rdata(pcie_axil_rdata),                // input wire [31 : 0] m_axil_rdata
    .m1_axil_rresp(pcie_axil_rresp),                // input wire [1 : 0] m_axil_rresp
    .m1_axil_rvalid(pcie_axil_rvalid),              // input wire m_axil_rvalid
    .m1_axil_rready(pcie_axil_rready)              // output wire m_axil_rready*/

);

/*example_controller controller_inst(
    .aclk(pcie_clk),
    .aresetn(pcie_aresetn),
    .net_aclk(net_clk),
    .net_aresetn(net_aresetn),
    
     // AXI Lite Master Interface connections
    .s_axil_awaddr  (pcie_axil_awaddr[31:0]),
    .s_axil_awvalid (pcie_axil_awvalid),
    .s_axil_awready (pcie_axil_awready),
    .s_axil_wdata   (pcie_axil_wdata[31:0]),    // block fifo for AXI lite only 31 bits.
    .s_axil_wstrb   (pcie_axil_wstrb[3:0]),
    .s_axil_wvalid  (pcie_axil_wvalid),
    .s_axil_wready  (pcie_axil_wready),
    .s_axil_bresp   (pcie_axil_bresp),
    .s_axil_bvalid  (pcie_axil_bvalid),
    .s_axil_bready  (pcie_axil_bready),
    .s_axil_araddr  (pcie_axil_araddr[31:0]),
    .s_axil_arvalid (pcie_axil_arvalid),
    .s_axil_arready (pcie_axil_arready),
    .s_axil_rdata   (pcie_axil_rdata),   // block ram for AXI Lite is only 31 bits
    .s_axil_rresp   (pcie_axil_rresp),
    .s_axil_rvalid  (pcie_axil_rvalid),
    .s_axil_rready  (pcie_axil_rready),
    
    // Control streams
    .m_axis_tlb_interface_valid        (axis_tlb_interface_valid),
    .m_axis_tlb_interface_ready        (axis_tlb_interface_ready),
    .m_axis_tlb_interface_data         (axis_tlb_interface_data),
    .m_axis_dma_bench_cmd_valid        (axis_pcie_bench_cmd_valid),
    .m_axis_dma_bench_cmd_ready        (axis_pcie_bench_cmd_ready),
    .m_axis_dma_bench_cmd_data         (axis_pcie_bench_cmd_data),
    
    //Host ARP lookup
    .m_axis_host_arp_lookup_request_TVALID(axis_pcie_host_arp_lookup_request_TVALID),
    .m_axis_host_arp_lookup_request_TREADY(axis_pcie_host_arp_lookup_request_TREADY),
    .m_axis_host_arp_lookup_request_TDATA(axis_pcie_host_arp_lookup_request_TDATA),
    .s_axis_host_arp_lookup_reply_TVALID(axis_pcie_host_arp_lookup_reply_TVALID),
    .s_axis_host_arp_lookup_reply_TREADY(axis_pcie_host_arp_lookup_reply_TREADY),
    .s_axis_host_arp_lookup_reply_TDATA(axis_pcie_host_arp_lookup_reply_TDATA),
    
    //Debug input
    //axi clock
    //general
    //.roce_crc_pkg_drop_count           (regCrcDropPkgCount),
    //.roce_psn_pkg_drop_count           (regInvalidPsnDropCount),
    //rxpart
    //mem cmd
    .roce_write_cmd_counter            (roce_write_cmd_counter),
    .roce_read_cmd_counter             (roce_read_cmd_counter),
    .rxpart_write_cmd_counter          (rxpart_write_cmd_counter),
    .txpart_write_cmd_counter          (txpart_write_cmd_counter),
    .txpart_read_cmd_counter           (txpart_read_cmd_counter),
    //roce
    .roce_rx_tuple_counter              (roce_rx_tuple_counter),
    .roce_tx_dma_tuple_counter          (roce_tx_dma_tuple_counter),
    .roce_tx_local_tuple_counter        (roce_tx_local_tuple_counter),
    .axis_stream_down                   (axis_stream_down),

    //tlb
    .tlb_miss_counter                   (tlb_miss_counter),
    .tlb_boundary_crossing_counter      (tlb_boundary_crossing_counter),
    //same clock
    .dma_write_cmd_counter              (dma_write_cmd_counter),
    .dma_write_word_counter             (dma_write_word_counter),
    .dma_write_pkg_counter              (dma_write_pkg_counter),
    .dma_read_cmd_counter               (dma_read_cmd_counter),
    .dma_read_word_counter              (dma_read_word_counter),
    .dma_read_pkg_counter               (dma_read_pkg_counter),
    //dma bench
    .dma_bench_execution_cycles        (pcie_dma_bench_execution_cycles),


    //length counters
    .reset_dma_write_length_counter      (reset_dma_write_length_counter),
    .dma_write_length_counter            (dma_write_length_counter),
    .reset_dma_read_length_counter      (reset_dma_read_length_counter),
    .dma_read_length_counter            (dma_read_length_counter),
    .dma_reads_flushed                  (dma_reads_flushed),
    
    .set_ip_addr_valid(set_ip_addr_valid),
    .set_ip_addr_data(set_ip_addr_data),
    .set_board_number_valid(set_board_number_valid),
    .set_board_number_data(set_board_number_data)
);*/

/*
 * DEBUG counters on pcie clk
 */
/*reg[31:0] dma_write_cmd_counter;
reg[31:0] dma_write_load_counter;
reg[31:0] dma_write_word_counter;
reg[31:0] dma_write_pkg_counter;
wire reset_dma_write_length_counter;
reg[47:0] dma_write_length_counter;

 reg[31:0] dma_read_cmd_counter;
reg[31:0] dma_read_load_counter;
 reg[31:0] dma_read_word_counter;
 reg[31:0] dma_read_pkg_counter;
wire reset_dma_read_length_counter;
reg[47:0] dma_read_length_counter;
reg dma_reads_flushed;
reg invalid_read;

reg[7:0] write_bypass_ready_counter;
reg[31:0] dma_write_back_pressure_counter;


always @(posedge pcie_clk)
begin 
    if (~pcie_aresetn) begin
        dma_write_cmd_counter <= 0;
        dma_write_load_counter <= 0;
        dma_write_word_counter <= 0;
        dma_write_pkg_counter <= 0;
        dma_read_cmd_counter <= 0;
        dma_read_word_counter <= 0;
        dma_read_pkg_counter <= 0;
        write_bypass_ready_counter <= 0;
        dma_write_length_counter <= 0;
        dma_read_length_counter <= 0;
        dma_write_back_pressure_counter <= 0;
        dma_reads_flushed <= 0;
        invalid_read <= 0;
    end
    else begin
        dma_reads_flushed <= (dma_read_cmd_counter == dma_read_pkg_counter);
        //write
        if (axis_dma_write_cmd_tvalid && axis_dma_write_cmd_tready) begin
            dma_write_cmd_counter <= dma_write_cmd_counter + 1;
            dma_write_length_counter <= dma_write_length_counter + axis_dma_write_cmd_tdata[95:64];
        end
        if (reset_dma_write_length_counter) begin
            dma_write_length_counter <= 0;
        end
        if (axis_dma_write_dsc_byp_load) begin
            dma_write_load_counter <= dma_write_load_counter + 1;
        end
        if (axis_dma_write_data_tvalid && axis_dma_write_data_tready) begin
            dma_write_word_counter <= dma_write_word_counter + 1;
            if (axis_dma_write_data_tlast) begin
                dma_write_pkg_counter <= dma_write_pkg_counter + 1;
            end
        end
        //read
        if (axis_dma_read_cmd_tvalid && axis_dma_read_cmd_tready) begin
            dma_read_cmd_counter <= dma_read_cmd_counter + 1;
            dma_read_length_counter <= dma_read_length_counter + axis_dma_read_cmd_tdata[95:64];
            if (axis_dma_read_cmd_tdata[95:64] == 0) begin
                invalid_read <=  1;
            end
        end
        if (reset_dma_read_length_counter) begin
            dma_read_length_counter <= 0;
        end
        if (axis_dma_read_dsc_byp_load) begin
            dma_read_load_counter <= dma_read_load_counter + 1;
        end
        if (axis_dma_read_data_tvalid && axis_dma_read_data_tready) begin
            dma_read_word_counter <= dma_read_word_counter + 1;
            if (axis_dma_read_data_tlast) begin
                dma_read_pkg_counter <= dma_read_pkg_counter + 1;
            end
        end
        if (axis_dma_write_cmd_tvalid && ~axis_dma_write_cmd_tready) begin
            dma_write_back_pressure_counter <= dma_write_back_pressure_counter + 1;
        end
        
        if (axis_dma_write_dsc_byp_ready) begin
            write_bypass_ready_counter <= 0;
        end
        else begin
            write_bypass_ready_counter <= write_bypass_ready_counter + 1;
        end
    end
end*/



//performance counter
wire roce_received;
wire roce_clear;
`ifdef PERF_COUNTER
reg ping_on;
reg pong_on;
reg read_ping_on;
reg writecmd_on;
reg dmaread_on;
reg[11:0] perf_write_cmd_counter;
reg[15:0] perf_ping_counter;
reg[11:0] perf_pong_counter;
reg[11:0] perf_dmaread_counter;
reg[15:0] perf_read_ping_counter;
always @(posedge pcie_clk)
begin 
    if (~pcie_aresetn) begin
	ping_on <= 0;
	pong_on <= 0;
	read_ping_on <= 0;
	dmaread_on <= 0;
    writecmd_on <= 0;
    perf_write_cmd_counter <= 0;
	perf_ping_counter <= 0;
	perf_pong_counter <= 0;
	perf_dmaread_counter <= 0;
	perf_read_ping_counter <= 0;
    end
    else begin
        if (axis_pcie_tx_metadata_TVALID && axis_pcie_tx_metadata_TREADY) begin
            if (axis_pcie_tx_metadata_TDATA[1:0] == 0) begin
                read_ping_on <= 1;
            end
            else begin
                writecmd_on <= 1;
                if (dma_write_cmd_counter == 0) begin
                            ping_on <= 1;
                end
                else begin
                    pong_on <= 0;
                end
            end
        end
        if (axis_dma_write_data_tvalid && axis_dma_write_data_tready && axis_dma_write_data_tlast) begin
            ping_on <= 0;
            read_ping_on <= 0;
            if (writecmd_on == 0) begin
                pong_on <= 1;    
            end
        end
        if (axis_dma_read_dsc_byp_load && axis_dma_read_dsc_byp_ready) begin
            writecmd_on <= 0;
            dmaread_on <= 1;
        end
        if (axis_dma_read_data_tvalid && axis_dma_read_data_tready) begin
            dmaread_on <= 0;
        end
        if (writecmd_on) begin
           perf_write_cmd_counter <= perf_write_cmd_counter + 1;
        end
        if (ping_on) begin
           perf_ping_counter <= perf_ping_counter + 1;
        end
        if (pong_on) begin
           perf_pong_counter <= perf_pong_counter + 1;
        end
        if (dmaread_on) begin
    		perf_dmaread_counter <= perf_dmaread_counter + 1;
        end
        if (read_ping_on) begin
            perf_read_ping_counter <= perf_read_ping_counter + 1;
        end
    end
end

//performance counters network path
reg[11:0] txwrite_counter;
reg[11:0] txread_counter;
reg[11:0] rx_counter;
reg[11:0] rxwrite_counter;
reg[11:0] rxread_counter;
reg txwrite_on;
reg txread_on;
reg rx_on;
always @(posedge net_clk)
begin 
    if (~aresetn_counter) begin
        txwrite_on <= 0;
        txread_on <= 0;
        rx_on <= 0;
        txwrite_counter <= 0;
        txread_counter <= 0;
        rx_counter <= 0;
        rxwrite_counter <= 0;
        rxread_counter <= 0;
    end
    else begin
        //txwrite
        if (axis_dma_data_clk_to_split_tvalid && axis_dma_data_clk_to_split_tready) begin
            txwrite_on <= 1;
        end
        if (axis_tx_metadata_TVALID & axis_tx_metadata_TREADY && axis_tx_metadata_TDATA[1:0] == 0) begin
            txread_on <= 1;
        end
        if (AXI_M_Stream_TVALID & AXI_M_Stream_TREADY & AXI_M_Stream_TLAST) begin
            txwrite_on <= 0;
            txread_on <= 0;
        end
        //rx
        if (roce_received) begin
            rx_on <= 1;
            //rx_counter <= 0;
        end
        if (rx_on) begin
            rx_counter <= rx_counter + 1;
        end
        if (axis_merge_to_clk_tvalid && axis_merge_to_clk_tready && axis_merge_to_clk_tlast) begin
            rx_on <= 0;
            rxwrite_counter <= rx_counter;
            rx_counter <= 0;
        end
        if (axis_roce_read_cmd_TVALID && axis_roce_read_cmd_TREADY) begin
            rx_on <= 0;
            if (rx_on) begin
                    rxread_counter <= rx_counter;
                    rx_counter <= 0;
            end
        end
        if (roce_clear) begin
            rx_on <= 0;
            rx_counter <= 0;
        end
        //counters
        if (txwrite_on) begin
            txwrite_counter <= txwrite_counter + 1;
        end
        if (txread_on) begin
            txread_counter <= txread_counter + 1;
        end
    end
end
`endif

/*
 * DEBUG counters on axi clk
 */

/*reg[15:0] rxpart_cmd_counter;
reg[15:0] rxpart_mapping_counter;
reg[31:0] rxpart_input_tuple_counter;
//reg[31:0] rxpart_input_pkg_counter;
reg[31:0] rxpart_output_tuple_counter;
reg[31:0] rxpart_output_pkg_counter;

reg[15:0]  txpart_cmd_counter;
reg[15:0] txpart_mapping_counter;
reg[31:0] txpart_input_tuple_counter;
//reg[31:0] txpart_input_pkg_counter;

reg[31:0] txpart_output_tuple_counter;
reg[31:0] txpart_output_pkg_counter;
reg[31:0] txpart_local_output_tuple_counter;
reg[31:0] txpart_local_output_pkg_counter;

reg[31:0] roce_write_cmd_counter;
reg[31:0] roce_read_cmd_counter;
reg[31:0] rxpart_write_cmd_counter;
reg[31:0] txpart_write_cmd_counter;
reg[31:0] txpart_read_cmd_counter;

reg[31:0] roce_rx_tuple_counter;
reg[31:0] roce_tx_dma_tuple_counter;
reg[31:0] roce_tx_local_tuple_counter;

reg[7:0]  axis_stream_down_counter;
reg axis_stream_down;
reg[7:0]  output_stream_down_counter;
reg output_stream_down;

 //debug
 reg aresetn_counter;
always @(posedge net_clk)
begin
    aresetn_counter <= net_aresetn;
    if (~aresetn_counter) begin
        rxpart_cmd_counter <= 0;
        rxpart_mapping_counter <= 0;
        rxpart_input_tuple_counter <= 0;
        //rxpart_input_pkg_counter <= 0;
        rxpart_output_tuple_counter <= 0;
        rxpart_output_pkg_counter <= 0;
         
        txpart_cmd_counter <= 0;
        txpart_mapping_counter <= 0;
        txpart_input_tuple_counter <= 0;
        //txpart_input_pkg_counter <= 0;
        txpart_output_tuple_counter <= 0;
        txpart_output_pkg_counter <= 0;
        txpart_local_output_tuple_counter <= 0;
        txpart_local_output_pkg_counter <= 0;

        roce_write_cmd_counter <= 0;
        roce_read_cmd_counter <= 0;
        rxpart_write_cmd_counter <= 0;
        txpart_write_cmd_counter <= 0;
        txpart_read_cmd_counter <= 0;

        roce_rx_tuple_counter <= 0;
        roce_tx_dma_tuple_counter <= 0;
        roce_tx_local_tuple_counter <= 0;

        axis_stream_down_counter <= 0;
        axis_stream_down <= 0;
    end
    else begin
        //rxpart
        if (axis_rxpart_cmd_valid && axis_rxpart_cmd_ready) begin
            rxpart_cmd_counter <= rxpart_cmd_counter + 1;
        end
        if (axis_rxpart_mapping_valid && axis_rxpart_mapping_ready) begin
            rxpart_mapping_counter <= rxpart_mapping_counter + 1;
        end
`ifdef LOCAL_PARTITIONING_OFFLOADED
        if (axis_merge_to_rxpart_tvalid && axis_merge_to_rxpart_tready) begin
            if (axis_merge_to_rxpart_tkeep[15]) begin
                rxpart_input_tuple_counter <= rxpart_input_tuple_counter + 2;
            end
            else begin
                rxpart_input_tuple_counter <= rxpart_input_tuple_counter + 1;
            end
        end
        if (axis_rxpart_to_bound_check_data_tvalid && axis_rxpart_to_bound_check_data_tready) begin
            if (axis_rxpart_to_bound_check_data_tkeep[63]) begin
                rxpart_output_tuple_counter <= rxpart_output_tuple_counter + 8;
            end
            else if(axis_rxpart_to_bound_check_data_tkeep[55]) begin
                rxpart_output_tuple_counter <= rxpart_output_tuple_counter + 7;
            end
            else if (axis_rxpart_to_bound_check_data_tkeep[47]) begin
                rxpart_output_tuple_counter <= rxpart_output_tuple_counter + 6;
            end
            else if (axis_rxpart_to_bound_check_data_tkeep[39]) begin
                rxpart_output_tuple_counter <= rxpart_output_tuple_counter + 5;
            end
            else if (axis_rxpart_to_bound_check_data_tkeep[31]) begin
                rxpart_output_tuple_counter <= rxpart_output_tuple_counter + 4;
            end
            else if (axis_rxpart_to_bound_check_data_tkeep[23]) begin
                rxpart_output_tuple_counter <= rxpart_output_tuple_counter + 3;
            end
            else if (axis_rxpart_to_bound_check_data_tkeep[15]) begin
                rxpart_output_tuple_counter <= rxpart_output_tuple_counter + 2;
            end
            else begin
                rxpart_output_tuple_counter <= rxpart_output_tuple_counter + 1;
            end
            if (axis_rxpart_to_bound_check_data_tlast) begin
               rxpart_output_pkg_counter <= rxpart_output_pkg_counter + 1;
            end
        end
`endif
        //txpart
        if (axis_txpart_cmd_valid && axis_txpart_cmd_ready) begin
            txpart_cmd_counter <= txpart_cmd_counter + 1;
        end
        if (axis_txpart_mapping_valid && axis_txpart_mapping_ready) begin
            txpart_mapping_counter <= txpart_mapping_counter + 1;
        end
        if (axis_dma_data_split_to_txpart_tvalid && axis_dma_data_split_to_txpart_tready) begin
            if (axis_dma_data_split_to_txpart_tkeep[31]) begin
                txpart_input_tuple_counter <= txpart_input_tuple_counter + 2;
            end
            else begin
                txpart_input_tuple_counter <= txpart_input_tuple_counter + 1;
            end
        end
        if (axis_txpart_data_tvalid && axis_txpart_data_tready) begin
           txpart_output_tuple_counter <= txpart_output_tuple_counter + 1;
           if (axis_txpart_data_tlast) begin
               txpart_output_pkg_counter <= txpart_output_pkg_counter + 1;
           end
        end
        if (axis_txpart_local_tvalid && axis_txpart_local_tready) begin
           if (axis_txpart_local_tkeep[15]) begin
                txpart_local_output_tuple_counter <= txpart_local_output_tuple_counter + 2;
           end
           else begin
                txpart_local_output_tuple_counter <= txpart_local_output_tuple_counter + 1;
           end
           if (axis_txpart_local_tlast) begin
               txpart_local_output_pkg_counter <= txpart_local_output_pkg_counter + 1;
           end
        end

        //memory cmd 
        if (axis_roce_write_cmd_TVALID && axis_roce_write_cmd_TREADY) begin
            roce_write_cmd_counter <= roce_write_cmd_counter + 1;
        end
        if (axis_roce_read_cmd_TVALID && axis_roce_read_cmd_TREADY) begin
            roce_read_cmd_counter <= roce_read_cmd_counter + 1;
        end
        if (axis_rxpart_write_cmd_TVALID && axis_rxpart_write_cmd_TREADY) begin
            rxpart_write_cmd_counter <= rxpart_write_cmd_counter + 1;
        end
        if (axis_txpart_write_cmd_TVALID && axis_txpart_write_cmd_TREADY) begin
            txpart_write_cmd_counter <= txpart_write_cmd_counter + 1;
        end
        if (axis_txpart_read_cmd_TVALID && axis_txpart_read_cmd_TREADY) begin
            txpart_read_cmd_counter <= txpart_read_cmd_counter + 1;
        end

        if (AXI_S_Stream_TREADY) begin
            axis_stream_down_counter <= 0;
        end
        if (AXI_S_Stream_TVALID && ~AXI_S_Stream_TREADY) begin
            axis_stream_down_counter <= axis_stream_down_counter + 1;
        end
        if (axis_stream_down_counter > 2) begin
            axis_stream_down <= 1;
        end
        if (axis_rxread_data_TREADY) begin
            output_stream_down_counter <= 0;
        end
        if (axis_rxread_data_TVALID && ~axis_rxread_data_TREADY) begin
            output_stream_down_counter <= output_stream_down_counter + 1;
        end
        if (output_stream_down_counter > 2) begin
            output_stream_down <= 1;
        end
        
        //roce rx & tx
        if (axis_rxwrite_data_TVALID && axis_rxwrite_data_TREADY) begin
            roce_rx_tuple_counter <= roce_rx_tuple_counter + 1;
        end
        if (axis_rxread_data_TVALID && axis_rxread_data_TREADY) begin
            roce_tx_dma_tuple_counter <= roce_tx_dma_tuple_counter + 1;
        end
        if (axis_tx_data_tvalid && axis_tx_data_tready) begin
            roce_tx_local_tuple_counter <= roce_tx_local_tuple_counter + 1;
        end
    end
end*/


/*
 * DEBUG for TLB
 */

/*reg[15:0] tlb_read_input;
reg[15:0] tlb_write_input;
reg[15:0] tlb_read_output;
reg[15:0] tlb_write_output;

always @(posedge net_clk)
begin 
    if (~aresetn) begin
        tlb_read_input <= 0;
        tlb_write_input <= 0;
        tlb_read_output <= 0;
        tlb_write_output <= 0;
    end
    else begin
        if (axis_dma_read_cmd_tvalid && axis_dma_read_cmd_tready) begin
            tlb_read_input <= tlb_read_input  + 1;
        end
        if (axis_dma_write_cmd_tvalid && axis_dma_write_cmd_tready) begin
            tlb_write_input <= tlb_write_input + 1;
        end
        if (axis_dma_read_cmd_to_clk_tvalid && axis_dma_read_cmd_to_clk_tready) begin
            tlb_read_output <= tlb_read_output + 1;
        end
        if (axis_dma_write_cmd_to_clk_tvalid && axis_dma_write_cmd_to_clk_tready) begin
            tlb_write_output <= tlb_write_output + 1;
        end
    end
end*/



 `ifdef USE_DDR //and USE_DDR

reg[17:0] rxwritebuf_cmd_counter;
reg[17:0] rxwritebuf_word_counter;
reg[17:0] rxwritebuf_sts_counter;
reg[7:0] rxreadbuf_cmd_counter;
reg[23:0] rxreadbuf_read_length_counter;
reg[23:0] rxreadbuf_write_length_counter;
reg[15:0] rxreadbuf_word_counter;
reg[15:0] rxreadbuf_pkg_counter;

reg[7:0] txreadbuf_cmd_counter;

always @(posedge net_clk)
begin
    if (~net_aresetn) begin
        rxwritebuf_cmd_counter <= 0;
        rxwritebuf_word_counter <= 0;
        rxwritebuf_sts_counter <= 0;
        rxreadbuf_cmd_counter <= 0;
        rxreadbuf_read_length_counter <= 0;
        rxreadbuf_write_length_counter <= 0;
        rxreadbuf_word_counter <= 0;
        rxreadbuf_pkg_counter <= 0;
        
        txreadbuf_cmd_counter <= 0;
        
    end
    else begin
        /*if (axis_rxpart_writebuf_cmd_tvalid && axis_rxpart_writebuf_cmd_tready)  begin
            rxwritebuf_cmd_counter <= rxwritebuf_cmd_counter + 1;
            rxreadbuf_write_length_counter <= rxreadbuf_write_length_counter + axis_rxpart_writebuf_cmd_tdata[15:0];
        end
        if (axis_rxpart_writebuf_data_tvalid && axis_rxpart_writebuf_data_tready) begin
            rxwritebuf_word_counter <= rxwritebuf_word_counter + 1;
        end
        if (axis_rxpart_writebuf_status_tvalid && axis_rxpart_writebuf_status_tready) begin
            rxwritebuf_sts_counter <= rxwritebuf_sts_counter + 1;
        end
        if (axis_rxpart_readbuf_cmd_tvalid && axis_rxpart_readbuf_cmd_tready) begin
            read_started <= 1;
            rxreadbuf_cmd_counter <= rxreadbuf_cmd_counter + 1;
            rxreadbuf_read_length_counter <= rxreadbuf_read_length_counter + axis_rxpart_readbuf_cmd_tdata[15:0];
       end
       if (axis_rxpart_readbuf_data_tvalid && axis_rxpart_readbuf_data_tready) begin
        if (axis_rxpart_readbuf_data_tkeep[31]) begin
            rxreadbuf_word_counter <= rxreadbuf_word_counter + 4;
        end
        else if (axis_rxpart_readbuf_data_tkeep[23]) begin
            rxreadbuf_word_counter <= rxreadbuf_word_counter + 3;
        end
        else if (axis_rxpart_readbuf_data_tkeep[15]) begin
            rxreadbuf_word_counter <= rxreadbuf_word_counter + 2;
        end
        else begin
            rxreadbuf_word_counter <= rxreadbuf_word_counter + 1;
        end
        
        if (axis_rxpart_readbuf_data_tlast) begin
            rxreadbuf_pkg_counter <= rxreadbuf_pkg_counter + 1;
        end
            //CHECK integrity
            //partitionIdValid <= 1'b1;
            //currPartitionId <= ((axis_rxpart_readbuf_data_tdata[63:0] & ((16-1) << (1+31))) >> 32);
       end
       if (axis_txpart_readbuf_cmd_tvalid && axis_txpart_readbuf_cmd_tready) begin
        txreadbuf_cmd_counter <= txreadbuf_cmd_counter + 1;
       end*/
    end
end


`endif

reg[7:0] bench_write_cmd_counter;
reg[15:0] bench_write_data_word_counter;
reg[7:0] bench_write_data_pkg_counter;
reg[15:0] bench_read_cmd_counter;
reg[15:0] bench_read_data_word_counter;
reg[7:0] bench_read_data_pkg_counter;

/* DEBUG boundary_check */
/*always @(posedge net_clk)
begin
    if (~net_aresetn) begin
        bench_write_cmd_counter <= 0;
        bench_write_data_word_counter <= 0;
        bench_write_data_pkg_counter <= 0;
        bench_read_cmd_counter <= 0;
        bench_read_data_word_counter <= 0;
        bench_read_data_pkg_counter <= 0;
    end
    else begin
        if (axis_bench_write_cmd_tvalid && axis_bench_write_cmd_tready) begin
            bench_write_cmd_counter <= bench_write_cmd_counter + 1;
        end
        if (axis_bench_write_data_tvalid && axis_bench_write_data_tready) begin
            bench_write_data_word_counter <= bench_write_data_word_counter + 1;
            if (axis_bench_write_data_tlast) begin
                bench_write_data_pkg_counter <= bench_write_data_pkg_counter + 1;
            end
        end
        if (axis_bench_read_cmd_tvalid && axis_bench_read_cmd_tready) begin
            bench_read_cmd_counter <= bench_read_cmd_counter + 1;
        end
        if (axis_bench_read_data_tvalid && axis_bench_read_data_tready) begin
            bench_read_data_word_counter <= bench_read_data_word_counter + 1;
            if (axis_bench_read_data_tlast) begin
                bench_read_data_pkg_counter <= bench_read_data_pkg_counter + 1;
            end
        end
    end
 end*/


endmodule

`default_nettype wire
