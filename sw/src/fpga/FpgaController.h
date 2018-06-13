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
#ifndef FPGA_CONTROLLER_HPP
#define FPGA_CONTROLLER_HPP

#include <stdio.h>
#include <unistd.h>
#include <byteswap.h>
#include <errno.h>
#include <iostream>
#include <fcntl.h>
#include <inttypes.h>
#include <cstdint>
#include <string>
#include <mutex>

#include <sys/types.h>
#include <sys/mman.h>

#define MAP_SIZE (32*1024UL)

/* ltoh: little to host */
/* htol: little to host */
#if __BYTE_ORDER == __LITTLE_ENDIAN
#  define ltohl(x)       (x)
#  define ltohs(x)       (x)
#  define htoll(x)       (x)
#  define htols(x)       (x)
#elif __BYTE_ORDER == __BIG_ENDIAN
#  define ltohl(x)     __bswap_32(x)
#  define ltohs(x)     __bswap_16(x)
#  define htoll(x)     __bswap_32(x)
#  define htols(x)     __bswap_16(x)
#endif


namespace fpga {

enum class memoryOp : uint8_t { READ=0, WRITE=1 };
enum class ctrlAddr : uint32_t { TLB = 2,
                                 DMA_BENCH = 3,
                                 BOARDNUM = 7,
                                 IPADDR = 8,
                                 DMA_READS = 10,
                                 DMA_WRITES = 11,
                                 DEBUG = 12,
                                 DMA_DEBUG = 13,
                                 DMA_BENCH_CYCLES = 14,
                              };
static const uint32_t numDebugRegs = 2;
static const std::string RegNames[] = {"TLB Miss counter",
                                       "TLB Page Boundary crossing counter",
                                       };
static const uint32_t numDmaDebugRegs = 8;
static const std::string DmaRegNames[] = {"DMA write cmd counter",
                                          "DMA write word counter",
                                          "DMA write pkg counter",
                                          "DMA write length counter",
                                          "DMA read cmd counter",
                                          "DMA read word counter",
                                          "DMA read pkg counter",
                                          "DMA read length counter",
                                          };


class FpgaController
{
   public:
      FpgaController(int  fd);
      ~FpgaController();
      /*static fpgaManger& getInstance()
      {
         static fpgaManger instance;
         return instance;
      }*/
      void writeTlb(unsigned long vaddr, unsigned long paddr, bool isBase);
      uint64_t runSeqWriteBenchmark(uint64_t baseAddr, uint64_t memorySize, uint32_t numberOfAcceses, uint32_t chunkLength);
      uint64_t runSeqReadBenchmark(uint64_t baseAddr, uint64_t memorySize, uint32_t numberOfAcceses, uint32_t chunkLength);
      uint64_t runRandomWriteBenchmark(uint64_t baseAddr, uint64_t memorySize, uint32_t numberOfAcceses, uint32_t chunkLength, uint32_t strideLength);
      uint64_t runRandomReadBenchmark(uint64_t baseAddr, uint64_t memorySize, uint32_t numberOfAcceses, uint32_t chunkLength, uint32_t strideLength);

      void setIpAddr(uint32_t addr);
      void setBoardNumber(uint8_t num);
      void resetDmaReads();
      uint64_t getDmaReads();
      void resetDmaWrites();
      uint64_t getDmaWrites();
      void printDebugRegs();
      void printDmaDebugRegs();

   private:
      uint64_t runDmaBenchmark(uint64_t baseAddr, uint64_t memorySize, uint32_t  numberOfAccesses, uint32_t chunkLength, uint32_t strideLength, memoryOp op);

      void writeReg(ctrlAddr addr, uint8_t value);
      void writeReg(ctrlAddr addr, uint32_t value);
      uint32_t readReg(ctrlAddr addr);

   public:
      FpgaController(FpgaController const&)     = delete;
      void operator =(FpgaController const&) = delete;
   private:
   void*  m_base;
   
   static std::mutex  ctrl_mutex;
};

} /* namespace fpga */

#endif
