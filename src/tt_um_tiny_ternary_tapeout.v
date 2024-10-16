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
  localparam IDLE_TO_LOAD = 'hA;


  // Assign Bi-Directional pin to input
  assign uio_oe  = 0;
  assign uio_out = 0;

  // List all unused inputs to prevent warnings
  wire _unused  = ena;

  wire [15:0] ui_input = {ui_in, uio_in}; 

  localparam IDLE = 0;
  localparam LOAD = 1;
  // localparam MULT = 2;
  // localparam OUT  = 3;

  reg [1:0] state;
  
  reg [6:0] cfg_param;

  wire                                       load_ena;
  wire [(2 * MAX_IN_LEN * MAX_OUT_LEN)-1: 0] load_weights;
  wire                                       load_done;

  genvar gi;

  for (gi = 0; gi < 8; gi ++) begin
    assign uo_out[gi] = |load_weights[(gi*32)+31:(gi*32)];
  end

  always @(posedge clk) begin
    if(!rst_n) begin
      state     <= IDLE;
      cfg_param <= 7'h7F; 
    end else begin
      case (state)
        IDLE : begin
          if(ui_input[15:12] == IDLE_TO_LOAD) begin
            state     <= LOAD;
            cfg_param <= ui_input[11:5];
          end
        end 
        LOAD : begin
          if(load_done) begin
            state    <= IDLE;
          end
        end
        default: state <= IDLE;
      endcase
    end
  end

  assign load_ena = state == LOAD;

  tt_um_load #(
    .MAX_IN_LEN  (MAX_IN_LEN),
    .MAX_OUT_LEN (MAX_OUT_LEN)
  ) tt_um_load_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .ena        (load_ena),
    .ui_input   (ui_input),
    .ui_param   (cfg_param),
    .uo_weights (load_weights),
    .uo_done    (load_done)
  );

endmodule : tt_um_tiny_ternary_tapeout
