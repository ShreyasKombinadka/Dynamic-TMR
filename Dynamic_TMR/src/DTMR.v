module DTMR (
    input clk, rst, // Clock and Reset
    input state_o,    // State probe for monitoring
    input [3:0] speed,  // Received speed
    input [3:0] dir,    // Received direcction
    input [1:0] mode,   // Received soperation mode
    input f1, f2,   // Front sensors (active low)
    input b1, b2,   // Back sensors (active low)
    output [3:0] speed_o,   // Processed speed
    output [3:0] dir_o,  // Processed direction
    output [2:0] fault  // Faulty module
);

state_o = state ; // State probe for monitoring

//------------------------------------------------
// PCM enabler for DTMR
//------------------------------------------------
wire [2:0] en ; // Enable signal for tmr modules
wire state ;    // state signal for voter
ctrl TMR_Control( .f1(f1), .f2(f2), .b1(b1), .b2(b2), .state(state), .err_rate(err_rate), .en(en), .state(state));


//------------------------------------------------
// PCM blocks for DTMR
//------------------------------------------------
wire [3:0] s1 ; // Speed 1
wire [3:0] d1 ; // Direction 1
PMC PMC_1( .clk(clk), .rst(rst), 
           .en(en[0]) .speed(speed), .dir(dir), .mode(mode),
           .f1(f1), .f2(f2), .b1(b1), .b2(b2), 
           .speed_o(s1), .dir_o(d1)
        );

wire [3:0] s2 ; // Speed 2
wire [3:0] d2 ; // Direction 2
PMC PMC_2( .clk(clk), .rst(rst),
           .en(en[1]) .speed(speed), .dir(dir), .mode(mode),
           .f1(f1), .f2(f2), .b1(b1), .b2(b2),
           .speed_o(s2), .dir_o(d2)
        );

wire [3:0] s3 ; // Speed 3
wire [3:0] d3 ; // Direction 3
PMC PMC_3( .clk(clk), .rst(rst),
           .en(en[2]) .speed(speed), .dir(dir), .mode(mode),
           .f1(f1), .f2(f2), .b1(b1), .b2(b2),
           .speed_o(s3), .dir_o(d3)
        );


//------------------------------------------------
// Majority voter
//------------------------------------------------
maj_vote Majority_voter( .state(state),
                         .s1(s1), .s2(s2), .s3(s3),
                         .d1(d1), d2(d2), .d3(d3),
                         .speed(speed_o), .dir(dir_o)
                        );

endmodule