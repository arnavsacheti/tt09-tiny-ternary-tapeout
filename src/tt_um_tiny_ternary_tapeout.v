/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_tiny_ternary_tapeout #(
  parameter MAX_IN_LEN  = 16,
  parameter MAX_OUT_LEN = 8
) (
    input  wire       clk,      // clock
    input  wire       rst_n,    // reset_n - low to reset
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe    // IOs: Enable path (active high: 0=input, 1=output)
);
  localparam BitWidth = 8;

  // Assign Bi-Directional pin to input
  assign uio_oe  = 0;
  assign uio_out = 0;

  // List all unused inputs to prevent warnings
  wire _unused  = ena;

  wire [15:0] ui_input = {ui_in, uio_in};

  localparam IDLE = 0;
  localparam LOAD = 1;
  localparam MULT = 2;

  reg [1:0] state_pos;
  reg [1:0] state_neg;
  reg [3:0] count_pos;
  reg [3:0] count_neg;

  wire [(2 * MAX_IN_LEN * MAX_OUT_LEN)-1: 0] load_weights;

  always @(clk) begin
    if(!rst_n) begin
      state_neg = IDLE;
      count_neg = 'h0;
    end else if (clk) begin
      case (state_neg)
        IDLE: if (|ui_input) state_pos = LOAD;
        LOAD: if (&count_neg) state_pos = MULT;
      endcase
      count_pos = count_neg + {3'b0, |state_neg};
    end
    else begin
      state_neg = state_pos;
      count_neg = count_pos;
    end
  end
   
  tt_um_load #(
    .MAX_IN_LEN  (MAX_IN_LEN),
    .MAX_OUT_LEN (MAX_OUT_LEN)
  ) tt_um_load_inst (
    .clk        (clk),
    .ena        (state_neg[0]),
    .ui_input   (ui_input),
    .ui_col     (count_neg),
    .uo_weights (load_weights)
  );

  tt_um_mult #(
	       .InLen(MAX_IN_LEN),
	       .OutLen(MAX_OUT_LEN),
	       .BitWidth(BitWidth)
  ) tt_um_mult_inst (
		    .clk(clk),
        .row(count_neg[2:0]),
		    .en(state_neg[1]),
		    .VecIn(ui_input),
		    .W(load_weights),
		    .VecOut(uo_out)
		    );

endmodule : tt_um_tiny_ternary_tapeout
