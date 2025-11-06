`timescale 1ns / 1ps

module fsm_copy1 #(
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

    // --- Memory for last UART command ---
    reg [3:0] last_speed;
    reg [3:0] last_dir;

    // --- Next-state combinational logic ---
    always @(*) begin
        // Default hold
        next_state = NORMAL;
        if (f1 && f2)
            next_state = REDUCE_SPEED;
        else if (f1)
            next_state = TURN_LEFT;
        else if (f2)
            next_state = TURN_RIGHT;
    end

    // --- Sequential FSM ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= NORMAL;
            speed_out   <= DEFAULT_SPEED;
            dir_out     <= DEFAULT_DIR;
            last_speed  <= DEFAULT_SPEED;
            last_dir    <= DEFAULT_DIR;
        end else if (enable) begin
            state <= next_state;

            // Update stored UART values only if mode == 0 (manual)
            if (mode == 4'd0) begin
                last_speed <= speed_in;
                last_dir   <= dir_in;
            end

            // Start each cycle with last known speed/dir
            speed_out <= last_speed;
            dir_out   <= last_dir;

            // Adjust based on sensors / current state
            case ( next_state )
                REDUCE_SPEED:
                begin
                    if ( speed_out > 0 ) speed_out <= speed_out - 1'b1 ;
                    else speed_out = 0 ;
                end

                TURN_LEFT:
                begin
                    if ( dir_out > 0 ) dir_out <= dir_out - 1'b1 ;
                    else dir_out = 0 ;
                end

                TURN_RIGHT:
                begin
                    if ( dir_out < 4'd15 ) dir_out <= dir_out + 1'b1 ;
                    else dir_out = 0 ;
                end

                NORMAL: begin
                    // Gradually return to neutral direction
                    if ( ( dir_out < DEFAULT_DIR ) or ( speed_out < DEFAULT_SPEED ) )
                    begin
                        dir_out <= dir_out + 1'b1 ;
                        speed_out <= speed_out + 1'b1 ;
                    end

                    else if ( ( dir_out > DEFAULT_DIR ) && ( speed_out > DEFAULT_SPEED ) )
                    begin
                        dir_out <= dir_out - 1'b1;
                        speed_out <= speed_out - 1'b1 ;
                    end
                end
            endcase

            // Boost speed slightly if any back sensor active
            if (b1 || b2)
                if (speed_out < 4'd15)
                    speed_out <= speed_out + 1'b1;
        end
        // else: if not enabled, hold last outputs automatically
    end

endmodule
