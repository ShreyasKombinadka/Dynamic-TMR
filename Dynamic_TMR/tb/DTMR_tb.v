`timescale 1ns / 1ps

module DTMR_tb ;
reg clk, rst ;  // Clock and Reset
reg [3:0] speed ;   // Received speed
reg [3:0] dir ; // Received direcction
reg [1:0] mode ;    // Received operation mode
reg [3:0] err_rate ; // Rate of errors in received data
reg f1, f2, b1, b2 ;    // Sensors (active low)
wire [3:0] speed_o ;    // Processed speed
wire [3:0] dir_o ;  // Processed direction
wire [2:0] fault ;  // Faulty module
wire state_o ;  // State probe for monitoring


DTMR dut( .clk(clk), .rst(rst), .speed(speed), .dir(dir), .mode(mode), .err_rate(err_rate), .f1(f1), .f2(f2), .b1(b1), .b2(b2), .speed_o(speed_o), .dir_o(dir_o), .fault(fault), .state_o(state_o));

initial clk = 0 ;
always #5 clk = ~clk ;

initial begin
    rst = 1 ; speed = 0 ; dir = 0 ; mode = 0 ; {f1, f2, b1, b2} = 0 ; repeat(2) @(negedge clk) ;
    rst = 0 ;
    speed = 10 ; dir = 5 ; input_sim() ;    // Auto mode
    speed = 10 ; dir = 6 ; mode = 1 ; input_sim() ; // Hybrid mode
    speed = 15 ; dir = 2 ; mode = 2 ; input_sim() ; // Manual mode
    speed = 10 ; dir = 5 ; mode = 3 ; input_sim() ; // Sleep mode
    
    @(negedge clk) ; $finish ;
end

task input_sim ;    //  Task to go through all the sensor sequences
integer i ;
begin
    for(i = 0 ; i < 7 ; i = i + 1)
    begin
        case(i)
            0 : {f1, f2, b1, b2} = 4'b0011 ;
            1 : {f1, f2, b1, b2} = 4'b1100 ;
            2 : {f1, f2, b1, b2} = 4'b0111 ;
            3 : {f1, f2, b1, b2} = 4'b1011 ;
            4 : {f1, f2, b1, b2} = 4'b0100 ;
            5 : {f1, f2, b1, b2} = 4'b1000 ;
            6 : {f1, f2, b1, b2} = 4'b1111 ;
        endcase
        repeat(10) @(negedge clk) ;
    end
end
endtask

endmodule