module demo_controller #(
        parameter
        clk_f = 50_000_000,             // Clock frequency
        range = 1_000_000,              // Range
        t = 300,                        // Bit duration
        data_l = 14,                    // Length of data to be sent
        cmd_l = 4,                      // Command length
        def_speed_cmd = 5,              // Default speed command
        def_dir_cmd = 8,                // Default speed command
        max_tmr_fault_count = 5,        // Max faults for tmr
        max_err_rate = 5                // Max err rate in the received data
)(
    input clk, rst,                     // Clock and Reset
    input s,                            // SASS transmission line
    input f1, f2,                       // Front sensors
    input b1, b2,                       // Back sensors
    output [cmd_l-1:0] speed_cmd_o,     // Processed speed command
    output [cmd_l-1:0] dir_cmd_o,       // Processed direction command
    output [2:0] fault,                 // Faulty module
    output state_o                      // State probe for monitoring
);

wire avl ;
wire [data_l-1:0] data_r ;
sass_r #(.data_l(data_l), .clk_f(clk_f), .range(range), .t(t)) Receiver(.clk(clk), .rst(rst), .s(s), .avl(avl), .data(data_r));

wire [1:0] mode ;
wire [cmd_l-1:0] speed_cmd, dir_cmd ;
wire [3:0] err_rate ;
data_dec #(.data_l(data_l), .cmd_l(cmd_l)) Decoder(.clk(clk), .rst(rst), .avl(avl), .data(data_r), .mode(mode), .speed_cmd(speed_cmd), .dir_cmd(dir_cmd), .err_rate(err_rate));

DTMR #(.cmd_l(cmd_l), .def_speed_cmd(def_speed_cmd), .def_dir_cmd(def_dir_cmd), .max_tmr_fault_count(max_tmr_fault_count), .max_err_rate(max_err_rate))
    Dynamic_TMR(.clk(clk), .rst(rst),
                .speed_cmd_i(speed_cmd), .dir_cmd_i(dir_cmd), .mode(mode), .err_rate(err_rate),
                .f1(f1), .f2(f2), .b1(b1), .b2(b2), 
                .speed_cmd_o(speed_cmd_o), .dir_cmd_o(dir_cmd_o), .fault(fault), .state_o(state_o)
                );

endmodule
