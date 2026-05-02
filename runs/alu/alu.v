`timescale 1ns / 1ps

module alu (
    input [7:0] a,
    input [7:0] b,
    input [2:0] opcode,
    output reg [7:0] result,
    output reg zero,
    output reg carry
);

    always @(*) begin
        carry = 1'b0;
        
        case(opcode)
            3'b000: {carry, result} = a + b;
            3'b001: result = a - b;
            3'b010: result = a & b;
            3'b011: result = a | b;
            3'b100: result = a ^ b;
            3'b101: result = ~a;
            3'b110: result = a << 1;
            3'b111: result = a >> 1;
            default: result = 8'h00; 
        endcase

        zero = (result == 8'h00) ? 1'b1 : 1'b0;
    end

endmodule