/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_load # (
  parameter MaxInLen = 16, 
  parameter MaxOutLen = 8
)(
  input  wire               clk,                               // clock
  input  wire               rst_n,                             // reset_n - low to reset
  input  wire               ena,                               // always 1 when the module is selected
  input  wire        [15:0] ui_input,                          // Dedicated inputs
  input  wire        [6:0]  ui_param,                          // Configured Parameters
  output wire signed [1:0]  uo_weights [MaxInLen] [MaxOutLen], // Loaded in Weights - finished setting one cycle after done
  output wire               uo_done                            // Pulse completed load
);
  localparam MaxInBits  = $clog2(MaxInLen);
  localparam MaxOutBits = $clog2(MaxOutLen);

  
  localparam MSB = 0;
  localparam LSB = 1;

  reg [1:0]            state;
  
  reg                  ena_d;
  reg [MaxOutBits-1:0] count;
  reg signed [1:0]     weights [MaxInLen] [MaxOutLen];
  reg                  done;

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
            for (int i = 0; i < MaxInLen; i++) 
              weights[i][0][1] <= ui_input[i];
          end else if(ena) begin
            state <= LSB;
            for (int i = 0; i < MaxInLen; i++)
              weights[i][count][1] <= ui_input[i];
            if(count == ui_param[2:0])
              done <= 1'b1;
          end
        end 
        LSB : begin
          if(ena) begin
            done  <= 1'b0;
            count <= count + 1;
            state <= MSB;
            for (int i = 0; i < MaxInLen; i++) 
              weights[i][count][1] <= ui_input[i];
          end
        end
      endcase
    end
  end

  assign uo_weights = weights;
  assign uo_done    = done;

endmodule : tt_um_load
