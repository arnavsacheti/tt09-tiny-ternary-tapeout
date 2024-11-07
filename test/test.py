# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

from weights import Weights
from Vecs import Vecs

import numpy as np

MAX_IN_LEN = 12
MAX_OUT_LEN = 12

@cocotb.test(stage=0)
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



@cocotb.test(stage=1)
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

@cocotb.test(stage=3)
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
    dut._log.info("Testing project behavior when driving 5000 subsequent vectors")

    # Set the input values you want to test
    weights = Weights(dut)
    values = [-1, 0, 1] # 
    w = np.random.choice(values, size=(MAX_OUT_LEN, MAX_IN_LEN)).tolist()
    await weights.set_weights(w)

    vecs = Vecs(dut, w)
    await vecs.drive_vecs(runs=5_000)

@cocotb.test(stage=2)
async def test_ones(dut) -> None:
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
    dut._log.info("Testing project behavior when setting weights to 1")

    # Set the input values you want to test
    weights = Weights(dut)
    w = np.ones(shape=(MAX_OUT_LEN, MAX_IN_LEN)).tolist()
    await weights.set_weights(w)

    vecs = Vecs(dut, w)
    await vecs.drive_vecs(runs=5_000)
    
@cocotb.test(stage=2)
async def test_neg_ones(dut) -> None:
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
    dut._log.info("Testing project behavior when setting weights to -1")

    # Set the input values you want to test
    weights = Weights(dut)
    w = -np.ones(shape=(MAX_OUT_LEN, MAX_IN_LEN))
    w = w.tolist()
    await weights.set_weights(w)

    vecs = Vecs(dut, w)
    await vecs.drive_vecs(runs=5_000)

async def test_n_bit(dut, bit_width) -> None:
    dut._log.info(f"Testing project behavior when setting diriving input with variable bit width {bit_width}")

    # Set the input values you want to test
    weights = Weights(dut, bit_width=bit_width)
    values = [-1, 0, 1] # 
    w = np.random.choice(values, size=(MAX_OUT_LEN, MAX_IN_LEN)).tolist()
    await weights.set_weights(w)

    vecs = Vecs(dut, w, bit_width=bit_width)
    await vecs.drive_vecs(runs=1_000)


@cocotb.test(stage=3)
async def test_n_bits(dut) -> None:
    dut._log.info("Start")

    # Set the clock period to 20 ns (50MHz)
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    for bits in range(1, 8):
        # Reset
        dut._log.info("Reset")
        dut.ena.value = 1
        dut.ui_in.value = 0
        dut.uio_in.value = 0
        dut.rst_n.value = 0
        await ClockCycles(dut.clk, 2)
        dut.rst_n.value = 1

        await test_n_bit(dut, (1 << bits))