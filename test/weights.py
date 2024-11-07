
from ast import match_case
import cocotb
from cocotb.triggers import RisingEdge
from cocotb.binary import BinaryValue, BinaryRepresentation

class Weights:
  MAX_IN_LEN = 12
  MAX_OUT_LEN = 12

  mapping = {
    1: (0, 1), 
    0: (0, 0), 
    -1: (1, 1)
  }
  
  def __init__(self, dut, weights: list[list[int]] | None =None, bit_width: int = 16):
    self.dut = dut
    self.weights: list[list[int]] = weights if weights else [[]]
    self.m = len(self.weights)
    self.n = len(self.weights[0])
    self.bit_width = bit_width

  async def drive_weights(self):
    assert (0 < self.n <= self.MAX_IN_LEN)
    assert (0 < self.m <= self.MAX_OUT_LEN)

    self.dut.ui_in.value  = BinaryValue(self.bit_width-1, n_bits=8, bigEndian=False, binaryRepresentation=BinaryRepresentation.UNSIGNED)
    self.dut.uio_in.value = 0x0
    await RisingEdge(self.dut.clk)

    self.dut._log.info(f"Setting weights: {self.weights}")
    rows = []

    for row in self.weights:
      msb = 0
      lsb = 0
      for cell in row:
        if (cell == 1):
          msb = (msb << 1) | 0b0
          lsb = (lsb << 1) | 0b1
        elif (cell == 0):
          msb = (msb << 1) | 0b0
          lsb = (lsb << 1) | 0b0
        elif (cell == -1):
          msb = (msb << 1) | 0b1
          lsb = (lsb << 1) | 0b1
      msb = BinaryValue(msb, n_bits=self.MAX_IN_LEN, bigEndian=False, binaryRepresentation=BinaryRepresentation.UNSIGNED)
      lsb = BinaryValue(lsb, n_bits=self.MAX_IN_LEN, bigEndian=False, binaryRepresentation=BinaryRepresentation.UNSIGNED)
      rows.append((msb, lsb))

    self.dut._log.info(f"Rows: {rows}")

    for row in rows[::-1]:
      self.dut._log.info(f"Loading Row into weight: {row}")
      msb, lsb = row

      self.dut.ui_in.value  = (msb & 0xFF0) >> 4
      self.dut.uio_in.value = (msb & 0X00F) << 4
      await RisingEdge(self.dut.clk)

      self.dut.ui_in.value  = (lsb & 0xFF0) >> 4
      self.dut.uio_in.value = (lsb & 0X00F) << 4
      await RisingEdge(self.dut.clk)

    self.dut.ui_in.value  = 0
    self.dut.uio_in.value = 0

  async def set_weights(self, weights: list[list[int]]):
    self.weights = weights
    self.m = len(self.weights)
    self.n = len(self.weights[0])
    await self.drive_weights()

  async def check_weights(self) -> bool:
    # Array packed [High: Low]
    load_weights = self.dut.tt_um_t3_inst.load_weights.value
    print(load_weights)
    check = True

    for i in range(self.n):
      for j in range(self.m):
        idx = (2 * ((self.MAX_IN_LEN * self.MAX_OUT_LEN) - ((i*self.MAX_OUT_LEN) + j))) - 1
        load_weight = load_weights[idx - 1: idx]
        if (not load_weight.is_resolvable) or (self.weights[i][j] != load_weight.signed_integer):
          self.dut._log.info(f"Load weights value {load_weight} at ({i}, {j}) didn't match expected value {self.weights[i][j]}")
          check = False
        
    self.dut._log.info(self.get_weights())
    return check
  
  
  async def get_weights(self) -> list[list[int]]:
    # Array packed [High: Low]
    load_weights = self.dut.tt_um_t3_inst.load_weights.value
    weights = [[0] * self.m for _ in range(self.n)]

    for i in range(self.n):
      for j in range(self.m):
        idx = (2 * ((self.MAX_IN_LEN * self.MAX_OUT_LEN) - ((i*self.MAX_OUT_LEN) + j))) - 1
        load_weight = load_weights[idx - 1: idx]
        if not load_weight.is_resolvable:
          self.dut._log.warn(f"Load weights value {load_weight} at ({i}, {j}) not resolvable")
        else:
          weights[i][j] = load_weight.signed_integer
        
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
    
