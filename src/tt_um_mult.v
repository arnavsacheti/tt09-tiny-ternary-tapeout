/*
 * Copyright (c) 2024 Arnav Sacheti & Jack Adiletta
 * SPDX-License-Identifier: Apache-2.0
 */
 

module tt_um_mult # (
   parameter InLen = 14, 
   parameter OutLen = 7, 
   parameter BitWidth = 8
)(
   input wire			     clk,
   input wire [2:0]       row,
   input wire [BitWidth*2-1:0]      VecIn, 
   input wire [(2 * InLen)-1: 0] W,
   output wire [BitWidth-1:0] VecOut
);
   reg [BitWidth*OutLen-1:0]             temp_out;
   wire [BitWidth*OutLen-1:0]             temp_out_q;
   reg [BitWidth*OutLen-1:0]             pipe_out;

   // wire [2*OutLen-1:0] row_data1 = W[({24'b0, row, 5'b0_0000})+: 2*OutLen]; // Register to hold the entire row
   // wire [2*OutLen-1:0] row_data2 = W[({24'b0, row, 5'b1_0000})+: 2*OutLen]; // Register to hold the entire row

   wire [2*OutLen-1:0] row_data1 = W[0+: 2*OutLen]; // wire to hold the 0th row
   wire [2*OutLen-1:0] row_data2 = W[14+: 2*OutLen]; // wire to hold the 1st row - reduces usage to 73% (not all latches synth)

   always @(posedge clk) begin
      // Logic for computing the temporary sums (before piping into registers)
      temp_out <= temp_out_q;
   end

   genvar gcol;
   generate
      for (gcol = 0; gcol < OutLen*2; gcol = gcol + 2) begin
            assign temp_out_q[(gcol<<2)+:BitWidth] = (row_data1[(gcol)+1] ? (-$signed(VecIn[0+:BitWidth])) :
                                                      row_data1[(gcol)+0] ? $signed(VecIn[0+:BitWidth]) : {BitWidth{1'b0}}) +
                                                     (row_data2[(gcol)+1] ? (-$signed(VecIn[BitWidth+:BitWidth])) :
                                                      row_data2[(gcol)+0] ? $signed(VecIn[BitWidth+:BitWidth]) : {BitWidth{1'b0}}) +
                                                     (row[2:0] == 3'b0 ? {BitWidth{1'b0}} : $signed(temp_out[(gcol<<2)+:BitWidth]));
      end
   endgenerate

   always @(row) begin
      if(row[2:0] == 3'b000)
         pipe_out = temp_out;
   end

   assign VecOut = pipe_out[({3'b0, row[2:0]}<<3)+:BitWidth];

endmodule