/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype wire

module tt_um_load # (
  parameter MAX_IN_LEN   = 12, 
  parameter MAX_OUT_LEN  = 12,
  parameter WIDTH        = 2
)(
  input                                             clk,        // clock
  input                                             ena,        // always 1 when the module is selected
  input  [MAX_IN_LEN - 1:0]                         ui_input,   // Dedicated inputs
  output [(WIDTH * MAX_IN_LEN * MAX_OUT_LEN) - 1:0] uo_weights // Loaded in Weights - finished setting one cycle after done
);

  reg [(WIDTH * MAX_IN_LEN * MAX_OUT_LEN) - 1:0] weights;

  always @ (posedge clk) begin
    if (ena) begin
      weights <= {weights[0 +: MAX_IN_LEN * ((WIDTH * MAX_OUT_LEN)-1)], ui_input};
    end else begin
      weights <= weights;
    end
  end

  assign uo_weights = weights;

endmodule : tt_um_load