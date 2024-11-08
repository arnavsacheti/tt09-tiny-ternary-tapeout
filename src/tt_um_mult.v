/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */
 

module tt_um_mult # (
   parameter InLen = 10, 
   parameter OutLen = 5, 
   parameter BitWidth = 8
)(
   input wire			     clk,
   input wire [2:0]       row,
   input wire [BitWidth*2-1:0]      VecIn, 
   input wire [(2 * InLen)-1: 0] W,
   output wire [BitWidth-1:0] VecOut
);

   reg [BitWidth*OutLen-1:0]             temp_out;
   reg [BitWidth*OutLen-1:0]             pipe_out;
   wire [OutLen*BitWidth-1:0] temp_out_comb;

   wire [2*OutLen-1:0] row_data1 = W[0+: 2*OutLen]; // wire to hold the 0th row
   wire [2*OutLen-1:0] row_data2 = W[InLen+: 2*OutLen]; // wire to hold the 1st row - reduces usage to 73% (not all latches synth)


   genvar col;
   generate
      for (col = 0; col < OutLen*2; col = col + 2) begin
         assign temp_out_comb[(col<<2)+:BitWidth] = 
               (row_data1[(col)+:2] == 2'b11 ? (-$signed(VecIn[0+:BitWidth])) :
               row_data1[(col)+:2] == 2'b01 ? $signed(VecIn[0+:BitWidth]) : {BitWidth{1'b0}}) +
               (row_data2[(col)+:2] == 2'b11 ? (-$signed(VecIn[BitWidth+:BitWidth])) :
               row_data2[(col)+:2] == 2'b01 ? $signed(VecIn[BitWidth+:BitWidth]) : {BitWidth{1'b0}}) +
               (row[2:0] == 3'b0 ? {BitWidth{1'b0}} : $signed(temp_out[(col<<2)+:BitWidth]));
      end
   endgenerate

   always @(posedge clk) begin
      // Logic for computing the temporary sums (before piping into registers)
      temp_out <= temp_out_comb;
      if(row[2:0] == 3'b000) begin
         pipe_out <= temp_out;
      end else begin
         pipe_out <= pipe_out >> BitWidth; 
      end
   end

   assign VecOut = pipe_out[0+:BitWidth];

endmodule