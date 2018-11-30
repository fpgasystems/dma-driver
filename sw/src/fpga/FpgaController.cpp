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
#include "FpgaController.h"

#include <cstring>
#include <thread>
#include <chrono>

//#define PRINT_DEBUG

using namespace std::chrono_literals;

namespace fpga {

std::mutex FpgaController::ctrl_mutex;

FpgaController::FpgaController(int fd)
{
   //open control devices
   m_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
}

FpgaController::~FpgaController()
{
   if (munmap(m_base, MAP_SIZE) == -1)
   {
      std::cerr << "Error on unmap of control device" << std::endl;
   }
}

void FpgaController::writeTlb(unsigned long vaddr, unsigned long paddr, bool isBase)
{
   std::lock_guard<std::mutex> guard(ctrl_mutex);
#ifdef PRINT_DEBUG
   printf("Writing tlb mapping\n");fflush(stdout);
#endif
   writeReg(dmaCtrlAddr::TLB, (uint32_t) vaddr);
   writeReg(dmaCtrlAddr::TLB, (uint32_t) (vaddr >> 32));
   writeReg(dmaCtrlAddr::TLB, (uint32_t) paddr);
   writeReg(dmaCtrlAddr::TLB, (uint32_t) (paddr >> 32));
   writeReg(dmaCtrlAddr::TLB, (uint32_t) isBase);
#ifdef PRINT_DEBUG
   printf("done\n");fflush(stdout);
#endif
}

uint64_t FpgaController::runDmaSeqWriteBenchmark(uint64_t baseAddr, uint64_t memorySize, uint32_t numberOfAccesses, uint32_t chunkLength)
{
   runDmaBenchmark(baseAddr, memorySize, numberOfAccesses, chunkLength, 0, memoryOp::WRITE);
}

uint64_t FpgaController::runDmaSeqReadBenchmark(uint64_t baseAddr, uint64_t memorySize, uint32_t numberOfAccesses, uint32_t chunkLength)
{
   runDmaBenchmark(baseAddr, memorySize, numberOfAccesses, chunkLength, 0, memoryOp::READ);
}

uint64_t FpgaController::runDmaRandomWriteBenchmark(uint64_t baseAddr, uint64_t memorySize, uint32_t numberOfAccesses, uint32_t chunkLength, uint32_t strideLength)
{
   runDmaBenchmark(baseAddr, memorySize, numberOfAccesses, chunkLength, strideLength, memoryOp::WRITE);
}

uint64_t FpgaController::runDmaRandomReadBenchmark(uint64_t baseAddr, uint64_t memorySize, uint32_t numberOfAccesses, uint32_t chunkLength, uint32_t strideLength)
{
   runDmaBenchmark(baseAddr, memorySize, numberOfAccesses, chunkLength, strideLength, memoryOp::READ);
}

uint64_t FpgaController::runDmaBenchmark(uint64_t baseAddr, uint64_t memorySize, uint32_t numberOfAccesses, uint32_t chunkLength, uint32_t strideLength, memoryOp op)
{
   std::lock_guard<std::mutex> guard(ctrl_mutex);
#ifdef PRINT_DEBUG
   printf("Run dma benchmark\n");fflush(stdout);
#endif

   writeReg(userCtrlAddr::DMA_BENCH, (uint32_t) baseAddr);
   writeReg(userCtrlAddr::DMA_BENCH, (uint32_t) (baseAddr >> 32));
   writeReg(userCtrlAddr::DMA_BENCH, (uint32_t) memorySize);
   writeReg(userCtrlAddr::DMA_BENCH, (uint32_t) (memorySize >> 32));
   writeReg(userCtrlAddr::DMA_BENCH, (uint32_t) numberOfAccesses);
   writeReg(userCtrlAddr::DMA_BENCH, (uint32_t) chunkLength);
   writeReg(userCtrlAddr::DMA_BENCH, (uint32_t) strideLength);
   writeReg(userCtrlAddr::DMA_BENCH, (uint32_t) op);

   //retrieve number of execution cycles
   
   uint64_t lower = 0;
   uint64_t upper = 0;
   do
   {
      std::this_thread::sleep_for(1s);
      lower = readReg(userCtrlAddr::DMA_BENCH_CYCLES);
      upper = readReg(userCtrlAddr::DMA_BENCH_CYCLES);
   } while (lower == 0);
   return ((upper << 32) | lower);


#ifdef PRINT_DEBUG
   printf("done\n");fflush(stdout);
#endif
}

uint64_t FpgaController::runMemSeqWriteBenchmark(uint64_t baseAddr, uint64_t memorySize, uint32_t numberOfAccesses, uint32_t chunkLength)
{
   runMemBenchmark(baseAddr, memorySize, numberOfAccesses, chunkLength, 0, memoryOp::WRITE);
}

uint64_t FpgaController::runMemSeqReadBenchmark(uint64_t baseAddr, uint64_t memorySize, uint32_t numberOfAccesses, uint32_t chunkLength)
{
   runMemBenchmark(baseAddr, memorySize, numberOfAccesses, chunkLength, 0, memoryOp::READ);
}

uint64_t FpgaController::runMemRandomWriteBenchmark(uint64_t baseAddr, uint64_t memorySize, uint32_t numberOfAccesses, uint32_t chunkLength, uint32_t strideLength)
{
   runMemBenchmark(baseAddr, memorySize, numberOfAccesses, chunkLength, strideLength, memoryOp::WRITE);
}

uint64_t FpgaController::runMemRandomReadBenchmark(uint64_t baseAddr, uint64_t memorySize, uint32_t numberOfAccesses, uint32_t chunkLength, uint32_t strideLength)
{
   runMemBenchmark(baseAddr, memorySize, numberOfAccesses, chunkLength, strideLength, memoryOp::READ);
}

uint64_t FpgaController::runMemBenchmark(uint64_t baseAddr, uint64_t memorySize, uint32_t numberOfAccesses, uint32_t chunkLength, uint32_t strideLength, memoryOp op)
{
   std::lock_guard<std::mutex> guard(ctrl_mutex);
#ifdef PRINT_DEBUG
   printf("Run dma benchmark\n");fflush(stdout);
#endif

   writeReg(userCtrlAddr::DDR_BENCH, (uint32_t) baseAddr);
   writeReg(userCtrlAddr::DDR_BENCH, (uint32_t) (baseAddr >> 32));
   writeReg(userCtrlAddr::DDR_BENCH, (uint32_t) memorySize);
   writeReg(userCtrlAddr::DDR_BENCH, (uint32_t) (memorySize >> 32));
   writeReg(userCtrlAddr::DDR_BENCH, (uint32_t) numberOfAccesses);
   writeReg(userCtrlAddr::DDR_BENCH, (uint32_t) chunkLength);
   writeReg(userCtrlAddr::DDR_BENCH, (uint32_t) strideLength);
   writeReg(userCtrlAddr::DDR_BENCH, (uint32_t) op);

   //retrieve number of execution cycles
   
   uint64_t lower = 0;
   uint64_t upper = 0;
   do
   {
      std::this_thread::sleep_for(1s);
      lower = readReg(userCtrlAddr::DDR_BENCH_CYCLES);
      upper = readReg(userCtrlAddr::DDR_BENCH_CYCLES);
   } while (lower == 0);
   return ((upper << 32) | lower);


#ifdef PRINT_DEBUG
   printf("done\n");fflush(stdout);
#endif
}


void FpgaController::setIpAddr(uint32_t addr)
{
   std::lock_guard<std::mutex> guard(ctrl_mutex);

   //writeReg(ctrlAddr::IPADDR, addr);
}

void FpgaController::setBoardNumber(uint8_t num)
{
   std::lock_guard<std::mutex> guard(ctrl_mutex);
   //writeReg(ctrlAddr::BOARDNUM, num);
}

void FpgaController::resetDmaReads()
{
   std::lock_guard<std::mutex> guard(ctrl_mutex);
   writeReg(dmaCtrlAddr::DMA_READS, uint8_t(1));
}

uint64_t FpgaController::getDmaReads()
{
   std::lock_guard<std::mutex> guard(ctrl_mutex);
   uint64_t lower = readReg(dmaCtrlAddr::DMA_READS);
   uint64_t upper = readReg(dmaCtrlAddr::DMA_READS);
   return ((upper << 32) | lower);
}

void FpgaController::resetDmaWrites()
{
   std::lock_guard<std::mutex> guard(ctrl_mutex);
   writeReg(dmaCtrlAddr::DMA_WRITES, uint8_t(1));
}

uint64_t FpgaController::getDmaWrites()
{
   std::lock_guard<std::mutex> guard(ctrl_mutex);
   uint64_t lower = readReg(dmaCtrlAddr::DMA_WRITES);
   uint64_t upper = readReg(dmaCtrlAddr::DMA_WRITES);
   return ((upper << 32) | lower);
}

void FpgaController::printDebugRegs()
{
   std::lock_guard<std::mutex> guard(ctrl_mutex);

   std::cout << "------------ DEBUG ---------------" << std::endl;
   for (int i = 0; i < numDebugRegs; ++i)
   {
      uint32_t reg = readReg(userCtrlAddr::DEBUG);
      std::cout << RegNames[i] << ": " << std::dec << reg << std::endl;
   }
   std::cout << "----------------------------------" << std::endl;
}

void FpgaController::printDmaStatsRegs()
{
   std::lock_guard<std::mutex> guard(ctrl_mutex);

   std::cout << "------------ DMA STATISTICS ---------------" << std::endl;
   for (int i = 0; i < numDmaStatsRegs; ++i)
   {
      uint32_t reg = readReg(dmaCtrlAddr::STATS);
      std::cout << DmaRegNames[i] << ": " << std::dec << reg << std::endl;
   }
   std::cout << "----------------------------------" << std::endl;
}

void FpgaController::printDdrStatsRegs(uint8_t channel)
{
   std::lock_guard<std::mutex> guard(ctrl_mutex);

   std::cout << "------------ DDR" << (uint16_t) channel << " STATISTICS ---------------" << std::endl;
   for (int i = 0; i < numDdrStatsRegs; ++i)
   {
      uint32_t reg = readReg(ddrCtrlAddr::STATS, channel);
      std::cout << "DDR" << (uint16_t) channel << " ";
      std::cout << DdrRegNames[i] << ": " << std::dec << reg << std::endl;
   }
   std::cout << "----------------------------------" << std::endl;
}



/*void FpgaController::writeReg(ctrlAddr addr, uint8_t value)
{
   volatile uint32_t* wPtr = (uint32_t*) (((uint64_t) m_base) + (uint64_t) ((uint32_t) addr << 5));
   uint32_t writeVal = htols(value);
   *wPtr = writeVal;
}*/

void FpgaController::writeReg(userCtrlAddr addr, uint32_t value)
{
   volatile uint32_t* wPtr = (uint32_t*) (((uint64_t) m_base) + userRegAddressOffset + (uint64_t) ((uint32_t) addr << 5));
   uint32_t writeVal = htols(value);
   *wPtr = writeVal;
}

void FpgaController::writeReg(dmaCtrlAddr addr, uint32_t value)
{
   volatile uint32_t* wPtr = (uint32_t*) (((uint64_t) m_base) + dmaRegAddressOffset +  (uint64_t) ((uint32_t) addr << 5));
   uint32_t writeVal = htols(value);
   *wPtr = writeVal;
}


/*void FpgaController::writeReg(ctrlAddr addr, uint64_t value)
{
   uint32_t* wPtr = (uint32_t*) (((uint64_t) m_base) + (uint64_t) ((uint32_t) addr << 5));
   uint32_t writeVal = htols((uint32_t) value);
   *wPtr = writeVal;
   
   writeVal = htols((uint32_t) (value >> 32));
   *wPtr = writeVal;

}*/

uint32_t FpgaController::readReg(userCtrlAddr addr)
{
   volatile uint32_t* rPtr = (uint32_t*) (((uint64_t) m_base) + userRegAddressOffset  + (uint64_t) ((uint32_t) addr << 5));
  return htols(*rPtr);
}

uint32_t FpgaController::readReg(dmaCtrlAddr addr)
{
   volatile uint32_t* rPtr = (uint32_t*) (((uint64_t) m_base) + dmaRegAddressOffset  + (uint64_t) ((uint32_t) addr << 5));
  return htols(*rPtr);
}

uint32_t FpgaController::readReg(ddrCtrlAddr addr, uint8_t channel)
{
   volatile uint32_t* rPtr = (uint32_t*) (((uint64_t) m_base) + ddrRegAddressOffset[channel]  + (uint64_t) ((uint32_t) addr << 5));
  return htols(*rPtr);
}



} /* namespace fpga */
