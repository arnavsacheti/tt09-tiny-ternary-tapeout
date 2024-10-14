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
  output wire signed [(2 * MAX_IN_LEN * MAX_OUT_LEN)-1: 0] uo_weights, // Loaded in Weights - finished setting one cycle after done
  output wire                                              uo_done     // Pulse completed load
);
  // localparam MAX_IN_BITS  = $clog2(MAX_IN_LEN);
  localparam MAX_OUT_BITS = $clog2(MAX_OUT_LEN);

  localparam MSB = 0;
  localparam LSB = 1;

  reg [1:0]              state;
  
  reg                    ena_d;
  reg [MAX_OUT_BITS-1:0] count;
  reg [MAX_IN_LEN-1:0]   weights_msb;
  reg signed [1:0]       weights [MAX_IN_LEN * MAX_OUT_LEN];
  reg                    done;
  
  genvar gi;
  integer i;

  // Always latch block to infer latches for `weights`
  always_latch begin
    if (state == LSB && ena) begin
      for (i = 0; i < MAX_IN_LEN; i++) begin
        if (ui_param[6:3] >= i[3:0]) begin
          weights[(i * MAX_OUT_LEN) + {29'h0, count}] = {weights_msb[i], ui_input[i]};
        end
        // weights retains previous value (latch inferred) if condition is not met
      end
    end
  end

  always @(posedge clk) begin
    if(!rst_n) begin
      state <= MSB;
      done  <= 1'b0;
      count <= 'h0;
      ena_d <= 'b0;
    end else begin
      ena_d <= ena;

      case (state)
        MSB : begin
          if(ena & !ena_d) begin
            count <= 0;
          end
          if(ena) begin
            state <= LSB;
            weights_msb <= ui_input;
            if(count == ui_param[2:0])
              done <= 1'b1;
          end
        end 
        LSB : begin
          if(ena) begin
            done  <= 1'b0;
            count <= (done) ? 'h0 : count + 1;
            state <= MSB;
          end
        end
      endcase
    end
  end

  generate
    for (gi = 0; gi < MAX_IN_LEN * MAX_OUT_LEN; gi ++)
      assign uo_weights[(2 * gi) + 1: 2 * gi] = weights[gi];
  endgenerate
  assign uo_done = done;

endmodule : tt_um_load


// module tt_um_load # (
//   parameter MAX_IN_LEN  = 16, 
//   parameter MAX_OUT_LEN = 8
// )(
//   input  wire                                              clk,        // clock
//   input  wire                                              rst_n,      // reset_n - low to reset
//   input  wire                                              ena,        // always 1 when the module is selected
//   input  wire        [MAX_IN_LEN-1:0]                      ui_input,   // Dedicated inputs
//   input  wire        [6:0]                                 ui_param,   // Configured Parameters
//   output wire signed [(2 * MAX_IN_LEN * MAX_OUT_LEN)-1: 0] uo_weights, // Loaded in Weights - finished setting one cycle after done
//   output wire                                              uo_done     // Pulse completed load
// );
//   // localparam MAX_IN_BITS  = $clog2(MAX_IN_LEN);
//   localparam MAX_OUT_BITS = $clog2(MAX_OUT_LEN);

//   localparam MSB = 0;
//   localparam LSB = 1;

//   reg [1:0]              state;
  
//   reg                    ena_d;
//   reg [MAX_OUT_BITS-1:0] count;
//   reg [MAX_IN_LEN-1:0]   weights_msb;
//   reg signed [1:0]       weights [MAX_IN_LEN * MAX_OUT_LEN];
//   reg                    done;
  
//   genvar gi;
//   integer i;

//   always @(posedge clk) begin
//     if(!rst_n) begin
//       state <= MSB;
//       done  <= 1'b0;
//       count <= 'h0;
//       ena_d <= 'b0;
//     end else begin
//       ena_d <= ena;

//       case (state)
//         MSB : begin
//           if(ena & !ena_d) begin
//             count <= 0;
//           end
//           if(ena) begin
//             state <= LSB;
//             weights_msb <= ui_input;
//             if(count == ui_param[2:0])
//               done <= 1'b1;
//           end
//         end 
//         LSB : begin
//           if(ena) begin
//             done  <= 1'b0;
//             count <= (done) ? 'h0: count + 1;
//             state <= MSB;
//             for (i = 0; i < MAX_IN_LEN; i++) 
//               weights[(i * MAX_OUT_LEN) + {29'h0, count}] <= (ui_param[6:3] >= i[3:0]) ? {weights_msb[i], ui_input[i]} : 2'b00;
//           end
//         end
//       endcase
//     end
//   end

//   generate
//     for (gi = 0; gi < MAX_IN_LEN * MAX_OUT_LEN; gi ++)
//       assign uo_weights[(2 * gi) + 1: 2 * gi] = weights[gi];
//   endgenerate
//   assign uo_done    = done;

// endmodule : tt_um_load