/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */
 

module tt_um_mult # (
   parameter InLen = 16, 
   parameter OutLen = 8, 
   parameter BitWidth = 8
)(
   input wire			     clk,
   input wire [2:0]       row,
   input wire			     en,
   input wire [BitWidth*2-1:0]      VecIn, 
   input wire [(2 * InLen * OutLen)-1: 0] W,
   output wire [BitWidth-1:0] VecOut
);
   reg [BitWidth*OutLen-1:0]             temp_out_pos;
   reg [BitWidth*OutLen-1:0]             temp_out_neg;
   reg [BitWidth*OutLen-1:0]             pipe_out;

   wire [2*2*OutLen-1:0] row_data = W[{row, 5'h0} +: 2*2*OutLen]; // Register to hold two rows
   // wire [2*OutLen-1:0] row_data2 = W[{row, 1'b1, 4'h0} +: 2*OutLen]; // Register to hold the entire row

   genvar  gi;

   for (gi = 0; gi < OutLen; gi++) begin
      always_latch begin
         if(clk) begin
            temp_out_pos[{gi[2:0], 3'b0} +: BitWidth] = 
               (row_data[{1'b0, gi[2:0], 1'b0}] ? (row_data[{1'b0, gi[2:0], 1'b1}] ? -VecIn[BitWidth+:BitWidth] : VecIn[BitWidth+:BitWidth]) : 'h0) + 
               (row_data[{1'b1, gi[2:0], 1'b0}] ? (row_data[{1'b1, gi[2:0], 1'b1}] ? -VecIn[0+:BitWidth] : VecIn[0+:BitWidth]) : 'h0) + 
               (|row ? temp_out_neg[{gi[2:0], 3'b0} +: BitWidth] : 'h0);
         end 
         if(~clk) begin
            temp_out_neg[{gi[2:0], 3'b0} +: BitWidth] = temp_out_pos[{gi[2:0], 3'b0} +: BitWidth];
         end
      end
   end

   always @(row) begin
      if(~|row & en) 
         pipe_out = temp_out_neg;
  end

   assign VecOut = pipe_out[({3'b0, row}<<3)+:BitWidth];

endmodule
