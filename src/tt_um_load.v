/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype wire

module tt_um_load # (
  parameter MAX_IN_LEN   = 10, 
  parameter MAX_OUT_LEN  = 5,
  parameter WIDTH        = 2
)(
  input                               clk,        // clock
  input                               half,      // counter
  input                               ena,        // always 1 when the module is selected
  input  [11:0]                       ui_input,   // Dedicated inputs
  output [(WIDTH * MAX_IN_LEN) - 1:0] uo_weights // Loaded in Weights - finished setting one cycle after done
);

  reg [(WIDTH * MAX_IN_LEN * MAX_OUT_LEN) - 1:0] weights;

  wire [MAX_IN_LEN*2-1:0] input_to_sr;

  assign input_to_sr[MAX_IN_LEN*2-1:MAX_IN_LEN] = ena ? ui_input[MAX_IN_LEN-1:0] : weights[MAX_IN_LEN*2-1:MAX_IN_LEN];
  assign input_to_sr[MAX_IN_LEN-1:0] = ena ? (half ? weights[MAX_IN_LEN-1:0] : ui_input[MAX_IN_LEN-1:0]) : weights[MAX_IN_LEN-1:0];

  always @ (posedge clk) begin
    weights <= {input_to_sr, weights[MAX_IN_LEN*2+:MAX_IN_LEN*2*(MAX_OUT_LEN-1)]};
  end

  assign uo_weights = weights[0+:WIDTH * MAX_IN_LEN];

endmodule : tt_um_load