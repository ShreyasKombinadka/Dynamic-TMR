module sass_r #(    // SASS receiver v1
    parameter data_l = 8,           // Length of data to be sent
              clk_f = 50_000_000,   // Clock frequency
              range = 1_000_000,    // Range
              t = 300               // Bit duration
)(
    input clk, rst,
    input s,                        // SASS transmission line
    output avl,                     // Flag to indicate the data being received
    output reg [data_l-1:0] data    // Received data
);

localparam t_d = (clk_f * t / range) ;              // Bit duration in terms of clock frequency
localparam bit_count = $clog2(data_l + 1) ;         // Bits needed to count bits of data
localparam t_count = $clog2(t_d + (t_d / 2) + 1) ;  // Bit duration count
localparam t_det_adj = $clog2((t_d / 2) + 1) ;      // Bits needed for counter adjuster

reg [data_l-1:0] data_r ;       // Data buffer
reg [bit_count-1:0] bit ;       // counter for bits of data
reg [t_count-1:0] count ;       // Counter for bit duration
reg [t_det_adj-1:0] count_adj ; // Count adjuster to set the sampling time to middle of bit

reg en ;    // Enable flag for self locking
reg load ;  // Flag to load data from buffer to output

always @(posedge clk or posedge rst)
begin
    if(rst)    // Reset
    begin
        data = 0 ;
        count <= 0 ;
        data_r <= 0 ;
        en <= 0 ;
        bit <= 0 ;
        load <= 0 ;
        count_adj <= 0 ;
    end
    else
    begin
        if(~s | en) // Start or Continue
        begin

            if(bit == 0 || bit == data_l) count_adj <= t_d / 2 ;    // Start and end sampling synchronization

            if(~s & ~en)    // Initialization
            begin
                data_r <= 0 ;
                count <= 0 ;
                en <= 1 ;
                load <= 0 ;
                bit <= 0 ;
            end

            else if(en)
            begin
                count <= count + 1 ;            // Counter incrimenting
                if(count == t_d + count_adj)    // At the middle of bit
                begin
                    if(bit == data_l)   // End bit
                    begin
                        bit <= 0 ;          // Clear bit counter
                        en <= 0 ;           // Clear self lock flag
                        load <= 1 ;         // Set flag to load the data from buffer
                        count <= 0 ;        // Clear counter
                        count_adj <= 0 ;    // Clear the counter adjuster
                    end
                    else
                    begin
                        count_adj <= 0 ;    // Clear the counter adjuster
                        count <= 0 ;        //  Reset counter
                        data_r[bit] <= s ;  // Load the data bit from line
                        bit <= bit + 1 ;    // incriment bit counter
                    end
                end
            end
        end
        else    // Idle state
        begin
            data_r <= 0 ;
            load <= 0 ;
            count_adj <= 0 ;
            count <= 0 ;
            en <= 0 ;
        end
    end
    if(load)
    begin
        data <= data_r ;   // Load buffer data to outptut
        load <= 0 ;        // Clear the load flag
    end
end

assign avl = (en) ? 1 : 0 ;    // Set avl flag when the data is being received

endmodule