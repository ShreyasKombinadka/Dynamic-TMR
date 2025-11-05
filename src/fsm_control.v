`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: fsm_control
// Description:
//   - Controls enabling of three replicated logic copies in Dynamic TMR.
//   - When state=0 → only copy1 active (normal mode).
//   - When state=1 → all copies active (fault-tolerant / recovery mode).
// Notes:
//   - Fully synchronous (async reset).
//   - Verilog-2001 compliant.
//////////////////////////////////////////////////////////////////////////////////

module fsm_control(
    input  wire clk,             // system clock
    input  wire rst,             // async reset, active high
    input  wire state,           // from state_monitor
    output reg  enable_copy1,
    output reg  enable_copy2,
    output reg  enable_copy3
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            enable_copy1 <= 1'b0;
            enable_copy2 <= 1'b0;
            enable_copy3 <= 1'b0;
        end else begin
            if (state == 1'b0) begin
                // Normal operation: only golden copy active
                enable_copy1 <= 1'b1;
                enable_copy2 <= 1'b0;
                enable_copy3 <= 1'b0;
            end else begin
                // Fault-tolerant / recovery mode: all copies enabled
                enable_copy1 <= 1'b1;
                enable_copy2 <= 1'b1;
                enable_copy3 <= 1'b1;
            end
        end
    end

endmodule
