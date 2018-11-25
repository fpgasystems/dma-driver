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


module benchmark_role(
    input wire      net_clk,
    input wire      net_aresetn,

    input wire      pcie_clk,
    input wire      pcie_aresetn,


    /* CONTROL INTERFACE */
    // LITE interface   
    //-- AXI Master Write Address Channel
    input wire[31:0]    s_axil_awaddr,
    input wire[2:0]     s_axil_awprot,
    input wire          s_axil_awvalid,
    output logic        s_axil_awready,
    //-- AXI Master Write Data Channel
    input wire[31:0]    s_axil_wdata,
    input wire[3:0]     s_axil_wstrb,
    input wire          s_axil_wvalid,
    output logic        s_axil_wready,
    //-- AXI Master Write Response Channel
    output logic        s_axil_bvalid,
    output logic[1:0]   s_axil_bresp,
    input wire          s_axil_bready,
    //-- AXI Master Read Address Channel
    input wire[31:0]    s_axil_araddr,
    input wire[2:0]     s_axil_arprot,
    input wire          s_axil_arvalid,
    output logic        s_axil_arready,
    output logic[31:0]  s_axil_rdata,
    //-- AXI Master Read Data Channel
    output logic[1:0]   s_axil_rresp,
    output logic        s_axil_rvalid,
    input wire          s_axil_rready,


    /* NETWORK  - TCP/IP INTERFACE */

    /* NETWORK - RDMA INTERFACE */

    /* MEMORY INTERFACE */
    // Channel 0 read path
    output logic            m_axis_mem0_read_cmd_tvalid,
    input wire              m_axis_mem0_read_cmd_tready,
    output logic[95:0]      m_axis_mem0_read_cmd_tdata, //[95:64]: length, [63:0]: addresss
    // read status
    /*input wire            s_axis_mem0_read_sts_tvalid,
    output logic            s_axis_mem0_read_sts_tready,
    input wire [7:0]        s_axis_mem0_read_sts_tdata,*/
    // read data stream
    input wire [511:0]      s_axis_mem0_read_data_tdata,
    input wire [63:0]       s_axis_mem0_read_data_tkeep,
    input wire              s_axis_mem0_read_data_tlast,
    input wire              s_axis_mem0_read_data_tvalid,
    output logic            s_axis_mem0_read_data_tready,
    
    // Channel 0 write path
    output logic            m_axis_mem0_write_cmd_tvalid,
    input wire              m_axis_mem0_write_cmd_tready,
    output logic[95:0]      m_axis_mem0_write_cmd_tdata,  //[95:64]: length, [63:0]: addresss
    // write status
    input wire              s_axis_mem0_write_sts_tvalid,
    output logic            s_axis_mem0_write_sts_tready,
    input wire [7:0]        s_axis_mem0_write_sts_tdata,
    // write data stream
    output logic[511:0]     m_axis_mem0_write_data_tdata,
    output logic[63:0]      m_axis_mem0_write_data_tkeep,
    output logic            m_axis_mem0_write_data_tlast,
    output logic            m_axis_mem0_write_data_tvalid,
    input wire              m_axis_mem0_write_data_tready,
    
    // Channel 1 read path
    output logic            m_axis_mem1_read_cmd_tvalid,
    input wire              m_axis_mem1_read_cmd_tready,
    output logic[95:0]      m_axis_mem1_read_cmd_tdata, //[95:64]: length, [63:0]: addresss
    // read status
    /*input wire            s_axis_mem1_read_sts_tvalid,
    output logic            s_axis_mem1_read_sts_tready,
    input wire [7:0]        s_axis_mem1_read_sts_tdata,*/
    // read stream
    input wire [511:0]      s_axis_mem1_read_data_tdata,
    input wire [63:0]       s_axis_mem1_read_data_tkeep,
    input wire              s_axis_mem1_read_data_tlast,
    input wire              s_axis_mem1_read_data_tvalid,
    output logic            s_axis_mem1_read_data_tready,
    
    // Channel 1 write path
    output logic            m_axis_mem1_write_cmd_tvalid,
    input wire              m_axis_mem1_write_cmd_tready,
    output logic[95:0]      m_axis_mem1_write_cmd_tdata, //[95:64]: length, [63:0]: addresss
    // write status
    input wire              s_axis_mem1_write_sts_tvalid,
    output logic            s_axis_mem1_write_sts_tready,
    input wire [7:0]        s_axis_mem1_write_sts_tdata,
    // write stream
    output logic[511:0]     m_axis_mem1_write_data_tdata,
    output logic[63:0]      m_axis_mem1_write_data_tkeep,
    output logic            m_axis_mem1_write_data_tlast,
    output logic            m_axis_mem1_write_data_tvalid,
    input wire              m_axis_mem1_write_data_tready,


    /* DMA INTERFACE */
    output logic            m_axis_dma_read_cmd_tvalid,
    input wire              m_axis_dma_read_cmd_tready,
    output logic[95:0]      m_axis_dma_read_cmd_tdata,
    output logic            m_axis_dma_write_cmd_tvalid,
    input wire              m_axis_dma_write_cmd_tready,
    output logic[95:0]      m_axis_dma_write_cmd_tdata,

    input wire              s_axis_dma_read_data_tvalid,
    output logic            s_axis_dma_read_data_tready,
    input wire[511:0]       s_axis_dma_read_data_tdata,
    input wire[63:0]        s_axis_dma_read_data_tkeep,
    input wire              s_axis_dma_read_data_tlast,

    output logic            m_axis_dma_write_data_tvalid,
    input wire              m_axis_dma_write_data_tready,
    output logic[511:0]     m_axis_dma_write_data_tdata,
    output logic[63:0]      m_axis_dma_write_data_tkeep,
    output logic            m_axis_dma_write_data_tlast

);



/*
 * DMA Test Bench
 */
(* mark_debug = "true" *)wire axis_dma_bench_cmd_valid;
(* mark_debug = "true" *)reg axis_dma_bench_cmd_ready;
wire[192:0] axis_dma_bench_cmd_data;
 
(* mark_debug = "true" *)wire execution_cycles_valid;
wire[63:0] execution_cycles_data;
reg[63:0] dma_bench_execution_cycles;
wire[63:0] pcie_dma_bench_execution_cycles;

reg[47:0] dmaBenchBaseAddr;
reg[47:0] dmaBenchMemorySize;
reg[31:0] dmaBenchNumberOfAccesses;
reg[31:0] dmaBenchChunkLength;
reg[31:0] dmaBenchStrideLength;
reg dmaBenchIsWrite;
(* mark_debug = "true" *)reg dmaBenchStart;

(* mark_debug = "true" *)reg[31:0] debug_cycle_counter;
(* mark_debug = "true" *)reg runBench;

always @(posedge net_clk) begin
    if (~net_aresetn) begin
        axis_dma_bench_cmd_ready <= 0;
        runBench <= 0;
    end
    else begin
        dmaBenchStart <= 0;
        axis_dma_bench_cmd_ready <= 1;
        if (axis_dma_bench_cmd_valid && axis_dma_bench_cmd_ready) begin
            dmaBenchBaseAddr <= axis_dma_bench_cmd_data[47:0];
            dmaBenchMemorySize <= axis_dma_bench_cmd_data[95:48];
            dmaBenchNumberOfAccesses <= axis_dma_bench_cmd_data[127:96];
            dmaBenchChunkLength <= axis_dma_bench_cmd_data[159:128];
            dmaBenchStrideLength <= axis_dma_bench_cmd_data[191:160];
            dmaBenchIsWrite <= axis_dma_bench_cmd_data[192];
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
 .m_axis_read_cmd_TVALID(m_axis_dma_read_cmd_tvalid),
 .m_axis_read_cmd_TREADY(m_axis_dma_read_cmd_tready),
 .m_axis_read_cmd_TDATA(m_axis_dma_read_cmd_tdata),
 .m_axis_write_cmd_TVALID(m_axis_dma_write_cmd_tvalid),
 .m_axis_write_cmd_TREADY(m_axis_dma_write_cmd_tready),
 .m_axis_write_cmd_TDATA(m_axis_dma_write_cmd_tdata),
 .m_axis_write_data_TVALID(m_axis_dma_write_data_tvalid),
 .m_axis_write_data_TREADY(m_axis_dma_write_data_tready),
 .m_axis_write_data_TDATA(m_axis_dma_write_data_tdata),
 .m_axis_write_data_TKEEP(m_axis_dma_write_data_tkeep),
 .m_axis_write_data_TLAST(m_axis_dma_write_data_tlast),
 .s_axis_read_data_TVALID(s_axis_dma_read_data_tvalid),
 .s_axis_read_data_TREADY(s_axis_dma_read_data_tready),
 .s_axis_read_data_TDATA(s_axis_dma_read_data_tdata),
 .s_axis_read_data_TKEEP(s_axis_dma_read_data_tkeep),
 .s_axis_read_data_TLAST(s_axis_dma_read_data_tlast),
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




/*
 * Memory Benchmark
 */
(* mark_debug = "true" *)wire axis_ddr_bench_cmd_valid;
(* mark_debug = "true" *)reg axis_ddr_bench_cmd_ready;
wire[192:0] axis_ddr_bench_cmd_data;
(* mark_debug = "true" *)wire[1:0]   axis_ddr_bench_cmd_dest;

//TODO
assign s_axis_mem0_write_sts_tready = 1'b1;
assign s_axis_mem1_write_sts_tready = 1'b1;

wire ddr0_execution_cycles_valid;
wire[63:0] ddr0_execution_cycles_data;
wire ddr1_execution_cycles_valid;
wire[63:0] ddr1_execution_cycles_data;
reg[63:0] ddr_bench_execution_cycles;
wire[63:0] pcie_ddr_bench_execution_cycles;

reg[47:0] ddrBenchBaseAddr;
reg[47:0] ddrBenchMemorySize;
reg[31:0] ddrBenchNumberOfAccesses;
reg[31:0] ddrBenchChunkLength;
reg[31:0] ddrBenchStrideLength;
reg ddrBenchIsWrite;
(* mark_debug = "true" *)reg[1:0] ddrBenchStart;

(* mark_debug = "true" *)reg[31:0] ddr_debug_cycle_counter;
(* mark_debug = "true" *)reg ddrRunBench;

always @(posedge net_clk) begin
    if (~net_aresetn) begin
        axis_ddr_bench_cmd_ready <= 0;
        ddrRunBench <= 0;
        ddrBenchStart <= 0;
    end
    else begin
        ddrBenchStart <= 0;
        axis_ddr_bench_cmd_ready <= 1;
        if (axis_ddr_bench_cmd_valid && axis_ddr_bench_cmd_ready) begin
            ddrBenchBaseAddr <= axis_ddr_bench_cmd_data[47:0];
            ddrBenchMemorySize <= axis_ddr_bench_cmd_data[95:48];
            ddrBenchNumberOfAccesses <= axis_ddr_bench_cmd_data[127:96];
            ddrBenchChunkLength <= axis_ddr_bench_cmd_data[159:128];
            ddrBenchStrideLength <= axis_ddr_bench_cmd_data[191:160];
            ddrBenchIsWrite <= axis_ddr_bench_cmd_data[192];
            ddr_bench_execution_cycles <= 0;
            ddrRunBench <= 1;
            ddr_debug_cycle_counter <= 0;
            case (axis_ddr_bench_cmd_dest)
            0: ddrBenchStart[0] <= 1'b1;
            1: ddrBenchStart[1] <= 1'b1;
            endcase
        end
        if (ddrRunBench) begin
            ddr_debug_cycle_counter <= ddr_debug_cycle_counter + 1;
        end
        if (ddr0_execution_cycles_valid) begin
            ddr_bench_execution_cycles <= ddr0_execution_cycles_data;
            ddrRunBench <= 0;
        end
        if (ddr1_execution_cycles_valid) begin
            ddr_bench_execution_cycles <= ddr1_execution_cycles_data;
            ddrRunBench <= 0;
        end
    end
end
 
dma_bench_ip ddr0_bench_inst(
 .m_axis_read_cmd_TVALID(m_axis_mem0_read_cmd_tvalid),
 .m_axis_read_cmd_TREADY(m_axis_mem0_read_cmd_tready),
 .m_axis_read_cmd_TDATA(m_axis_mem0_read_cmd_tdata),
 .m_axis_write_cmd_TVALID(m_axis_mem0_write_cmd_tvalid),
 .m_axis_write_cmd_TREADY(m_axis_mem0_write_cmd_tready),
 .m_axis_write_cmd_TDATA(m_axis_mem0_write_cmd_tdata),
 .m_axis_write_data_TVALID(m_axis_mem0_write_data_tvalid),
 .m_axis_write_data_TREADY(m_axis_mem0_write_data_tready),
 .m_axis_write_data_TDATA(m_axis_mem0_write_data_tdata),
 .m_axis_write_data_TKEEP(m_axis_mem0_write_data_tkeep),
 .m_axis_write_data_TLAST(m_axis_mem0_write_data_tlast),
 .s_axis_read_data_TVALID(s_axis_mem0_read_data_tvalid),
 .s_axis_read_data_TREADY(s_axis_mem0_read_data_tready),
 .s_axis_read_data_TDATA(s_axis_mem0_read_data_tdata),
 .s_axis_read_data_TKEEP(s_axis_mem0_read_data_tkeep),
 .s_axis_read_data_TLAST(s_axis_mem0_read_data_tlast),
 .aresetn(net_aresetn),
 .aclk(net_clk),
 .regBaseAddr_V({16'h00, ddrBenchBaseAddr}),
 .memorySize_V({16'h00, ddrBenchMemorySize}),
 .numberOfAccesses_V(ddrBenchNumberOfAccesses),
 .chunkLength_V(ddrBenchChunkLength),
 .strideLength_V(ddrBenchStrideLength),
 .isWrite_V(ddrBenchIsWrite),
 .start_V(ddrBenchStart[0]),
 .regExecutionCycles_V(ddr0_execution_cycles_data),
 .regExecutionCycles_V_ap_vld(ddr0_execution_cycles_valid)
 );

dma_bench_ip ddr1_bench_inst(
 .m_axis_read_cmd_TVALID(m_axis_mem1_read_cmd_tvalid),
 .m_axis_read_cmd_TREADY(m_axis_mem1_read_cmd_tready),
 .m_axis_read_cmd_TDATA(m_axis_mem1_read_cmd_tdata),
 .m_axis_write_cmd_TVALID(m_axis_mem1_write_cmd_tvalid),
 .m_axis_write_cmd_TREADY(m_axis_mem1_write_cmd_tready),
 .m_axis_write_cmd_TDATA(m_axis_mem1_write_cmd_tdata),
 .m_axis_write_data_TVALID(m_axis_mem1_write_data_tvalid),
 .m_axis_write_data_TREADY(m_axis_mem1_write_data_tready),
 .m_axis_write_data_TDATA(m_axis_mem1_write_data_tdata),
 .m_axis_write_data_TKEEP(m_axis_mem1_write_data_tkeep),
 .m_axis_write_data_TLAST(m_axis_mem1_write_data_tlast),
 .s_axis_read_data_TVALID(s_axis_mem1_read_data_tvalid),
 .s_axis_read_data_TREADY(s_axis_mem1_read_data_tready),
 .s_axis_read_data_TDATA(s_axis_mem1_read_data_tdata),
 .s_axis_read_data_TKEEP(s_axis_mem1_read_data_tkeep),
 .s_axis_read_data_TLAST(s_axis_mem1_read_data_tlast),
 .aresetn(net_aresetn),
 .aclk(net_clk),
 .regBaseAddr_V({16'h00, ddrBenchBaseAddr}),
 .memorySize_V({16'h00, ddrBenchMemorySize}),
 .numberOfAccesses_V(ddrBenchNumberOfAccesses),
 .chunkLength_V(ddrBenchChunkLength),
 .strideLength_V(ddrBenchStrideLength),
 .isWrite_V(ddrBenchIsWrite),
 .start_V(ddrBenchStart[1]),
 .regExecutionCycles_V(ddr1_execution_cycles_data),
 .regExecutionCycles_V_ap_vld(ddr1_execution_cycles_valid)
 );

/*
 * Role Controller
 */
benchmark_controller controller_inst(
    .pcie_clk(pcie_clk),
    .pcie_aresetn(pcie_aresetn),
    .user_clk(net_clk),
    .user_aresetn(net_aresetn),
    
     // AXI Lite Master Interface connections
    .s_axil_awaddr  (s_axil_awaddr[31:0]),
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
    .s_axil_arvalid (s_axil_arvalid),
    .s_axil_arready (s_axil_arready),
    .s_axil_rdata   (s_axil_rdata),   // block ram for AXI Lite is only 31 bits
    .s_axil_rresp   (s_axil_rresp),
    .s_axil_rvalid  (s_axil_rvalid),
    .s_axil_rready  (s_axil_rready),
    
    // Control streams
    .m_axis_ddr_bench_cmd_valid         (axis_ddr_bench_cmd_valid),
    .m_axis_ddr_bench_cmd_ready         (axis_ddr_bench_cmd_ready),
    .m_axis_ddr_bench_cmd_data          (axis_ddr_bench_cmd_data),
    .m_axis_ddr_bench_cmd_dest          (axis_ddr_bench_cmd_dest),
    .m_axis_dma_bench_cmd_valid         (axis_dma_bench_cmd_valid),
    .m_axis_dma_bench_cmd_ready         (axis_dma_bench_cmd_ready),
    .m_axis_dma_bench_cmd_data          (axis_dma_bench_cmd_data),

    .ddr_bench_execution_cycles         (ddr_bench_execution_cycles),
    .dma_bench_execution_cycles         (dma_bench_execution_cycles)
    
);



endmodule
`default_nettype wire