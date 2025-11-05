`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: state_monitor
// Function:
//   - Monitors error_rate (from UART/Hamming block) and 4 sensors.
//   - Sets state = 1 when either error_rate exceeds threshold
//     or ≥3 sensors are active.
// Notes:
//   - Compatible with the latest uart_hamming74_receiver (error_rate[3:0]).
//   - Uses only Verilog-2001 constructs.
//   - Fully synchronous except async reset.
//////////////////////////////////////////////////////////////////////////////////

module state_monitor #(
    parameter [3:0] ERROR_THRESHOLD = 4'd5   // adjustable threshold
)(
    input  wire       clk,          // system clock
    input  wire       rst,          // asynchronous reset, active high
    input  wire [3:0] error_rate,   // from UART/Hamming receiver
    input  wire       f1, f2,       // front sensors
    input  wire       b1, b2,       // back sensors
    output reg        state         // output state flag
);

    // --- Internal signals ---
    reg [2:0] sensor_sum;

    // Count active sensors
    always @(*) begin
        sensor_sum = f1 + f2 + b1 + b2;
    end

    // --- State logic ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 1'b0;
        end else begin
            // Priority: error_rate condition first
            if (error_rate > ERROR_THRESHOLD)
                state <= 1'b1;
            else if (sensor_sum >= 3)
                state <= 1'b1;
            else
                state <= 1'b0;
        end
    end

endmodule
