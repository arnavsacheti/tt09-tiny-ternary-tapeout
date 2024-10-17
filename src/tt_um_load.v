/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype wire

module tt_um_load # (
  parameter MAX_IN_LEN   = 16, 
  parameter MAX_OUT_LEN  = 8,
  parameter WIDTH        = 2,
  parameter MAX_IN_BITS  = $clog2(MAX_IN_LEN),
  parameter MAX_OUT_BITS = $clog2(MAX_OUT_LEN),
  parameter WIDTH_BITS   = $clog2(WIDTH)
)(
  input                                             clk,        // clock
  input                                             rst_n,      // reset_n - low to reset
  input                                             ena,        // always 1 when the module is selected
  input  [MAX_IN_LEN-1:0]                           ui_input,   // Dedicated inputs
  output [(WIDTH * MAX_IN_LEN * MAX_OUT_LEN) - 1:0] uo_weights, // Loaded in Weights - finished setting one cycle after done
  output                                            uo_done     // Pulse completed load
);

  // integer                                        idx;
  reg [MAX_IN_BITS  + WIDTH_BITS - 1:0]          idx;
  reg [MAX_OUT_BITS + WIDTH_BITS - 1:0]          count;
  reg [(WIDTH * MAX_IN_LEN * MAX_OUT_LEN) - 1:0] weights;
  
  always @(posedge clk) begin
    if(!rst_n) begin
      count <= 'h0;
    end else if (ena) begin
      count <= count + 1;
    end
  end

  always @(ui_input) begin
    if(ena) 
      for (idx = 0; idx < MAX_IN_LEN; idx ++)
        weights[{idx[MAX_IN_BITS-1:0], count}] <= ui_input[idx[MAX_IN_BITS-1:0]];
  end

  assign uo_weights = weights;
  assign uo_done    = count == {3'b111, {WIDTH_BITS{1'b1}}};

endmodule : tt_um_load