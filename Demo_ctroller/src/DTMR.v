module DTMR #(
        parameter
        def_speed_cmd = 5,              // Default speed command
        def_dir_cmd = 8,                // Default speed command
        cmd_l = 4,                      // Command length
        max_tmr_fault_count = 5,        // Max faults for tmr
        max_err_rate_received = 5       // Max err rate in the received data
)(
    input clk, rst,                     // Clock and Reset
    input [cmd_l-1:0] speed_cmd_i,      // Received speed command
    input [cmd_l-1:0] dir_cmd_i,        // Received direcction command
    input [1:0] mode,                   // Received operation mode
    input [cmd_l-1:0] err_rate,         // Rate of errors in received data
    input f1, f2,                       // Front sensors
    input b1, b2,                       // Back sensors
    output [cmd_l-1:0] speed_cmd_o,     // Processed speed command
    output [cmd_l-1:0] dir_cmd_o,       // Processed direction command
    output [2:0] fault,                 // Faulty module
    output state_o                      // State probe for monitoring
);

//------------------------------------------------
// PCM enabler for DTMR
//------------------------------------------------
wire [2:0] en ; // Enable signal for tmr modules
wire state ;    // state signal for voter
ctrl #(.max_tmr_fault_count(max_tmr_fault_count), .max_err_rate_received(max_err_rate_received)) TMR_Control(.clk(clk), .rst(rst), .f1(f1), .f2(f2), .b1(b1), .b2(b2), .fault(fault), .err_rate(err_rate), .en(en), .state(state));


assign state_o = state ; // State probe for monitoring

wire [cmd_l-1:0] speed_cmd_prev ;       // Previous stable speed_cmd
wire [cmd_l-1:0] dir_cmd_prev ;         // Previous stable dir_cmd

//------------------------------------------------
// PCM blocks for DTMR
//------------------------------------------------
wire [cmd_l-1:0] s1_cmd ; // Speed command 1
wire [cmd_l-1:0] d1_cmd ; // Direction command 1
PCC #(.def_speed_cmd(def_speed_cmd), .def_dir_cmd(def_dir_cmd), .cmd_l(cmd_l)) PCC_1( .clk(clk), .rst(rst), 
           .en(en[0]), .speed_cmd_i(speed_cmd_i), .dir_cmd_i(dir_cmd_i), .mode(mode),
           .f1(f1), .f2(f2), .b1(b1), .b2(b2),
           .state(state), .speed_cmd_prev(speed_cmd_prev), .dir_cmd_prev(dir_cmd_prev),
           .speed_cmd_o(s1_cmd), .dir_cmd_o(d1_cmd)
        );

wire [cmd_l-1:0] s2_cmd ; // Speed command 2
wire [cmd_l-1:0] d2_cmd ; // Direction command 2
PCC #(.def_speed_cmd(def_speed_cmd), .def_dir_cmd(def_dir_cmd), .cmd_l(cmd_l)) PCC_2( .clk(clk), .rst(rst),
           .en(en[1]), .speed_cmd_i(speed_cmd_i), .dir_cmd_i(dir_cmd_i), .mode(mode),
           .f1(f1), .f2(f2), .b1(b1), .b2(b2),
           .state(state), .speed_cmd_prev(speed_cmd_prev), .dir_cmd_prev(dir_cmd_prev),
           .speed_cmd_o(s2_cmd), .dir_cmd_o(d2_cmd)
        );

wire [cmd_l-1:0] s3_cmd ; // Speed command 3
wire [cmd_l-1:0] d3_cmd ; // Direction command 3
PCC #(.def_speed_cmd(def_speed_cmd), .def_dir_cmd(def_dir_cmd), .cmd_l(cmd_l)) PCC_3( .clk(clk), .rst(rst),
           .en(en[2]), .speed_cmd_i(speed_cmd_i), .dir_cmd_i(dir_cmd_i), .mode(mode),
           .f1(f1), .f2(f2), .b1(b1), .b2(b2),
           .state(state), .speed_cmd_prev(speed_cmd_prev), .dir_cmd_prev(dir_cmd_prev),
           .speed_cmd_o(s3_cmd), .dir_cmd_o(d3_cmd)
        );


//------------------------------------------------
// Psuedo-Random error addition
//------------------------------------------------
wire [(2 * cmd_l)-1:0] cmd_out_tmr1 ;
err_in #( .cmd_l(cmd_l), .lfsr_ini(3)) error_TMR1( .clk(clk), .rst(rst), .state(state), .cmd_raw({s1_cmd, d1_cmd}), .cmd_out(cmd_out_tmr1));

wire [(2 * cmd_l)-1:0] cmd_out_tmr2 ;
err_in #( .cmd_l(cmd_l), .lfsr_ini(5)) error_TMR2( .clk(clk), .rst(rst), .state(state), .cmd_raw({s2_cmd, d2_cmd}), .cmd_out(cmd_out_tmr2));

wire [(2 * cmd_l)-1:0] cmd_out_tmr3 ;
err_in #( .cmd_l(cmd_l), .lfsr_ini(12)) error_TMR3( .clk(clk), .rst(rst), .state(state), .cmd_raw({s3_cmd, d3_cmd}), .cmd_out(cmd_out_tmr3));


//------------------------------------------------
// Majority voter
//------------------------------------------------
maj_vote #(.cmd_l(cmd_l)) Majority_voter( .clk(clk), .rst(rst),
                         .state(state),
                         .s1_cmd(cmd_out_tmr1[(2 * cmd_l)-1:cmd_l]), .s2_cmd(cmd_out_tmr2[(2 * cmd_l)-1:cmd_l]), .s3_cmd(cmd_out_tmr3[(2 * cmd_l)-1:cmd_l]),
                         .d1_cmd(cmd_out_tmr1[cmd_l-1:0]), .d2_cmd(cmd_out_tmr2[cmd_l-1:0]), .d3_cmd(cmd_out_tmr3[cmd_l-1:0]),
                         .en(en),
                         .speed_cmd_o(speed_cmd_o), .dir_cmd_o(dir_cmd_o),
                         .fault(fault),
                         .speed_cmd_prev(speed_cmd_prev), .dir_cmd_prev(dir_cmd_prev)
                        );

endmodule
