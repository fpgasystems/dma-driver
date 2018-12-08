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

`include "os_types.svh"

module os #(
    parameter AXI_ID_WIDTH = 1,
    parameter NUM_DDR_CHANNELS = 2, //TODO move
    parameter ENABLE_DDR = 1
) (
    input wire      pcie_clk,
    input wire      pcie_aresetn,
    input wire[NUM_DDR_CHANNELS-1:0]    mem_clk,
    input wire[NUM_DDR_CHANNELS-1:0]    mem_aresetn,
    input wire      net_clk,
    input wire      net_aresetn,
    output logic    user_clk,
    output logic    user_aresetn,

    //Axi Lite Control Interface
    axi_lite.slave      s_axil_control,
    
    //DDR
    input wire          ddr_calib_complete,
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

    /* DMA */
    // AXI Stream Interface
    axi_stream.master       m_axis_dma_c2h,
    axi_stream.slave    s_axis_dma_h2c,

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

    //Network



);

// Axi Lite Control Signals
localparam NUM_AXIL_MODULES = 4;
localparam AxilPortUserRole = 0; //TODO enum
localparam AxilPortDMA = 1;
localparam AxilPortDDR0 = 2;
localparam AxilPortDDR1 = 3;

axi_lite        axil_to_modules[NUM_AXIL_MODULES]();

// Memory Signals
(* mark_debug = "true" *)axis_mem_cmd    axis_mem_read_cmd[NUM_DDR_CHANNELS]();
 (* mark_debug = "true" *)axi_stream      axis_mem_read_data[NUM_DDR_CHANNELS]();
 (* mark_debug = "true" *)axis_mem_status axis_mem_read_status[NUM_DDR_CHANNELS](); 

 (* mark_debug = "true" *)axis_mem_cmd    axis_mem_write_cmd[NUM_DDR_CHANNELS]();
 (* mark_debug = "true" *)axi_stream      axis_mem_write_data[NUM_DDR_CHANNELS]();
 (* mark_debug = "true" *)axis_mem_status axis_mem_write_status[NUM_DDR_CHANNELS]();

// DMA Signals
axis_mem_cmd    axis_dma_read_cmd();
axis_mem_cmd    axis_dma_write_cmd();
axi_stream      axis_dma_read_data();
axi_stream      axis_dma_write_data();


/*
 * User Role
 */
benchmark_role user_role(
    .net_clk(net_clk),
    .net_aresetn(net_aresetn),
    .pcie_clk(pcie_clk),
    .pcie_aresetn(pcie_aresetn),

    .user_clk(user_clk),
    .user_aresetn(user_aresetn),

    /* CONTROL INTERFACE */
    // LITE interface
    .s_axil         (axil_to_modules[AxilPortUserRole]),

    /* MEMORY INTERFACE */
    .m_axis_mem_read_cmd(axis_mem_read_cmd),
    .m_axis_mem_write_cmd(axis_mem_write_cmd),
    .s_axis_mem_read_data(axis_mem_read_data),
    .m_axis_mem_write_data(axis_mem_write_data),
    .s_axis_mem_read_status(axis_mem_read_status),
    .s_axis_mem_write_status(axis_mem_write_status),

    /* DMA INTERFACE */
    .m_axis_dma_read_cmd    (axis_dma_read_cmd),
    .m_axis_dma_write_cmd   (axis_dma_write_cmd),

    .s_axis_dma_read_data   (axis_dma_read_data),
    .m_axis_dma_write_data  (axis_dma_write_data)

);


/*
 * Memory Interface
 */
//TODO move
localparam DDR_CHANNEL0 = 0;
localparam DDR_CHANNEL1 = 1;

mem_single_inf #(
    .ENABLE(ENABLE_DDR)
) mem_inf_inst0 (
.user_clk(user_clk),
.user_aresetn(ddr_calib_complete),
.pcie_clk(pcie_clk), //TODO remove
.pcie_aresetn(pcie_aresetn),
.mem_clk(mem_clk[DDR_CHANNEL0]),
.mem_aresetn(mem_aresetn[DDR_CHANNEL0]),

/* USER INTERFACE */
//memory read commands
.s_axis_mem_read_cmd(axis_mem_read_cmd[DDR_CHANNEL0]),
//memory read status
.m_axis_mem_read_status(axis_mem_read_status[DDR_CHANNEL0]),
//memory read stream
.m_axis_mem_read_data(axis_mem_read_data[DDR_CHANNEL0]),

//memory write commands
.s_axis_mem_write_cmd(axis_mem_write_cmd[DDR_CHANNEL0]),
//memory rite status
.m_axis_mem_write_status(axis_mem_write_status[DDR_CHANNEL0]),
//memory write stream
.s_axis_mem_write_data(axis_mem_write_data[DDR_CHANNEL0]),

/* CONTROL INTERFACE */
// LITE interface
.s_axil(axil_to_modules[AxilPortDDR0]),

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

mem_single_inf #(
    .ENABLE(ENABLE_DDR)
) mem_inf_inst1 (
.user_clk(user_clk),
.user_aresetn(ddr_calib_complete),
.pcie_clk(pcie_clk),
.pcie_aresetn(pcie_aresetn), //TODO remove
.mem_clk(mem_clk[DDR_CHANNEL1]),
.mem_aresetn(mem_aresetn[DDR_CHANNEL1]),


/* USER INTERFACE */
.s_axis_mem_read_cmd(axis_mem_read_cmd[DDR_CHANNEL1]),
//memory read status
.m_axis_mem_read_status(axis_mem_read_status[DDR_CHANNEL1]),
//memory read stream
.m_axis_mem_read_data(axis_mem_read_data[DDR_CHANNEL1]),

//memory write commands
.s_axis_mem_write_cmd(axis_mem_write_cmd[DDR_CHANNEL1]),
//memory rite status
.m_axis_mem_write_status(axis_mem_write_status[DDR_CHANNEL1]),
//memory write stream
.s_axis_mem_write_data(axis_mem_write_data[DDR_CHANNEL1]),

/* CONTROL INTERFACE */
// LITE interface
.s_axil(axil_to_modules[AxilPortDDR1]),

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


 
/*
 * DMA Interface
 */

dma_inf dma_interface (
    .pcie_clk(pcie_clk),
    .pcie_aresetn(pcie_aresetn),
    .user_clk(user_clk),
    .user_aresetn(user_aresetn),

    /* USER INTERFACE */
    .s_axis_dma_read_cmd            (axis_dma_read_cmd),
    .s_axis_dma_write_cmd           (axis_dma_write_cmd),

    .m_axis_dma_read_data           (axis_dma_read_data),
    .s_axis_dma_write_data          (axis_dma_write_data),

    /* DRIVER INTERFACE */
    // Control interface
    .s_axil(axil_to_modules[AxilPortDMA]),

    // Data
    .m_axis_c2h_data(m_axis_dma_c2h),
    .s_axis_h2c_data(s_axis_dma_h2c),

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
 axil_interconnect_done_right axi_controller_interconnect_inst (
    .aclk(pcie_clk),
    .aresetn(pcie_aresetn),

    .s_axil(s_axil_control),
    .m_axil(axil_to_modules)

);
   
endmodule
`default_nettype wire