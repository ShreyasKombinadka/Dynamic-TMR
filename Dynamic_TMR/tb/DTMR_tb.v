`timescale 1ns / 1ps

module DTMR_tb ;
reg clk, rst ;  // Clock and Reset
reg [3:0] speed_cmd_i ;   // Received speed
reg [3:0] dir_cmd_i ; // Received direcction
reg [1:0] mode ;    // Received operation mode
reg [3:0] err_rate ; // Rate of errors in received data
reg f1, f2, b1, b2 ;    // Sensors (active low)
wire [3:0] speed_cmd_o ;    // Processed speed
wire [3:0] dir_cmd_o ;  // Processed direction
wire [2:0] fault ;  // Faulty module
wire state_o ;  // State probe for monitoring


DTMR dut(.clk(clk), .rst(rst),
            .speed_cmd_i(speed_cmd_i), .dir_cmd_i(dir_cmd_i), .mode(mode),
            .err_rate(err_rate), .f1(f1), .f2(f2), .b1(b1), .b2(b2),
            .speed_cmd_o(speed_cmd_o), .dir_cmd_o(dir_cmd_o), .fault(fault), .state_o(state_o));

initial clk = 0 ;
always #5 clk = ~clk ;

initial begin
    rst = 1 ; speed_cmd_i = 0 ; dir_cmd_i = 0 ; mode = 0 ; err_rate = 0 ; {f1, f2, b1, b2} = 0 ; repeat(2) @(negedge clk) ;
    rst = 0 ; input_sim() ;     // Auto mode
    mode = 1 ; input_sim() ;    // Hybrid mode
    mode = 2 ; input_sim() ;    // Manual mode
    mode = 3 ; input_sim() ;    // Sleep mode
    
    @(negedge clk) ; $finish ;
end

task input_sim ;    //  Task to go through all the sensor sequences
integer i ;
begin
    err_rate = 0 ;
    {f1, f2, b1, b2} = 0 ;
    for(i = 0 ; i <= 8 ; i = i + 1)
    begin
        case(i)
            0 : {f1, f2, b1, b2} = 4'b1100 ;
            1 : {f1, f2, b1, b2} = 4'b0011 ;
            2 : {f1, f2, b1, b2} = 4'b1000 ;
            3 : {f1, f2, b1, b2} = 4'b0100 ;
            4 : {f1, f2, b1, b2} = 4'b1011 ;
            5 : {f1, f2, b1, b2} = 4'b0111 ;
            6 : {f1, f2, b1, b2} = 4'b1111 ;
            7 : {f1, f2, b1, b2} = 0 ;
            8 : err_rate = 10 ;
        endcase
        speed_cmd_i = speed_cmd_i + 1 ;
        dir_cmd_i = dir_cmd_i + 1 ;
        repeat(10) @(negedge clk) ;
    end
end
endtask

endmodule