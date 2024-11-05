/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_tiny_ternary_tapeout #(
  parameter MAX_IN_LEN  = 8,
  parameter MAX_OUT_LEN = 4
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
  localparam WeightWidth = 2;

  // Assign Bi-Directional pin to input
  assign uio_oe  = 0;
  assign uio_out = 0;

  // List all unused inputs to prevent warnings
  wire _unused  = ena;

  wire [15:0] ui_input = {ui_in, uio_in};

  localparam LOAD = 0;
  localparam MULT = 1;

  // wire internal_reset;
  reg state;
  reg [2:0] count;

  wire [(WeightWidth * MAX_IN_LEN * MAX_OUT_LEN)-1: 0] load_weights;

  always @(posedge clk) begin
    if(!rst_n) begin
      state     <= LOAD;
      count <=  3'b0;
    end else begin
      count <= count + 'b1;
      if(state == LOAD) begin
        if(count == MAX_OUT_LEN - 1) begin
          state <= MULT;
          count <=  3'b0;
        end
      end
    end
  end
   
  tt_um_load #(
    .MAX_IN_LEN (MAX_IN_LEN),
    .MAX_OUT_LEN(MAX_OUT_LEN)
  ) tt_um_load_inst (
    .clk        (clk),
    .ena        (!state),
    .ui_input   (ui_input),
    .uo_weights (load_weights)
  );

  tt_um_mult #(
    .MAX_IN_LEN  (MAX_IN_LEN),
    .MAX_OUT_LEN (MAX_OUT_LEN),
    .BIT_WIDTH   (BitWidth),
    .WEIGHT_WDITH(WeightWidth)
  ) tt_um_mult_inst (
    .clk          (clk),
    .ui_bit_select(count),
    .ui_input     (ui_input[7:0]),
    .ui_weights   (load_weights),
    .uo_output    (uo_out[3:0])
  );

  assign uo_out[7:4] = 4'b0;

endmodule : tt_um_tiny_ternary_tapeout