`timescale 1ns / 1ps

module tb_satellite_control_unit;

    // --------------------------------
    // DUT I/O
    // --------------------------------
    reg  clk;
    reg  rst;
    reg  uart_rx;
    reg  f1, f2, b1, b2;
    wire uart_tx;

    // --------------------------------
    // Instantiate DUT
    // --------------------------------
    satellite_control_unit uut (
        .clk     (clk),
        .rst     (rst),
        .uart_rx (uart_rx),
        .f1      (f1),
        .f2      (f2),
        .b1      (b1),
        .b2      (b2),
        .uart_tx (uart_tx)
    );

    // --------------------------------
    // 50 MHz Clock
    // --------------------------------
    initial clk = 1'b0;
    always #10 clk = ~clk;  // 20 ns period

    // --------------------------------
    // FAST SIMULATION SETTINGS
    // --------------------------------
    // Baud rate boosted 10× for faster sim (96 000 baud)
    localparam integer CLK_FREQ     = 50000000;
    localparam integer SIM_BAUD     = 96000;          // 10× faster baud
    localparam integer CLKS_PER_BIT = (CLK_FREQ + (SIM_BAUD/2)) / SIM_BAUD;

    // --------------------------------
    // Reset
    // --------------------------------
    task reset_dut;
    begin
        rst     = 1'b1;
        uart_rx = 1'b1;
        f1 = 0; f2 = 0; b1 = 0; b2 = 0;
        repeat (50000) @(posedge clk);
        rst     = 1'b0;
        repeat (1000) @(posedge clk);
    end
    endtask

    // --------------------------------
    // UART Send Byte (8N1, LSB first)
    // --------------------------------
    task send_uart_byte;
        input [7:0] data;
        integer i, c;
    begin
        uart_rx = 1'b0; // start
        for (c = 0; c < CLKS_PER_BIT; c = c + 1) @(posedge clk);
        for (i = 0; i < 8; i = i + 1) begin
            uart_rx = data[i];
            for (c = 0; c < CLKS_PER_BIT; c = c + 1) @(posedge clk);
        end
        uart_rx = 1'b1; // stop
        for (c = 0; c < CLKS_PER_BIT; c = c + 1) @(posedge clk);
    end
    endtask

    // --------------------------------
    // Hamming(7,4) Encoder (same as receiver mapping)
    // --------------------------------
    function [6:0] h74_encode_nibble;
        input [3:0] d;
        integer p;
        reg [6:0] t, r;
        reg s0, s1, s2;
        reg done;
    begin
        t = 7'b0;
        t[6] = d[3];
        t[5] = d[2];
        t[3] = d[1];
        t[0] = d[0];
        done = 1'b0;
        for (p = 0; p < 8 && !done; p = p + 1) begin
            r = t;
            r[4] = p[2];
            r[2] = p[1];
            r[1] = p[0];
            s0 = r[6] ^ r[4] ^ r[2] ^ r[0];
            s1 = r[5] ^ r[4] ^ r[1] ^ r[0];
            s2 = r[3] ^ r[2] ^ r[1] ^ r[0];
            if ({s2,s1,s0} == 3'b000) begin
                h74_encode_nibble = r;
                done = 1'b1;
            end
        end
        if (!done) h74_encode_nibble = t;
    end
    endfunction

    // --------------------------------
    // Send full 3-byte control frame
    // --------------------------------
    task send_control_frame;
        input [3:0] sp, di, mo;
        reg [6:0] c0, c1, c2;
        integer c;
    begin
        c0 = h74_encode_nibble(sp);
        c1 = h74_encode_nibble(di);
        c2 = h74_encode_nibble(mo);
        send_uart_byte({1'b0, c0});
        send_uart_byte({1'b0, c1});
        send_uart_byte({1'b0, c2});
        for (c = 0; c < (5 * CLKS_PER_BIT); c = c + 1) @(posedge clk); // small gap
    end
    endtask

    // --------------------------------
    // Apply sensors
    // --------------------------------
    task apply_sensors(input sf1, input sf2, input sb1, input sb2, input integer hold_clks);
        integer k;
    begin
        f1 = sf1; f2 = sf2; b1 = sb1; b2 = sb2;
        for (k = 0; k < hold_clks; k = k + 1) @(posedge clk);
    end
    endtask

    // --------------------------------
    // MAIN STIMULUS
    // --------------------------------
    initial begin
        $dumpfile("satellite_control_unit_fast.vcd");
        $dumpvars(0, tb_satellite_control_unit);

        reset_dut;

        apply_sensors(0,0,0,0,  25000); send_control_frame(4'd5,  4'd8, 4'd0);
        apply_sensors(1,0,0,0,  25000); send_control_frame(4'd6,  4'd8, 4'd0);
        apply_sensors(0,1,0,0,  25000); send_control_frame(4'd7,  4'd7, 4'd0);
        apply_sensors(0,0,1,0,  25000); send_control_frame(4'd8,  4'd8, 4'd0);
        apply_sensors(0,0,0,1,  25000); send_control_frame(4'd9,  4'd8, 4'd0);
        apply_sensors(1,1,0,0,  25000); send_control_frame(4'd10, 4'd8, 4'd0);
        apply_sensors(0,0,1,1,  25000); send_control_frame(4'd3,  4'd8, 4'd0);
        apply_sensors(1,1,1,1,  25000); send_control_frame(4'd2,  4'd8, 4'd0);

        // End sim
        repeat (2_000_000) @(posedge clk); // ~40 ms total simulated time
        $finish;
    end

endmodule
