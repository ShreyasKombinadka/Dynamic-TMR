`timescale 1ns / 1ps
module majority_voter(
    input  wire       clk,
    input  wire       rst,        // async, active-high
    input  wire       state,      // 0: pass copy1, 1: vote
    input  wire [3:0] speed1,
    input  wire [3:0] dir1,
    input  wire [3:0] speed2,
    input  wire [3:0] dir2,
    input  wire [3:0] speed3,
    input  wire [3:0] dir3,
    output reg  [3:0] speed_out,
    output reg  [3:0] dir_out
);
    // Bitwise 3-input majority: ab + bc + ac
    wire [3:0] speed_vote = (speed1 & speed2) | (speed2 & speed3) | (speed1 & speed3);
    wire [3:0] dir_vote   = (dir1   & dir2)   | (dir2   & dir3)   | (dir1   & dir3);

    wire [3:0] speed_mux = (state == 1'b0) ? speed1 : speed_vote;
    wire [3:0] dir_mux   = (state == 1'b0) ? dir1   : dir_vote;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            speed_out <= 4'd0;
            dir_out   <= 4'd0;
        end else begin
            speed_out <= speed_mux;
            dir_out   <= dir_mux;
        end
    end
endmodule
