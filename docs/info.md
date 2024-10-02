<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

The proposed configurable Matrix Multiplier with Ternary weights for MatMul-free LLMs operates in several stages: configuration, multiplication, and output.
During the configuration stage, parameters for the weight matrix are loaded, taking 1 cycle for loading parameters and 16 cycles for loading the weight matrix itself, at 16 bits per cycle. This results in a total configuration time of 340ns.
The multiplication stage involves performing a series of select, add, and accumulate operations. These operations are pipelined across the weight matrix and are completed in 8 clock cycles, resulting in a latency of 160ns and a throughput of 1.55 Gops.
The output stage can output either accumulated values or the weight matrix serially. Outputting accumulated values takes 4 cycles (160ns), while outputting weights takes 17 cycles (340ns).

## How to test

Use external MCU to load weights, then drive input vector to get output

## External hardware

Raspberry PI or similar external MCU
