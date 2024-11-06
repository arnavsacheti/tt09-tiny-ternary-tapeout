import cocotb
import numpy as np

from cocotb.triggers import RisingEdge
from cocotb.binary import BinaryValue, BinaryRepresentation

import random

class Vecs:  
  def __init__(self, dut, weights: list[list[int]]):
    self.dut = dut
    self.weights = weights

    self.vecs_in = []
    self.vecs_out = []

    self.M = len(self.weights)
    self.N = len(self.weights[0])

  async def drive_vecs(self, runs = 1):
    uo_output = None
    
    for run in range(runs):
      self.gen_vecs(set = True)
      self.dut._log.info(f"Starting Run {run + 1}")
      
      # Cycle through each bit in the input vector
      for i in range(8):
        ui_input = 0
        for n in range(self.N):
          ui_input = BinaryValue((ui_input << 1) | ((self.vecs_in[n] >> i) & 0b1), n_bits=16, bigEndian=False, binaryRepresentation=BinaryRepresentation.UNSIGNED)

        self.dut._log.info(f"ui_input for bit {i}: {ui_input}")

        self.dut.ui_in.value  = (ui_input & 0xFF00) >> 8  # higher 8 bits
        self.dut.uio_in.value =  ui_input & 0x00FF        # lower 8 bits
        await RisingEdge(self.dut.clk)
        
        if uo_output is not None:
          assert uo_output == self.dut.uo_out.value

        uo_output = 0
        for m in range(self.M):
          uo_output = BinaryValue(uo_output | (((self.vecs_out[m] >> i) & 0b1) << m), n_bits=8, bigEndian=False, binaryRepresentation=BinaryRepresentation.UNSIGNED)
        self.dut._log.info(f"uo_output for bit {i}: {uo_output}")

    await RisingEdge(self.dut.clk)
    assert uo_output == self.dut.uo_out.value

  def gen_vecs(self, set = False):
    self.prev = [val for val in self.vecs_out]
    self.vecs_in  = [0 for i in range(self.N)]
    self.vecs_out = [0 for i in range(self.M)]

    # Generate Input Vector
    for i in range(self.N): # generate the correct number of input vecs
      self.vecs_in[i] = BinaryValue(random.randint(-128, 127), n_bits=8, bigEndian=False, binaryRepresentation=BinaryRepresentation.TWOS_COMPLEMENT)

    # Generate Output Vector
    for row in range(self.M):
      for col in range(self.N):
        # self.vecs_out[row] = BinaryValue(self.vecs_out[row] + (self.vecs_in[col] * self.weights[row][col]), n_bits=8, bigEndian=False, binaryRepresentation=BinaryRepresentation.TWOS_COMPLEMENT)
        self.vecs_out[row] += self.vecs_in[col] * self.weights[row][col]
        self.vecs_out[row] = ((self.vecs_out[row] + 128) % 256) - 128
      self.vecs_out[row] = BinaryValue(self.vecs_out[row], n_bits=8, bigEndian=False, binaryRepresentation=BinaryRepresentation.TWOS_COMPLEMENT)

    self.dut._log.info(f"input:  {self.vecs_in}")
    self.dut._log.info(f"output: {self.vecs_out}")
    # for row in range(self.N):
    #   for col in range(self.M):
    #     self.vecs_out[col] += self.vecs_in[row] * self.weights[row][col]
    #     self.vecs_out[col] = ((self.vecs_out[col] + 128) % 256) - 128
