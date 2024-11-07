/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */
 

module tt_um_mult # (
  parameter MAX_IN_LEN = 12, 
  parameter MAX_OUT_LEN = 12, 
  parameter WEIGHT_WDITH = 2
)(
  input wire			                                          clk,
  input wire                                                  ui_lsb_select,
  input wire [MAX_IN_LEN-1:0]                                 ui_input, 
  input wire [(WEIGHT_WDITH * MAX_IN_LEN * MAX_OUT_LEN)-1: 0] ui_weights,
  output wire [MAX_OUT_LEN-1:0]                               uo_output
);

  genvar row;
  generate
    for (row = 0; row < MAX_OUT_LEN; row ++) begin
      reg  [3:0] carry;
      wire [3:0] carry_q;

      reg  out;
      wire out_q;

      wire [MAX_IN_LEN*WEIGHT_WDITH-1:0] row_data;
      wire [3:0] lsb_offset;

      assign row_data = ui_weights[row * MAX_IN_LEN * WEIGHT_WDITH +: MAX_IN_LEN * WEIGHT_WDITH];

      assign lsb_offset = {3'b0, row_data[MAX_OUT_LEN +  0]} 
                        + {3'b0, row_data[MAX_OUT_LEN +  1]} 
                        + {3'b0, row_data[MAX_OUT_LEN +  2]} 
                        + {3'b0, row_data[MAX_OUT_LEN +  3]} 
                        + {3'b0, row_data[MAX_OUT_LEN +  4]} 
                        + {3'b0, row_data[MAX_OUT_LEN +  5]} 
                        + {3'b0, row_data[MAX_OUT_LEN +  6]} 
                        + {3'b0, row_data[MAX_OUT_LEN +  7]} 
                        + {3'b0, row_data[MAX_OUT_LEN +  8]} 
                        + {3'b0, row_data[MAX_OUT_LEN +  9]} 
                        + {3'b0, row_data[MAX_OUT_LEN + 10]} 
                        + {3'b0, row_data[MAX_OUT_LEN + 11]}
                        ;

      assign {carry_q, out_q} = (row_data[MAX_OUT_LEN +  0]? {4'b0, ~ui_input[ 0]} : (row_data[ 0]? {4'b0, ui_input[ 0]} : 5'b0))
                              + (row_data[MAX_OUT_LEN +  1]? {4'b0, ~ui_input[ 1]} : (row_data[ 1]? {4'b0, ui_input[ 1]} : 5'b0))
                              + (row_data[MAX_OUT_LEN +  2]? {4'b0, ~ui_input[ 2]} : (row_data[ 2]? {4'b0, ui_input[ 2]} : 5'b0))
                              + (row_data[MAX_OUT_LEN +  3]? {4'b0, ~ui_input[ 3]} : (row_data[ 3]? {4'b0, ui_input[ 3]} : 5'b0))
                              + (row_data[MAX_OUT_LEN +  4]? {4'b0, ~ui_input[ 4]} : (row_data[ 4]? {4'b0, ui_input[ 4]} : 5'b0))
                              + (row_data[MAX_OUT_LEN +  5]? {4'b0, ~ui_input[ 5]} : (row_data[ 5]? {4'b0, ui_input[ 5]} : 5'b0))
                              + (row_data[MAX_OUT_LEN +  6]? {4'b0, ~ui_input[ 6]} : (row_data[ 6]? {4'b0, ui_input[ 6]} : 5'b0))
                              + (row_data[MAX_OUT_LEN +  7]? {4'b0, ~ui_input[ 7]} : (row_data[ 7]? {4'b0, ui_input[ 7]} : 5'b0))
                              + (row_data[MAX_OUT_LEN +  8]? {4'b0, ~ui_input[ 8]} : (row_data[ 8]? {4'b0, ui_input[ 8]} : 5'b0))
                              + (row_data[MAX_OUT_LEN +  9]? {4'b0, ~ui_input[ 9]} : (row_data[ 9]? {4'b0, ui_input[ 9]} : 5'b0))
                              + (row_data[MAX_OUT_LEN + 10]? {4'b0, ~ui_input[10]} : (row_data[10]? {4'b0, ui_input[10]} : 5'b0))
                              + (row_data[MAX_OUT_LEN + 11]? {4'b0, ~ui_input[11]} : (row_data[11]? {4'b0, ui_input[11]} : 5'b0))
                              + (ui_lsb_select ? {1'b0, lsb_offset}: {1'b0, carry});

      assign uo_output[row] = out;

      always @(posedge clk) begin
        carry <= carry_q;
        out   <= out_q; 
      end
    end
  endgenerate
endmodule