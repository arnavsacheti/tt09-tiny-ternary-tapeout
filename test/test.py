# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

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
    values = [-1, 0, 1]
    w = np.random.choice(values, size=(16, 8)).tolist()
    await weights.set_weights(w)

    # Wait for one clock cycle to see the output values
    await ClockCycles(dut.clk, 2) # done should now be high, mult is now running

    vecs = Vecs(dut, w)
    await vecs.gen_vecs()
    await ClockCycles(dut.clk, 2)
    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    assert dut.uo_out.value == 0

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
