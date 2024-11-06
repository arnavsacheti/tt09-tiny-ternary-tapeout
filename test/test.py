# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

from weights import Weights
from Vecs import Vecs

import numpy as np

MAX_IN_LEN = 10
MAX_OUT_LEN = 5

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
    dut._log.info("Test Weights behavior")

    # Set the input values you want to test
    weights = Weights(dut)
    values = [-1, 0, 1] # 
    w = np.random.choice(values, size=(MAX_IN_LEN, MAX_OUT_LEN)).tolist()
    await weights.set_weights(w)
    
@cocotb.test()
async def test_single_vector(dut) -> None:
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
    dut._log.info("Test Singe Vector behavior")

    # Set the input values you want to test
    weights = Weights(dut)
    values = [-1, 0, 1] # 
    w = np.random.choice(values, size=(MAX_IN_LEN, MAX_OUT_LEN)).tolist()
    await weights.set_weights(w)

    vecs = Vecs(dut, w)
    await vecs.drive_vecs()


@cocotb.test()
async def test_piplined(dut) -> None:
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
    dut._log.info("Test Pipeline behavior")

    # Set the input values you want to test
    weights = Weights(dut)
    values = [-1, 0, 1] # 
    w = np.random.choice(values, size=(MAX_IN_LEN, MAX_OUT_LEN)).tolist()
    await weights.set_weights(w)

    vecs = Vecs(dut, w)
    await vecs.drive_vecs(runs=5_000)


@cocotb.test()
async def test_pause(dut) -> None:
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
    dut._log.info("Test Pause behavior")

    # Set the input values you want to test
    weights = Weights(dut)
    values = [-1, 0, 1] # 
    w = np.random.choice(values, size=(MAX_IN_LEN, MAX_OUT_LEN)).tolist()
    await weights.set_weights(w)

    vecs = Vecs(dut, w)
    await vecs.drive_vecs(runs=1_000)
    dut._log.info("Pausing")
    await ClockCycles(dut.clk, 5)
    await vecs.drive_vecs(runs=1_000)

@cocotb.test()
async def test_reset(dut) -> None:
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
    dut._log.info("Test Reset behavior")

    # Set the input values you want to test
    weights = Weights(dut)
    values = [-1, 0, 1] # 
    w = np.random.choice(values, size=(MAX_IN_LEN, MAX_OUT_LEN)).tolist()
    await weights.set_weights(w)

    vecs = Vecs(dut, w)
    await vecs.drive_vecs(runs=5_000)

    
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    await ClockCycles(dut.clk, 10)
    w = np.zeros(shape=(MAX_IN_LEN, MAX_OUT_LEN)).tolist()

    vecs = Vecs(dut, w)
    await vecs.drive_vecs(runs=5_000)
