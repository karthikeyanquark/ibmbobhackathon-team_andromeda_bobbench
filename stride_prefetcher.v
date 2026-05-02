`timescale 1ns / 1ps
module stride_prefetcher (
    input clk, rst_n,
    input mem_access_valid,
    input [31:0] access_addr,
    output reg prefetch_valid,
    output reg [31:0] prefetch_addr
);
    reg [31:0] last_addr;
    reg [31:0] current_stride;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_addr <= 0; current_stride <= 0; prefetch_valid <= 0;
        end else if (mem_access_valid) begin
            current_stride <= access_addr - last_addr;
            last_addr <= access_addr;
            prefetch_valid <= 1'b1;
            prefetch_addr <= access_addr + (access_addr - last_addr);
        end else begin
            prefetch_valid <= 1'b0;
        end
    end
endmodule