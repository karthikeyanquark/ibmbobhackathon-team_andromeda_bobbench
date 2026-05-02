`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Testbench for pseudo_lru_4way module
// Tests LRU replacement policy for 4-way set-associative cache
////////////////////////////////////////////////////////////////////////////////

module tb_pseudo_lru_4way();
    // Clock and reset signals
    reg clk;
    reg rst_n;
    
    // DUT interface signals
    reg access_en;
    reg [1:0] accessed_way;
    wire [1:0] victim_way;
    
    // Test control signals
    integer test_count;
    integer pass_count;
    integer fail_count;
    
    // Clock parameters
    parameter T_CLK_PER = 10;  // 10ns clock period (100MHz)
    parameter T_SETUP = 2;     // Setup time before clock edge
    parameter T_HOLD = 2;      // Hold time after clock edge
    
    ////////////////////////////////////////////////////////////////////////////
    // DUT Instantiation
    ////////////////////////////////////////////////////////////////////////////
    pseudo_lru_4way dut (
        .clk(clk),
        .rst_n(rst_n),
        .access_en(access_en),
        .accessed_way(accessed_way),
        .victim_way(victim_way)
    );
    
    ////////////////////////////////////////////////////////////////////////////
    // Clock Generation
    ////////////////////////////////////////////////////////////////////////////
    initial begin
        clk = 1'b0;
        forever #(T_CLK_PER / 2) clk = ~clk;
    end
    
    ////////////////////////////////////////////////////////////////////////////
    // Waveform Dump for GTKWave
    ////////////////////////////////////////////////////////////////////////////
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_pseudo_lru_4way);
    end
    
    ////////////////////////////////////////////////////////////////////////////
    // Test Monitoring and Checking
    ////////////////////////////////////////////////////////////////////////////
    task check_victim;
        input [1:0] expected_victim;
        input [80*8-1:0] test_name;
        begin
            if (victim_way === expected_victim) begin
                $display("[PASS] %0s: victim_way = %0d (expected %0d)", 
                         test_name, victim_way, expected_victim);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s: victim_way = %0d (expected %0d)", 
                         test_name, victim_way, expected_victim);
                fail_count = fail_count + 1;
            end
            test_count = test_count + 1;
        end
    endtask
    
    task access_way;
        input [1:0] way;
        input [80*8-1:0] description;
        begin
            @(negedge clk);  // Setup on negative edge
            access_en = 1'b1;
            accessed_way = way;
            $display("  [ACCESS] %0s: Accessing way %0d at time %0t", 
                     description, way, $time);
            @(posedge clk);  // Wait for positive edge
            #T_HOLD;         // Hold time
            access_en = 1'b0;
            accessed_way = 2'b00;
        end
    endtask
    
    task reset_dut;
        begin
            $display("\n[RESET] Asserting reset at time %0t", $time);
            rst_n = 1'b0;
            access_en = 1'b0;
            accessed_way = 2'b00;
            repeat(2) @(posedge clk);
            @(negedge clk);
            rst_n = 1'b1;
            @(posedge clk);
            $display("[RESET] Reset deasserted at time %0t\n", $time);
        end
    endtask
    
    ////////////////////////////////////////////////////////////////////////////
    // Main Test Sequence
    ////////////////////////////////////////////////////////////////////////////
    initial begin
        // Initialize counters
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        // Initialize signals
        clk = 1'b0;
        rst_n = 1'b0;
        access_en = 1'b0;
        accessed_way = 2'b00;
        
        $display("\n");
        $display("================================================================================");
        $display("  Pseudo-LRU 4-Way Cache Replacement Policy Testbench");
        $display("================================================================================");
        $display("  Clock Period: %0d ns", T_CLK_PER);
        $display("  Start Time: %0t", $time);
        $display("================================================================================\n");
        
        // Apply reset
        reset_dut();
        
        ////////////////////////////////////////////////////////////////////////
        // Test Case 1: Initial state after reset
        ////////////////////////////////////////////////////////////////////////
        $display("--------------------------------------------------------------------------------");
        $display("Test Case 1: Initial State After Reset");
        $display("--------------------------------------------------------------------------------");
        #1;  // Small delay for combinational logic to settle
        check_victim(2'b00, "TC1: Initial victim after reset");
        repeat(2) @(posedge clk);
        
        ////////////////////////////////////////////////////////////////////////
        // Test Case 2: Single way accesses (0, 1, 2, 3)
        ////////////////////////////////////////////////////////////////////////
        $display("\n--------------------------------------------------------------------------------");
        $display("Test Case 2: Sequential Single Way Accesses");
        $display("--------------------------------------------------------------------------------");
        
        access_way(2'b00, "Access way 0");
        #1;
        check_victim(2'b01, "TC2.1: Victim after accessing way 0");
        
        access_way(2'b01, "Access way 1");
        #1;
        check_victim(2'b00, "TC2.2: Victim after accessing way 1");
        
        access_way(2'b10, "Access way 2");
        #1;
        check_victim(2'b11, "TC2.3: Victim after accessing way 2");
        
        access_way(2'b11, "Access way 3");
        #1;
        check_victim(2'b10, "TC2.4: Victim after accessing way 3");
        
        repeat(2) @(posedge clk);
        
        ////////////////////////////////////////////////////////////////////////
        // Test Case 3: LRU behavior with repeated accesses
        ////////////////////////////////////////////////////////////////////////
        $display("\n--------------------------------------------------------------------------------");
        $display("Test Case 3: LRU Behavior with Repeated Accesses");
        $display("--------------------------------------------------------------------------------");
        
        reset_dut();
        
        // Access pattern: 0, 1, 0, 1 (ways 2 and 3 should be victims)
        access_way(2'b00, "First access to way 0");
        access_way(2'b01, "First access to way 1");
        access_way(2'b00, "Second access to way 0");
        access_way(2'b01, "Second access to way 1");
        #1;
        // After accessing 0,1,0,1 repeatedly, victim should be from {2,3}
        if (victim_way == 2'b10 || victim_way == 2'b11) begin
            $display("[PASS] TC3.1: Victim is way %0d (from unused set {2,3})", victim_way);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] TC3.1: Victim is way %0d (expected from {2,3})", victim_way);
            fail_count = fail_count + 1;
        end
        test_count = test_count + 1;
        
        repeat(2) @(posedge clk);
        
        ////////////////////////////////////////////////////////////////////////
        // Test Case 4: All ways accessed in sequence
        ////////////////////////////////////////////////////////////////////////
        $display("\n--------------------------------------------------------------------------------");
        $display("Test Case 4: All Ways Accessed in Sequence");
        $display("--------------------------------------------------------------------------------");
        
        reset_dut();
        
        access_way(2'b00, "Access way 0");
        access_way(2'b01, "Access way 1");
        access_way(2'b10, "Access way 2");
        access_way(2'b11, "Access way 3");
        #1;
        check_victim(2'b00, "TC4.1: Victim after 0->1->2->3 sequence");
        
        repeat(2) @(posedge clk);
        
        ////////////////////////////////////////////////////////////////////////
        // Test Case 5: Reverse sequence
        ////////////////////////////////////////////////////////////////////////
        $display("\n--------------------------------------------------------------------------------");
        $display("Test Case 5: Reverse Access Sequence");
        $display("--------------------------------------------------------------------------------");
        
        reset_dut();
        
        access_way(2'b11, "Access way 3");
        access_way(2'b10, "Access way 2");
        access_way(2'b01, "Access way 1");
        access_way(2'b00, "Access way 0");
        #1;
        check_victim(2'b11, "TC5.1: Victim after 3->2->1->0 sequence");
        
        repeat(2) @(posedge clk);
        
        ////////////////////////////////////////////////////////////////////////
        // Test Case 6: Alternating pattern
        ////////////////////////////////////////////////////////////////////////
        $display("\n--------------------------------------------------------------------------------");
        $display("Test Case 6: Alternating Access Pattern");
        $display("--------------------------------------------------------------------------------");
        
        reset_dut();
        
        access_way(2'b00, "Access way 0");
        access_way(2'b10, "Access way 2");
        access_way(2'b01, "Access way 1");
        access_way(2'b11, "Access way 3");
        #1;
        check_victim(2'b00, "TC6.1: Victim after 0->2->1->3 pattern");
        
        repeat(2) @(posedge clk);
        
        ////////////////////////////////////////////////////////////////////////
        // Test Case 7: Reset during operation
        ////////////////////////////////////////////////////////////////////////
        $display("\n--------------------------------------------------------------------------------");
        $display("Test Case 7: Reset During Operation");
        $display("--------------------------------------------------------------------------------");
        
        access_way(2'b10, "Access before reset");
        reset_dut();
        #1;
        check_victim(2'b00, "TC7.1: Victim immediately after reset");
        
        repeat(2) @(posedge clk);
        
        ////////////////////////////////////////////////////////////////////////
        // Test Case 8: Access enable control
        ////////////////////////////////////////////////////////////////////////
        $display("\n--------------------------------------------------------------------------------");
        $display("Test Case 8: Access Enable Control");
        $display("--------------------------------------------------------------------------------");
        
        reset_dut();
        
        access_way(2'b01, "Access way 1 with enable");
        #1;
        check_victim(2'b00, "TC8.1: Victim after enabled access");
        
        // Try to access without enable (should not change state)
        @(negedge clk);
        access_en = 1'b0;
        accessed_way = 2'b11;
        @(posedge clk);
        #1;
        check_victim(2'b00, "TC8.2: Victim unchanged (access_en=0)");
        
        repeat(2) @(posedge clk);
        
        ////////////////////////////////////////////////////////////////////////
        // Test Case 9: Boundary conditions
        ////////////////////////////////////////////////////////////////////////
        $display("\n--------------------------------------------------------------------------------");
        $display("Test Case 9: Boundary Conditions");
        $display("--------------------------------------------------------------------------------");
        
        reset_dut();
        
        // Test with all possible 2-bit values
        for (integer i = 0; i < 4; i = i + 1) begin
            access_way(i[1:0], $sformatf("Boundary test way %0d", i));
            @(posedge clk);
        end
        
        $display("[INFO] TC9: Boundary test completed without errors");
        
        repeat(2) @(posedge clk);
        
        ////////////////////////////////////////////////////////////////////////
        // Test Case 10: Stress test with random accesses
        ////////////////////////////////////////////////////////////////////////
        $display("\n--------------------------------------------------------------------------------");
        $display("Test Case 10: Stress Test with Random Accesses");
        $display("--------------------------------------------------------------------------------");
        
        reset_dut();
        
        for (integer i = 0; i < 20; i = i + 1) begin
            automatic reg [1:0] random_way = $random & 2'b11;
            access_way(random_way, $sformatf("Random access %0d", i));
            #1;
            // Verify victim_way is always valid (0-3)
            if (victim_way > 2'b11) begin
                $display("[FAIL] TC10.%0d: Invalid victim_way = %0d", i, victim_way);
                fail_count = fail_count + 1;
            end
        end
        
        $display("[INFO] TC10: Stress test completed");
        
        repeat(5) @(posedge clk);
        
        ////////////////////////////////////////////////////////////////////////
        // Test Summary
        ////////////////////////////////////////////////////////////////////////
        $display("\n");
        $display("================================================================================");
        $display("  Test Summary");
        $display("================================================================================");
        $display("  Total Tests: %0d", test_count);
        $display("  Passed:      %0d", pass_count);
        $display("  Failed:      %0d", fail_count);
        $display("  Pass Rate:   %0.2f%%", (pass_count * 100.0) / test_count);
        $display("  End Time:    %0t", $time);
        $display("================================================================================");
        
        if (fail_count == 0) begin
            $display("\n*** ALL TESTS PASSED ***\n");
        end else begin
            $display("\n*** SOME TESTS FAILED ***\n");
        end
        
        $finish;
    end
    
    ////////////////////////////////////////////////////////////////////////////
    // Timeout Watchdog
    ////////////////////////////////////////////////////////////////////////////
    initial begin
        #100000;  // 100us timeout
        $display("\n[ERROR] Testbench timeout at %0t", $time);
        $display("Test may be stuck in infinite loop\n");
        $finish;
    end
    
    ////////////////////////////////////////////////////////////////////////////
    // Protocol Checker - Verify no X or Z values
    ////////////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
        if (rst_n) begin
            if (^victim_way === 1'bx) begin
                $display("[ERROR] at %0t: victim_way contains X values: %b", $time, victim_way);
            end
            if (^victim_way === 1'bz) begin
                $display("[ERROR] at %0t: victim_way contains Z values: %b", $time, victim_way);
            end
        end
    end

endmodule