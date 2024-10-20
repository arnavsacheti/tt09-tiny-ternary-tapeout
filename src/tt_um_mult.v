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
   input wire			     rst_n,
   input wire			     en,
   input wire [BitWidth*2-1:0]      VecIn, 
   input wire [(2 * InLen * OutLen)-1: 0] W,
   output wire [BitWidth-1:0] VecOut
);
   reg [BitWidth*OutLen-1:0]             temp_out;
   reg [BitWidth*OutLen-1:0]             pipe_out;
   integer                               col;

   wire [2*OutLen-1:0] row_data1 = W[{row, 1'b0, 4'h0} +: 2*OutLen]; // Register to hold the entire row
   wire [2*OutLen-1:0] row_data2 = W[{row, 1'b1, 4'h0} +: 2*OutLen]; // Register to hold the entire row

   always @(posedge clk) begin
      // Logic for computing the temporary sums (before piping into registers)
      
      for (col = 0; col < InLen; col = col + 1) begin
            // If we are not at the end of the loop
            // Update temp_out based on current W values
            temp_out[(col<<3)+:BitWidth] <= (row_data1[col[3:0] + 1'b1] ? (-$signed(VecIn[BitWidth+:BitWidth])) :
                                             row_data1[col[3:0]] ? $signed(VecIn[BitWidth+:BitWidth]) : {BitWidth{1'b0}}) +
                                            (row_data2[col[3:0] + 1'b1] ? (-$signed(VecIn[0+:BitWidth])) :
                                             row_data2[col[3:0]] ? $signed(VecIn[0+:BitWidth]) : {BitWidth{1'b0}}) +
                                            (|row ? $signed(temp_out[col<<2+:BitWidth]) : {BitWidth{1'b0}});
      end
   end

   always @(row) begin
      if(~|row && en) 
         pipe_out = temp_out;
  end

   assign VecOut = pipe_out[({3'b0, row}<<3)+:BitWidth];

endmodule
