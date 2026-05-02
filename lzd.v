`timescale 1ns / 1ps
module leading_zero_detector (
    input [15:0] mantissa_in,
    output reg [3:0] shift_amt,
    output reg [15:0] normalized_out
);
    always @(*) begin
        if (mantissa_in[15]) shift_amt = 0;
        else if (mantissa_in[14]) shift_amt = 1;
        else if (mantissa_in[13]) shift_amt = 2;
        // ... truncated for brevity ...
        else shift_amt = 15;
        
        normalized_out = mantissa_in << shift_amt;
    end
endmodule