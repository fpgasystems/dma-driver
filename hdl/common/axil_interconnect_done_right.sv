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



module axil_interconnect_done_right #(
    parameter NUM_MASTER_PORTS = 4
) (
    input wire      aclk,
    input wire      aresetn,

    input  wire  [31:0] s_axil_awaddr,
    input  wire   [2:0] s_axil_awprot,
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
    input  wire   [2:0] s_axil_arprot,
    input  wire         s_axil_arvalid,
    output wire         s_axil_arready,
    output wire  [31:0] s_axil_rdata,
    output wire   [1:0] s_axil_rresp,
    output wire         s_axil_rvalid,
    input  wire         s_axil_rready,
    
    output logic[31:0]  m_axil_awaddr  [NUM_MASTER_PORTS-1:0],
    output logic[2:0]   m_axil_awprot  [NUM_MASTER_PORTS-1:0],
    output logic[NUM_MASTER_PORTS-1:0]        m_axil_awvalid,
    input wire[NUM_MASTER_PORTS-1:0]          m_axil_awready,
    output logic[31:0]  m_axil_wdata   [NUM_MASTER_PORTS-1:0],
    output logic[3:0]   m_axil_wstrb   [NUM_MASTER_PORTS-1:0],
    output logic[NUM_MASTER_PORTS-1:0]        m_axil_wvalid,
    input wire[NUM_MASTER_PORTS-1:0]          m_axil_wready,
    input wire[NUM_MASTER_PORTS-1:0]          m_axil_bvalid,
    input wire[1:0]     m_axil_bresp   [NUM_MASTER_PORTS-1:0],
    output logic[NUM_MASTER_PORTS-1:0]        m_axil_bready,
    output logic[31:0]  m_axil_araddr  [NUM_MASTER_PORTS-1:0],
    output logic[2:0]   m_axil_arprot  [NUM_MASTER_PORTS-1:0],
    output logic[NUM_MASTER_PORTS-1:0]        m_axil_arvalid,
    input wire[NUM_MASTER_PORTS-1:0]          m_axil_arready,
    input wire[31:0]    m_axil_rdata   [NUM_MASTER_PORTS-1:0],
    input wire[1:0]     m_axil_rresp   [NUM_MASTER_PORTS-1:0],
    input wire[NUM_MASTER_PORTS-1:0]          m_axil_rvalid,
    output logic[NUM_MASTER_PORTS-1:0]        m_axil_rready

);

//address write
wire [NUM_MASTER_PORTS*32-1:0]  axil_awaddr;
wire [NUM_MASTER_PORTS*3-1:0]   axil_awprot;
wire [NUM_MASTER_PORTS-1:0]     axil_awvalid;
wire [NUM_MASTER_PORTS-1:0]     axil_awready;
 
//data write
wire [NUM_MASTER_PORTS*32-1:0]  axil_wdata;
wire [NUM_MASTER_PORTS*4-1:0]   axil_wstrb;
wire [NUM_MASTER_PORTS-1:0]     axil_wvalid;
wire [NUM_MASTER_PORTS-1:0]     axil_wready;
 
//write response (handhake)
wire [NUM_MASTER_PORTS*2-1:0]   axil_bresp;
wire [NUM_MASTER_PORTS-1:0]     axil_bvalid;
wire [NUM_MASTER_PORTS-1:0]     axil_bready;
 
//address read
wire [NUM_MASTER_PORTS*32-1:0]  axil_araddr;
wire [NUM_MASTER_PORTS*3-1:0]   axil_arprot;
wire [NUM_MASTER_PORTS-1:0]     axil_arvalid;
wire [NUM_MASTER_PORTS-1:0]     axil_arready;
 
//data read
wire [NUM_MASTER_PORTS*32-1:0]  axil_rdata;
wire [NUM_MASTER_PORTS*2-1:0]   axil_rresp;
wire [NUM_MASTER_PORTS-1:0]     axil_rvalid;
wire [NUM_MASTER_PORTS-1:0]     axil_rready;


axil_controller_crossbar axi_interconnect_crossbar (
  .aclk(aclk),
  .aresetn(aresetn),
  .s_axi_awaddr(s_axil_awaddr),
  .s_axi_awprot(s_axil_awprot),
  .s_axi_awvalid(s_axil_awvalid),
  .s_axi_awready(s_axil_awready),
  .s_axi_wdata(s_axil_wdata),
  .s_axi_wstrb(s_axil_wstrb),
  .s_axi_wvalid(s_axil_wvalid),
  .s_axi_wready(s_axil_wready),
  .s_axi_bresp(s_axil_bresp),
  .s_axi_bvalid(s_axil_bvalid),
  .s_axi_bready(s_axil_bready),
  .s_axi_araddr(s_axil_araddr),
  .s_axi_arprot(s_axil_arprot),
  .s_axi_arvalid(s_axil_arvalid),
  .s_axi_arready(s_axil_arready),
  .s_axi_rdata(s_axil_rdata),
  .s_axi_rresp(s_axil_rresp),
  .s_axi_rvalid(s_axil_rvalid),
  .s_axi_rready(s_axil_rready),

  .m_axi_awaddr(axil_awaddr),
  .m_axi_awprot(axil_awprot),
  .m_axi_awvalid(axil_awvalid),
  .m_axi_awready(axil_awready),
  .m_axi_wdata(axil_wdata),
  .m_axi_wstrb(axil_wstrb),
  .m_axi_wvalid(axil_wvalid),
  .m_axi_wready(axil_wready),
  .m_axi_bresp(axil_bresp),
  .m_axi_bvalid(axil_bvalid),
  .m_axi_bready(axil_bready),
  .m_axi_araddr(axil_araddr),
  .m_axi_arprot(axil_arprot),
  .m_axi_arvalid(axil_arvalid),
  .m_axi_arready(axil_arready),
  .m_axi_rdata(axil_rdata),
  .m_axi_rresp(axil_rresp),
  .m_axi_rvalid(axil_rvalid),
  .m_axi_rready(axil_rready)
);


genvar idx;
generate
    for (idx=0; idx < NUM_MASTER_PORTS; idx=idx+1) begin
        assign m_axil_awaddr[idx] =    axil_awaddr[idx*32 +: 32];
        assign m_axil_awprot[idx] =    axil_awprot[idx*3 +: 3];
        assign m_axil_awvalid[idx] =   axil_awvalid[idx];
        assign axil_awready[idx] =   m_axil_awready[idx];
        assign m_axil_wdata[idx] =     axil_wdata[idx*32 +: 32];
        assign m_axil_wstrb[idx] =     axil_wstrb[idx*4 +: 4];
        assign m_axil_wvalid[idx] =    axil_wvalid[idx];
        assign axil_wready[idx] =    m_axil_wready[idx];
        assign axil_bvalid[idx] =    m_axil_bvalid[idx];
        assign axil_bresp[idx*2 +: 2]=    m_axil_bresp[idx];
        assign m_axil_bready[idx] =    axil_bready[idx];
        assign m_axil_araddr[idx] =    axil_araddr[idx*32 +: 32];
        assign m_axil_arprot[idx] =    axil_arprot[idx*3 +: 3];
        assign m_axil_arvalid[idx] =   axil_arvalid[idx];
        assign axil_arready[idx] =   m_axil_arready[idx];
        assign axil_rdata[idx*32 +: 32] =  m_axil_rdata[idx];
        assign axil_rresp[idx*2 +: 2] =   m_axil_rresp[idx];
        assign axil_rvalid[idx] =    m_axil_rvalid[idx];
        assign m_axil_rready[idx] =    axil_rready[idx];
    end
endgenerate
    
endmodule
`default_nettype wire