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

module benchmark_role(
    input wire      net_clk,
    input wire      net_aresetn,
    input wire      pcie_clk,
    input wire      pcie_aresetn,
    
    output logic    user_clk,
    output logic    user_aresetn,


    /* CONTROL INTERFACE */
    axi_lite.slave      s_axil,

    /* NETWORK  - TCP/IP INTERFACE */

    /* NETWORK - RDMA INTERFACE */

    /* MEMORY INTERFACE */
    // read command
    axis_mem_cmd.master     m_axis_mem_read_cmd[NUM_DDR_CHANNELS],
    // read status
    axis_mem_status.slave   s_axis_mem_read_status[NUM_DDR_CHANNELS],
    // read data stream
    axi_stream.slave        s_axis_mem_read_data[NUM_DDR_CHANNELS],
    
    // write command
    axis_mem_cmd.master     m_axis_mem_write_cmd[NUM_DDR_CHANNELS],
    // write status
    axis_mem_status.slave   s_axis_mem_write_status[NUM_DDR_CHANNELS],
    // write data stream
    axi_stream.master       m_axis_mem_write_data[NUM_DDR_CHANNELS],
    
    /* DMA INTERFACE */
    axis_mem_cmd.master     m_axis_dma_read_cmd,
    axis_mem_cmd.master     m_axis_dma_write_cmd,

    axi_stream.slave        s_axis_dma_read_data,
    axi_stream.master       m_axis_dma_write_data

);

/*
 * Clock
 */
//Choose clock for the user logic
assign user_clk = pcie_clk;
assign user_aresetn = pcie_aresetn; 


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

always @(posedge user_clk) begin
    if (~user_aresetn) begin
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
 .m_axis_read_cmd_TVALID(m_axis_dma_read_cmd.valid),
 .m_axis_read_cmd_TREADY(m_axis_dma_read_cmd.ready),
 .m_axis_read_cmd_TDATA({m_axis_dma_read_cmd.length, m_axis_dma_read_cmd.address}),
 .m_axis_write_cmd_TVALID(m_axis_dma_write_cmd.valid),
 .m_axis_write_cmd_TREADY(m_axis_dma_write_cmd.ready),
 .m_axis_write_cmd_TDATA({m_axis_dma_write_cmd.length, m_axis_dma_write_cmd.address}),
 .m_axis_write_data_TVALID(m_axis_dma_write_data.valid),
 .m_axis_write_data_TREADY(m_axis_dma_write_data.ready),
 .m_axis_write_data_TDATA(m_axis_dma_write_data.data),
 .m_axis_write_data_TKEEP(m_axis_dma_write_data.keep),
 .m_axis_write_data_TLAST(m_axis_dma_write_data.last),
 .s_axis_read_data_TVALID(s_axis_dma_read_data.valid),
 .s_axis_read_data_TREADY(s_axis_dma_read_data.ready),
 .s_axis_read_data_TDATA(s_axis_dma_read_data.data),
 .s_axis_read_data_TKEEP(s_axis_dma_read_data.keep),
 .s_axis_read_data_TLAST(s_axis_dma_read_data.last),
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
assign s_axis_mem_write_status[0].ready = 1'b1;
assign s_axis_mem_write_status[1].ready = 1'b1;
assign s_axis_mem_read_status[0].ready = 1'b1;
assign s_axis_mem_read_status[1].ready = 1'b1;

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

always @(posedge user_clk) begin
    if (~user_aresetn) begin
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
 .m_axis_read_cmd_TVALID(m_axis_mem_read_cmd[0].valid),
 .m_axis_read_cmd_TREADY(m_axis_mem_read_cmd[0].ready),
 .m_axis_read_cmd_TDATA({m_axis_mem_read_cmd[0].length, m_axis_mem_read_cmd[0].address}),
 .m_axis_write_cmd_TVALID(m_axis_mem_write_cmd[0].valid),
 .m_axis_write_cmd_TREADY(m_axis_mem_write_cmd[0].ready),
 .m_axis_write_cmd_TDATA({m_axis_mem_write_cmd[0].length, m_axis_mem_write_cmd[0].address}),
 .m_axis_write_data_TVALID(m_axis_mem_write_data[0].valid),
 .m_axis_write_data_TREADY(m_axis_mem_write_data[0].ready),
 .m_axis_write_data_TDATA(m_axis_mem_write_data[0].data),
 .m_axis_write_data_TKEEP(m_axis_mem_write_data[0].keep),
 .m_axis_write_data_TLAST(m_axis_mem_write_data[0].last),
 .s_axis_read_data_TVALID(s_axis_mem_read_data[0].valid),
 .s_axis_read_data_TREADY(s_axis_mem_read_data[0].ready),
 .s_axis_read_data_TDATA(s_axis_mem_read_data[0].data),
 .s_axis_read_data_TKEEP(s_axis_mem_read_data[0].keep),
 .s_axis_read_data_TLAST(s_axis_mem_read_data[0].last),
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
 .m_axis_read_cmd_TVALID(m_axis_mem_read_cmd[1].valid),
 .m_axis_read_cmd_TREADY(m_axis_mem_read_cmd[1].ready),
 .m_axis_read_cmd_TDATA({m_axis_mem_read_cmd[1].length, m_axis_mem_read_cmd[1].address}),
 .m_axis_write_cmd_TVALID(m_axis_mem_write_cmd[1].valid),
 .m_axis_write_cmd_TREADY(m_axis_mem_write_cmd[1].ready),
 .m_axis_write_cmd_TDATA({m_axis_mem_write_cmd[1].length, m_axis_mem_write_cmd[1].address}),
 .m_axis_write_data_TVALID(m_axis_mem_write_data[1].valid),
 .m_axis_write_data_TREADY(m_axis_mem_write_data[1].ready),
 .m_axis_write_data_TDATA(m_axis_mem_write_data[1].data),
 .m_axis_write_data_TKEEP(m_axis_mem_write_data[1].keep),
 .m_axis_write_data_TLAST(m_axis_mem_write_data[1].last),
 .s_axis_read_data_TVALID(s_axis_mem_read_data[1].valid),
 .s_axis_read_data_TREADY(s_axis_mem_read_data[1].ready),
 .s_axis_read_data_TDATA(s_axis_mem_read_data[1].data),
 .s_axis_read_data_TKEEP(s_axis_mem_read_data[1].keep),
 .s_axis_read_data_TLAST(s_axis_mem_read_data[1].last),
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
    .user_clk(user_clk),
    .user_aresetn(user_aresetn),
    
     // AXI Lite Master Interface connections
    .s_axil         (s_axil),

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