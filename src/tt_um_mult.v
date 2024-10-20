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
   reg [BitWidth*OutLen-1:0]             temp_out;
   wire [BitWidth*OutLen-1:0]            temp_out_d;
   reg [BitWidth*OutLen-1:0]             pipe_out;

   wire [2*OutLen-1:0] row_data1 = W[{row, 1'b0, 4'h0} +: 2*OutLen]; // Register to hold the entire row
   wire [2*OutLen-1:0] row_data2 = W[{row, 1'b1, 4'h0} +: 2*OutLen]; // Register to hold the entire row

   wire [BitWidth*2-1:0] VecIn_neg;
   genvar  gi;

   for (gi = 0; gi < 2; gi++) begin
      assign VecIn_neg[gi * BitWidth +: BitWidth] = ~VecIn[gi * BitWidth +: BitWidth] + 1;
   end

   for (gi = 0; gi < OutLen; gi++) begin
      assign temp_out_d[gi << 3 +: BitWidth] = ((row_data1[{gi[2:0], 1'b1}] ? VecIn_neg[BitWidth+:BitWidth] : VecIn[BitWidth+:BitWidth]) 
                                                   & {BitWidth{row_data1[{gi[2:0], 1'b0}]}}) +
                                               ((row_data2[{gi[2:0], 1'b1}] ? VecIn_neg[BitWidth+:BitWidth] : VecIn[BitWidth+:BitWidth]) 
                                                   & {BitWidth{row_data1[{gi[2:0], 1'b0}]}})  +
                                               (temp_out[gi<<3+:BitWidth] & {BitWidth{|row}});
   end

   always @(posedge clk) begin
      // Logic for computing the temporary sums (before piping into registers)
      temp_out <= temp_out_d;
   end

   always @(row) begin
      if(~|row && en) 
         pipe_out = temp_out;
  end

   assign VecOut = pipe_out[({3'b0, row}<<3)+:BitWidth];

endmodule
