module sass_t_tb ;  // SASS transmitter v1 test bench
reg clk, rst ;
reg send ;          // Flag to start the transmission
reg [7:0] data ;    // Data to be sent
wire busy ;         // Flag to indicate the state of transmitter
wire s ;            // Output line

localparam clk_f = 50_000_000 ;         // Clock frequency
localparam t = 100 ;                    // Bit duration
localparam range = 1_000_000 ;          // Range
localparam t_d = (clk_f * t / range) ;   // Calculating edges needed for the bit duration
localparam data_l  = 8 ;

sass_t #(.data_l(data_l), .t(t)) dut(.clk(clk), .rst(rst), .send(send), .data(data), .busy(busy), .s(s));

initial clk = 0 ;       // Initializing clk
always #5 clk = ~clk ;  // Generating clk

initial begin
    rst = 1 ; send = 0 ; data = 0 ;             // Initialize
    @(negedge clk) ; rst = 0 ;                  // Clear rst
    @(negedge clk) ; transmit_data_sim(135) ;   // Send 153
    @(negedge clk) ; transmit_data_sim(95) ;    // Send 95
    @(negedge clk) ; transmit_data_sim(5) ;     // Send 5
    @(negedge clk) ; transmit_data_sim(200) ;   // Send 200
    @(negedge clk) ; transmit_data_sim(69) ;    // Send 69
    
    repeat(t_d) @(negedge clk) ; $finish ;
end

task automatic transmit_data_sim ;  // Task to load the data to send and set transmission using busy flag
input [data_l-1:0] temp ;
reg run ;
begin
    run = 1 ;
    while(run)
    begin
        if(~busy)   // Transmitter is idle
        begin
            data = temp ;   // Load data to send
            send = 1 ;      // Set transmission flag
            @(posedge busy) ;
            send = 0 ;      // Clear transmission flag
            run = 0 ;       // Stop the loop
            @(negedge busy) ; // Let all bits get sent
        end
        else repeat(t_d) @(negedge clk) ;
    end
end
endtask

endmodule