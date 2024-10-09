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
   input wire signed [BitWidth-1:0]      VecIn [1:0], 
   input wire signed [1:0] W [InLen][OutLen],
   output reg signed [BitWidth-1:0] VecOut,
   output reg set
);

   reg [3:0]                    row;
   reg signed [BitWidth-1:0]    temp_out[OutLen];
   reg signed [BitWidth-1:0]    pipe_out[OutLen-1];
   integer                      col;
   integer                      i, j;

   

   always @ (posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         row <= 4'b0;
         set <= 1'b0;
         for (i = 0; i < OutLen; i = i + 1) begin
            temp_out[i] <= {BitWidth{1'b0}};
            pipe_out[i] <= {BitWidth{1'b0}};
         end
      end else if(en) begin
         // Logic for computing the temporary sums (before piping into registers)
         for (col = 0; col < OutLen; col = col + 1) begin
            // If we are not at the end of the loop
            if (row != 4'b1110) begin
               temp_out[col] <= (W[row][col]==2'b11 ? (-VecIn[0]):
                                 W[row][col]==2'b01 ?   VecIn[0]: {BitWidth{1'b0}}) +
                                 (W[row+1][col]==2'b11 ? (-VecIn[1]):
                                 W[row+1][col]==2'b01 ?   VecIn[1]: {BitWidth{1'b0}}) +
                                 (row == 4'b0 ? {BitWidth{1'b0}} : temp_out[col]);
            end else begin // load into pipe registers
               if(col != 0) begin // no need to load in the first column, the Vec Out already has it
                  pipe_out[col-1] <= (W[row][col]==2'b11 ? (-VecIn[0]):
                                    W[row][col]==2'b01 ?   VecIn[0]: {BitWidth{1'b0}}) +
                                   (W[row+1][col]==2'b11 ? (-VecIn[1]):
                                    W[row+1][col]==2'b01 ?   VecIn[1]: {BitWidth{1'b0}}) +
                                    temp_out[col];
               end
            end
         end
         // Increment the row
         row <= row + 2;
         // If we are at the end of the loop
         if (row == 4'b1110) begin
            // the output is set now - compute the first vec out
            set <= 1'b1;
            VecOut <= (W[4'b1110][0]==2'b11 ? (-VecIn[0]):
                     W[4'b1110][0]==2'b01 ?   VecIn[0]: {BitWidth{1'b0}}) +
                     (W[4'b1111][0]==2'b11 ? (-VecIn[1]):
                     W[4'b1111][0]==2'b01 ?   VecIn[1]: {BitWidth{1'b0}}) +
                     temp_out[0];
         end else if (set && row!= 4'b1110) begin
            VecOut <= pipe_out[row[3:1]];
         end else if (row!= 4'b1110 && !set) begin
            VecOut <= {BitWidth{1'b0}};
         end
      end else begin
         row <= 4'b0;
         set <= 1'b0;         
         VecOut <= {BitWidth{1'b0}};
      end
   end
endmodule
