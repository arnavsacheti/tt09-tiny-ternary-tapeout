/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */
 

module tt_um_mult # (
   parameter MAX_IN_LEN = 12, 
   parameter MAX_OUT_LEN = 6, 
   parameter BIT_WIDTH = 8,
   parameter WEIGHT_WDITH = 2
)(
   input wire			                                          clk,
   input wire [2:0]                                            ui_bit_select,
   input wire [MAX_IN_LEN-1:0]                                 ui_input, 
   input wire [(WEIGHT_WDITH * MAX_IN_LEN * MAX_OUT_LEN)-1: 0] ui_weights,
   output wire [MAX_OUT_LEN-1:0]                               uo_output
);

   reg  [3:0]  carry [MAX_OUT_LEN];
   wire [3:0]  carry_q [MAX_OUT_LEN];
   reg         out [MAX_OUT_LEN];
   wire        out_q [MAX_OUT_LEN];

   wire [MAX_IN_LEN*2-1:0] row_data[MAX_OUT_LEN];
   wire [3:0] lsb_offset [MAX_OUT_LEN];
   integer  idx;

   genvar row;
   generate
      for (row = 0; row < MAX_OUT_LEN; row ++) begin
         assign row_data[row] = ui_weights[row * MAX_IN_LEN * WEIGHT_WDITH +: MAX_IN_LEN * WEIGHT_WDITH];

         assign lsb_offset[row] = {3'b00, row_data[row][23]} 
                                + {3'b00, row_data[row][22]} 
                                + {3'b00, row_data[row][21]} 
                                + {3'b00, row_data[row][20]} 
                                + {3'b00, row_data[row][19]} 
                                + {3'b00, row_data[row][18]} 
                                + {3'b00, row_data[row][17]} 
                                + {3'b00, row_data[row][16]} 
                                + {3'b00, row_data[row][15]} 
                                + {3'b00, row_data[row][14]} 
                                + {3'b00, row_data[row][13]} 
                                + {3'b00, row_data[row][12]};

         assign {carry_q[row], out_q[row]} = (row_data[row][23]? {4'b0, ~ui_input[11]} : (row_data[row][11]? {4'b0, ui_input[11]} : 'b0))
                                           + (row_data[row][22]? {4'b0, ~ui_input[10]} : (row_data[row][10]? {4'b0, ui_input[10]} : 'b0))
                                           + (row_data[row][21]? {4'b0, ~ui_input[ 9]} : (row_data[row][ 9]? {4'b0, ui_input[ 9]} : 'b0))
                                           + (row_data[row][20]? {4'b0, ~ui_input[ 8]} : (row_data[row][ 8]? {4'b0, ui_input[ 8]} : 'b0))
                                           + (row_data[row][19]? {4'b0, ~ui_input[ 7]} : (row_data[row][ 7]? {4'b0, ui_input[ 7]} : 'b0))
                                           + (row_data[row][18]? {4'b0, ~ui_input[ 6]} : (row_data[row][ 6]? {4'b0, ui_input[ 6]} : 'b0))
                                           + (row_data[row][17]? {4'b0, ~ui_input[ 5]} : (row_data[row][ 5]? {4'b0, ui_input[ 5]} : 'b0))
                                           + (row_data[row][16]? {4'b0, ~ui_input[ 4]} : (row_data[row][ 4]? {4'b0, ui_input[ 4]} : 'b0))
                                           + (row_data[row][15]? {4'b0, ~ui_input[ 3]} : (row_data[row][ 3]? {4'b0, ui_input[ 3]} : 'b0))
                                           + (row_data[row][14]? {4'b0, ~ui_input[ 2]} : (row_data[row][ 2]? {4'b0, ui_input[ 2]} : 'b0))
                                           + (row_data[row][13]? {4'b0, ~ui_input[ 1]} : (row_data[row][ 1]? {4'b0, ui_input[ 1]} : 'b0))
                                           + (row_data[row][12]? {4'b0, ~ui_input[ 0]} : (row_data[row][ 0]? {4'b0, ui_input[ 0]} : 'b0))
                                           + (ui_bit_select == 0? {1'b0, lsb_offset[row]}: {1'b0, carry[row]});

         assign uo_output[row] = out[row];
      end
   endgenerate

   always @(posedge clk ) begin
      for (idx = 0; idx < MAX_OUT_LEN; idx++) begin
         carry[idx] <= carry_q[idx];
         out[idx]   <= out_q[idx];
      end
   end

endmodule