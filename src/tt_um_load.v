/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_load # (
  parameter MAX_IN_LEN  = 16, 
  parameter MAX_OUT_LEN = 8
)(
  input  wire                                              clk,        // clock
  input  wire                                              rst_n,      // reset_n - low to reset
  input  wire                                              ena,        // always 1 when the module is selected
  input  wire        [MAX_IN_LEN-1:0]                      ui_input,   // Dedicated inputs
  output reg [(2 * MAX_IN_LEN * MAX_OUT_LEN)-1: 0] uo_weights, // Loaded in Weights - finished setting one cycle after done
  output wire                                              uo_done     // Pulse completed load
);
  // localparam MAX_IN_BITS  = $clog2(MAX_IN_LEN);
  
  reg [3:0]   count;

  integer i;

  // // Always latch block to infer latches for `weights`
  // always @ (*) begin
  //   if (!rst_n) begin
  //     for (i = 0; i < MAX_IN_LEN; i++) begin
  //       uo_weights[(i * MAX_OUT_LEN * 2) + {{28'b0},count}] = 'b0;
  //     end
  //   end else if (ena && !uo_done) begin
  //     for (i = 0; i < MAX_IN_LEN; i++) begin
  //       uo_weights[(i * MAX_OUT_LEN * 2) + {{28'b0},count}] = ui_input[i];
  //     end
  //   end else begin
  //     // Retain previous values when `ena` is not active or `rst_n` is not asserted
  //     for (i = 0; i < MAX_IN_LEN; i++) begin
  //       uo_weights[(i * MAX_OUT_LEN * 2) + {{28'b0},count}] = uo_weights[(i * MAX_OUT_LEN * 2) + {{28'b0},count}];
  //     end
  //   end
  // end


  always @(posedge clk) begin
    if(!rst_n) begin
      count <= 4'h0;
    end else if (ena) begin
      count <= count + 1'b1;
      uo_weights[({28'b0, count} << 4)+:MAX_OUT_LEN*2] <=  ui_input;
    end else begin
      count <= 4'h0;
    end
  end

assign uo_done = count == 4'b1111;

endmodule : tt_um_load