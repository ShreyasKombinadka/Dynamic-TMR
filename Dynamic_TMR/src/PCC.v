module PCC #(   // Praportional Command Controller
    parameter def_speed_cmd = 5,
    parameter def_dir_cmd = 8
)(
    input clk, rst, // Clock and Reset
    input en,   // Enable signal
    input [3:0] speed_cmd_i,  // Received speed
    input [3:0] dir_cmd_i,    // Received direcction
    input [1:0] mode,   // Received soperation mode
    input f1, f2,   // Front sensors
    input b1, b2,   // Back sensors
    output reg [3:0] speed_cmd_o,   // Processed speed
    output reg [3:0] dir_cmd_o  // Processed direction
);

`include "cmd_ctrl.vh"

reg [3:0] speed_cmd_d ; // Desired speed value
reg [3:0] dir_cmd_d ;   // Desired dir value

always @(*)
begin
    case ( mode )
        0 : begin   // Autonomous mode (Ignore the received data produce output data using sensor data)
            case ( {f1, f2, b1, b2} )
                4'b1100 : begin
                        speed_cmd_d = 0 ;  // Decrease speed
                        dir_cmd_d = def_dir_cmd ; // Default dir
                    end
                4'b0011 : begin
                        speed_cmd_d = 15 ;    // Increase speed
                        dir_cmd_d = def_dir_cmd ; // Default dir
                    end
                4'b1000 : begin
                        speed_cmd_d = def_speed_cmd ; // Default speed
                        dir_cmd_d = 15 ;  // Turn clockwise
                    end
                4'b0100 : begin
                        speed_cmd_d = def_speed_cmd ; // Default speed
                        dir_cmd_d = 0 ;    // Turn anti-clockwise
                    end
                4'b1011 : begin
                        speed_cmd_d = 15 ;    // Increase speed
                        dir_cmd_d = 15 ;  // Turn clockwise
                    end
                4'b0111 : begin
                        speed_cmd_d = 15 ;    // Increase speed
                        dir_cmd_d = 0 ;    // Turn anti-clockwise
                    end
                default : begin
                        speed_cmd_d = def_speed_cmd ; // Default speed
                        dir_cmd_d = def_dir_cmd ; // Default dir
                    end
            endcase
        end
        1 : begin   // Hybrid mode (Combine both sensor readings and received data to controll speed and direction)
            case( {f1, f2, b1, b2} )
                4'b1100 : begin
                        speed_cmd_d = 0 ; // Decrease speed
                        dir_cmd_d = dir_cmd_i ; // Received dir
                    end
                4'b0011 : begin
                        speed_cmd_d = 15 ;   // Increase speed
                        dir_cmd_d = dir_cmd_i ; // Received dir
                    end
                4'b1000 : begin
                        speed_cmd_d = speed_cmd_i ; // Received speed
                        dir_cmd_d = 15 ;  // Turn clockwise
                    end
                4'b0100 : begin
                        speed_cmd_d = speed_cmd_i ; // Received speed
                        dir_cmd_d = 0 ;    // Turn anti-clockwise
                    end
                4'b1011 : begin
                        speed_cmd_d = 15 ;    // Increase speed
                        dir_cmd_d = 15 ;   // Turn clockwise
                    end
                4'b0111 : begin
                        speed_cmd_d = 15 ; // Increase speed
                        dir_cmd_d = 0 ;    // Turn anti-clockwise
                    end
                default : begin
                        speed_cmd_d = speed_cmd_i ; // Received speed
                        dir_cmd_d = dir_cmd_i ; // Received dir
                    end
            endcase
        end
        2 : begin   // Manual mode (Pass the received data directly)
            speed_cmd_d = speed_cmd_i ; // Received speed
            dir_cmd_d = dir_cmd_i ; // Received dir
        end
        3 : begin   // Sleep mode (Semi active condition)
            case ( {f1, f2, b1, b2} )
                4'b1100 : begin
                        speed_cmd_d = 0 ;  // Reduce speed
                        dir_cmd_d = def_dir_cmd ; // Default dir
                    end
                4'b0011 : begin
                        speed_cmd_d = def_speed_cmd ; // Default speed
                        dir_cmd_d = def_dir_cmd ; // Default dir
                    end
                4'b1000 : begin
                        speed_cmd_d = def_speed_cmd ; // Default speed
                        dir_cmd_d = 15 ;   // Turn clockwise
                    end
                4'b0100 : begin
                        speed_cmd_d = def_speed_cmd ; // Default speed
                        dir_cmd_d = 0 ;    // Turn anti-clockwise
                    end
                4'b1011 : begin
                        speed_cmd_d = def_speed_cmd ; // Default speed
                        dir_cmd_d = 15 ;   // Turn clockwise
                    end
                4'b0111 : begin
                        speed_cmd_d = def_speed_cmd ; // Default speed
                        dir_cmd_d = 0 ;    // Turn anti-clockwise
                    end
                default : begin
                        speed_cmd_d = 0 ;  // Reduce speed
                        dir_cmd_d = def_dir_cmd ;  // Default dir
                    end
            endcase
        end
        default : begin
                speed_cmd_d = 0 ;
                dir_cmd_d = 0 ;
            end
    endcase
end

always  @( posedge clk or posedge rst )
begin
    if ( rst )
    begin
        speed_cmd_o <= 0 ;
        dir_cmd_o <= 0 ;
    end
    else if (en)
    begin
        speed_cmd_o <= cmd_ctrl(speed_cmd_o, speed_cmd_d) ;    // Use praportional control for speed
        dir_cmd_o <= cmd_ctrl(dir_cmd_o, dir_cmd_d) ;  // Use praportional control for speed
    end
end

endmodule