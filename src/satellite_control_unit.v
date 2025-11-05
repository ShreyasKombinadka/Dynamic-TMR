module satellite_control_unit(
    input  wire clk,
    input  wire rst,
    input  wire uart_rx,          // UART RX from ESP32
    input  wire f1,
    input  wire f2,
    input  wire b1,
    input  wire b2,
    output wire uart_tx           // UART TX line
);

    // -------------------------------
    // Internal signals
    // -------------------------------
    wire [3:0] speed_uart, dir_uart, mode_uart;
    wire [7:0] error_rate;

    wire state;

    wire enable_copy1, enable_copy2, enable_copy3;

    wire [3:0] speed1, dir1;
    wire [3:0] speed2, dir2;
    wire [3:0] speed3, dir3;

    wire [3:0] speed_voted, dir_voted;

    // -------------------------------
    // UART Receiver
    // -------------------------------
    uart_hamming74_receiver uart_rx_inst(
        .clk(clk),
        .rst(rst),
        .rx(uart_rx),
        .speed(speed_uart),
        .dir(dir_uart),
        .mode(mode_uart),
        .error_rate(error_rate)
    );

    // -------------------------------
    // State Monitor
    // -------------------------------
    state_monitor state_mon_inst(
        .clk(clk),
        .rst(rst),
        .error_rate(error_rate),
        .f1(f1),
        .f2(f2),
        .b1(b1),
        .b2(b2),
        .state(state)
    );

    // -------------------------------
    // FSM Control
    // -------------------------------
    fsm_control fsm_ctrl_inst(
        .clk(clk),
        .rst(rst),
        .state(state),
        .enable_copy1(enable_copy1),
        .enable_copy2(enable_copy2),
        .enable_copy3(enable_copy3)
    );

    // -------------------------------
    // FSM Copies
    // -------------------------------
    fsm_copy1 fsm1(
        .clk(clk),
        .rst(rst),
        .enable(enable_copy1),
        .speed_in(speed_uart),
        .dir_in(dir_uart),
        .mode(mode_uart),
        .f1(f1), .f2(f2), .b1(b1), .b2(b2),
        .speed_out(speed1),
        .dir_out(dir1)
    );

    fsm_copy2 fsm2(
        .clk(clk),
        .rst(rst),
        .enable(enable_copy2),
        .speed_in(speed_uart),
        .dir_in(dir_uart),
        .mode(mode_uart),
        .f1(f1), .f2(f2), .b1(b1), .b2(b2),
        .speed_out(speed2),
        .dir_out(dir2)
    );

    fsm_copy3 fsm3(
        .clk(clk),
        .rst(rst),
        .enable(enable_copy3),
        .speed_in(speed_uart),
        .dir_in(dir_uart),
        .mode(mode_uart),
        .f1(f1), .f2(f2), .b1(b1), .b2(b2),
        .speed_out(speed3),
        .dir_out(dir3)
    );

    // -------------------------------
    // Majority Voter
    // -------------------------------
    majority_voter voter_inst(
        .clk(clk),
        .rst(rst),
        .state(state),
        .speed1(speed1), .dir1(dir1),
        .speed2(speed2), .dir2(dir2),
        .speed3(speed3), .dir3(dir3),
        .speed_out(speed_voted),
        .dir_out(dir_voted)
    );

    // -------------------------------
    // Majority Voter UART
    // -------------------------------
    output_uart uart_inst(
        .clk(clk),
        .rst(rst),
        .speed_out(speed_voted),
        .dir_out(dir_voted),
        .uart_tx(uart_tx)
    );

endmodule
