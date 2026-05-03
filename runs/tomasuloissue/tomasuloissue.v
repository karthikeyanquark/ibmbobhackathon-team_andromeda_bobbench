`timescale 1ns / 1ps
module wakeup_logic (
    input clk,
    input cdb_valid,
    input [3:0] cdb_tag,
    input [3:0] my_src_tag,
    input my_src_valid,
    output reg ready_to_issue
);
    always @(posedge clk) begin
        if (!my_src_valid) ready_to_issue <= 1'b1;
        else if (cdb_valid && (cdb_tag == my_src_tag)) ready_to_issue <= 1'b1;
        else ready_to_issue <= 1'b0;
    end
endmodule