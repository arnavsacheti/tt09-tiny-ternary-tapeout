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
   input wire			     rst_n,
   input wire			     en,
   input wire [BitWidth*2-1:0]      VecIn, 
   input wire [(2 * InLen * OutLen)-1: 0] W,
   output wire [BitWidth-1:0] VecOut
);

   reg [2:0]                             row;
   reg [BitWidth*OutLen-1:0]             temp_out;
   reg [BitWidth*(OutLen-1)-1:0]         pipe_out;
   integer                               col;
   integer                               i, j;

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         // Reset all state variables
         row <= 3'b0;
         temp_out <= {(BitWidth*OutLen){1'b0}};
         pipe_out <= {BitWidth*(OutLen-1){1'b0}};
      end else if (en) begin
         // Logic for computing the temporary sums (before piping into registers)
         for (col = 0; col < 2*OutLen; col = col + 2) begin
            // If we are not at the end of the loop
            // Update temp_out based on current W values\
            temp_out[(col<<2)+:BitWidth] <=          (W[({24'b0, row, 5'b0} + col)+: 2] == 2'b11 ? (-$signed(VecIn[BitWidth+:BitWidth])) :
                                                      W[({24'b0, row, 5'b0} + col)+: 2] == 2'b01 ? $signed(VecIn[BitWidth+:BitWidth]) : {BitWidth{1'b0}}) +
                                                     (W[({24'b0, row, 5'b1_0000} + col)+: 2] == 2'b11 ? (-$signed(VecIn[0+:BitWidth])) :
                                                      W[({24'b0, row, 5'b1_0000} + col)+: 2] == 2'b01 ? $signed(VecIn[0+:BitWidth]) : {BitWidth{1'b0}}) +
                                                      (row == 3'b0 ? {BitWidth{1'b0}} : $signed(temp_out[col<<2+:BitWidth]));
         end
         row <= row + 3'b1;
         // Increment the row
         // If we are at the end of the loop
         pipe_out <= |row ? pipe_out >> BitWidth : temp_out[BitWidth+:BitWidth*(OutLen-1)];
      end
   end

   assign VecOut = |row ? pipe_out[0+:BitWidth] : temp_out[0+:BitWidth];

endmodule
