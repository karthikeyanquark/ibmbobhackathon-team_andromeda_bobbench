`timescale 1ns/1ps

module tb_wakeup_logic();
    reg clk;
    reg cdb_valid;
    reg [3:0] cdb_tag;
    reg [3:0] my_src_tag;
    reg my_src_valid;
    wire ready_to_issue;

    // Instantiate the DUT
    wakeup_logic dut (
        .clk(clk),
        .cdb_valid(cdb_valid),
        .cdb_tag(cdb_tag),
        .my_src_tag(my_src_tag),
        .my_src_valid(my_src_valid),
        .ready_to_issue(ready_to_issue)
    );

    // 1. Signal declarations
    // 2. Clock generation (if needed)
    reg reset_n = 1;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period
    end

    // 3. Waveform dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_wakeup_logic);
    end

    // 5. Test stimulus with comprehensive coverage
    localparam int NUM_TEST_VECTORS = 50;
    integer test_id;
    initial begin
        reset_n = 0;
        #20;    // Hold reset for 20ns
        reset_n = 1;
        for (test_id = 0; test_id < NUM_TEST_VECTORS; test_id++) begin
            // Edge Cases + Boundary Values
            (cdb_valid, cdb_tag, my_src_tag, my_src_valid) = test_vector[test_id];
            #10;  // Give the DUT enough time to respond
        end
        $finish;
    end

    // 6. Self-checking with expected values
    parameter int expected_count = 4;
    reg [NUM_TEST_VECTORS-1:0] error_count;
    initial begin
        error_count = 0;
    end

    task check_output;
        input expected_value;
        begin
            if (ready_to_issue !== expected_value) begin
                $display("ERROR at time %0t: Expected %b, Got %b", 
                         $time, expected_value, ready_to_issue);
                error_count = error_count + 1;
            end
        end
    endtask

    // Test vectors: Comprehensive set of test vectors
    parameter int NUM_TEST_VECTORS = 50;
    localparam [3:0] test_vectors[NUM_TEST_VECTORS][2][5] = {
        // Edge Cases
        '0'h0, 1'b0, '0'h0, 1'b0, {26'd0, 3'b0}, {26'd0, 3'b7},
        // All 0s
        {1'b0, 4'b0, 4'b0, 1'b0},
        // All 1s
        {1'b1, 4'b1, 4'b1, 1'b1},
        // Alternating patterns
        {1'b0, 4'b1, 4'b0, 1'b1}, {1'b1, 4'b0, 4'b1, 1'b0},
        // Boundary values
        {1'b0, 4'b1, 4'b1, 1'b0}, {1'b1, 4'b0, 4'b1, 1'b1},
        // Random values (replace these with actual randomized test vectors)
        {1'b0, 4'b0, 4'b0, 1'b0}, {1'b1, 4'b1, 4'b1, 1'b1},
        // More patterns...
    };

    task automatic run_tests;
        input int test_id;
        reg [2:0] expected_value;
        begin
            (cdb_valid, cdb_tag, my_src_tag, my_src_valid) = test_vectors[test_id];
            expected_value = expected_count;

            // Run test for 100ns
            repeat (100) @(posedge clk);

            check_output(expected_value);
        end
    endtask

    initial begin
        fork
            run_tests(0);
        join
    end
endmodule