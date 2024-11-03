# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

from weights import Weights
from Vecs import Vecs

import numpy as np


@cocotb.test()
async def test_project(dut) -> None:
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
    dut._log.info("Test project behavior")

    # Set the input values you want to test
    weights = Weights(dut)
    values = [-1, 0, 1] # 
    w = np.random.choice(values, size=(10, 5)).tolist()
    await weights.set_weights(w)
    


    vecs = Vecs(dut, w)
    await vecs.drive_vecs(runs=15)

    # test reset

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await weights.set_weights(w)

    await vecs.drive_vecs(runs=15)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    # assert weights.check_weights()

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    dut._log.info("Test project behavior")

    # Set the input values you want to test
    w = np.random.choice(values, size=(10, 5)).tolist()
    await weights.set_weights(w)
    


    vecs = Vecs(dut, w)
    await vecs.drive_vecs(runs=15)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await weights.set_weights(w)

    await vecs.drive_vecs(runs=15)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    # assert weights.check_weights()