import cocotb
import numpy as np
from cocotb.triggers import RisingEdge
import random

class Vecs:  
  def __init__(self, dut, weights: list[list[int]] | None =None):
    self.dut = dut
    self.weights: list[list[int]] = weights if weights else []
    self.vecs_in = []
    self.temp = []
    self.vecs_out = []
    self.N = len(self.weights)
    self.M = len(self.weights[0])

  async def drive_vecs(self, runs = 1, enabled = False):
    if (not enabled):
      self.dut.uio_in.value = (runs & 0xF) # set the number of runs
      self.dut.ui_in.value  = (0xF << 4) # set the control word

    await RisingEdge(self.dut.clk)
    pipeline_out = False
    for run in range(runs):
      await self.gen_vecs(set = True)
      for cycle in range(int(self.N/2)+(self.N%2)):
        self.dut.ui_in.value  = self.vecs_in[cycle*2]
        self.dut.uio_in.value = self.vecs_in[cycle*2+1] if (cycle*2+1) < len(self.vecs_in) else 0
        await RisingEdge(self.dut.clk)
        if (pipeline_out==True) :
          assert self.prev[cycle] == self.dut.uo_out.value.signed_integer
      pipeline_out = True
    for cycle in range(self.M):
      self.dut.ui_in.value  = 0x00
      self.dut.uio_in.value = 0x00
      await RisingEdge(self.dut.clk)
      assert self.vecs_out[cycle] == self.dut.uo_out.value.signed_integer


  async def gen_vecs(self, set = False):
    self.prev = [val for val in self.vecs_out]
    self.vecs_in.clear()
    for i in range(self.N): # generate the correct number of input vecs
      self.vecs_in.append(random.randint(-128, 127))
    self.vecs_out = [0 for i in range(self.M)]
    for row in range(self.N):
      for col in range(self.M):
        self.vecs_out[col] += self.vecs_in[row] * self.weights[row][col]
        self.vecs_out[col] = ((self.vecs_out[col] + 128) % 256) - 128
    self.dut._log.info(f"input:  {self.vecs_in}")
    # self.dut._log.info(self.weights)
    self.dut._log.info(f"output: {self.vecs_out}")