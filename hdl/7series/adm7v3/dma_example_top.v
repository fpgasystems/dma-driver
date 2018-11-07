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

assign AXI_S_Stream0_TREADY = 1'b1;
assign AXI_S_Stream1_TREADY = 1'b1;



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
axis_clock_converter_32 axis_clock_converter_ip_address (
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
end


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
 * DMA Test Bench
 */
 wire axis_bench_cmd_valid;
 reg axis_bench_cmd_ready;
wire[192:0] axis_bench_cmd_data;
 
wire axis_pcie_bench_cmd_valid;
wire axis_pcie_bench_cmd_ready;
wire[192:0] axis_pcie_bench_cmd_data;
 
 wire        axis_bench_read_cmd_tvalid;
 wire        axis_bench_read_cmd_tready;
 wire[95:0]  axis_bench_read_cmd_tdata;
wire        axis_bench_write_cmd_tvalid;
 wire        axis_bench_write_cmd_tready;
 wire[95:0]  axis_bench_write_cmd_tdata;

 wire        axis_pcie_bench_read_cmd_tvalid;
 wire        axis_pcie_bench_read_cmd_tready;
 wire[95:0]  axis_pcie_bench_read_cmd_tdata;
wire        axis_pcie_bench_write_cmd_tvalid;
 wire        axis_pcie_bench_write_cmd_tready;
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
);

/*
 * TLB wires
 */

wire axis_tlb_interface_valid;
wire axis_tlb_interface_ready;
wire[135:0] axis_tlb_interface_data;

wire        axis_dma_read_cmd_to_tlb_tvalid;
wire        axis_dma_read_cmd_to_tlb_tready;
wire[95:0]  axis_dma_read_cmd_to_tlb_tdata;
wire        axis_dma_write_cmd_to_tlb_tvalid;
wire        axis_dma_write_cmd_to_tlb_tready;
wire[95:0]  axis_dma_write_cmd_to_tlb_tdata;


//PCIe clock
wire        axis_dma_write_data_to_width_tvalid;
wire        axis_dma_write_data_to_width_tready;
wire[511:0] axis_dma_write_data_to_width_tdata;
wire[63:0]  axis_dma_write_data_to_width_tkeep;
wire        axis_dma_write_data_to_width_tlast;

wire        axis_dma_write_data_tvalid;
wire        axis_dma_write_data_tready;
wire[255:0] axis_dma_write_data_tdata;
wire[31:0]  axis_dma_write_data_tkeep;
wire        axis_dma_write_data_tlast;


//PCIe clock
wire        axis_dma_read_data_tvalid;
wire        axis_dma_read_data_tready;
wire[255:0] axis_dma_read_data_tdata;
wire[31:0]  axis_dma_read_data_tkeep;
wire        axis_dma_read_data_tlast;


//read
assign axis_dma_read_cmd_to_tlb_tvalid = axis_pcie_bench_read_cmd_tvalid;
assign axis_pcie_bench_read_cmd_tready = axis_dma_read_cmd_to_tlb_tready;
assign axis_dma_read_cmd_to_tlb_tdata = axis_pcie_bench_read_cmd_tdata;

mem_write_cmd_page_boundary_check_512_ip mem_write_cmd_page_boundary_check_inst (
  .regBaseVaddr_V(regBaseVaddrBoundCheck),          // input wire [63 : 0] regBaseVaddr_V
  .m_axis_cmd_TVALID(axis_dma_write_cmd_to_tlb_tvalid),    // output wire m_axis_cmd_TVALID
  .m_axis_cmd_TREADY(axis_dma_write_cmd_to_tlb_tready),    // input wire m_axis_cmd_TREADY
  .m_axis_cmd_TDATA(axis_dma_write_cmd_to_tlb_tdata),      // output wire [95 : 0] m_axis_cmd_TDATA
  .m_axis_data_TVALID(axis_dma_write_data_to_width_tvalid),  // output wire m_axis_data_TVALID
  .m_axis_data_TREADY(axis_dma_write_data_to_width_tready),  // input wire m_axis_data_TREADY
  .m_axis_data_TDATA(axis_dma_write_data_to_width_tdata),    // output wire [63 : 0] m_axis_data_TDATA
  .m_axis_data_TKEEP(axis_dma_write_data_to_width_tkeep),    // output wire [7 : 0] m_axis_data_TKEEP
  .m_axis_data_TLAST(axis_dma_write_data_to_width_tlast),    // output wire [0 : 0] m_axis_data_TLAST
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
);

assign axis_pcie_bench_read_data_tvalid = axis_dma_read_data_width_to_clk_tvalid;
assign axis_dma_read_data_width_to_clk_tready = axis_pcie_bench_read_data_tready;
assign axis_pcie_bench_read_data_tdata = axis_dma_read_data_width_to_clk_tdata;
assign axis_pcie_bench_read_data_tkeep = axis_dma_read_data_width_to_clk_tkeep;
assign axis_pcie_bench_read_data_tlast = axis_dma_read_data_width_to_clk_tlast;


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


`ifdef USE_DDR
mem_inf  #(
    .C0_SIMULATION("FALSE"),
    .C1_SIMULATION("FALSE"),
    .C0_SIM_BYPASS_INIT_CAL("OFF"),
    .C1_SIM_BYPASS_INIT_CAL("OFF")
)
mem_inf_inst(
.clk156_25(net_clk),
//.reset233_n(reset233_n), //active low reset signal for 233MHz clock domain
//.reset156_25_n(ddr3_calib_complete),
.reset156_25_n(ddr3_calib_complete),
//.clk233(clk233),
//.clk200(clk_ref_200),
.sys_rst(perst_n & pok_dram),

//ddr3 pins
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
.c0_ui_clk(c0_ui_clk),
.c0_init_calib_complete(c0_init_calib_complete),
  // Differential system clocks
.c0_sys_clk_p(c0_sys_clk_p),
.c0_sys_clk_n(c0_sys_clk_n),
 // differential iodelayctrl clk (reference clock)
.clk_ref_p(clk_ref_p),
.clk_ref_n(clk_ref_n),
.c1_sys_clk_p(c1_sys_clk_p),
.c1_sys_clk_n(c1_sys_clk_n),
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
.c1_ui_clk(),
.c1_init_calib_complete(c1_init_calib_complete),

//memory 0 read commands
.s_axis_mem0_read_cmd_tvalid(axis_txpart_readbuf_cmd_tvalid),
.s_axis_mem0_read_cmd_tready(axis_txpart_readbuf_cmd_tready),
.s_axis_mem0_read_cmd_tdata(axis_txpart_readbuf_cmd_tdata),
//memory 0 read status
.m_axis_mem0_read_sts_tvalid(),
.m_axis_mem0_read_sts_tready(1'b1),
.m_axis_mem0_read_sts_tdata(),
//memory 0 read stream
.m_axis_mem0_read_tvalid(axis_txpart_readbuf_data_tvalid),
.m_axis_mem0_read_tready(axis_txpart_readbuf_data_tready),
.m_axis_mem0_read_tdata(axis_txpart_readbuf_data_tdata),
.m_axis_mem0_read_tkeep(axis_txpart_readbuf_data_tkeep),
.m_axis_mem0_read_tlast(axis_txpart_readbuf_data_tlast),

//memory 0 write commands
.s_axis_mem0_write_cmd_tvalid(axis_txpart_writebuf_cmd_tvalid),
.s_axis_mem0_write_cmd_tready(axis_txpart_writebuf_cmd_tready),
.s_axis_mem0_write_cmd_tdata(axis_txpart_writebuf_cmd_tdata),
//memory 0 write status
.m_axis_mem0_write_sts_tvalid(axis_txpart_writebuf_status_tvalid),
.m_axis_mem0_write_sts_tready(axis_txpart_writebuf_status_tready),
.m_axis_mem0_write_sts_tdata(axis_txpart_writebuf_status_tdata),
//memory 0 write stream
.s_axis_mem0_write_tvalid(axis_txpart_writebuf_data_tvalid),
.s_axis_mem0_write_tready(axis_txpart_writebuf_data_tready),
.s_axis_mem0_write_tdata(axis_txpart_writebuf_data_tdata),
.s_axis_mem0_write_tkeep(axis_txpart_writebuf_data_tkeep),
.s_axis_mem0_write_tlast(axis_txpart_writebuf_data_tlast),

//memory 1 read commands
.s_axis_mem1_read_cmd_tvalid(axis_rxpart_readbuf_cmd_tvalid),
.s_axis_mem1_read_cmd_tready(axis_rxpart_readbuf_cmd_tready),
.s_axis_mem1_read_cmd_tdata(axis_rxpart_readbuf_cmd_tdata),
//memory 1 read status
.m_axis_mem1_read_sts_tvalid(),
.m_axis_mem1_read_sts_tready(1'b1),
.m_axis_mem1_read_sts_tdata(),
//memory 1 read stream
.m_axis_mem1_read_tvalid(axis_rxpart_readbuf_data_tvalid),
.m_axis_mem1_read_tready(axis_rxpart_readbuf_data_tready),
.m_axis_mem1_read_tdata(axis_rxpart_readbuf_data_tdata),
.m_axis_mem1_read_tkeep(axis_rxpart_readbuf_data_tkeep),
.m_axis_mem1_read_tlast(axis_rxpart_readbuf_data_tlast),


//memory 1 write commands
.s_axis_mem1_write_cmd_tvalid(axis_rxpart_writebuf_cmd_tvalid),
.s_axis_mem1_write_cmd_tready(axis_rxpart_writebuf_cmd_tready),
.s_axis_mem1_write_cmd_tdata(axis_rxpart_writebuf_cmd_tdata),
//memory 1 write status
.m_axis_mem1_write_sts_tvalid(axis_rxpart_writebuf_status_tvalid),
.m_axis_mem1_write_sts_tready(axis_rxpart_writebuf_status_tready),
.m_axis_mem1_write_sts_tdata(axis_rxpart_writebuf_status_tdata),
//memory 1 write stream
.s_axis_mem1_write_tvalid(axis_rxpart_writebuf_data_tvalid),
.s_axis_mem1_write_tready(axis_rxpart_writebuf_data_tready),
.s_axis_mem1_write_tdata(axis_rxpart_writebuf_data_tdata),
.s_axis_mem1_write_tkeep(axis_rxpart_writebuf_data_tkeep),
.s_axis_mem1_write_tlast(axis_rxpart_writebuf_data_tlast)

);
`else

`endif



//get Base Addr of TLB for page boundary check
reg[47:0] regBaseVaddr;
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
end


axis_512_to_256_converter pcie_axis_write_data_512_256 (
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
);


/*
 * TLB
 */
wire tlb_miss_count_valid;
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


 
axis_clock_converter_200 axis_dma_bench_cmd_clock_converter_inst (
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
  );
 
axis_clock_converter_64 axis_dma_bench_cycles_clock_converter_inst (
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
  );

 tlb_ip tlb_inst (
   /*.m_axis_ddr_read_cmd_TVALID(axis_ddr_read_cmd_tvalid),    // output wire m_axis_ddr_read_cmd_tvalid
   .m_axis_ddr_read_cmd_TREADY(axis_ddr_read_cmd_tready),    // input wire m_axis_ddr_read_cmd_tready
   .m_axis_ddr_read_cmd_TDATA(axis_ddr_read_cmd_tdata),      // output wire [71 : 0] m_axis_ddr_read_cmd_tdata
   .m_axis_ddr_write_cmd_TVALID(axis_ddr_write_cmd_tvalid),  // output wire m_axis_ddr_write_cmd_tvalid
   .m_axis_ddr_write_cmd_TREADY(axis_ddr_write_cmd_tready),  // input wire m_axis_ddr_write_cmd_tready
   .m_axis_ddr_write_cmd_TDATA(axis_ddr_write_cmd_tdata),    // output wire [71 : 0] m_axis_ddr_write_cmd_tdata*/
   .m_axis_dma_read_cmd_TVALID(axis_dma_read_cmd_tvalid),    // output wire m_axis_dma_read_cmd_tvalid
   .m_axis_dma_read_cmd_TREADY(axis_dma_read_cmd_tready),    // input wire m_axis_dma_read_cmd_tready
   .m_axis_dma_read_cmd_TDATA(axis_dma_read_cmd_tdata),      // output wire [95 : 0] m_axis_dma_read_cmd_tdata
   .m_axis_dma_write_cmd_TVALID(axis_dma_write_cmd_tvalid),  // output wire m_axis_dma_write_cmd_tvalid
   .m_axis_dma_write_cmd_TREADY(axis_dma_write_cmd_tready),  // input wire m_axis_dma_write_cmd_tready
   .m_axis_dma_write_cmd_TDATA(axis_dma_write_cmd_tdata),    // output wire [95 : 0] m_axis_dma_write_cmd_tdata
   .s_axis_mem_read_cmd_TVALID(axis_dma_read_cmd_to_tlb_tvalid),    // input wire s_axis_mem_read_cmd_tvalid
   .s_axis_mem_read_cmd_TREADY(axis_dma_read_cmd_to_tlb_tready),    // output wire s_axis_mem_read_cmd_tready
   .s_axis_mem_read_cmd_TDATA(axis_dma_read_cmd_to_tlb_tdata),      // input wire [111 : 0] s_axis_mem_read_cmd_tdata
   .s_axis_mem_write_cmd_TVALID(axis_dma_write_cmd_to_tlb_tvalid),  // input wire s_axis_mem_write_cmd_tvalid
   .s_axis_mem_write_cmd_TREADY(axis_dma_write_cmd_to_tlb_tready),  // output wire s_axis_mem_write_cmd_tready
   .s_axis_mem_write_cmd_TDATA(axis_dma_write_cmd_to_tlb_tdata),    // input wire [111 : 0] s_axis_mem_write_cmd_tdata
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





/*
 * DMA
 */

//address write
wire [31: 0] pcie_axil_awaddr;
wire  pcie_axil_awvalid;
wire pcie_axil_awready;
 
//data write
wire [31: 0]   pcie_axil_wdata;
wire [3: 0] pcie_axil_wstrb;
wire pcie_axil_wvalid;
wire pcie_axil_wready;
 
//write response (handhake)
wire [1:0] pcie_axil_bresp;
wire pcie_axil_bvalid;
wire pcie_axil_bready;
 
//address read
wire [31: 0] pcie_axil_araddr;
wire pcie_axil_arvalid;
wire pcie_axil_arready;
 
//data read
wire [31: 0] pcie_axil_rdata;
wire [1:0] pcie_axil_rresp;
wire pcie_axil_rvalid;
wire pcie_axil_rready;

reg led_light;
assign led[5] = pcie_aresetn; //led_light;

always @(posedge pcie_clk)
begin 
    if (~pcie_aresetn) begin
        led_light <= 1'b0;
    end
    else begin
        if (pcie_axil_wvalid) begin
            led_light <= ~led_light;
        end
    end
end

wire      axis_dma_write_dsc_byp_ready;
reg       axis_dma_write_dsc_byp_load;
reg[63:0] axis_dma_write_dsc_byp_addr;
reg[31:0] axis_dma_write_dsc_byp_len;

wire      axis_dma_read_dsc_byp_ready;
reg       axis_dma_read_dsc_byp_load;
reg[63:0] axis_dma_read_dsc_byp_addr;
reg[31:0] axis_dma_read_dsc_byp_len;

// Write descriptor bypass
assign axis_dma_write_cmd_tready = axis_dma_write_dsc_byp_ready;
always @(posedge pcie_clk)
begin 
    if (~pcie_aresetn) begin
        //axis_dma_write_cmd_tready <= 1'b0;
        axis_dma_write_dsc_byp_load <= 1'b0;
    end
    else begin
        //axis_dma_write_cmd_tready <= axis_dma_write_dsc_byp_ready;
        axis_dma_write_dsc_byp_load <= 1'b0;
        
        if (axis_dma_write_cmd_tvalid && axis_dma_write_cmd_tready) begin
            //axis_dma_write_cmd_tready <= 1'b0;
            axis_dma_write_dsc_byp_load <= 1'b1;
            axis_dma_write_dsc_byp_addr <= axis_dma_write_cmd_tdata[63:0];
            axis_dma_write_dsc_byp_len  <= axis_dma_write_cmd_tdata[95:64];
        end
    end
end

// Read descriptor bypass
assign axis_dma_read_cmd_tready = axis_dma_read_dsc_byp_ready;
always @(posedge pcie_clk)
begin 
    if (~pcie_aresetn) begin
        //axis_dma_read_cmd_tready <= 1'b0;
        axis_dma_read_dsc_byp_load <= 1'b0;
    end
    else begin
        //axis_dma_read_cmd_tready <= axis_dma_read_dsc_byp_ready;
        axis_dma_read_dsc_byp_load <= 1'b0;
        
        if (axis_dma_read_cmd_tvalid && axis_dma_read_cmd_tready) begin
            //axis_dma_read_cmd_tready <= 1'b0;
            axis_dma_read_dsc_byp_load <= 1'b1;
            axis_dma_read_dsc_byp_addr <= axis_dma_read_cmd_tdata[63:0];
            axis_dma_read_dsc_byp_len  <= axis_dma_read_cmd_tdata[95:64];
        end
    end
end


wire[7:0] c2h_sts_0;
wire[7:0] h2c_sts_0;

xdma_ip dma_inst (
  .sys_clk(pcie_ref_clk),                                              // input wire sys_clk
  .sys_rst_n(perst_n),                                          // input wire sys_rst_n
  .user_lnk_up(pcie_lnk_up),                                      // output wire user_lnk_up
  .pci_exp_txp(pcie_tx_p),                                      // output wire [7 : 0] pci_exp_txp
  .pci_exp_txn(pcie_tx_n),                                      // output wire [7 : 0] pci_exp_txn
  .pci_exp_rxp(pcie_rx_p),                                      // input wire [7 : 0] pci_exp_rxp
  .pci_exp_rxn(pcie_rx_n),                                      // input wire [7 : 0] pci_exp_rxn
  .axi_aclk(pcie_clk),                                            // output wire axi_aclk
  .axi_aresetn(pcie_aresetn),                                      // output wire axi_aresetn
  .usr_irq_req(1'b0),                                      // input wire [0 : 0] usr_irq_req
  .usr_irq_ack(),                                      // output wire [0 : 0] usr_irq_ack
  .msi_enable(),                                        // output wire msi_enable
  .msi_vector_width(),                            // output wire [2 : 0] msi_vector_width
  
  // LITE interface   
  //-- AXI Master Write Address Channel
  .m_axil_awaddr(pcie_axil_awaddr),              // output wire [31 : 0] m_axil_awaddr
  .m_axil_awprot(),              // output wire [2 : 0] m_axil_awprot
  .m_axil_awvalid(pcie_axil_awvalid),            // output wire m_axil_awvalid
  .m_axil_awready(pcie_axil_awready),            // input wire m_axil_awready
  //-- AXI Master Write Data Channel
  .m_axil_wdata(pcie_axil_wdata),                // output wire [31 : 0] m_axil_wdata
  .m_axil_wstrb(pcie_axil_wstrb),                // output wire [3 : 0] m_axil_wstrb
  .m_axil_wvalid(pcie_axil_wvalid),              // output wire m_axil_wvalid
  .m_axil_wready(pcie_axil_wready),              // input wire m_axil_wready
  //-- AXI Master Write Response Channel
  .m_axil_bvalid(pcie_axil_bvalid),              // input wire m_axil_bvalid
  .m_axil_bresp(pcie_axil_bresp),                // input wire [1 : 0] m_axil_bresp
  .m_axil_bready(pcie_axil_bready),              // output wire m_axil_bready
  //-- AXI Master Read Address Channel
  .m_axil_araddr(pcie_axil_araddr),              // output wire [31 : 0] m_axil_araddr
  .m_axil_arprot(),              // output wire [2 : 0] m_axil_arprot
  .m_axil_arvalid(pcie_axil_arvalid),            // output wire m_axil_arvalid
  .m_axil_arready(pcie_axil_arready),            // input wire m_axil_arready
  .m_axil_rdata(pcie_axil_rdata),                // input wire [31 : 0] m_axil_rdata
  //-- AXI Master Read Data Channel
  .m_axil_rresp(pcie_axil_rresp),                // input wire [1 : 0] m_axil_rresp
  .m_axil_rvalid(pcie_axil_rvalid),              // input wire m_axil_rvalid
  .m_axil_rready(pcie_axil_rready),              // output wire m_axil_rready
  
  // AXI Stream Interface
  .s_axis_c2h_tdata_0(axis_dma_write_data_tdata),                        // input wire [255 : 0] s_axis_c2h_tdata_0
  .s_axis_c2h_tlast_0(axis_dma_write_data_tlast),                        // input wire s_axis_c2h_tlast_0
  .s_axis_c2h_tvalid_0(axis_dma_write_data_tvalid),                      // input wire s_axis_c2h_tvalid_0
  .s_axis_c2h_tready_0(axis_dma_write_data_tready),                      // output wire s_axis_c2h_tready_0
  .s_axis_c2h_tkeep_0(axis_dma_write_data_tkeep),                        // input wire [31 : 0] s_axis_c2h_tkeep_0
  .m_axis_h2c_tdata_0(axis_dma_read_data_tdata),                        // output wire [255 : 0] m_axis_h2c_tdata_0
  .m_axis_h2c_tlast_0(axis_dma_read_data_tlast),                        // output wire m_axis_h2c_tlast_0
  .m_axis_h2c_tvalid_0(axis_dma_read_data_tvalid),                      // output wire m_axis_h2c_tvalid_0
  .m_axis_h2c_tready_0(axis_dma_read_data_tready),                      // input wire m_axis_h2c_tready_0
  .m_axis_h2c_tkeep_0(axis_dma_read_data_tkeep),                        // output wire [31 : 0] m_axis_h2c_tkeep_0
  
  // Descriptor Bypass
  .c2h_dsc_byp_ready_0    (axis_dma_write_dsc_byp_ready),
  .c2h_dsc_byp_src_addr_0 (64'h0),
  .c2h_dsc_byp_dst_addr_0 (axis_dma_write_dsc_byp_addr),
  .c2h_dsc_byp_len_0      (axis_dma_write_dsc_byp_len),
  .c2h_dsc_byp_ctl_0      (16'h13), //was 16'h3
  .c2h_dsc_byp_load_0     (axis_dma_write_dsc_byp_load),
  
  .h2c_dsc_byp_ready_0    (axis_dma_read_dsc_byp_ready),
  .h2c_dsc_byp_src_addr_0 (axis_dma_read_dsc_byp_addr),
  .h2c_dsc_byp_dst_addr_0 (64'h0),
  .h2c_dsc_byp_len_0      (axis_dma_read_dsc_byp_len),
  .h2c_dsc_byp_ctl_0      (16'h13), //was 16'h3
  .h2c_dsc_byp_load_0     (axis_dma_read_dsc_byp_load),
  
  .c2h_sts_0(c2h_sts_0),                                          // output wire [7 : 0] c2h_sts_0
  .h2c_sts_0(h2c_sts_0)                                          // output wire [7 : 0] h2c_sts_0
);

example_controller controller_inst(
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
    /*.m_axis_host_arp_lookup_request_TVALID(axis_pcie_host_arp_lookup_request_TVALID),
    .m_axis_host_arp_lookup_request_TREADY(axis_pcie_host_arp_lookup_request_TREADY),
    .m_axis_host_arp_lookup_request_TDATA(axis_pcie_host_arp_lookup_request_TDATA),
    .s_axis_host_arp_lookup_reply_TVALID(axis_pcie_host_arp_lookup_reply_TVALID),
    .s_axis_host_arp_lookup_reply_TREADY(axis_pcie_host_arp_lookup_reply_TREADY),
    .s_axis_host_arp_lookup_reply_TDATA(axis_pcie_host_arp_lookup_reply_TDATA),*/
    
    //Debug input
    //axi clock
    //general
    //.roce_crc_pkg_drop_count           (regCrcDropPkgCount),
    //.roce_psn_pkg_drop_count           (regInvalidPsnDropCount),
    //rxpart
    //mem cmd
    /*.roce_write_cmd_counter            (roce_write_cmd_counter),
    .roce_read_cmd_counter             (roce_read_cmd_counter),
    .rxpart_write_cmd_counter          (rxpart_write_cmd_counter),
    .txpart_write_cmd_counter          (txpart_write_cmd_counter),
    .txpart_read_cmd_counter           (txpart_read_cmd_counter),
    //roce
    .roce_rx_tuple_counter              (roce_rx_tuple_counter),
    .roce_tx_dma_tuple_counter          (roce_tx_dma_tuple_counter),
    .roce_tx_local_tuple_counter        (roce_tx_local_tuple_counter),
    .axis_stream_down                   (axis_stream_down),*/

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
);

/*
 * DEBUG counters on pcie clk
 */
reg[31:0] dma_write_cmd_counter;
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
end



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

reg[15:0] rxpart_cmd_counter;
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
        /*if (axis_rxpart_cmd_valid && axis_rxpart_cmd_ready) begin
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
        end*/
    end
end


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
    if (~aresetn) begin
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
always @(posedge net_clk)
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
 end


endmodule

`default_nettype wire
