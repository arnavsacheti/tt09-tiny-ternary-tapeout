/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype wire

module tt_um_load # (
  parameter MAX_IN_LEN   = 14, 
  parameter MAX_OUT_LEN  = 7,
  parameter WIDTH        = 2
)(
  input                               clk,        // clock
  input                               half,      // counter
  input                               ena,        // always 1 when the module is selected
  input  [13:0]                       ui_input,   // Dedicated inputs
  output [(WIDTH * MAX_IN_LEN) - 1:0] uo_weights // Loaded in Weights - finished setting one cycle after done
);

  reg [(WIDTH * MAX_IN_LEN * MAX_OUT_LEN) - 1:0] weights;

  wire [27:0] input_to_sr;

  assign input_to_sr = half ? {ui_input[13:0], weights[0+:14]} 
                                : {ui_input[13:0], ui_input[13:0]}; // loading by halves

  always @ (posedge clk) begin
    if (ena) begin
      weights <= {input_to_sr, weights[28+:168]};
    end else begin
      weights <= {weights[0+:28], weights[28+:168]};
    end
  end

  assign uo_weights = weights[0+:WIDTH * MAX_IN_LEN];

endmodule : tt_um_load