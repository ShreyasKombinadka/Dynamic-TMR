`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: output_uart
// Function:
//   - Alternately transmits speed_out and dir_out as 8-bit UART bytes.
//   - Waits for UART to finish (busy=0) before triggering next send.
// Notes:
//   - Designed for 50 MHz + 9600 baud UART transmitter.
//   - Fully Verilog-2001 compliant.
//////////////////////////////////////////////////////////////////////////////////

module output_uart(
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] speed_out,  // from majority voter
    input  wire [3:0] dir_out,    // from majority voter
    output wire       uart_tx
);

    // UART interface signals
    reg  [7:0] uart_data;
    reg        send_uart;
    wire       uart_busy;

    // Instantiate UART transmitter
    uart_tx uart_tx_inst (
        .clk   (clk),
        .rst   (rst),
        .data_in (uart_data),
        .send    (send_uart),
        .tx      (uart_tx),
        .busy    (uart_busy)
    );

    // Control FSM
    reg send_flag;       // 0: send speed, 1: send dir
    reg pending_send;    // prevents immediate retrigger
    reg [7:0] next_data; // holds next byte to send

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            send_uart    <= 1'b0;
            uart_data    <= 8'd0;
            send_flag    <= 1'b0;
            pending_send <= 1'b0;
            next_data    <= 8'd0;
        end else begin
            send_uart <= 1'b0; // default

            if (!uart_busy && !pending_send) begin
                // Prepare next byte when transmitter is idle
                send_flag    <= ~send_flag;
                next_data    <= {4'b0000, (send_flag ? dir_out : speed_out)};
                pending_send <= 1'b1;
            end

            // Once prepared, issue send on next clock
            if (pending_send && !uart_busy) begin
                uart_data    <= next_data;
                send_uart    <= 1'b1;
                pending_send <= 1'b0;
            end
        end
    end

endmodule
