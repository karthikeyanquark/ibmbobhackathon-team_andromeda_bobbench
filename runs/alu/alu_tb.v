`timescale 1ns/1ps

module tb_alu();
    // 1. Signal declarations
    reg [7:0] a;
    reg [7:0] b;
    reg [2:0] opcode;
    reg clk;
    wire [7:0] result;
    wire zero;
    wire carry;

    // 2. DUT instantiation
    alu u_alu(
        .a(a),
        .b(b),
        .opcode(opcode),
        .result(result),
        .zero(zero),
        .carry(carry)
    );

    // 3. Clock generation (if needed) - Not needed for this module
    // 4. Waveform dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_alu);
    end

    // 5. Test stimulus with comprehensive coverage
    integer error_count = 0;
    initial begin
        a = 0; b = 0; opcode = 3'b000;
        repeat(50) begin : g_stimulus
            @(posedge clk);
            check_output(8'h000);
            @(posedge clk);
            check_output(8'h000 << 1); // Shift left by 1
            @(posedge clk);
            check_output(8'h000 >> 1); // Shift right by 1
            @(posedge clk);
            check_output(8'hFFFF); // All ones (subtract)
            @(posedge clk);
            check_output(8'h0000); // All zeros (add)
            @(posedge clk);
            a = 8'h1234; b = 8'h5678; opcode = 3'b000; // Full range
            @(posedge clk);
            check_output(8'hB1B1); // Full range result
            @(posedge clk);
            // Repeat other operations and edge cases here
        end
        $display("Total errors: %0d", error_count);
        $finish;
    end

    // 6. Self-checking with expected values
    task check_output;
        input expected_value;
        begin
            if (result !== expected_value) begin
                $display("ERROR at time %0t: Expected %h, Got %h", 
                         $time, expected_value, result);
                error_count = error_count + 1;
            end
        end
    endtask

endmodule