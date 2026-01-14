module sass_t #(    // SASS transmitter v1
    parameter data_l = 8,           // Length of data to be sent
              clk_f = 50_000_000,   // Clock frequency
              range = 1_000_000,    // Range
              t = 300               // Bit duration
)(
    input clk, rst,
    input send,                 // Flag to start the transmission
    input [data_l-1:0] data,    // Data to be sent
    output busy,                // Flag to indicate the state of transmitter
    output s                    // Output line
);

localparam t_d = (clk_f * t / range) ;      // Bit duration in terms of clock frequency
localparam bit_count = $clog2(data_l + 1) ; // Data bits + frame bits count
localparam t_count = $clog2(t_d + 1) ;      // Bit duration count

reg [data_l:0] data_f ;     // Data frame
reg st ;                    // Register to store the data bit to be put on the line
reg en ;                    // Enable flag for self locking
reg [bit_count-1:0] bit ;   // counter to count bits of data
reg [t_count-1:0] count ;   // Counter for bit duration

always @(posedge clk or posedge rst)
begin
    if (rst)    // Reset
    begin
        count <= 0 ;
        data_f <= 0 ;
        en <= 0 ;
        bit <= 0 ;
        st <= 0 ;
    end
    else
    begin
        if (en | send)                      // Start of transmission
        begin
            if(send & ~en) begin            // Initialization
                data_f <= {1'b0, data} ;    // Adding the end delimeter
                count <= 0;                 // Set count to 0
                en <= 1;                    // Self locking the loop
            end

            else
            begin
                count <= count + 1 ;        // Counter incrimenting
                if (count == t_d)           // After 't' time
                begin
                    count <= 0 ;            //  Reset count
                    st <= data_f[bit] ;     // Load the data bit to send
                    bit <= bit + 1 ;        // incriment bit counter
                    if (bit == data_l+1)    // After the last bit
                    begin                   // Reset
                        data_f <= 0 ;       // Clear data frame
                        bit <= 0 ;          // Clear bit counter
                        en <= 0 ;           // Clear self lock flag
                        st <= 0 ;           // Set the output bit low
                    end
                end
            end

        end
        else st <= 0 ;  // Set the output bit low
    end
end

assign busy = (en) ? 1 : 0 ;    // Transmitter state
assign s = (en) ? st : 1 ;      // Put the output bit on the output line if transmission is active else keep the line idle

endmodule