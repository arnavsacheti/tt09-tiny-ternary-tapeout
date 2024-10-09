from ast import match_case
import cocotb
from cocotb.triggers import RisingEdge

class Weights:
  MAX_IN_LEN = 16
  MAX_OUT_LEN = 8

  mapping = {
    1: (0, 1), 
    0: (0, 0), 
    -1: (1, 1)
  }
  
  def __init__(self, dut, weights: list[list[int]] | None =None):
    self.dut = dut
    self.weights: list[list[int]] = weights if weights else [[]]
    self.n = len(self.weights)
    self.m = len(self.weights[0])

  async def drive_weights(self):
    assert (0 < self.n <= self.MAX_IN_LEN)
    assert (0 < self.m <= self.MAX_OUT_LEN)

    self.dut.ui_in.value  = (0xA << 4) + ((self.n-1) & 0xF)
    self.dut.uio_in.value = ((self.m-1) & 0x7) << 5
    await RisingEdge(self.dut.clk)

    for m in range(self.m):
      col: list[int] = [row[m] for row in self.weights]
      msb: int = 0
      lsb: int = 0
      for i, val in enumerate(col):
        msb_val, lsb_val = self.mapping[val]
        msb |= (msb_val & 0b1) << i
        lsb |= (lsb_val & 0b1) << i
        # self.dut._log.info(f"for val {val}, msb {bin(msb)}, lsb {bin(msb)}")
      
      # self.dut._log.info(f"Setting [col: {col}, MSB: {bin(msb)},  LSB: {bin(lsb)}]")
      self.dut.ui_in.value  = (msb & 0xFF00) >> 8
      self.dut.uio_in.value = (msb & 0XFF)
      await RisingEdge(self.dut.clk)

      self.dut.ui_in.value  = (lsb & 0xFF00) >> 8
      self.dut.uio_in.value = (lsb & 0XFF)
      await RisingEdge(self.dut.clk)
      
  async def set_weights(self, weights: list[list[int]]):
    self.weights = weights
    self.n = len(self.weights)
    self.m = len(self.weights[0])
    await self.drive_weights()

  async def check_weights(self) -> bool:
    # Array packed [High: Low]
    uo_weights = await self.get_weights()
    check = self.weights == uo_weights
    if not check:
      self.dut._log.info(f"Weights Matrix did not match: [exp: {self.weights}, act: {uo_weights}]")
    return check
  
  
  async def get_weights(self) -> list[list[int]]:
    # Array packed [High: Low]
    weights = []

    self.dut.ui_in.value  = (0xB << 4)
    self.dut.uio_in.value = 0
    await RisingEdge(self.dut.clk)
    self.dut.ui_in.value  = 0
    self.dut.uio_in.value = 0
    await RisingEdge(self.dut.clk)

    for n in range(self.n):
      await RisingEdge(self.dut.clk)
      msb = self.dut.uo_out.value

      await RisingEdge(self.dut.clk)
      lsb = self.dut.uo_out.value

      row = []
      for m in range (self.m):
        val = (msb[self.MAX_OUT_LEN - m - 1].integer << 1) | lsb[self.MAX_OUT_LEN - m - 1].integer
        if val >= 2:  # 2 is binary '10', which represents -2 in 2-bit signed int
          val -= 4
        row.append(val)

      weights.append(row)
      # self.dut._log.info(f"Reading [row: {row}, MSB: {msb},  LSB: {lsb}]")

    return weights

  async def __setitem__(self, key, value):
    if isinstance(key, tuple) and isinstance(key[0], slice) and isinstance(key[1], slice):
      # Handle a 2D slice (block update)
      row_slice, col_slice = key
      row_indices = range(*row_slice.indices(len(self.array)))
      col_indices = range(*col_slice.indices(len(self.array[0])))
      for i, row in enumerate(row_indices):
        for j, col in enumerate(col_indices):
          self.weights[row][col] = value[i][j]
    elif isinstance(key, tuple) and len(key) == 2:  # Handle 2D element access
      row, col = key
      self.weights[row][col] = value
      
    await self.drive_weights()

  def __getitem__(self, key):
    if isinstance(key, tuple) and len(key) == 2:  # Handle 2D access (e.g., dut_array[row, col])
      row, col = key
      return self.weights[row][col]
    else:
      raise ValueError("Invalid index for 2D array.")
    