`timescale 1ns/1ps

module tb_satellite_control_unit;

    // ---------------------------------
    // DUT I/O
    // ---------------------------------
    reg  clk;
    reg  rst;
    reg  uart_rx;
    reg  f1, f2, b1, b2;
    wire uart_tx;

    // ---------------------------------
    // Instantiate DUT
    // ---------------------------------
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

    // ---------------------------------
    // Clock: 50 MHz → 20 ns period
    // ---------------------------------
    initial clk = 1'b0;
    always #10 clk = ~clk;

    // ---------------------------------
    // Reset
    // ---------------------------------
    task reset_dut;
    begin
        rst = 1'b1;
        #200;
        rst = 1'b0;
    end
    endtask

    // ---------------------------------
    // Apply sensors
    // ---------------------------------
    task apply_sensors(input sf1, input sf2, input sb1, input sb2, input [31:0] hold);
    begin
        f1 = sf1; f2 = sf2; b1 = sb1; b2 = sb2;
        #(hold);
    end
    endtask

    // ---------------------------------
    // Dummy UART generator
    //  - Just drives a valid idle/start/stop pattern periodically
    // ---------------------------------
    task fake_uart_frame;
    integer i;
    reg [9:0] frame;
    begin
        // Start(0), 8 bits(0xA5), Stop(1)
        frame = {1'b1, 8'hA5, 1'b0};
        for (i = 0; i < 10; i = i + 1) begin
            uart_rx = frame[i];
            #(104166); // ≈1/9600 s @ 1ns units
        end
        uart_rx = 1'b1; // idle high
        #(104166);       // one idle bit-time gap
    end
    endtask

    // ---------------------------------
    // Main stimulus
    // ---------------------------------
    initial begin
        // init
        uart_rx = 1'b1;
        f1 = 0; f2 = 0; b1 = 0; b2 = 0;

        // Dump waveforms
        $dumpfile("satellite_control_unit.vcd");
        $dumpvars(0, tb_satellite_control_unit);

        // Reset DUT
        reset_dut;

        // Apply various sensor combos
        apply_sensors(0,0,0,0,  1000);
        apply_sensors(1,0,0,0,  1000);
        apply_sensors(0,1,0,0,  1000);
        apply_sensors(1,1,0,0,  1000);
        apply_sensors(0,0,1,0,  1000);
        apply_sensors(0,0,0,1,  1000);
        apply_sensors(1,1,1,1,  1000);

        // Simulate UART activity
        fake_uart_frame();
        fake_uart_frame();

        // Alternate sensors + UART
        apply_sensors(1,0,1,0,  2000);
        fake_uart_frame();
        apply_sensors(0,1,0,1,  2000);
        fake_uart_frame();

        #500000;
        $display("Simulation finished.");
        $stop;
    end

endmodule
