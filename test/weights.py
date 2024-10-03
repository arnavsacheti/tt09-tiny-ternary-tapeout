from ast import match_case
import cocotb
from cocotb.triggers import RisingEdge

class Weights:
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
    assert (0 < self.n <= 16)
    assert (0 < self.m <= 8)

    await RisingEdge(self.dut.clk)
    self.dut.ui_in.value  = (0xA << 4) + ((self.n-1) & 0xF)
    self.dut.uio_in.value = ((self.m-1) & 0x7) << 5

    for m in range(self.m):
      col: list[int] = [row[m] for row in self.weights]
      msb: int = 0
      lsb: int = 0
      for i, val in enumerate(col):
        msb_val, lsb_val = self.mapping[val]
        msb |= (msb_val & 0b1) << i
        lsb |= (lsb_val & 0b1) << i
      
      # self.dut._log.info(f"Setting [col: {col}, MSB: {bin(msb)},  LSB: {bin(lsb)}]")

      await RisingEdge(self.dut.clk)
      self.dut.ui_in.value  = (msb & 0xF0) >> 4
      self.dut.uio_in.value = (msb & 0XF)

      await RisingEdge(self.dut.clk)
      self.dut.ui_in.value  = (lsb & 0xF0) >> 4
      self.dut.uio_in.value = (lsb & 0XF)

    await RisingEdge(self.dut.clk)
    self.dut.ui_in.value  = 0
    self.dut.uio_in.value = 0
      
  async def set_weights(self, weights: list[list[int]]):
    self.weights = weights
    self.n = len(self.weights)
    self.m = len(self.weights[0])
    await self.drive_weights()

  def check_weights(self) -> bool:
    for i in range(self.n):
      for j in range(self.m):
        w = self.dut.tt_um_t3_inst.load_weights.value[(i*8) + j]
        if self.weights[i][j] != w.signed_integer:
          self.dut._log.info(f"Load weights value {w} at ({i}, {j}) didn't match expected value {self.weights[i][j]}")
          return False
        
    return True

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
    