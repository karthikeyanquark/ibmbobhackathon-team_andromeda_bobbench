`timescale 1ns / 1ps
module axi4_lite_slave (
    input aclk, aresetn,
    input awvalid, input [31:0] awaddr, output reg awready,
    input wvalid, input [31:0] wdata, output reg wready,
    output reg bvalid, output reg [1:0] bresp, input bready
);
    reg [1:0] state;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state <= 0; awready <= 0; wready <= 0; bvalid <= 0;
        end else case(state)
            0: if (awvalid && wvalid) begin
                awready <= 1; wready <= 1; state <= 1;
            end
            1: begin
                awready <= 0; wready <= 0; bvalid <= 1; bresp <= 2'b00; state <= 2;
            end
            2: if (bready) begin
                bvalid <= 0; state <= 0;
            end
        endcase
    end
endmodule