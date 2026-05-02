`timescale 1ns / 1ps
module pseudo_lru_4way (
    input clk, rst_n,
    input access_en,
    input [1:0] accessed_way,
    output reg [1:0] victim_way
);
    reg [2:0] tree; // Bit 0 is root, 1 is left, 2 is right

    always @(*) begin
        if (!tree[0]) victim_way = tree[1] ? 2'b01 : 2'b00;
        else          victim_way = tree[2] ? 2'b11 : 2'b10;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) tree <= 3'b000;
        else if (access_en) begin
            tree[0] <= ~accessed_way[1];
            if (!accessed_way[1]) tree[1] <= ~accessed_way[0];
            else                  tree[2] <= ~accessed_way[0];
        end
    end
endmodule