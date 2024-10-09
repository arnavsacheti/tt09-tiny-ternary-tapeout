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

  async def drive_vecs(self, runs = 1):
    self.dut.ui_in.value  = (0xF << 4)
    await RisingEdge(self.dut.clk)
    temps = [0 for _ in range(self.M)]
    temps_p = [0 for _ in range(self.M)]

    pipeline_out = False

    for run in range(runs):
      await self.gen_vecs(set = True)
      for cycle in range(int(self.N/2)):
        self.dut.ui_in.value  = self.vecs_in[cycle*2]
        self.dut.uio_in.value = self.vecs_in[cycle*2+1]
        await RisingEdge(self.dut.clk)
        intermediate_result = [_.signed_integer for _ in self.dut.tt_um_t3_inst.tt_um_mult_inst.temp_out.value]
        pipe_result = [_.signed_integer for _ in self.dut.tt_um_t3_inst.tt_um_mult_inst.pipe_out.value]
        self.dut._log.info(f"Output val: {intermediate_result}")
        self.dut._log.info(f"Pipe  val: {pipe_result}")
        self.dut._log.info(f"Actual val: {temps_p}")
        # Check
        for col in range(self.M):
          if (cycle != 0): # don't check the last cycle (temp not computed here)
            assert temps_p[col] == intermediate_result[col]
          self.weights[cycle*2].reverse()
          self.weights[cycle*2+1].reverse()
          mult1 = -1 if self.weights[cycle*2][col]== -1 else (1 if self.weights[cycle*2][col] == 1 else 0)
          mult2 = -1 if self.weights[cycle*2+1][col]== -1 else (1 if self.weights[cycle*2+1][col] == 1 else 0)
          self.weights[cycle*2].reverse()
          self.weights[cycle*2+1].reverse()
          temps[col] += self.vecs_in[cycle*2] * mult1
          temps[col] = ((temps[col] + 128) % 256) - 128
          temps[col] += self.vecs_in[cycle*2+1] * mult2
          temps[col] = ((temps[col] + 128) % 256) - 128 
        temps_p = temps
        if (pipeline_out==True) :
          assert self.dut.uo_out.value.signed_integer == self.prev[cycle]
      pipeline_out = True
      temps = [0 for _ in range(len(temps))]
    for cycle in range(self.M):
      self.dut.ui_in.value  = 0x00
      self.dut.uio_in.value = 0x00
      await RisingEdge(self.dut.clk)
      assert self.vecs_out[cycle] == self.dut.uo_out.value.signed_integer


  async def gen_vecs(self, set = False):
    self.prev = []
    if set:
      self.prev = [val for val in self.vecs_out]
    else:
      prev = [val for val in self.vecs_out]
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