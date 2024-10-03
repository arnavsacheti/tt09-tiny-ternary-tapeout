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
   input wire signed [1:0] 		     W [InLen][OutLen],
   output reg signed [BitWidth-1:0] VecOut
);

   reg [3:0]                    row;
   reg                          set;
   reg signed [BitWidth-1:0]    temp_out[OutLen];
   reg signed [BitWidth-1:0]    pipe_out[OutLen];
   integer                      col;
   integer                      i;

   always @ (posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         row <= 4'b0;
         set <= 1'b0;
         for (i = 0; i < OutLen; i = i + 1) begin
            temp_out[i] <= {BitWidth{1'b0}};
            pipe_out[i] <= {BitWidth{1'b0}};
         end
      end else if(en) begin
         for (col = 0; col < OutLen; col = col + 1) begin
           temp_out[col] <= (W[row][col]==2'b11 ? (-VecIn[0]):
		             W[row][col]==2'b01 ?   VecIn[0]: {BitWidth{1'b0}}) +
		            (W[row+1][col]==2'b11 ? (-VecIn[1]):
		             W[row+1][col]==2'b01 ?   VecIn[1]: {BitWidth{1'b0}}) +
			     ((row == 4'b0) ? {BitWidth{1'b0}}:temp_out[col]);
         end
         row <= row + 2;
         if (row == 4'b1110) begin
            set <= 1'b1;
         end
         if (row == 4'b0 && set) begin
            for (i = 0; i < OutLen; i = i + 1) begin
               pipe_out[i] <= temp_out[i];
            end
            VecOut <= temp_out[0];
         end else if (set) begin
            VecOut <= pipe_out[row[3:1]];
         end else begin
            VecOut <= {BitWidth{1'b0}};
         end
      end
   end
endmodule
