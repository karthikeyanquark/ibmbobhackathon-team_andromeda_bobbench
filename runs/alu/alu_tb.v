`timescale 1ns / 1ps

module tb_alu;

    reg [7:0] a, b;
    reg [2:0] opcode;
    wire [7:0] result;
    wire zero;
    wire carry;

    alu tb_alu_inst (.a(a), .b(b), .opcode(opcode), .result(result), .zero(zero), .carry(carry));

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_alu);

        a = 8'b00000001; b = 8'b00000001; opcode = 3'b000; #10;
        a = 8'b00000010; b = 8'b00000001; opcode = 3'b001; #10;
        a = 8'b11111111; b = 8'b11111111; opcode = 3'b010; #10;
        a = 8'hAAAA; b = 8'h5555; opcode = 3'b011; #10;
        a = 8'hFFFF; b = 8'h0000; opcode = 3'b100; #10;
    end

endmodule