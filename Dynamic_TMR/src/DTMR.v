module DTMR (
    input clk, rst, // Clock and Reset
    input state,
    input [3:0] speed,  // Received speed
    input [3:0] dir,    // Received direcction
    input [1:0] mode,   // Received soperation mode
    input f1, f2,   // Front sensors (active low)
    input b1, b2,   // Back sensors (active low)
    output [3:0] speed_o,   // Processed speed
    output [3:0] dir_o  // Processed direction
);

//------------------------------------------------
// PCM enabler for DTMR
//------------------------------------------------
wire [2:0] en ;
ctrl TMR_Control( .rst(rst), .state(state), .en(en) )

//------------------------------------------------
// PCM blocks for DTMR
//------------------------------------------------
wire [3:0] speed_1 ;
wire [3:0] dir_1 ;
PMC PMC_1( .clk(clk), .rst(rst), .en(en[0]) .speed(speed), .dir(dir), .mode(mode), .f1(f1), .f2(f2), .b1(b1), .b2(b2), .speed_o(speed_1), .dir_o(dir_1), )

wire [3:0] speed_2 ;
wire [3:0] dir_2 ;
PMC PMC_2( .clk(clk), .rst(rst), .en(en[1]) .speed(speed), .dir(dir), .mode(mode), .f1(f1), .f2(f2), .b1(b1), .b2(b2), .speed_o(speed_2), .dir_o(dir_2), )

wire [3:0] speed_3 ;
wire [3:0] dir_3 ;
PMC PMC_3( .clk(clk), .rst(rst), .en(en[2]) .speed(speed), .dir(dir), .mode(mode), .f1(f1), .f2(f2), .b1(b1), .b2(b2), .speed_o(speed_3), .dir_o(dir_3), )

//------------------------------------------------
// Majority voter
//------------------------------------------------
maj_vote Majority_voter()

endmodule