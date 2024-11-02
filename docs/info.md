<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

The proposed configurable Matrix Multiplier with Ternary weights for MatMul-free LLMs operates in several stages: configuration, multiplication, and output.
During the configuration stage, parameters for the weight matrix are loaded, taking 1 cycle for loading parameters and 16 cycles for loading the weight matrix itself, at 16 bits per cycle. This results in a total configuration time of 340ns.
The multiplication stage involves performing a series of select, add, and output operations. These operations are pipelined across the weight matrix and are completed in 7 clock cycles, resulting in a latency of 160ns and a throughput of 1.4 Gops.

## How to test

To test the Matrix Multiplier with an external MCU like a Raspberry Pi, follow these steps:

1. **Setup**:
  - Connect the Raspberry Pi to the Matrix Multiplier hardware using appropriate GPIO pins.
  - Ensure that the Raspberry Pi has the necessary libraries installed for GPIO manipulation.

2. **Load Weights**:
  - Use the Raspberry Pi to load the weight matrix into the Matrix Multiplier. This can be done by writing a Python script that sends the weight data through the GPIO pins.

3. **Drive Input Vector**:
  - After loading the weights, drive the input vector to the Matrix Multiplier using the Raspberry Pi.

4. **Read Output**:
  - Finally, read the output from the Matrix Multiplier using the Raspberry Pi.

By following these steps, you can use a Raspberry Pi to load weights, drive input vectors, and read outputs from the Matrix Multiplier.

## External hardware

Raspberry PI or similar external MCU
