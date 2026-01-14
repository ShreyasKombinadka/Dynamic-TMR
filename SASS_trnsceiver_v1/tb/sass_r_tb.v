module sass_r_tb ;  // SASS receiver v1 test bench
reg clk, rst ;
reg s ;             // SASS transmission line
wire avl ;          // Flag to indicate the presence of data on the line
wire [7:0] data ;   // Received data

localparam data_l = 8 ;           // Length of data to be sent
localparam clk_f = 50_000_000 ;   // Clock frequency
localparam range = 1_000_000 ;    // Range
localparam t = 300 ;              // Bit duration

localparam t_d = (clk_f * t / range) ;  // Bit duration in terms of clock frequency


sass_r #(.data_l(data_l), .t(t)) dut(.clk(clk), .rst(rst), .s(s), .avl(avl), .data(data));

initial clk = 0 ;       // Initializing clk
always #5 clk = ~clk ;  // Generating clk

initial begin
    rst = 1 ; s = 1 ;   // Initialize
    @(negedge clk) ; rst = 0 ;

    repeat(t_d) @(negedge clk) ;
    @(negedge clk) ; sass_t_sim(135) ;  // Simulate the s line for data 135
    repeat(t_d) @(negedge clk) ;
    @(negedge clk) ; sass_t_sim(95) ;   // Simulate the s line for data 95
    repeat(t_d) @(negedge clk) ;
    @(negedge clk) ; sass_t_sim(5) ;    // Simulate the s line for data 5
    repeat(t_d) @(negedge clk) ;
    @(negedge clk) ; sass_t_sim(200) ;  // Simulate the s line for data 200
    repeat(t_d) @(negedge clk) ;
    @(negedge clk) ; sass_t_sim(69) ;   // Simulate the s line for data 69
    repeat(t_d) @(negedge clk) ;

    @(negedge clk) ; $finish ;
end

task automatic sass_t_sim ; // Task to simulate the s line
input [data_l-1:0] temp ;

integer i ; // Bit index
reg run ;   // Loop enable
begin
    run = 1 ;
    i = 0 ;
    $display("send : ", temp) ;
    while(run)
    begin
        $display("bit : ", i) ;
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

endmodule