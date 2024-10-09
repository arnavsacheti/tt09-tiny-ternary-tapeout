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
   input wire signed [BitWidth*2-1:0]      VecIn, 
   input wire signed [(2 * InLen * OutLen)-1: 0] W,
   output reg signed [BitWidth-1:0] VecOut,
   output reg set
);

   reg [3:0]                             row;
   reg signed [BitWidth*OutLen-1:0]      temp_out;
   reg signed [BitWidth*(OutLen-1)-1:0]  pipe_out;
   integer                               col;
   integer                               i, j;

   

   always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         // Reset all state variables
         row <= 4'b0;
         set <= 1'b0;
         temp_out <= {(BitWidth*OutLen){1'b0}};
         pipe_out <= {BitWidth*(OutLen-1){1'b0}};
         VecOut <= {BitWidth{1'b0}};
      end else if (en) begin
         // Logic for computing the temporary sums (before piping into registers)
         for (col = 0; col < OutLen; col = col + 1) begin
            // If we are not at the end of the loop
            if (row != 4'b1110) begin
               // Update temp_out based on current W values
               temp_out[col*BitWidth+:BitWidth] <= (W[(2 * ({28'b0, row} * OutLen + col))+: 2] == 2'b11 ? (-$signed(VecIn[BitWidth+:BitWidth])) :
                                                    W[(2 * ({28'b0, row} * OutLen + col))+: 2] == 2'b01 ? $signed(VecIn[BitWidth+:BitWidth]) : {BitWidth{1'b0}}) +
                                                   (W[(2 * (({28'b0, row} + 32'b1) * OutLen + col))+: 2] == 2'b11 ? (-$signed(VecIn[0+:BitWidth])) :
                                                    W[(2 * (({28'b0, row} + 32'b1) * OutLen + col))+: 2] == 2'b01 ? $signed(VecIn[0+:BitWidth]) : {BitWidth{1'b0}}) +
                                                   (row == 4'b0 ? {BitWidth{1'b0}} : $signed(temp_out[(col*BitWidth)+:BitWidth]));
            end else begin // load into pipe registers
               if (col != 0) begin
                  pipe_out[(BitWidth*(col - 1))+:BitWidth] <=(W[(2 * ({28'b0, 4'b1110} * OutLen + col))+: 2] == 2'b11 ? (-$signed(VecIn[BitWidth+:BitWidth])) :
                                                              W[(2 * ({28'b0, 4'b1110} * OutLen + col))+: 2] == 2'b01 ? $signed(VecIn[BitWidth+:BitWidth]) : {BitWidth{1'b0}}) +
                                                             (W[(2 * (({28'b0, 4'b1110} + 32'b1) * OutLen + col))+: 2] == 2'b11 ? (-$signed(VecIn[0+:BitWidth])) :
                                                              W[(2 * (({28'b0, 4'b1110} + 32'b1) * OutLen + col))+: 2] == 2'b01 ? $signed(VecIn[0+:BitWidth]) : {BitWidth{1'b0}}) +
                                                              $signed(temp_out[(col*BitWidth)+:BitWidth]);
               end
            end
         end
         // Increment the row
         row <= row + 2;
         // If we are at the end of the loop
         if (row == 4'b1110) begin
               // the output is set now - compute the first vec out
               set <= 1'b1;
               VecOut <= (W[4'b1110 * OutLen * 2 +: 2] == 2'b11 ? (-$signed(VecIn[BitWidth+:BitWidth])) :
                          W[4'b1110 * OutLen * 2 +: 2] == 2'b01 ? $signed(VecIn[BitWidth+:BitWidth]) : {BitWidth{1'b0}}) +
                         (W[4'b1111 * OutLen * 2 +: 2] == 2'b11 ? (-$signed(VecIn[0+:BitWidth])) :
                          W[4'b1111 * OutLen * 2 +: 2] == 2'b01 ? $signed(VecIn[0+:BitWidth]) : {BitWidth{1'b0}}) +
                          temp_out[0+:BitWidth];
         end else if (set && row != 4'b1110) begin
               // if set then output the value from pipeout
               VecOut <= pipe_out[row[3:1]*BitWidth+:BitWidth];
         end else if (row != 4'b1110 && !set) begin
               // if not set set Vecout low
               VecOut <= {BitWidth{1'b0}};
         end
      end else begin
         // Reset state when enable is low
         row <= 4'b0;
         set <= 1'b0;
         VecOut <= {BitWidth{1'b0}};
      end
   end
endmodule
