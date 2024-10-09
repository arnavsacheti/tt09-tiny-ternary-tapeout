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
  input  wire        [6:0]                                 ui_param,   // Configured Parameters
  output reg signed [1:0]       weights [MAX_IN_LEN][MAX_OUT_LEN], // Loaded in Weights - finished setting one cycle after done
  output wire                                              uo_done     // Pulse completed load
);
  // localparam MAX_IN_BITS  = $clog2(MAX_IN_LEN);
  localparam MAX_OUT_BITS = $clog2(MAX_OUT_LEN);

  localparam MSB = 0;
  localparam LSB = 1;

  reg              state;
  
  reg                    ena_d;
  reg [MAX_OUT_BITS-1:0] count;
  reg [MAX_IN_LEN-1:0]   weights_msb;
  wire signed [(2 * MAX_IN_LEN * MAX_OUT_LEN)-1: 0] uo_weights;
  reg                    done;
  
  genvar gi;
  integer i;

  always @(posedge clk) begin
    if(!rst_n) begin
      state <= MSB;
      done  <= 1'b0;
      count <= 'h0;
      ena_d <= 'b0;
    end else begin
      ena_d <= ena;

      if(!ena & ena_d) begin
        // Falling Edge Reset
        state <= MSB;
        count <= 0;
      end

      if(ena) begin
        case (state)
          MSB : begin
              state <= LSB;
              weights_msb <= ui_input;
              if(count == ui_param[2:0])
                done <= 1'b1;
            end
          LSB : begin
              done  <= 1'b0;
              count <= count + 1;
              state <= MSB;
              for (i = 0; i < MAX_IN_LEN; i++) 
                weights[(i * MAX_OUT_LEN) + {29'h0, count}] <= (ui_param[6:3] >= i[3:0]) ? {weights_msb[i], ui_input[i]} : 2'bxx;
          end
        endcase
      end
    end
  end

  generate
    for (gi = 0; gi < MAX_IN_LEN * MAX_OUT_LEN; gi ++)
      assign uo_weights[(2 * gi) + 1: 2 * gi] = weights[gi/MAX_OUT_LEN][gi%MAX_OUT_LEN];
  endgenerate
  assign uo_done    = done;

endmodule : tt_um_load
