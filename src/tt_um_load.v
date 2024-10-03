/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_load # (
  parameter MAX_IN_LEN  = 16, 
  parameter MAX_OUT_LEN = 8
)(
  input  wire               clk,                                   // clock
  input  wire               rst_n,                                 // reset_n - low to reset
  input  wire               ena,                                   // always 1 when the module is selected
  input  wire        [15:0] ui_input,                              // Dedicated inputs
  input  wire        [6:0]  ui_param,                              // Configured Parameters
  output wire signed [1:0]  uo_weights [MAX_IN_LEN] [MAX_OUT_LEN], // Loaded in Weights - finished setting one cycle after done
  output wire               uo_done                                // Pulse completed load
);
  localparam MAX_IN_BITS  = $clog2(MAX_IN_LEN);
  localparam MAX_OUT_BITS = $clog2(MAX_OUT_LEN);

  localparam MSB = 0;
  localparam LSB = 1;

  reg [1:0]              state;
  
  reg                    ena_d;
  reg [MAX_OUT_BITS-1:0] count;
  reg signed [1:0]       weights [MAX_IN_LEN] [MAX_OUT_LEN];
  reg                    done;

  always @(posedge clk) begin
    if(!rst_n) begin
      state <= MSB;
      ena_d <= 1'b0;
      done  <= 1'b0;
      count <= 'h0;
    end else begin
      ena_d <= ena;

      case (state)
        MSB : begin
          if(ena && !ena_d) begin
            count <= 0;
            state <= LSB;
            for (int i = 0; i < MAX_IN_LEN; i++) 
              weights[i][0][1] <= (i <= ui_param[6:3]) ? ui_input[i] : 1'bx;
          end else if(ena) begin
            state <= LSB;
            for (int i = 0; i < MAX_IN_LEN; i++)
              weights[i][count][1] <= (i <= ui_param[6:3]) ? ui_input[i] : 1'bx;
            if(count == ui_param[2:0])
              done <= 1'b1;
          end
        end 
        LSB : begin
          if(ena) begin
            done  <= 1'b0;
            count <= count + 1;
            state <= MSB;
            for (int i = 0; i < MAX_IN_LEN; i++) 
              weights[i][count][0] <= (i <= ui_param[6:3]) ? ui_input[i] : 1'bx;
          end
        end
      endcase
    end
  end

  assign uo_weights = weights;
  assign uo_done    = done;

endmodule : tt_um_load
