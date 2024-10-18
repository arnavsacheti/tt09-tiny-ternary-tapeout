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
  localparam IDLE_TO_LOAD = 2'b10;
  localparam IDLE_TO_MULT = 2'b11;

  // Assign Bi-Directional pin to input
  assign uio_oe  = 0;
  assign uio_out = 0;

  // List all unused inputs to prevent warnings
  wire _unused  = ena;


  wire [15:0] ui_input = {ui_in, uio_in};

  localparam IDLE = 0;
  localparam LOAD = 2;
  localparam MULT = 1;

  // wire internal_reset;
  reg [1:0] state;
  reg [3:0] count;

  reg [(2 * MAX_IN_LEN * MAX_OUT_LEN)-1: 0] load_weights;
  wire                                      load_done;

  always @(posedge clk) begin
    if(!rst_n) begin
      state     <= IDLE;
    end else begin
      case (state)
        IDLE : begin
          if(ui_input[13:12] == IDLE_TO_LOAD) begin
            state      <= LOAD;
          end else if(ui_input[13:12] == IDLE_TO_MULT) begin
            state      <= MULT;
          end else begin
            state      <= IDLE;
          end
        end 
        LOAD : begin
          if(load_done) begin
            state <= MULT;
          end else begin
            state <= LOAD;
          end
        end
        MULT : begin
          state  <= MULT;
        end
        default: state <= IDLE;
      endcase
    end
  end

  always @(posedge clk) begin
    if(!rst_n) begin
      count <= 'h0;
    end else if (state!=2'b00) begin
      count <= count + 1;
    end
  end
   
  tt_um_load #(
    .MAX_IN_LEN  (MAX_IN_LEN),
    .MAX_OUT_LEN (MAX_OUT_LEN)
  ) tt_um_load_inst (
    .clk        (clk),
    .count      (count),
    .rst_n      (rst_n),
    .ena        (state[1]),
    .ui_input   (ui_input),
    .uo_weights (load_weights),
    .uo_done    (load_done)
  );

  tt_um_mult #(
	       .InLen(MAX_IN_LEN),
	       .OutLen(MAX_OUT_LEN),
	       .BitWidth(BitWidth)
  ) tt_um_mult_inst (
		    .clk(clk),
        .row(count[2:0]),
		    .rst_n(rst_n),
		    .en( state[0]),
		    .VecIn(ui_input),
		    .W(load_weights),
		    .VecOut(uo_out)
		    );

endmodule : tt_um_tiny_ternary_tapeout
