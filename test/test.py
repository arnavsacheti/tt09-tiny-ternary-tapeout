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
    # Known Values test
    weights = Weights(dut)
    values = [-1, 0, 1]
    w = np.random.choice(values, size=(16, 8)).tolist()
    await weights.set_weights(w)
    dut.ui_in.value  = 0x00
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)
    assert weights.check_weights()


    vecs = Vecs(dut, w)
    await vecs.drive_vecs(runs=2)

    await ClockCycles(dut.clk, 10)

    
    await weights.set_weights([
        [ 1, 0, 1, 0, 1],
        [ 0, 0, 1, 0, 0],
        [ 0, 1, 0,-1, 0],
        [ 0, 0,-1, 0, 0],
        [-1, 0,-1, 0,-1]
    ])

    # Wait for one clock cycle to see the output values
    await RisingEdge(dut.clk)
    assert weights.check_weights()

    # Randomize the values and test again
    for i in range(2): #Weights.MAX_IN_LEN
        for j in range(2): #Weights.MAX_OUT_LEN
            dut._log.info(f"Testing with Random Array of dim: [{i+1}, {j+1}]")
            weight_matrix = [[random.randint(-1, 1) for _ in range(j+1)] for _ in range (i+1)]
            dut._log.info(weight_matrix)
            await weights.set_weights(weight_matrix, runs=0)
            # Wait for one clock cycle to see the output values
            await RisingEdge(dut.clk)
            assert weights.check_weights()

            vecs = Vecs(dut, weight_matrix)
            await vecs.drive_vecs(runs=1, enabled=False)
            await RisingEdge(dut.clk)

