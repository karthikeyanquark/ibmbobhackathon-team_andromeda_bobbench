`timescale 1ns / 1ps
module wallace_reduction (
    input [7:0] p0, p1, p2,
    output [7:0] sum, carry
);
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : csa
            assign sum[i] = p0[i] ^ p1[i] ^ p2[i];
            assign carry[i] = (p0[i] & p1[i]) | (p1[i] & p2[i]) | (p0[i] & p2[i]);
        end
    endgenerate
endmodule