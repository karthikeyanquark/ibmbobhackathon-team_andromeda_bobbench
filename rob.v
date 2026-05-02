`timescale 1ns / 1ps
module rob_manager #(parameter DEPTH = 16) (
    input clk, rst_n,
    input dispatch_valid, commit_ready,
    output reg full, empty,
    output reg [$clog2(DEPTH)-1:0] head, tail
);
    reg [$clog2(DEPTH):0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head <= 0; tail <= 0; count <= 0;
            full <= 0; empty <= 1;
        end else begin
            if (dispatch_valid && !full) begin
                tail <= tail + 1;
            end
            if (commit_ready && !empty) begin
                head <= head + 1;
            end
            
            if (dispatch_valid && !full && (!commit_ready || empty))
                count <= count + 1;
            else if (commit_ready && !empty && (!dispatch_valid || full))
                count <= count - 1;

            full <= (count == DEPTH);
            empty <= (count == 0);
        end
    end
endmodule