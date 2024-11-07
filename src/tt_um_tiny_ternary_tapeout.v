/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_tiny_ternary_tapeout #(
  parameter MAX_IN_LEN  = 12,
  parameter MAX_OUT_LEN = 12
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
  localparam WeightWidth = 2;

  // Assign Bi-Directional pin to input
  assign uio_oe  = 8'h0F;
  assign uio_out[7:4] = 4'h0;

  // List all unused inputs to prevent warnings
  wire _unused  = |{ena, uio_in[3:0]};

  wire [11:0] ui_input = {ui_in, uio_in[7:4]};
  wire [11:0] uo_output;


  reg [7:0] bit_select;

  reg load_ena;
  reg mult_ena;
  reg [7:0] count;

  wire [(WeightWidth * MAX_IN_LEN * MAX_OUT_LEN) - 1:0] load_weights;

  always @(posedge clk) begin
    if(!rst_n) begin
      load_ena <= 1'b0;
      mult_ena <= 1'b0;
      count   <=  'b0;
    end else begin
      count <= count + 'b1;
      if(load_ena) begin
        if(count == (WeightWidth * MAX_OUT_LEN) - 1) begin
          load_ena <= 1'b0;
          mult_ena <= 1'b1;
          count <=  'b0;
        end
      end else if (mult_ena) begin
        if(count == bit_select) begin
          count <=  'b0;
        end
      end else begin
        if(|ui_input) begin
          bit_select <= ui_input[11:4];
          load_ena <= 1'b1;
        end
        count <=  'b0;
      end
    end
  end
   
  tt_um_load #(
    .MAX_IN_LEN (MAX_IN_LEN),
    .MAX_OUT_LEN(MAX_OUT_LEN),
    .WIDTH      (WeightWidth)
  ) tt_um_load_inst (
    .clk        (clk),
    .ena        (load_ena),
    .ui_input   (ui_input),
    .uo_weights (load_weights)
  );

  tt_um_mult #(
    .MAX_IN_LEN  (MAX_IN_LEN),
    .MAX_OUT_LEN (MAX_OUT_LEN),
    .WEIGHT_WDITH(WeightWidth)
  ) tt_um_mult_inst (
    .clk          (clk),
    .ui_lsb_select(count == 0),
    .ui_input     (ui_input),
    .ui_weights   (load_weights),
    .uo_output    (uo_output)
  );

  assign {uo_out, uio_out[3:0]} = uo_output;

endmodule : tt_um_tiny_ternary_tapeout