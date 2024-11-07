import cocotb
import numpy as np

from cocotb.triggers import RisingEdge
from cocotb.binary import BinaryValue, BinaryRepresentation

import random

class Vecs:  
  MAX_IN_LEN = 12
  MAX_OUT_LEN = 12

  def __init__(self, dut, weights: list[list[int]], bit_width: int = 16):
    self.dut = dut
    self.weights = weights

    self.vecs_in = []
    self.vecs_out = []

    self.M = len(self.weights)
    self.N = len(self.weights[0])
    self.bit_width = bit_width
    self.bound = int(2 ** (self.bit_width - 1))

  async def drive_vecs(self, runs = 1):
    uo_output = None
    
    for run in range(runs):
      self.gen_vecs(set = True)
      self.dut._log.info(f"Starting Run {run + 1}")
      
      # Cycle through each bit in the input vector
      for i in range(self.bit_width):
        ui_input = 0
        for n in range(self.N):
          ui_input = BinaryValue((ui_input << 1) | ((self.vecs_in[n] >> i) & 0b1), n_bits=self.MAX_IN_LEN, bigEndian=False, binaryRepresentation=BinaryRepresentation.UNSIGNED)

        self.dut._log.info(f"ui_input for bit {i}: {ui_input}")

        self.dut.ui_in.value  = (ui_input & 0xFF0) >> 4  # higher 8 bits
        self.dut.uio_in.value = (ui_input & 0x00F) << 4        # lower 4 bits
        await RisingEdge(self.dut.clk)

        if uo_output is not None:
          assert uo_output == self.dut.uo_out.value << 4 | (self.dut.uio_out.value & 0x0F)

        uo_output = 0
        for m in range(self.M):
          uo_output = BinaryValue(uo_output | (((self.vecs_out[m] >> i) & 0b1) << m), n_bits=self.MAX_OUT_LEN, bigEndian=False, binaryRepresentation=BinaryRepresentation.UNSIGNED)
        self.dut._log.info(f"uo_output for bit {i}: {uo_output}")

    await RisingEdge(self.dut.clk)
    assert uo_output == self.dut.uo_out.value << 4 | (self.dut.uio_out.value & 0x0F)

  def gen_vecs(self, set = False):
    self.prev = [val for val in self.vecs_out]
    self.vecs_in  = [0 for i in range(self.N)]
    self.vecs_out = [0 for i in range(self.M)]

    # Generate Input Vector
    for i in range(self.N): # generate the correct number of input vecs
      self.vecs_in[i] = BinaryValue(random.randint(-self.bound, self.bound - 1), n_bits=self.bit_width, bigEndian=False, binaryRepresentation=BinaryRepresentation.TWOS_COMPLEMENT)

    # Generate Output Vector
    for row in range(self.M):
      for col in range(self.N):
        # self.vecs_out[row] = BinaryValue(self.vecs_out[row] + (self.vecs_in[col] * self.weights[row][col]), n_bits=8, bigEndian=False, binaryRepresentation=BinaryRepresentation.TWOS_COMPLEMENT)
        self.vecs_out[row] += self.vecs_in[col] * self.weights[row][col]
        self.vecs_out[row] = ((self.vecs_out[row] + self.bound) % (2*self.bound)) - self.bound
      self.vecs_out[row] = BinaryValue(self.vecs_out[row], n_bits=self.bit_width, bigEndian=False, binaryRepresentation=BinaryRepresentation.TWOS_COMPLEMENT)

    self.dut._log.info(f"input:  {self.vecs_in}")
    self.dut._log.info(f"output: {self.vecs_out}")
