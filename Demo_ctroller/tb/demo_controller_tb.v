`timescale 1ns / 1ps

module demo_controller_tb ;
reg clk, rst ;              // Clock and Reset
reg s ;
reg f1, f2, b1, b2 ;        // Sensors (active low)
wire [3:0] speed_cmd_o ;    // Processed speed
wire [3:0] dir_cmd_o ;      // Processed direction
wire [2:0] fault ;          // Faulty module
wire state_o ;              // State probe for monitoring

localparam clk_f = 50_000_000 ;   // Clock frequency
localparam range = 1_000_000 ;    // Range
localparam t = 0.1 ;              // Bit duration
localparam data_l = 14 ;           // Length of data to be sent
localparam cmd_l = 4 ;                  // Command length
localparam def_speed_cmd = 5 ;          // Default speed command
localparam def_dir_cmd = 8 ;            // Default speed command
localparam max_tmr_fault_count = 5 ;    // Max faults for tmr
localparam max_err_rate = 5 ;           // Max err rate in the received data

localparam t_d = (clk_f * t / range) ;  // Bit duration in terms of clock frequency

reg [1:0] mode ;
reg [cmd_l-1:0] speed_cmd ;
reg [cmd_l-1:0] dir_cmd ;
reg [data_l-1:0] data ;

demo_controller #(.clk_f(clk_f), .range(range), .t(t),
        .data_l(data_l), .cmd_l(cmd_l),
        .def_speed_cmd(def_speed_cmd), .def_dir_cmd(def_dir_cmd), .max_tmr_fault_count(max_tmr_fault_count), .max_err_rate(max_err_rate))
    dut(.clk(clk), .rst(rst),
        .s(s), .f1(f1), .f2(f2), .b1(b1), .b2(b2),
        .speed_cmd_o(speed_cmd_o), .dir_cmd_o(dir_cmd_o), .fault(fault), .state_o(state_o));

initial clk = 0 ;
always #5 clk = ~clk ;

initial begin
    rst = 1 ; s = 0 ; {f1, f2, b1, b2} = 0 ;
    mode = 0 ; speed_cmd = 0 ; dir_cmd = 0 ;
    repeat(2) @(negedge clk) ; rst = 0 ;
    repeat(2) @(negedge clk) ;
    input_sim() ;     // Auto mode
    input_sim() ;    // Hybrid mode
    input_sim() ;    // Manual mode
    input_sim() ;    // Sleep mode
    
    @(negedge clk) ; $finish ;
end

task automatic input_sim ;    //  Task to go through all the sensor sequences
integer i ;
begin
    {f1, f2, b1, b2} = 0 ;
    for(i = 0 ; i <= 7 ; i = i + 1)
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
        endcase
        speed_cmd = speed_cmd + 1 ;
        dir_cmd = dir_cmd + 1 ;

        data = hamming_14_10({dir_cmd, speed_cmd, mode}, 0);

        sass_t_sim(data);

        repeat(10) @(negedge clk) ;
    end
    mode = mode + 1 ;
end
endtask

function [9:0] hamming_14_10 ;
input [13:0] data ;
input [3:0] err_in ;

reg [3:0] parity ;
begin
    parity = 0 ;
    parity[0] = (data[0] ^ data[1] ^ data[3] ^ data[4] ^ data[6] ^ data[8]) ;
    parity[1] = (data[0] ^ data[2] ^ data[3] ^ data[5] ^ data[6] ^ data[9]) ;
    parity[2] = (data[1] ^ data[2] ^ data[3] ^ data[7] ^ data[8] ^ data[9]) ;
    parity[3] = (data[4] ^ data[5] ^ data[6] ^ data[7] ^ data[8] ^ data[9]) ;

    hamming_14_10 = {data[9], data[8], data[7], data[6], data[5], data[4], parity[3], data[3], data[2], data[1], parity[2], data[0], parity[1], parity[0]};
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
    $monitor("Time : %0t | Data_sent : %b | Data_recv : %b", $time, {dir_cmd, speed_cmd, mode}, {demo_controller.dir_cmd, demo_controller.speed_cmd, demo_controller.mode});
    $monitor("Time : %0t | packet_sent : %b | packet_recv : 0%b0", $time, {1'b0, data, 1'b0}, {1'b0, demo_controller.data_r, 1'b0});
end

endmodule