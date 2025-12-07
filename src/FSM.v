module FSM #( 
    parameter default_speed = 5,
    parameter default_dir = 8
)(
    input clk, rst, // Clock and Reset
    input [3:0] speed,  // Received speed
    input [3:0] dir,    // Received direcction
    input [1:0] mode,   // Received soperation mode
    input f1, f2,   // Front sensors (active low)
    input b1, b2,   // Back sensors (active low)
    output [3:0] speed_o,   // Processed speed
    output [3:0] dir_o  // Processed direction
);

reg [3:0] speed_n ; // Next speed value
reg [3:0] dir_n ;   // Next dir value

always  @( posedge clk or posedge rst )
begin
    if ( rst )
    begin
        speed_n <= 0 ;  // Instant speed reset
        dir_n <= 0 ;    // Instant dir reset
    end
    else 
    begin
        case ( mode )
            0 : begin   // Autonomous mode (Ignore the received data produce output data using sensor data)
                case ( {f1, f2, b1, b2} )
                    4'b0011 : begin
                            speed_n <= (speed_n > 0) ? (speed_n - 1) : 0 ;  // Gradual stop
                            dir_n <= (dir_n != default_dir) ? ( (dir_n < default_dir) ? (dir_n + 1) : (dir_n - 1) ) : default_dir ; // Keep the dir steady
                        end
                    4'b1100 : begin
                            speed_n <= (speed_n < 15) ? (speed_n + 1) : 15 ;    // Gradual speed increase
                            dir_n <= (dir_n != default_dir) ? ( (dir_n < default_dir) ? (dir_n + 1) : (dir_n - 1) ) : default_dir ; // Keep the dir steady
                        end
                    4'b0111 : begin
                            speed_n <= (speed_n != default_speed) ? ( (speed_n < default_speed) ? (speed_n + 1) : (speed_n - 1) ) : default_speed ; // Keep the speed steady
                            dir_n <= (dir_n < 15) ? (dir_n + 1) : 15 ;
                        end
                    4'b1011 : begin
                            speed_n <= (speed_n != default_speed) ? ( (speed_n < default_speed) ? (speed_n + 1) : (speed_n - 1) ) : default_speed ; // Keep the speed steady
                            dir_n <= (dir_n > 0) ? (dir_n - 1) : 0 ;
                        end
                    4'b0100 : begin
                            speed_n <= (speed_n < 15) ? (speed_n + 1) : 15 ;
                            dir_n <= (dir_n < 15) ? (dir_n + 1) : 15 ;
                        end
                    4'b1000 : begin
                            speed_n <= (speed_n < 15) ? (speed_n + 1) : 15 ;
                            dir_n <= (dir_n > 0) ? (dir_n - 1) : 0 ;
                        end
                    default : begin
                                speed_n <= (speed_n != default_speed) ? ( (speed_n < default_speed) ? (speed_n + 1) : (speed_n - 1) ) : default_speed ; // Keep the speed steady
                                dir_n <= (dir_n != default_dir) ? ( (dir_n < default_dir) ? (dir_n + 1) : (dir_n - 1) ) : default_dir ; // Keep the dir steady
                        end
                endcase
            end
            1 : begin
                case( {f1, f2, b1, b2} )
                    4'b0011 : begin
                            speed_n <= (speed_n > 0 ) ? (speed_n - 1) : 0 ;
                            dir_n <= (dir_n != dir) ? ( (dir_n < dir) ? (dir_n + 1) : (dir_n - 1) ) : dir ; // Make the next dir to received dir
                        end
                    4'b1100 : begin
                            speed_n <= (speed_n < 15 ) ? (speed_n + 1) : 15 ;
                            dir_n <= (dir_n != dir) ? ( (dir_n < dir) ? (dir_n + 1) : (dir_n - 1) ) : dir ; // Make the next dir to received dir
                        end
                    4'b0111 : begin
                            speed_n <= (speed_n != speed) ? ( (speed_n < speed) ? (speed_n + 1) : (speed_n - 1) ) : speed ; // Make the next speed to received speed
                            dir_n <= (dir_n < 15) ? (dir_n + 1) : 15 ;
                        end
                    4'b1011 : begin
                            speed_n <= (speed_n != speed) ? ( (speed_n < speed) ? (speed_n + 1) : (speed_n - 1) ) : speed ; // Make the next speed to received speed
                            dir_n <= (dir_n > 0) ? (dir_n - 1) : 0 ;
                        end
                    4'b0100 : begin
                            speed_n <= (speed_n < 15) ? (speed_n + 1) : 15 ;
                            dir_n <= (dir_n < 0) ? (dir_n + 1) : 15 ;
                        end
                    4'b1000 : begin
                            speed_n <= (speed_n < 15) ? (speed_n + 1) : 0 ;
                            dir_n <= (dir_n > 0) ? (dir_n - 1) : 0 ;
                        end
                    default : begin
                                speed_n <= (speed_n != speed) ? ( (speed_n < speed) ? (speed_n + 1) : (speed_n - 1) ) : speed ; // Make the next speed to received speed
                                dir_n <= (dir_n != dir) ? ( (dir_n < dir) ? (dir_n + 1) : (dir_n - 1) ) : dir ; // Make the next dir to received dir
                        end
                endcase
            end
            2 : begin
                speed_n <= (speed_n != speed) ? ( (speed_n < speed) ? (speed_n + 1) : (speed_n - 1) ) : speed ;
                dir_n <= (dir_n != dir) ? ( (dir_n < dir) ? (dir_n + 1) : (dir_n - 1) ) : dir ;
            end
            3 : begin
                case ( {f1, f2, b1, b2} )
                    4'b0011 : begin
                            speed_n <= (speed_n > 0) ? (speed_n - 1) : 0 ;
                            dir_n <= (dir_n != default_dir) ? ( (dir_n < default_dir) ? (dir_n + 1) : (dir_n - 1) ) : default_dir ;
                        end
                    4'b1100 : begin
                            speed_n <= (speed_n != default_speed) ? ( (speed_n < default_speed) ? (speed_n + 1) : (speed_n - 1) ) : default_speed ;
                            dir_n <= (dir_n != default_dir) ? ( (dir_n < default_dir) ? (dir_n + 1) : (dir_n - 1) ) : default_dir ;
                        end
                    4'b0111 : begin
                            speed_n <= (speed_n != default_speed) ? ( (speed_n < default_speed) ? (speed_n + 1) : (speed_n - 1) ) : default_speed ;
                            dir_n <= (dir_n < 15) ? (dir_n + 1) : 15 ;
                        end
                    4'b1011 : begin
                            speed_n <= (speed_n > 0) ? (speed_n - 1) : 0 ;
                            dir_n <= (dir_n > 0) ? (dir_n - 1) : 0 ;
                        end
                    4'b0100 : begin
                            speed_n <= (speed_n != default_speed) ? ( (speed_n < default_speed) ? (speed_n + 1) : (speed_n - 1) ) : default_speed ;
                            dir_n <= (dir_n < 15) ? (dir_n + 1) : 15 ;
                        end
                    4'b1000 : begin
                            speed_n <= (speed_n != default_speed) ? ( (speed_n < default_speed) ? (speed_n + 1) : (speed_n - 1) ) : default_speed ;
                            dir_n <= (dir_n > 0) ? (dir_n - 1) : 0 ;
                        end
                    default : begin
                                speed_n <= (speed_n > 0) ? (speed_n - 1) : 0 ;
                                dir_n <= (dir_n != default_dir) ? ( (dir_n < default_dir) ? (dir_n + 1) : (dir_n - 1) ) : default_dir ;
                        end
                endcase
            end
        endcase
    end
end

assign speed_o = speed_n ;
assign dir_o = dir_n ;

endmodule