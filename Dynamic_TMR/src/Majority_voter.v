module maj_vote (   // Majority voter
    input clk, rst, // Clock and Reset
    input state,    // DTMR state
    input [3:0] s1_cmd, s2_cmd, s3_cmd, //  Speed command from TMR copies
    input [3:0] d1_cmd, d2_cmd, d3_cmd, //  Dir command from TMR copies
    output reg [3:0] speed_cmd_o, // Voted speed command output
    output reg [3:0]  dir_cmd_o,    // Voted dir command output
    output [2:0] fault  // Faulty module indicator
);

`include "cmd_ctrl.vh"

reg [3:0] speed_cmd_d ; // Desired speed command
reg [3:0] dir_cmd_d ;   // Desired dir command
reg f1, f2, f3 ;    // Fault flags

always @( * )
begin
    speed_cmd_d = 0 ;
    dir_cmd_d = 0 ;
    {f3, f2, f1} = 0 ;
    if ( state )   // If state is active use voting logic
    begin
        speed_cmd_d = ( s3_cmd & ( s1_cmd ^ s2_cmd ) ) | ( s1_cmd & s2_cmd ) ;    // Speed command majority voting
        dir_cmd_d = ( d3_cmd & ( d1_cmd ^ d2_cmd ) ) | ( d1_cmd & d2_cmd ) ;  // Dir command majority voting
        f1 = ( s1_cmd != speed_cmd_d || d1_cmd != dir_cmd_d ) ; // Flag module 1
        f2 = ( s2_cmd != speed_cmd_d || d2_cmd != dir_cmd_d ) ; // Flag module 2
        f3 = ( s3_cmd != speed_cmd_d || d3_cmd != dir_cmd_d ) ; // Flag module 3
    end
    else    // In normal conditon just pass the values of one module
    begin
        speed_cmd_d = s1_cmd ;
        dir_cmd_d = d1_cmd ;
        {f1, f2, f3} = 0 ;
    end
end

always  @( posedge clk or posedge rst )
begin
    if ( rst )
    begin
        speed_cmd_o <= 0 ;
        dir_cmd_o <= 0 ;
    end
    else
    begin
        speed_cmd_o <= cmd_ctrl(speed_cmd_o, speed_cmd_d) ;    // Use praportional control for speed command
        dir_cmd_o <= cmd_ctrl(dir_cmd_o, dir_cmd_d) ;  // Use praportional control for dir command
    end
end

assign fault = {f1, f2, f3} ;

endmodule