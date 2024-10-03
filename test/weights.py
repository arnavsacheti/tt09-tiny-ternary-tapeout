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
    self.weights: list[list[int]] = weights if weights else []

  async def drive_weights(self):
    N = len(self.weights)
    M = len(self.weights[0])

    await RisingEdge(self.dut.clk)
    self.dut.ui_in.value  = (0xA << 4) + (N & 0xF)
    self.dut.uio_in.value = (M & 0x7) << 5

    for m in range(M):
      col: list[int] = [row[m] for row in self.weights]
      msb: int = 0
      lsb: int = 0
      for val in col:
        msb_val, lsb_val = self.mapping[val]
        msb = (msb << 1) + msb_val
        lsb = (lsb << 1) + lsb_val 

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
    await self.drive_weights()

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