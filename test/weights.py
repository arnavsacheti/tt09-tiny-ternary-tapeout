
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

  async def drive_weights(self, start = 1):
    assert (0 < self.n <= self.MAX_IN_LEN)
    assert (0 < self.m <= self.MAX_OUT_LEN)
    out = 0
    self.dut.ui_in.value  = 0x00
    self.dut.uio_in.value = 0x00
    # await RisingEdge(self.dut.clk)
    rows = []
    for i in range(self.n//2):
      rows.append(i * 2)
    for i in range(self.n//2):
      rows.append(i * 2 + 1)
    self.dut._log.info(f"Rows: {rows}")
    for n in rows:
      row: list[int] = self.weights[n]
      row_bits = 0
      for i, val in enumerate(row):
        msb_val, lsb_val = self.mapping[val]
        row_bits |= (msb_val & 0b1) << (i)*2 + 1 # len(row) - 1 - 
        row_bits |= (lsb_val & 0b1) << (i)*2     # len(row) - 1 - 
      out = (out << (28)) | row_bits  
      self.dut._log.info(f"Setting [row: {row}, bits: {bin(row_bits)}] {n}")
      # self.dut._log.info(f"Pred weights {n}, vals {hex(out)}")
      self.dut.ui_in.value  = (row_bits & 0xFF00) >> 8
      self.dut.uio_in.value = (row_bits & 0XFF)
      await RisingEdge(self.dut.clk)
      # self.dut._log.info(f"Wrote [28bits: {self.dut.tt_um_t3_inst.tt_um_load_inst.input_to_sr.value}], {n}")

    # self.dut._log.info(f"Pred weights {hex(out)}")
    self.dut.ui_in.value  = 0
    self.dut.uio_in.value = 0
    
      
  async def set_weights(self, weights: list[list[int]], start = 0):
    self.weights = weights
    self.n = len(self.weights)
    self.m = len(self.weights[0])
    await self.drive_weights(start)

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
    
