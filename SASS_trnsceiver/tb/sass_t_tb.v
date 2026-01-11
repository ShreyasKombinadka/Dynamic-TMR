module sass_t_tb ;  // SASS transmitter test bench
reg clk, rst ;
reg send ;          // Flag to start the transmission
reg [7:0] data ;    // Data to be sent
wire busy ;         // Flag to indicate the state of transmitter
wire s ;            // Output line

sass_t #(.frame_l(8), .t(100)) dut(.clk(clk), .rst(rst), .send(send), .data(data), .busy(busy), .s(s));

initial clk = 0 ;       // Initializing clk
always #5 clk = ~clk ;  // Generating clk

initial begin
    rst = 1 ; send = 0 ; data = 0 ;             // Initialize
    @(negedge clk) ; rst = 0 ; data = 8'd135 ;  // Data to send
    repeat(5) @(negedge clk) ;                  // Wait 5 cycles
    @(negedge clk) ; send = 1 ;                 // Start the transmission
    @(negedge clk) ; send = 0 ;                 // Clear transmission flag 
    repeat(10000) @(negedge clk) ;              // Wait 10K cycles
    @(negedge clk) ; data = 8'd95 ;             // Data to send
    repeat(5) @(negedge clk) ;                  // Wait 5 cycles
    @(negedge clk) ; send = 1 ;                 // Start the transmission
    @(negedge clk) ; send = 0 ;                 // Clear transmission flag 
    repeat(10000) @(negedge clk) ; $finish ;    // Wait 10K cycles
end

endmodule