module DTMR (
    input clk, rst, // Clock and Reset
    input [3:0] speed_cmd_i,  // Received speed
    input [3:0] dir_cmd_i,    // Received direcction
    input [1:0] mode,   // Received operation mode
    input [3:0] err_rate,       // Rate of errors in received data
    input f1, f2,   // Front sensors
    input b1, b2,   // Back sensors
    output [3:0] speed_cmd_o,   // Processed speed
    output [3:0] dir_cmd_o,  // Processed direction
    output [2:0] fault,  // Faulty module
    output state_o    // State probe for monitoring
);

//------------------------------------------------
// PCM enabler for DTMR
//------------------------------------------------
wire [2:0] en ; // Enable signal for tmr modules
wire state ;    // state signal for voter
ctrl TMR_Control( .f1(f1), .f2(f2), .b1(b1), .b2(b2), .err_rate(err_rate), .en(en), .state(state));


assign state_o = state ; // State probe for monitoring


//------------------------------------------------
// PCM blocks for DTMR
//------------------------------------------------
wire [3:0] s1_cmd ; // Speed 1
wire [3:0] d1_cmd ; // Direction 1
PCC PCC_1( .clk(clk), .rst(rst), 
           .en(en[0]), .speed_cmd_i(speed_cmd_i), .dir_cmd_i(dir_cmd_i), .mode(mode),
           .f1(f1), .f2(f2), .b1(b1), .b2(b2), 
           .speed_cmd_o(s1_cmd), .dir_cmd_o(d1_cmd)
        );

wire [3:0] s2_cmd ; // Speed 2
wire [3:0] d2_cmd ; // Direction 2
PCC PCC_2( .clk(clk), .rst(rst),
           .en(en[1]), .speed_cmd_i(speed_cmd_i), .dir_cmd_i(dir_cmd_i), .mode(mode),
           .f1(f1), .f2(f2), .b1(b1), .b2(b2),
           .speed_cmd_o(s2_cmd), .dir_cmd_o(d2_cmd)
        );

wire [3:0] s3_cmd ; // Speed 3
wire [3:0] d3_cmd ; // Direction 3
PCC PCC_3( .clk(clk), .rst(rst),
           .en(en[2]), .speed_cmd_i(speed_cmd_i), .dir_cmd_i(dir_cmd_i), .mode(mode),
           .f1(f1), .f2(f2), .b1(b1), .b2(b2),
           .speed_cmd_o(s3_cmd), .dir_cmd_o(d3_cmd)
        );


//------------------------------------------------
// Majority voter
//------------------------------------------------
maj_vote Majority_voter( .clk(clk), .rst(rst),
                         .state(state),
                         .s1_cmd(s1_cmd), .s2_cmd(s2_cmd), .s3_cmd(s3_cmd),
                         .d1_cmd(d1_cmd), .d2_cmd(d2_cmd), .d3_cmd(d3_cmd),
                         .speed_cmd_o(speed_cmd_o), .dir_cmd_o(dir_cmd_o),
                         .fault(fault)
                        );

endmodule