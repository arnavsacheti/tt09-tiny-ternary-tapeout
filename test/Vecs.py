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
    pipeline_out = False
    # self.dut.ui_in.value  = 0x00 # higher 8 bits
    # self.dut.uio_in.value = 0x00 # lower 8 bits
    # await RisingEdge(self.dut.clk)

    for run in range(runs):
      await self.gen_vecs(set = True)
      for cycle in range(self.N//2):
        new_cycle = ((self.N) + cycle*2) % self.N
        self.dut.ui_in.value  = self.vecs_in[new_cycle+1] # higher 8 bits
        self.dut.uio_in.value = self.vecs_in[new_cycle] # lower 8 bits
        # self.dut._log.info(f"Cycle {new_cycle}")
        # self.dut._log.info(f"Inputting [v1: {self.dut.tt_um_t3_inst.tt_um_mult_inst.VecIn.value[8:15].signed_integer}]")
        # self.dut._log.info(f"Inputting [v2: {self.dut.tt_um_t3_inst.tt_um_mult_inst.VecIn.value[0:7].signed_integer}]")
        # self.dut._log.info(f"Reading [row1: {self.dut.tt_um_t3_inst.tt_um_mult_inst.row_data1.value}]")
        # self.dut._log.info(f"Reading [row2: {self.dut.tt_um_t3_inst.tt_um_mult_inst.row_data2.value}]")
        # self.dut._log.info(f"Row num [row: {self.dut.tt_um_t3_inst.tt_um_mult_inst.row.value.integer}]")
        await RisingEdge(self.dut.clk)
        # self.dut._log.info(f"New Temp0: {self.dut.tt_um_t3_inst.tt_um_mult_inst.temp_out.value[0:7].signed_integer}")
        # self.dut._log.info(f"New Pipe0: {self.dut.tt_um_t3_inst.tt_um_mult_inst.pipe_out.value[0:7].signed_integer}")
        if (pipeline_out==True) :
          # pass
          # assert self.prev[cycle] == self.dut.uo_out.value.signed_integer
          if (cycle != 0):
            assert self.prev[cycle-1] == self.dut.uo_out.value.signed_integer
      pipeline_out = True 
    for cycle in range(self.M):
      self.dut.ui_in.value  = 0x00
      self.dut.uio_in.value = 0x00
      await RisingEdge(self.dut.clk)
      # assert self.vecs_out[cycle] == self.dut.uo_out.value.signed_integer
      if (cycle != 0):
        assert self.vecs_out[cycle-1] == self.dut.uo_out.value.signed_integer
      self.dut.rst_n.value = 1
    self.dut.rst_n.value = 0
    await RisingEdge(self.dut.clk)
    self.dut.rst_n.value = 1

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