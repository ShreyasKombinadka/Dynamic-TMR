`timescale 1ns / 1ps

module receiver_tb ;
reg clk, rst ;              // Clock and Reset
reg s ;
wire [1:0] mode ;
wire [3:0] speed_cmd ;    // Processed speed
wire [3:0] dir_cmd ;      // Processed direction
wire [3:0] err_rate ;

localparam clk_f = 50_000_000 ;   // Clock frequency
localparam range = 1_000_000 ;    // Range
localparam t = 0.1 ;              // Bit duration
localparam data_l = 14 ;           // Length of data to be sent
localparam cmd_l = 4 ;                  // Command length

localparam t_d = (clk_f * t / range) ;  // Bit duration in terms of clock frequency

reg [1:0] mode_t ;
reg [cmd_l-1:0] speed_cmd_t ;
reg [cmd_l-1:0] dir_cmd_t ;
reg [data_l-1:0] data_t ;

receiver #(.clk_f(clk_f), .range(range), .t(t),
                    .data_l(data_l), .cmd_l(cmd_l))
                dut(.clk(clk), .rst(rst),
                    .s(s),
                    .mode(mode), .speed_cmd(speed_cmd), .dir_cmd(dir_cmd), .err_rate(err_rate));

initial clk = 0 ;
always #5 clk = ~clk ;

initial begin
    rst = 1 ; s = 1 ;
    mode_t = 0 ; speed_cmd_t = 0 ; dir_cmd_t = 0 ; data_t  = 0 ;
    repeat(t_d) @(negedge clk) ;
    rst = 0 ;
    repeat(t_d) @(negedge clk) ;
    input_sim() ;     // Auto mode
    input_sim() ;    // Hybrid mode
    input_sim() ;    // Manual mode
    input_sim() ;    // Sleep mode
    
    @(negedge clk) ; $finish ;
end

task automatic input_sim ;    //  Task to go through all the sensor sequences
integer i ;
begin
    for(i = 0 ; i <= 15 ; i = i + 1)
    begin
        speed_cmd_t = i ;
        dir_cmd_t = i ;
        data_t = hamming_14_10({dir_cmd_t, speed_cmd_t, mode_t}, 0);
        sass_t_sim(data_t);
        repeat(t_d) @(negedge clk) ;
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

task automatic sass_t_sim ; // Task to simulate the s line
input [data_l-1:0] temp ;

integer i ; // Bit index
reg run ;   // Loop enable
begin
    run = 1 ;
    i = 0 ;
    while(run)
    begin
        if(i == data_l + 1) // End transmission
        begin
            s = 0 ;     // End bit
            temp = 0 ;  // Clear data
            i = 0 ;     // Reset bit index
            run = 0 ;   // Exit loop
        end
        else
        begin
            if(i == 0)
            begin
                s = 0 ; // Start bit
            end
            else        // Send data
            begin
                s = temp[i - 1] ;   // Load the i-1 index data to the SASS line
            end
            i = i + 1 ; // Inceriment index
        end
        repeat(t_d) @(negedge clk) ;    // Bit duration
    end
    s = 1 ; // Return the line to idle state
end
endtask

initial
begin
    $monitor("Time : %0t | Data_sent : %b | Data_recv : %b |/n| packet_sent : %b | packet_recv : 0%b0",
            $time, {dir_cmd_t, speed_cmd_t, mode_t}, {dir_cmd, speed_cmd, mode},
            {1'b0, data_t, 1'b0}, {1'b0, receiver.data_r, 1'b0});
end

endmodule