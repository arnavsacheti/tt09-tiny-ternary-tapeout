/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_out # (
  parameter MAX_IN_LEN  = 16, 
  parameter MAX_OUT_LEN = 8
)(
  input  wire                                              clk,        // clock
  input  wire                                              rst_n,      // reset_n - low to reset
  input  wire                                              ena,        // always 1 when the module is selected
  input  wire        [6:0]                                 ui_param,   // Configured Parameters
  input  wire signed [(2 * MAX_IN_LEN * MAX_OUT_LEN)-1: 0] ui_weights, // Configured Weights
  output wire        [MAX_OUT_LEN-1:0]                     uo_output,  // Dedicated outputs
  output wire                                              uo_done     // Pulse completed load
);
  localparam MAX_IN_BITS = $clog2(MAX_IN_LEN);

  localparam MSB = 0;
  localparam LSB = 1;
  reg        state;
  
  reg [MAX_IN_BITS-1:0]   count;
  wire signed [1:0]       weights [MAX_IN_LEN * MAX_OUT_LEN];
  reg                     done;
  reg                     ena_d;

  reg [MAX_OUT_LEN-1:0]   uo_output_d;

  integer i;
  genvar gi;


  always @(posedge clk ) begin
    if (!rst_n) begin
      state <= MSB;
      done  <= 'b0;
      ena_d <= 'b0;
      count <= 'h0;
    end else begin
      ena_d  <= ena;

      if(!ena && ena_d) begin
        // Falling Edge
        state <= MSB;
        count <= 'h0;
        uo_output_d <= 8'hxx;
      end

      if (ena) begin
        case (state)
          MSB : begin
              state <= LSB;
              if(count == ui_param[6:3])
                done <= 1'b1;
              for(i = 0; i < MAX_OUT_LEN; i ++) 
                uo_output_d[i] <= weights[(count * MAX_OUT_LEN) + i][1];
            end
          LSB : begin
              state <= MSB;
              count <= count + 1;
              done  <= 1'b0;
              for(i = 0; i < MAX_OUT_LEN; i ++) 
                uo_output_d[i] <= weights[(count * MAX_OUT_LEN) + i][0];
          end
          default: state <= MSB;
        endcase
      end

    end
  end

  generate
    for (gi = 0; gi < MAX_IN_LEN * MAX_OUT_LEN; gi ++)
      assign weights[gi] = ui_weights[(2 * gi) + 1: 2 * gi];
  endgenerate

  assign uo_done    = done;
  assign uo_output  = uo_output_d;
endmodule : tt_um_out
