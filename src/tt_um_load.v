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
  input                                             ena,        // always 1 when the module is selected
  input  [MAX_IN_LEN-1:0]                           ui_input,   // Dedicated inputs
  input  [MAX_OUT_BITS + WIDTH_BITS - 1:0]          ui_col,     // Column to load
  output [(WIDTH * MAX_IN_LEN * MAX_OUT_LEN) - 1:0] uo_weights  // Loaded in Weights - finished setting one cycle after done
);

  reg [(WIDTH * MAX_IN_LEN * MAX_OUT_LEN) - 1:0] weights;
  genvar gi, gj;

  for (gi = 0; gi < MAX_IN_LEN ; gi ++) begin
    for (gj = 0; gj < MAX_OUT_LEN * WIDTH ; gj ++) begin
      always_latch begin
        if (ena && ui_col == gj) begin
          weights[{gi[MAX_IN_BITS-1:0], gj[MAX_OUT_BITS+WIDTH_BITS-1:0]}] = ui_input[gi];
        end
      end
    end
  end

  assign uo_weights = weights;

endmodule : tt_um_load


// Version using One hot encoding.

// /*
//  * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
//  * SPDX-License-Identifier: Apache-2.0
//  */

// `default_nettype wire

// module tt_um_load # (
//   parameter MAX_IN_LEN   = 16, 
//   parameter MAX_OUT_LEN  = 8,
//   parameter WIDTH        = 2,
//   parameter MAX_IN_BITS  = $clog2(MAX_IN_LEN),
//   parameter MAX_OUT_BITS = $clog2(MAX_OUT_LEN),
//   parameter WIDTH_BITS   = $clog2(WIDTH)
// )(
//   input                                             ena,        // always 1 when the module is selected
//   input  [MAX_IN_LEN-1:0]                           ui_input,   // Dedicated inputs
//   input  [(MAX_OUT_LEN * WIDTH) - 1:0]              ui_col,     // Column to load
//   output [(WIDTH * MAX_IN_LEN * MAX_OUT_LEN) - 1:0] uo_weights  // Loaded in Weights - finished setting one cycle after done
// );

//   reg [(WIDTH * MAX_IN_LEN * MAX_OUT_LEN) - 1:0] weights;
//   genvar gi, gj;

//   for (gi = 0; gi < MAX_IN_LEN ; gi ++) begin
//     for (gj = 0; gj < MAX_OUT_LEN * WIDTH ; gj ++) begin
//       always @(ui_col or ui_input) begin
//         if (ena & ui_col[gj]) begin
//           weights[{gi[MAX_IN_BITS-1:0], gj[MAX_OUT_BITS+WIDTH_BITS-1:0]}] = ui_input[gi];
//         end
//       end
//     end
//   end

//   assign uo_weights = weights;

// endmodule : tt_um_load