`timescale 1ns / 1ns
module tb_branch_target_buffer;
    parameter num_tests = 5; // Change as needed
    reg clk, rst_n;
    reg [31:0] pc_in;
    reg update_en, branch_taken;
    reg [31:0] update_pc, target_pc;
    wire predict_taken, predicted_pc;

    // Instantiate the module under test (MUT)
    branch_target_buffer u_branch_target_buffer (
        .*
    );

    // Signal declarations
    wire [31:0] tag_array [0:15];
    wire [31:0] target_array [0:15];
    wire [1:0] bimodal_counters [0:15];

    // Assign internal signals to MUT output
    assign predict_taken = u_branch_target_buffer.predict_taken;
    assign predicted_pc = u_branch_target_buffer.predicted_pc;

    // Clock generation
    always begin
        clk = 1'b0;
        #20;
        clk = 1'b1;
        #20;
    end

    initial begin
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;

        // Test stimulus goes here

        #100 $finish;
    end
endmodule