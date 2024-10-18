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
  input [3:0]           count,
  input                                             rst_n,      // reset_n - low to reset
  input                                             ena,        // always 1 when the module is selected
  input  [MAX_IN_LEN-1:0]                           ui_input,   // Dedicated inputs
  output [(WIDTH * MAX_IN_LEN * MAX_OUT_LEN) - 1:0] uo_weights, // Loaded in Weights - finished setting one cycle after done
  output                                            uo_done     // Pulse completed load
);

  reg [(WIDTH * MAX_IN_LEN * MAX_OUT_LEN) - 1:0] weights;

  always @(posedge clk) begin
    weights <= {weights[223:0], (ena ? (count[3] ? {weights[240+:16], ui_input} : {ui_input, weights[224+:16]}) : weights[224+:32])};
  end

  assign uo_weights = weights;
  assign uo_done    = count == {3'b111, {WIDTH_BITS{1'b1}}};

endmodule : tt_um_load