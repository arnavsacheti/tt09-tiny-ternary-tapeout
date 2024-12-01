# Tiny Ternary Tapeout Project Documentation

**Authors:** Jack Adiletta, Arnav Sacheti  
**Date:** [Project Repository](https://github.com/arnavsacheti/tt09-tiny-ternary-tapeout)

---

## Inspiration

The inspiration for this Tiny Tapeout project comes from the *Scalable MatMul-free Language Modeling* paper, which explores a novel approach to language modeling that bypasses traditional matrix multiplication (MatMul) operations. Standard neural network models, especially those used for language processing, rely heavily on matrix multiplications to handle complex data transformations. These operations can be computationally expensive and power-intensive, especially at large scales.

The key insight of this research is to leverage alternative mathematical structures and sparse representations, reducing the need for resource-heavy MatMul operations while still enabling efficient language processing. By multiplying by only 1, 0, or -1, the condensed architecture opens up possibilities for more energy-efficient, scalable models.

This Tiny Tapeout project aims to implement and experiment with these principles on a small scale, designing circuitry that emulates the core ideas of this MatMul-free approach. This can pave the way for more efficient and compact language models in embedded systems, potentially transforming real-time, on-device language processing applications.

---

## How it Works

The `tt_um_tiny_ternary_tapeout.v` module is designed to perform matrix multiplication using a pipelined architecture. Here's how it works.

### 1. Loading the Weights (`tt_um_load.v`)

The module starts by loading the 10 by 5 weight matrix. These weights (1, 0, or -1) are stored in an internal register array (2-bit elements: `01`, `00`, or `11`) and are used for matrix multiplication operations. The weights are stored in a continuously looping shift register, requiring no complex muxing structures for data routing when loading or computing. Removing all random-access muxes uses fewer gates and provides large area savings.

### 2. Matrix Multiplication (`tt_um_mult.v`)

The module performs Ternary matrix multiplication by multiplying two integers by two weights from each column of the weight matrix and accumulating them with the prior result from the column each cycle. The rotating shift register array ensures that two new weights are routed to the Ternary multipliers and adders for each column each cycle. The module employs both the 8 inputs and 8 input-outputs of the Tiny Tapeout chip as a 16-bit input bus for two 8-bit integers. The 8 outputs produce one 8-bit integer per cycle.

### 3. Pipelined Architecture

The module is pipelined, meaning that 10 additions and 10 Ternary Multiplications (`X × 1, 0, or -1`) occur each cycle while a prior result is output. 

- In the first five cycles of operation, two integers are multiplied by 10 weights (5 weights per row, two rows at a time).
- After 5 cycles, the 5, 8-bit outputs are stored and the accumulator values are reset.
- Every successive cycle, two more integers are fed into the module while one of the five values from the prior computation is output, allowing for continuous data processing without interruption.

### 4. Output Stage

After driving all the inputs, the outputs are produced as 8-bit integers. These outputs are one element of the output vector - the result of the vector-Ternary matrix multiplication operation. By leveraging a pipelined architecture, the `tt_um_mult.v` module ensures efficient and continuous data processing, allowing for high-throughput matrix multiplication operations. This design achieves **1.0 GOps at 50 MHz**.

---

## Example: Using a Ternary Array for Efficient Computation

This example demonstrates how a `4 × 2` ternary array can process a `1 × 4` input vector.

### Step 1: Define a Ternary Array

A ternary array is one where each element can take on one of three possible values, commonly `+1`, `0`, or `-1`. These values simplify calculations because instead of performing complex multiplications, you can use additions, subtractions, or ignore the zero entries altogether.

Sample `4 × 2` ternary array:

