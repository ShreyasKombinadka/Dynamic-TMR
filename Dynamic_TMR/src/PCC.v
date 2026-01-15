module PCC #(   // Praportional Command Controller
    parameter
    def_speed_cmd = 5,      // Default speed command
    def_dir_cmd = 8,        // Default speed command
    cmd_l = 4               // Command length
)(
    input clk, rst,                     // Clock and Reset
    input en,                           // Enable signal
    input [cmd_l-1:0] speed_cmd_i,      // Received speed command
    input [cmd_l-1:0] dir_cmd_i,        // Received direcction command
    input [1:0] mode,                   // Received soperation mode
    input f1, f2,                       // Front sensors
    input b1, b2,                       // Back sensors
    input state,
    input [cmd_l-1:0] speed_cmd_prev,
    input [cmd_l-1:0] dir_cmd_prev,
    output reg [cmd_l-1:0] speed_cmd_o, // Processed speed command
    output reg [cmd_l-1:0] dir_cmd_o    // Processed direction command
);

`include "cmd_ctrl.vh"  // Command smoothing function

reg [cmd_l-1:0] speed_cmd_d ; // Desired speed command value
reg [cmd_l-1:0] dir_cmd_d ;   // Desired dir command value
reg state_prev ;

always @(*)
begin
    case ( mode )
        0 : begin   // Autonomous mode (Ignore the received data produce output data using sensor data)
            case ( {f1, f2, b1, b2} )
                4'b1100 : begin
                        speed_cmd_d = 0 ;               // Decrease speed command
                        dir_cmd_d = def_dir_cmd ;       // Default dir command
                    end
                4'b0011 : begin
                        speed_cmd_d = 15 ;              // Increase speed command
                        dir_cmd_d = def_dir_cmd ;       // Default dir command
                    end
                4'b1000 : begin
                        speed_cmd_d = def_speed_cmd ;   // Default speed command
                        dir_cmd_d = 15 ;                // Turn clockwise
                    end
                4'b0100 : begin
                        speed_cmd_d = def_speed_cmd ;   // Default speed command
                        dir_cmd_d = 0 ;                 // Turn anti-clockwise
                    end
                4'b1011 : begin
                        speed_cmd_d = 15 ;              // Increase speed command
                        dir_cmd_d = 15 ;                // Turn clockwise
                    end
                4'b0111 : begin
                        speed_cmd_d = 15 ;              // Increase speed command
                        dir_cmd_d = 0 ;                 // Turn anti-clockwise
                    end
                default : begin
                        speed_cmd_d = def_speed_cmd ;   // Default speed command
                        dir_cmd_d = def_dir_cmd ;       // Default dir command
                    end
            endcase
        end
        1 : begin   // Hybrid mode (Combine both sensor readings and received data to controll speed and direction)
            case( {f1, f2, b1, b2} )
                4'b1100 : begin
                        speed_cmd_d = 0 ;           // Decrease speed command
                        dir_cmd_d = dir_cmd_i ;     // Received dir command
                    end
                4'b0011 : begin
                        speed_cmd_d = 15 ;          // Increase speed command
                        dir_cmd_d = dir_cmd_i ;     // Received dir command
                    end
                4'b1000 : begin
                        speed_cmd_d = speed_cmd_i ; // Received speed command
                        dir_cmd_d = 15 ;            // Turn clockwise
                    end
                4'b0100 : begin
                        speed_cmd_d = speed_cmd_i ; // Received speed command
                        dir_cmd_d = 0 ;             // Turn anti-clockwise
                    end
                4'b1011 : begin
                        speed_cmd_d = 15 ;          // Increase speed command
                        dir_cmd_d = 15 ;            // Turn clockwise
                    end
                4'b0111 : begin
                        speed_cmd_d = 15 ;          // Increase speed command
                        dir_cmd_d = 0 ;             // Turn anti-clockwise
                    end
                default : begin
                        speed_cmd_d = speed_cmd_i ; // Received speed command
                        dir_cmd_d = dir_cmd_i ;     // Received dir command
                    end
            endcase
        end
        2 : begin   // Manual mode (Pass the received data directly)
            speed_cmd_d = speed_cmd_i ; // Received speed command
            dir_cmd_d = dir_cmd_i ;     // Received dir command
        end
        3 : begin   // Sleep mode (Semi active condition)
            case ( {f1, f2, b1, b2} )
                4'b1100 : begin
                        speed_cmd_d = 0 ;  // Reduce speed command
                        dir_cmd_d = def_dir_cmd ; // Default dir command
                    end
                4'b0011 : begin
                        speed_cmd_d = def_speed_cmd ;   // Default speed command
                        dir_cmd_d = def_dir_cmd ;       // Default dir command
                    end
                4'b1000 : begin
                        speed_cmd_d = def_speed_cmd ;   // Default speed command
                        dir_cmd_d = 15 ;                // Turn clockwise
                    end
                4'b0100 : begin
                        speed_cmd_d = def_speed_cmd ;   // Default speed command
                        dir_cmd_d = 0 ;                 // Turn anti-clockwise
                    end
                4'b1011 : begin
                        speed_cmd_d = def_speed_cmd ;   // Default speed command
                        dir_cmd_d = 15 ;                // Turn clockwise
                    end
                4'b0111 : begin
                        speed_cmd_d = def_speed_cmd ;   // Default speed command
                        dir_cmd_d = 0 ;                 // Turn anti-clockwise
                    end
                default : begin
                        speed_cmd_d = 0 ;               // Reduce speed command
                        dir_cmd_d = def_dir_cmd ;       // Default dir command
                    end
            endcase
        end
        default : begin
                speed_cmd_d = 0 ;
                dir_cmd_d = 0 ;
            end
    endcase
end

always  @(posedge clk or posedge rst)
begin
    if (rst)
    begin
        speed_cmd_o <= 0 ;
        dir_cmd_o <= 0 ;
        state_prev <= 0 ;
    end

    else if(state != state_prev && state == 1)
    begin
        speed_cmd_o <= speed_cmd_prev ;
        dir_cmd_o <= dir_cmd_prev ;
    end

    else if(en)
    begin
        speed_cmd_o <= cmd_ctrl(speed_cmd_o, speed_cmd_d) ;     // Use praportional control for speed command
        dir_cmd_o <= cmd_ctrl(dir_cmd_o, dir_cmd_d) ;           // Use praportional control for speed command
    end

    state_prev <= state ;
end

endmodule