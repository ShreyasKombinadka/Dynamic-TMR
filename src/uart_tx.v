`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: uart_tx
// Description:
//   - Transmits 8N1 UART frames (1 start, 8 data, 1 stop).
//   - Operates at parameterized CLK_FREQ and BAUD.
//   - 'send' pulse loads data when IDLE; 'busy' high while sending.
//
// Notes:
//   - Fully Verilog-2001 compliant.
//   - Designed for 50 MHz system clock and 9600 baud default.
//   - Generates 1-bit-time accurate output per UART standard.
//////////////////////////////////////////////////////////////////////////////////

module uart_tx #(
    parameter integer CLK_FREQ = 50000000,   // Hz
    parameter integer BAUD     = 9600        // bits/sec
)(
    input  wire       clk,
    input  wire       rst,       // asynchronous reset, active high
    input  wire [7:0] data_in,   // byte to transmit
    input  wire       send,      // 1-clk pulse to start transmit
    output reg        tx,        // UART TX line
    output reg        busy       // high while transmitting
);

    // UART timing
    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD;

    // FSM encoding
    localparam [1:0]
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11;

    reg [1:0]  state;
    reg [12:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  data_buf;

    // --------------------------------------------------------------
    // Sequential transmitter FSM
    // --------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            tx        <= 1'b1;
            busy      <= 1'b0;
            clk_count <= 13'd0;
            bit_index <= 3'd0;
            data_buf  <= 8'd0;
        end else begin
            case (state)
                //--------------------------------------------------
                IDLE: begin
                    tx        <= 1'b1;    // line idle high
                    busy      <= 1'b0;
                    clk_count <= 13'd0;
                    bit_index <= 3'd0;

                    // start when send pulse occurs
                    if (send) begin
                        data_buf  <= data_in;
                        busy      <= 1'b1;
                        state     <= START;
                    end
                end

                //--------------------------------------------------
                START: begin
                    tx <= 1'b0; // start bit
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 13'd0;
                        state     <= DATA;
                    end
                end

                //--------------------------------------------------
                DATA: begin
                    tx <= data_buf[bit_index];  // send LSB first
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 13'd0;
                        if (bit_index < 3'd7)
                            bit_index <= bit_index + 1'b1;
                        else begin
                            bit_index <= 3'd0;
                            state     <= STOP;
                        end
                    end
                end

                //--------------------------------------------------
                STOP: begin
                    tx <= 1'b1;  // stop bit
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 13'd0;
                        busy      <= 1'b0;
                        state     <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
