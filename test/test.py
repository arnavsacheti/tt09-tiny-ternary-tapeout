# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

from weights import Weights
from Vecs import Vecs

import numpy as np

MAX_IN_LEN = 8
MAX_OUT_LEN = 4

@cocotb.test()
async def test_load_weights(dut) -> None:
    dut._log.info("Start")

    # Set the clock period to 20 ns (50MHz)
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    dut._log.info("Test project behavior for loading weights")

    # Set the input values you want to test
    weights = Weights(dut)
    values = [-1, 0, 1] # 
    w = np.random.choice(values, size=(MAX_OUT_LEN, MAX_IN_LEN)).tolist()
    await weights.set_weights(w)

    await ClockCycles(dut.clk, 4)



@cocotb.test()
async def test_vector(dut) -> None:
    dut._log.info("Start")

    # Set the clock period to 20 ns (50MHz)
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    dut._log.info("Test project behavior when driving a single vector")

    # Set the input values you want to test
    weights = Weights(dut)
    values = [-1, 0, 1] # 
    w = np.random.choice(values, size=(MAX_OUT_LEN, MAX_IN_LEN)).tolist()
    await weights.set_weights(w)

    vecs = Vecs(dut, w)
    await vecs.drive_vecs()

@cocotb.test()
async def test_vector_long(dut) -> None:
    dut._log.info("Start")

    # Set the clock period to 20 ns (50MHz)
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    dut._log.info("Testing project behavior when driving 100 subsequent vectors")

    # Set the input values you want to test
    weights = Weights(dut)
    values = [-1, 0, 1] # 
    w = np.random.choice(values, size=(MAX_OUT_LEN, MAX_IN_LEN)).tolist()
    await weights.set_weights(w)

    vecs = Vecs(dut, w)
    await vecs.drive_vecs(runs=50_000)