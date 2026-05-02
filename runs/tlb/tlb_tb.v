`timescale 1ns / 1ps

module tb_tlb_4way;
    reg clk;
    reg [19:0] vpn_in;
    wire [19:0] ppn_out;
    wire hit;

    // Local reg to hold clock value (driving local signal clk)
    reg local_clk;

    // Clock generator
    always #5 local_clk = ~local_clk;

    // DUT instance (mapping local signals to ports)
    tlb_4way dut (
        .clk(local_clk),
        .vpn_in(vpn_in),
        .ppn_out(ppn_out),
        .hit(hit)
    );

    initial begin
        // Reset sequence
        clk = 1'b0; vpn_in = 20'h0;
        #20;
        // Test sequence
        clk = 1'b1; vpn_in = 20'hDEADBEEF;
        #20;
        vpn_in = 20'hBABEFACE;
        #20;
        vpn_in = 20'hCAFEBABE;
        #20;
        vpn_in = 20'hFEEEDEEA;
        #20;
        $finish;
    end

    // Dump file for waveform viewing
    initial $dumpfile("dump.vcd");
    initial $dumpvars(0, tb_tlb_4way);
endmodule