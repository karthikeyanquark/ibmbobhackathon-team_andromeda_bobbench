`timescale 1ns / 1ps
module branch_target_buffer (
    input clk, rst_n,
    input [31:0] pc_in,
    input update_en, branch_taken,
    input [31:0] update_pc, target_pc,
    output reg predict_taken,
    output reg [31:0] predicted_pc
);
    reg [31:0] tag_array [0:15];
    reg [31:0] target_array [0:15];
    reg [1:0] bimodal_counters [0:15];

    wire [3:0] idx = pc_in[5:2];
    wire [3:0] upd_idx = update_pc[5:2];

    always @(*) begin
        if (tag_array[idx] == pc_in && bimodal_counters[idx][1]) begin
            predict_taken = 1'b1;
            predicted_pc = target_array[idx];
        end else begin
            predict_taken = 1'b0;
            predicted_pc = pc_in + 4;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset logic omitted for brevity
        end else if (update_en) begin
            tag_array[upd_idx] <= update_pc;
            target_array[upd_idx] <= target_pc;
            if (branch_taken && bimodal_counters[upd_idx] != 2'b11)
                bimodal_counters[upd_idx] <= bimodal_counters[upd_idx] + 1;
            else if (!branch_taken && bimodal_counters[upd_idx] != 2'b00)
                bimodal_counters[upd_idx] <= bimodal_counters[upd_idx] - 1;
        end
    end
endmodule