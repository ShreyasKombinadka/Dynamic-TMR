`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: fsm_copy2
// Function:
//   - Identical to fsm_copy1, operates under enable from fsm_control.
//   - Processes UART inputs and 4 sensors to generate speed/dir commands.
// Notes:
//   - Fully Verilog-2001 compliant.
//   - Synchronous design suitable for TMR replication on Arty S7-25 FPGA.
//////////////////////////////////////////////////////////////////////////////////

module fsm_copy2 #(
    parameter [3:0] DEFAULT_SPEED = 4'd5,  // default cruising speed
    parameter [3:0] DEFAULT_DIR   = 4'd8   // neutral direction
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       enable,      // from fsm_control
    input  wire [3:0] speed_in,    // from UART block
    input  wire [3:0] dir_in,      // from UART block
    input  wire [3:0] mode,        // from UART block
    input  wire       f1,
    input  wire       f2,
    input  wire       b1,
    input  wire       b2,
    output reg  [3:0] speed_out,
    output reg  [3:0] dir_out
);

    // --- State encoding ---
    localparam NORMAL       = 2'b00;
    localparam REDUCE_SPEED = 2'b01;
    localparam TURN_LEFT    = 2'b10;
    localparam TURN_RIGHT   = 2'b11;

    reg [1:0] state, next_state;

    // --- Last UART command storage ---
    reg [3:0] last_speed;
    reg [3:0] last_dir;

    // --- Combinational next-state logic ---
    always @(*) begin
        next_state = NORMAL;
        if (f1 && f2)
            next_state = REDUCE_SPEED;
        else if (f1)
            next_state = TURN_LEFT;
        else if (f2)
            next_state = TURN_RIGHT;
    end

    // --- Sequential logic ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= NORMAL;
            speed_out   <= DEFAULT_SPEED;
            dir_out     <= DEFAULT_DIR;
            last_speed  <= DEFAULT_SPEED;
            last_dir    <= DEFAULT_DIR;
        end else if (enable) begin
            state <= next_state;

            // Update UART-based inputs only in manual mode (mode==0)
            if (mode == 4'd0) begin
                last_speed <= speed_in;
                last_dir   <= dir_in;
            end

            // Begin with the last known state
            speed_out <= last_speed;
            dir_out   <= last_dir;

            // Sensor-based adaptive behavior
            case (next_state)
                REDUCE_SPEED:
                    if (speed_out > 0)
                        speed_out <= speed_out - 1'b1;

                TURN_LEFT:
                    if (dir_out > 0)
                        dir_out <= dir_out - 1'b1;

                TURN_RIGHT:
                    if (dir_out < 4'd15)
                        dir_out <= dir_out + 1'b1;

                NORMAL: begin
                    // Gradually re-center the direction
                    if (dir_out < DEFAULT_DIR)
                        dir_out <= dir_out + 1'b1;
                    else if (dir_out > DEFAULT_DIR)
                        dir_out <= dir_out - 1'b1;
                end
            endcase

            // Back sensors boost speed slightly
            if (b1 || b2)
                if (speed_out < 4'd15)
                    speed_out <= speed_out + 1'b1;
        end
        // else: when disabled, hold outputs
    end

endmodule
