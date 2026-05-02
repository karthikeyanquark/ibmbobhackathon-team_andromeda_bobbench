module axi4_lite_slave_tb();
    // Signal Declaration
    reg aclk;
    reg aresetn;
    reg awvalid;
    reg [31:0] awaddr;
    wire awready;
    wire wready;
    reg wvalid;
    reg [31:0] wdata;
    wire bvalid;
    wire [1:0] bresp;
    wire bready;

    // Instantiate the DUT
    axi4_lite_slave DUT (.*);

    // Clock Generation
    always #5 aclk = ~aclk;

    // Test Sequence
    initial begin
        // Initialize signals
        aclk = 1'b0;
        aresetn = 1'b0;
        awaddr = 32'hDEADBEEF;
        wdata = 32'hCAFEBABE;

        // Apply reset
        #(10) aresetn = 1'b1;

        // Test Write Operation
        #(10) awvalid = 1'b1;
        #(10) awaddr = 32'hCAFEDEAD;
        #(10) wvalid = 1'b1;
        #(10) wdata = 32'hDEADBEEF;
        #(10) awvalid = 1'b0;
        #(10) wvalid = 1'b0;

        // Expect bvalid and bresp
        #(10) if (!(bvalid && bresp == 2'b00)) begin
            $display("ERROR: Write operation failed");
            $finish;
        end

        // Apply reset
        #(10) aresetn = 1'b0;
        #(10) aresetn = 1'b1;

        // Test Read Operation
        #(10) awvalid = 1'b1;
        #(10) awaddr = 32'hCAFEBABE;
        #(10) awvalid = 1'b0;

        // Expect awready
        #(10) if (!awready) begin
            $display("ERROR: Read operation awready failed");
            $finish;
        end

    end
endmodule