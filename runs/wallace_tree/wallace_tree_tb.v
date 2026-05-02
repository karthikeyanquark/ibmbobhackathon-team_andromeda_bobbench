`timescale 1ns/1ps

module tb_wallace_reduction();

    // 1. Signal declarations
    reg [7:0] p0, p1, p2;
    wire [7:0] sum, carry;

    // 2. DUT instantiation
    wallace_reduction dut (
        .p0(p0),
        .p1(p1),
        .p2(p2),
        .sum(sum),
        .carry(carry)
    );

    // 3. Clock generation (if needed)
    reg clk = 0;
    always #5 clk = ~clk;

    // 4. Waveform dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_wallace_reduction);
    end

    // 5. Test stimulus with comprehensive coverage
    integer i;

    initial begin
        clk = 0;
        for (i = 0; i < 50; i = i + 1) begin
            p0 = $random;
            p1 = $random;
            p2 = $random;

            @(posedge clk);
            check_output(expected_value);
        end
    end

    // 6. Self-checking with expected values
    task check_output;
        input expected_value;
        begin
            if (actual_output !== expected_value) begin
                $display("ERROR at time %0t: Expected %h, Got %h", 
                         $time, expected_value, sum);
                error_count = error_count + 1;
            end
        end
    endtask

endmodule