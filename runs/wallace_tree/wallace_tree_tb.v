`timescale 1ns / 1ps
module tb_wallace_reduction;
    reg [7:0] p0, p1, p2;
    wire [7:0] sum, carry;

    reg clk, reset;
    initial begin
        // Initialize signals
        p0 = 0; p1 = 0; p2 = 0;
        clk = 0; reset = 0;
        
        // Set initial values for the inputs
        p0 = 8'h12; p1 = 8'h34; p2 = 8'h56;

        // Start the clock
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_wallace_reduction);
        
        // Initialize the clock
        always #5 clk = ~clk;

        // Reset the design
        #5 reset = 1;
        #5 reset = 0;

        // Apply stimulus
        #10 p0 = 8'hFF;
        #10 p1 = 8'hAA;
        #10 p2 = 8'h55;
        
        // Wait for a few more cycles
        #10;
        #10;
        #10;
        
        // Finish simulation
        $finish;
    end

    // Instantiate the DUT
    wallace_reduction UUT(
        .p0(p0),
        .p1(p1),
        .p2(p2),
        .sum(sum),
        .carry(carry),
        .clk(clk),
        .reset(reset)
    );
endmodule