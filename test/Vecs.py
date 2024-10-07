import cocotb
import numpy as np
from cocotb.triggers import RisingEdge
import random

class Vecs:  
  def __init__(self, dut, weights: list[list[int]] | None =None):
    self.dut = dut
    self.weights: list[list[int]] = weights if weights else []
    self.vecs_in = []
    self.vecs_out = []
    self.N = len(self.weights)
    self.M = len(self.weights[0])

  async def drive_vecs(self, runs = 1):
    pipeline_out = False
    for run in runs:
      for cycle in range(self.N/2):
        await RisingEdge(self.dut.clk)
        self.dut.ui_in.value  = self.vecs_in[cycle*2] & 0xFF
        self.dut.uio_in.value = self.vecs_in[cycle*2+1] & 0xFF
        if (pipeline_out) :
          assert dut.uo_out.value == self.vecs_out[cycle]
      pipeline_out = True
      self.gen_vecs()
    for cycle in range(self.M):
      await RisingEdge(self.dut.clk)
      assert dut.uo_out.value == self.vecs_out[cycle]

  async def set_weights(self, weights: list[list[int]]):
    self.weights = weights
    self.N = len(self.weights)
    self.M = len(self.weights[0])
    await self.drive_weights()

  async def gen_vecs(self):
    for i in range(self.N): # generate the correct number of input vecs
      self.vecs_in.append(random.randint(-128, 127))
    self.vecs_out = [0 for i in range(self.M)]
    for row in range(self.N):
      for col in range(self.M):
        self.vecs_out[col] += self.vecs_in[row] * self.weights[row][col]
        self.vecs_out[col] = max(-128, min(self.vecs_out[col], 127))
    self.dut._log.info(self.vecs_in)
    self.dut._log.info(self.weights)
    self.dut._log.info(self.vecs_out)