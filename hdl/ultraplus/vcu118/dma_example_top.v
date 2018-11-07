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
    inout  wire[9:0]            c0_ddr4_dm_dbi_n,
    inout  wire[79:0]            c0_ddr4_dq,
    inout  wire[9:0]            c0_ddr4_dqs_t,
    inout  wire[9:0]            c0_ddr4_dqs_c,
    
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
    inout  wire[9:0]            c1_ddr4_dm_dbi_n,
    inout  wire[79:0]            c1_ddr4_dq,
    inout  wire[9:0]            c1_ddr4_dqs_t,
    inout  wire[9:0]            c1_ddr4_dqs_c,
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

wire sys_reset_n;
wire aclk;
wire aresetn;
wire network_init;

wire [2:0] gt_loopback_in_0; 
wire[3:0] user_rx_reset;
wire[3:0] user_tx_reset;
wire gtpowergood_out;

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
   .O(aresetn)
);



assign led[0] = gtpowergood_out;
assign led[1] = network_init;

// PCIe signals
wire pcie_lnk_up;
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
    .net_clk(aclk),
    .sys_reset (sys_reset),
    .aresetn(aresetn),
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
axis_clock_converter_32 axis_clock_converter_ip_address (
   .s_axis_aresetn(pcie_aresetn),  // input wire s_axis_aresetn
   .s_axis_aclk(pcie_clk),        // input wire s_axis_aclk
   .s_axis_tvalid(set_ip_addr_valid),    // input wire s_axis_tvalid
   .s_axis_tready(),    // output wire s_axis_tready
   .s_axis_tdata(set_ip_addr_data),
   
   .m_axis_aclk(aclk),        // input wire m_axis_aclk
   .m_axis_aresetn(aresetn),  // input wire m_axis_aresetn
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

always @(posedge aclk) begin
    if (~aresetn) begin
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

always @(posedge aclk)
begin
    l0_ctr <= l0_ctr + {{(LED_CTR_WIDTH-1){1'b0}}, 1'b1};
end

always @(posedge c0_ui_clk)
begin
    l1_ctr <= l1_ctr + {{(LED_CTR_WIDTH-1){1'b0}}, 1'b1};
end
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
assign led[4] = perst_n & aresetn;
///assign led[5] = aresetn;

   
/*   always @(posedge aclk) begin
        reset156_25_n_r1 <= perst_n & pok_dram & network_init;
        reset156_25_n_r2 <= reset156_25_n_r1;
        aresetn <= reset156_25_n_r2;
   end
  
always @(posedge aclk) 
    if (~aresetn) begin
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
assign init_calib_complete = ddr3_calib_complete;*/



/*
 * DMA Test Bench
 */
 wire axis_bench_cmd_valid;
 reg axis_bench_cmd_ready;
wire[192:0] axis_bench_cmd_data;
 
 /*wire axis_pcie_bench_cmd_valid;
 wire axis_pcie_bench_cmd_ready;
 wire[192:0] axis_pcie_bench_cmd_data;*/
 
 wire        axis_bench_read_cmd_TVALID;
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
 );



/*
 * TLB wires
 */

wire axis_tlb_interface_valid;
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
wire        axis_dma_write_width_tlast;

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


wire axis_write_data_boundary_to_cc_tvalid;
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
assign axis_bench_read_data_tlast = axis_dma_read_data_tlast;


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


`ifdef USE_DDR
mem_inf  #(
    .C0_SIMULATION("FALSE"),
    .C1_SIMULATION("FALSE"),
    .C0_SIM_BYPASS_INIT_CAL("OFF"),
    .C1_SIM_BYPASS_INIT_CAL("OFF")
)
mem_inf_inst(
.clk156_25(aclk),
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
reg[63:0] regBaseVaddr;
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
assign axis_dma_write_data_tlast = axis_write_data_boundary_to_cc_tlast;

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
//assign led[5] = pcie_aresetn; //led_light;

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
assign axis_pcie_dma_write_cmd_tready = axis_dma_write_dsc_byp_ready;
always @(posedge pcie_clk)
begin 
    if (~pcie_aresetn) begin
        //axis_dma_write_cmd_tready <= 1'b0;
        axis_dma_write_dsc_byp_load <= 1'b0;
    end
    else begin
        //axis_dma_write_cmd_tready <= axis_dma_write_dsc_byp_ready;
        axis_dma_write_dsc_byp_load <= 1'b0;
        
        if (axis_pcie_dma_write_cmd_tvalid && axis_pcie_dma_write_cmd_tready) begin
            //axis_dma_write_cmd_tready <= 1'b0;
            axis_dma_write_dsc_byp_load <= 1'b1;
            axis_dma_write_dsc_byp_addr <= axis_pcie_dma_write_cmd_tdata[63:0];
            axis_dma_write_dsc_byp_len  <= axis_pcie_dma_write_cmd_tdata[95:64];
        end
    end
end

// Read descriptor bypass
assign axis_pcie_dma_read_cmd_tready = axis_dma_read_dsc_byp_ready;
always @(posedge pcie_clk)
begin 
    if (~pcie_aresetn) begin
        //axis_dma_read_cmd_tready <= 1'b0;
        axis_dma_read_dsc_byp_load <= 1'b0;
    end
    else begin
        //axis_dma_read_cmd_tready <= axis_dma_read_dsc_byp_ready;
        axis_dma_read_dsc_byp_load <= 1'b0;
        
        if (axis_pcie_dma_read_cmd_tvalid && axis_pcie_dma_read_cmd_tready) begin
            //axis_dma_read_cmd_tready <= 1'b0;
            axis_dma_read_dsc_byp_load <= 1'b1;
            axis_dma_read_dsc_byp_addr <= axis_pcie_dma_read_cmd_tdata[63:0];
            axis_dma_read_dsc_byp_len  <= axis_pcie_dma_read_cmd_tdata[95:64];
        end
    end
end


wire[7:0] c2h_sts_0;
wire[7:0] h2c_sts_0;

xdma_ip dma_inst (
  .sys_clk(pcie_ref_clk),                                              // input wire sys_clk
  .sys_clk_gt(pcie_ref_clk_gt),
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
    .net_aclk(aclk),
    .net_aresetn(aresetn),
    
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
    .m_axis_dma_bench_cmd_valid        (axis_bench_cmd_valid),
    .m_axis_dma_bench_cmd_ready        (axis_bench_cmd_ready),
    .m_axis_dma_bench_cmd_data         (axis_bench_cmd_data),
    
    //Debug input

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
        if (axis_pcie_dma_write_cmd_tvalid && axis_pcie_dma_write_cmd_tready) begin
            dma_write_cmd_counter <= dma_write_cmd_counter + 1;
            dma_write_length_counter <= dma_write_length_counter + axis_pcie_dma_write_cmd_tdata[95:64];
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
        if (axis_pcie_dma_read_cmd_tvalid && axis_pcie_dma_read_cmd_tready) begin
            dma_read_cmd_counter <= dma_read_cmd_counter + 1;
            dma_read_length_counter <= dma_read_length_counter + axis_pcie_dma_read_cmd_tdata[95:64];
            if (axis_pcie_dma_read_cmd_tdata[95:64] == 0) begin
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
        if (axis_pcie_dma_write_cmd_tvalid && ~axis_pcie_dma_write_cmd_tready) begin
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
always @(posedge aclk)
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
 * DEBUG for TLB
 */

/*reg[15:0] tlb_read_input;
reg[15:0] tlb_write_input;
reg[15:0] tlb_read_output;
reg[15:0] tlb_write_output;

always @(posedge aclk)
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




reg[7:0] bench_write_cmd_counter;
reg[15:0] bench_write_data_word_counter;
reg[7:0] bench_write_data_pkg_counter;
reg[15:0] bench_read_cmd_counter;
reg[15:0] bench_read_data_word_counter;
reg[7:0] bench_read_data_pkg_counter;

/* DEBUG boundary_check */
always @(posedge pcie_clk)
begin
    if (~pcie_aresetn) begin
        bench_write_cmd_counter <= 0;
        bench_write_data_word_counter <= 0;
        bench_write_data_pkg_counter <= 0;
        bench_read_cmd_counter <= 0;
        bench_read_data_word_counter <= 0;
        bench_read_data_pkg_counter <= 0;
    end
    else begin
        if (axis_bench_write_cmd_TVALID && axis_bench_write_cmd_TREADY) begin
            bench_write_cmd_counter <= bench_write_cmd_counter + 1;
        end
        if (axis_bench_write_data_tvalid && axis_bench_write_data_tready) begin
            bench_write_data_word_counter <= bench_write_data_word_counter + 1;
            if (axis_bench_write_data_tlast) begin
                bench_write_data_pkg_counter <= bench_write_data_pkg_counter + 1;
            end
        end
        if (axis_bench_read_cmd_TVALID && axis_bench_read_cmd_TREADY) begin
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
