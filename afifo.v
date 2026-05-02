`timescale 1ns / 1ps
module gray_sync (
    input clk_dest, rst_n,
    input [3:0] ptr_async,
    output reg [3:0] ptr_sync
);
    reg [3:0] meta;
    always @(posedge clk_dest or negedge rst_n) begin
        if (!rst_n) {ptr_sync, meta} <= 8'b0;
        else {ptr_sync, meta} <= {meta, ptr_async};
    end
endmodule