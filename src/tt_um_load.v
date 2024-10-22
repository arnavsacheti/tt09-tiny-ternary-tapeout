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
  input                                             ena,        // always 1 when the module is selected
  input  [MAX_IN_LEN-1:0]                           ui_input,   // Dedicated inputs
  output [(WIDTH * MAX_IN_LEN * MAX_OUT_LEN) - 1:0] uo_weights  // Loaded in Weights - finished setting one cycle after done
);

  reg [(WIDTH * MAX_IN_LEN * MAX_OUT_LEN) - 1:0] weights;
  genvar gi;

  for (gi = 0; gi < MAX_IN_LEN ; gi ++) begin
    always @(clk) begin
      if(ena) begin
        if(clk) begin
          weights[{gi[MAX_IN_BITS-1:0], 4'hF}] = ui_input[gi];
          weights[{gi[MAX_IN_BITS-1:0], 4'hD}] = weights[{gi[MAX_IN_BITS-1:0], 4'hE}];
          weights[{gi[MAX_IN_BITS-1:0], 4'hB}] = weights[{gi[MAX_IN_BITS-1:0], 4'hC}];
          weights[{gi[MAX_IN_BITS-1:0], 4'h9}] = weights[{gi[MAX_IN_BITS-1:0], 4'hA}];
          weights[{gi[MAX_IN_BITS-1:0], 4'h7}] = weights[{gi[MAX_IN_BITS-1:0], 4'h8}];
          weights[{gi[MAX_IN_BITS-1:0], 4'h5}] = weights[{gi[MAX_IN_BITS-1:0], 4'h6}];
          weights[{gi[MAX_IN_BITS-1:0], 4'h3}] = weights[{gi[MAX_IN_BITS-1:0], 4'h4}];
          weights[{gi[MAX_IN_BITS-1:0], 4'h1}] = weights[{gi[MAX_IN_BITS-1:0], 4'h2}];
        end
        if (~clk) begin
          weights[{gi[MAX_IN_BITS-1:0], 4'hE}] = weights[{gi[MAX_IN_BITS-1:0], 4'hF}];
          weights[{gi[MAX_IN_BITS-1:0], 4'hC}] = weights[{gi[MAX_IN_BITS-1:0], 4'hD}];
          weights[{gi[MAX_IN_BITS-1:0], 4'hA}] = weights[{gi[MAX_IN_BITS-1:0], 4'hB}];
          weights[{gi[MAX_IN_BITS-1:0], 4'h8}] = weights[{gi[MAX_IN_BITS-1:0], 4'h9}];
          weights[{gi[MAX_IN_BITS-1:0], 4'h6}] = weights[{gi[MAX_IN_BITS-1:0], 4'h7}];
          weights[{gi[MAX_IN_BITS-1:0], 4'h4}] = weights[{gi[MAX_IN_BITS-1:0], 4'h5}];
          weights[{gi[MAX_IN_BITS-1:0], 4'h2}] = weights[{gi[MAX_IN_BITS-1:0], 4'h3}];
          weights[{gi[MAX_IN_BITS-1:0], 4'h0}] = weights[{gi[MAX_IN_BITS-1:0], 4'h1}];
        end
      end
    end
  end

  assign uo_weights = weights;

endmodule : tt_um_load