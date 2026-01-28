module maj_vote #(  // Majority voter
        parameter cmd_l = 4 // Command length
)(
    input clk, rst,                             // Clock and Reset
    input state,                                // DTMR state
    input [cmd_l-1:0] s1_cmd, s2_cmd, s3_cmd,   //  Speed command from TMR copies
    input [cmd_l-1:0] d1_cmd, d2_cmd, d3_cmd,   //  Dir command from TMR copies
    input [2:0] en,
    output reg [cmd_l-1:0] speed_cmd_o,         // Voted speed command output
    output reg [cmd_l-1:0]  dir_cmd_o,          // Voted dir command output
    output [2:0] fault,                         // Faulty module indicator
    output reg [cmd_l-1:0] speed_cmd_prev,
    output reg [cmd_l-1:0] dir_cmd_prev
);

`include "cmd_ctrl.vh"  // Command smoothing function

reg [cmd_l-1:0] speed_cmd_d ;   // Desired speed command
reg [cmd_l-1:0] dir_cmd_d ;     // Desired dir command
reg f1, f2, f3 ;                // Fault flags
reg state_prev ;

always @( * )
begin
    speed_cmd_d = 0 ;
    dir_cmd_d = 0 ;

    if ( state )   // If state is active use voting logic
    begin
        speed_cmd_d = ( s3_cmd & ( s1_cmd ^ s2_cmd ) ) | ( s1_cmd & s2_cmd ) ;  // Speed command majority voting
        dir_cmd_d = ( d3_cmd & ( d1_cmd ^ d2_cmd ) ) | ( d1_cmd & d2_cmd ) ;    // Dir command majority voting

    end
    else    // In normal conditon just pass the values of one module
    begin
        case(en)
            3'b001 : begin
                speed_cmd_d = s1_cmd ;
                dir_cmd_d = d1_cmd ;
            end
            3'b010 : begin
                speed_cmd_d = s2_cmd ;
                dir_cmd_d = d2_cmd ;
            end
            3'b100 : begin
                speed_cmd_d = s3_cmd ;
                dir_cmd_d = d3_cmd ;
            end
            default : begin
                speed_cmd_d = s1_cmd ;
                dir_cmd_d = d1_cmd ;
            end
        endcase
    end
end

always  @( posedge clk or posedge rst )
begin
    if ( rst )
    begin
        speed_cmd_o <= 0 ;
        dir_cmd_o <= 0 ;
        {f1, f2, f3} <= 0 ;
        state_prev <= 0 ;
        speed_cmd_prev <= 0 ;
        dir_cmd_prev <= 0 ;
    end
    else
    begin
        if(state && en == 0)
        begin
            speed_cmd_o <= cmd_ctrl(speed_cmd_o, speed_cmd_prev) ; // Use praportional control for speed command
            dir_cmd_o <= cmd_ctrl(dir_cmd_o, dir_cmd_prev) ;       // Use praportional control for dir command
        end
        else
        begin
            speed_cmd_o <= cmd_ctrl(speed_cmd_o, speed_cmd_d) ; // Use praportional control for speed command
            dir_cmd_o <= cmd_ctrl(dir_cmd_o, dir_cmd_d) ;       // Use praportional control for dir command
        end

        if(state && en != 0)
        begin
            speed_cmd_prev <= speed_cmd_o ;
            dir_cmd_prev <= dir_cmd_o ;
        end

        // Faults
        if(state && state == state_prev)
        begin
            f1 <= (en[0] == 1) ? ( s1_cmd != speed_cmd_d || d1_cmd != dir_cmd_d ) : 0 ; // Flag module 1
            f2 <= (en[1] == 1) ? ( s2_cmd != speed_cmd_d || d2_cmd != dir_cmd_d ) : 0 ; // Flag module 2
            f3 <= (en[2] == 1) ? ( s3_cmd != speed_cmd_d || d3_cmd != dir_cmd_d ) : 0 ; // Flag module 3
        end
        else
        begin
            {f1, f2, f3} <= 0 ;
            state_prev <= state ;
        end
    end
end

assign fault = {f3, f2, f1} ;   // Fault data output

endmodule
