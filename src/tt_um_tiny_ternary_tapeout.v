/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_tiny_ternary_tapeout #(
  parameter MAX_IN_LEN  = 10,
  parameter MAX_OUT_LEN = 5
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

  localparam LOAD = 0;

  // wire internal_reset;
  reg state;
  reg [3:0] count;

  wire [(2 * MAX_IN_LEN)-1: 0] load_weights;

  always @(posedge clk) begin
    if(!rst_n) begin
      state     <= LOAD;
    end else begin
      if(state == LOAD) begin
        state <= count == 4'b1100;
      end
    end
  end

  always @(posedge clk) begin
    if(!rst_n) begin
      count <=  4'h0;
    end else begin
      if (count[2:0] == 3'd4) begin
        count <= count<<1;
      end else begin
        count <= count + 1;
      end
    end
  end
   
  tt_um_load #(
    .MAX_IN_LEN  (MAX_IN_LEN),
    .MAX_OUT_LEN (MAX_OUT_LEN)
  ) tt_um_load_inst (
    .clk        (clk),
    .half      (count[3]),
    .ena        (!state),
    .ui_input   (ui_input[11:0]),
    .uo_weights (load_weights)
  );

  tt_um_mult #(
	       .InLen(MAX_IN_LEN),
	       .OutLen(MAX_OUT_LEN),
	       .BitWidth(BitWidth)
  ) tt_um_mult_inst (
		    .clk(clk),
        .row(count[2:0]),
		    .VecIn(ui_input),
		    .W(load_weights),
		    .VecOut(uo_out)
		    );

endmodule : tt_um_tiny_ternary_tapeout