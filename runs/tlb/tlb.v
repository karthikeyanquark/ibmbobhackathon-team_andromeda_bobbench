`timescale 1ns / 1ps
module tlb_4way (
    input clk,
    input [19:0] vpn_in,
    output reg [19:0] ppn_out,
    output reg hit
);
    reg [19:0] vpn_array [0:3];
    reg [19:0] ppn_array [0:3];
    reg valid_array [0:3];

    integer i;
    always @(*) begin
        hit = 0; ppn_out = 0;
        for (i = 0; i < 4; i = i + 1) begin
            if (valid_array[i] && vpn_array[i] == vpn_in) begin
                hit = 1;
                ppn_out = ppn_array[i];
            end
        end
    end
endmodule