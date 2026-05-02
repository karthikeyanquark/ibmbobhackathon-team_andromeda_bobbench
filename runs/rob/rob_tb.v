`timescale 1ns / 1ps
module tb_rob_manager;
    parameter DEPTH = 16;

    // 1. Reg/Wire declarations
    logic clk, rst_n, dispatch_valid, commit_ready, full, empty;
    logic [$clog2(DEPTH)-1:0] head, tail;

    // 2. Clock gen
    always #5 clk = ~clk;

    // 3. DUT Instance
    tb_rob_manager #(DEPTH) dut (
        .clk(clk),
        .rst_n(rst_n),
        .dispatch_valid(dispatch_valid),
        .commit_ready(commit_ready),
        .full(full),
        .empty(empty),
        .head(head),
        .tail(tail)
    );

    // 3. Initial begin block for test cases
    initial begin
        // Initialization
        rst_n = 0;
        #20; rst_n = 1;
        #20;

        // Test case 1: Normal operation with no FIFO overflow/underflow
        dispatch_valid = 1'b1;
        commit_ready = 1'b1;
        #40;
        dispatch_valid = 1'b0;
        commit_ready = 1'b0;
        #20;

        // Test case 2: Full FIFO check
        dispatch_valid = 1'b1;
        commit_ready = 1'b0;
        #20;
        #20; // wait for 40 total ticks, should assert "full"
        dispatch_valid = 1'b0;
        commit_ready = 1'b1;
        #20;
        #20; // wait for 40 total ticks, should assert "empty" if no further dispatch
        $finish;
    end
endmodule