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
  input  [MAX_IN_BITS + MAX_OUT_BITS - 1:0]         ui_param,   // Configured Parameters
  output [(WIDTH * MAX_IN_LEN * MAX_OUT_LEN) - 1:0] uo_weights, // Loaded in Weights - finished setting one cycle after done
  output                                            uo_done     // Pulse completed load
);

  reg [MAX_IN_BITS  + WIDTH_BITS - 1:0]          idx;
  reg [MAX_OUT_BITS + WIDTH_BITS - 1:0]          count;
  reg [(WIDTH * MAX_IN_LEN * MAX_OUT_LEN) - 1:0] weights;
  

  always @(posedge clk) begin
    if(!rst_n) begin
      count <= 'h0;
    end else begin
      count <= ena ? count + 1 : count;
    end
  end

  always_latch begin
    if (ena) begin
      for(idx = 0; idx < MAX_IN_LEN; idx ++) begin
        weights[{idx[MAX_IN_BITS-1:0], count}] = ui_input[idx[MAX_IN_BITS-1:0]];
      end
    end
  end

  assign uo_weights = weights;
  assign uo_done    = count == {ui_param[MAX_OUT_BITS-1:0], WIDTH_BITS{1'b1}};

endmodule : tt_um_load
