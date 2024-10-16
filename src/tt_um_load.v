/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype wire

module tt_um_load # (
  parameter MAX_IN_LEN  = 16, 
  parameter MAX_OUT_LEN = 8
)(
  input                                        clk,        // clock
  input                                        rst_n,      // reset_n - low to reset
  input                                        ena,        // always 1 when the module is selected
  input  [MAX_IN_LEN-1:0]                      ui_input,   // Dedicated inputs
  input  [6:0]                                 ui_param,   // Configured Parameters
  output [(2 * MAX_IN_LEN * MAX_OUT_LEN)-1: 0] uo_weights, // Loaded in Weights - finished setting one cycle after done
  output                                       uo_done     // Pulse completed load
);
  localparam MAX_IN_BITS  = $clog2(MAX_IN_LEN);
  localparam MAX_OUT_BITS = $clog2(MAX_OUT_LEN);

  localparam MSB = 0;
  localparam LSB = 1;
  reg        state;

  reg [MAX_IN_BITS:0]                       idx;
  reg [MAX_OUT_BITS-1:0]                    count;

  reg [(2 * MAX_IN_LEN * MAX_OUT_LEN)-1: 0] weights;
  

  always @(posedge clk) begin
    if(!rst_n) begin
      state <= MSB;
      count <= 'h0;
    end else begin

      if (ena) begin
        case (state)
          MSB : begin
            state <= LSB;
          end 
          LSB : begin
            state <= MSB;
            count <= count + 1;
          end 
        endcase
      end
    end
  end

  always_latch begin
    if (ena) begin
      for(idx = 0; idx < MAX_IN_LEN; idx ++) begin
        weights[{idx[3:0], count, state}] = ui_input[idx[3:0]];
      end
    end
  end

  assign uo_weights = weights;
  assign uo_done    = &{count == ui_param[2:0], state};
  // TODO: Make count one hot to simplify comparision?

endmodule : tt_um_load
