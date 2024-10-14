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
   input wire [6:0]       ui_param,
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

   wire [3:0] row_end = ui_param[6:3] & 4'b1110;

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         // Reset all state variables
         row <= 4'b0;
         temp_out <= {(BitWidth*OutLen){1'b0}};
         pipe_out <= {BitWidth*(OutLen-1){1'b0}};
         VecOut <= {BitWidth{1'b0}};
      end else if (en) begin
         // Logic for computing the temporary sums (before piping into registers)
         for (col = 0; col <= ui_param[2:0]; col = col + 1) begin
            // If we are not at the end of the loop
            if (row != row_end) begin
               // Update temp_out based on current W values
               temp_out[col*BitWidth+:BitWidth] <= (W[(2 * ({28'b0, row} * OutLen + col))+: 2] == 2'b11 ? (-$signed(VecIn[BitWidth+:BitWidth])) :
                                                    W[(2 * ({28'b0, row} * OutLen + col))+: 2] == 2'b01 ? $signed(VecIn[BitWidth+:BitWidth]) : {BitWidth{1'b0}}) +
                                                   (W[(2 * (({28'b0, row} + 32'b1) * OutLen + col))+: 2] == 2'b11 ? (-$signed(VecIn[0+:BitWidth])) :
                                                    W[(2 * (({28'b0, row} + 32'b1) * OutLen + col))+: 2] == 2'b01 ? $signed(VecIn[0+:BitWidth]) : {BitWidth{1'b0}}) +
                                                   (row == 4'b0 ? {BitWidth{1'b0}} : $signed(temp_out[(col*BitWidth)+:BitWidth]));
            end else begin // load into pipe registers
               if (col != 0) begin
                  pipe_out[(BitWidth*(col - 1))+:BitWidth] <=(W[(2 * ({28'b0, row_end} * OutLen + col))+: 2] == 2'b11 ? (-$signed(VecIn[BitWidth+:BitWidth])) :
                                                              W[(2 * ({28'b0, row_end} * OutLen + col))+: 2] == 2'b01 ? $signed(VecIn[BitWidth+:BitWidth]) : {BitWidth{1'b0}}) +
                                                             (W[(2 * (({28'b0, row_end} + 32'b1) * OutLen + col))+: 2] == 2'b11 ? (-$signed(VecIn[0+:BitWidth])) :
                                                              W[(2 * (({28'b0, row_end} + 32'b1) * OutLen + col))+: 2] == 2'b01 ? $signed(VecIn[0+:BitWidth]) : {BitWidth{1'b0}}) +
                                                              $signed(temp_out[(col*BitWidth)+:BitWidth]);
               end
            end
         end
         // Increment the row
         row <= row + 2;
         // If we are at the end of the loop
         if (row == row_end) begin
            // the output is set now - compute the first vec out
            VecOut <= (W[row_end * OutLen * 2 +: 2] == 2'b11 ? (-$signed(VecIn[BitWidth+:BitWidth])) :
                       W[row_end * OutLen * 2 +: 2] == 2'b01 ? $signed(VecIn[BitWidth+:BitWidth]) : {BitWidth{1'b0}}) +
                      (W[(row_end+1) * OutLen * 2 +: 2] == 2'b11 ? (-$signed(VecIn[0+:BitWidth])) :
                       W[(row_end+1) * OutLen * 2 +: 2] == 2'b01 ? $signed(VecIn[0+:BitWidth]) : {BitWidth{1'b0}}) +
                       temp_out[0+:BitWidth];
            set <= 1'b1;
            row <= 4'b0;
         // if pipelining then output the value from pipe_out
         end else begin
            VecOut <= pipe_out[row[3:1]*BitWidth+:BitWidth];
            set <= 1'b0;
         // if not pipelining set Vecout low
         end
         // set <= (row == row_end) && pipe_line;
      end else begin
         // Reset state when enable is low
         if (pipe_line == 1'b1) begin
            row <= row + 2;
            if (row != row_end) begin
               VecOut <= pipe_out[row[3:1]*BitWidth+:BitWidth];
               set <= 1'b0;
            end else begin
               VecOut <= {BitWidth{1'b0}};
               set <= 1'b0;
            end
         end else begin
            row <= 4'b0;
            VecOut <= {BitWidth{1'b0}};
            set <= 1'b0;
         end
      end
   end

   // assign set = (row == row_end) && pipe_line;

endmodule
