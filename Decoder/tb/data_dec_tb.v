`timescale 1ns / 1ps

module data_dec_tb ;
reg clk, rst ;              // Clock and Reset
reg avl ;
reg [13:0] data ;
wire [1:0] mode ;
wire [3:0] speed_cmd ;    // Processed speed
wire [3:0] dir_cmd ;      // Processed direction
wire [3:0] err_rate ;

localparam data_l = 14 ;           // Length of data to be sent
localparam cmd_l = 4 ;                  // Command length

reg [1:0] mode_t ; 

reg [9:0] debug_data ;

data_dec #(.data_l(data_l), .cmd_l(cmd_l))
        dut(.clk(clk), .rst(rst),
            .avl(avl), .data(data),
            .mode(mode), .speed_cmd(speed_cmd), .dir_cmd(dir_cmd), .err_rate(err_rate));

initial clk = 0 ;
always #5 clk = ~clk ;

initial begin
    rst = 1 ;
    data  = 0 ; avl = 0 ; mode_t = 0 ; debug_data = 0 ;
    repeat(1) @(negedge clk) ;
    rst = 0 ;
    repeat(1) @(negedge clk) ;
    input_sim() ;     // Auto mode
    input_sim() ;    // Hybrid mode
    input_sim() ;    // Manual mode
    input_sim() ;    // Sleep mode
    
    @(negedge clk) ; $finish ;
end

task automatic input_sim ;    //  Task to go through all the sensor sequences
reg [3:0] speed_cmd_t ;
reg [3:0] dir_cmd_t ;
integer i ;
begin
    avl = 0 ;
    speed_cmd_t = 0 ;
    dir_cmd_t = 0 ;
    for(i = 0 ; i <= 15 ; i = i + 1)
    begin
        speed_cmd_t = i ;
        dir_cmd_t = i ;
        debug_data = {dir_cmd_t, speed_cmd_t, mode_t} ;
        data = hamming_14_10({dir_cmd_t, speed_cmd_t, mode_t}, 0);
        @(negedge clk) ;
        avl = 1 ;
        @(negedge clk) ;
        avl = 0 ;
        repeat(2) @(negedge clk) ;
    end
    mode_t = mode_t + 1 ;
end
endtask

function [13:0] hamming_14_10 ;
input [9:0] data ;
input [3:0] err_in ;

reg [3:0] parity ;
begin
    parity = 0 ;
    parity[0] = (data[0] ^ data[1] ^ data[3] ^ data[4] ^ data[6] ^ data[8]) ;
    parity[1] = (data[0] ^ data[2] ^ data[3] ^ data[5] ^ data[6] ^ data[9]) ;
    parity[2] = (data[1] ^ data[2] ^ data[3] ^ data[7] ^ data[8] ^ data[9]) ;
    parity[3] = (data[4] ^ data[5] ^ data[6] ^ data[7] ^ data[8] ^ data[9]) ;

    hamming_14_10 = {data[9:4], parity[3], data[3:1], parity[2], data[0], parity[1:0]};
    if(err_in != 0) hamming_14_10[err_in-1] = ~hamming_14_10[err_in-1] ;
end
endfunction

initial
begin
    $monitor("Time : %0t D_sent : %d | P_sent : %d | P_recv : %d || Dec :- P_recv : %d | D_rec : %d | avl : %b",
            $time, debug_data, data, data_dec.data, dut.hamming_decoder.data_i, dut.hamming_decodder.temp, avl);
end

endmodule