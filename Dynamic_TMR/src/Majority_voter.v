module maj_vote (   // Majority voter
    input state,    // DTMR state
    input [3:0] s1, s2, s3, //  Speed from TMR copies
    input [3:0] d1, d2, d3, //  Dir from TMR copies
    output reg [3:0] speed, // Voted speed output
    output reg [3:0] dir,    // Voted dir output
    output [2:0] fault  // Faulty module
);

reg f1, f2, f3 ;

always @( * )
begin
    speed = 0 ;
    dir = 0 ;
    {f3, f2, f1} = 0 ;
    if ( state )   // If state is active use voting logic
    begin
        speed = ( s3 & ( s1 ^ s2 ) ) | ( s1 & s2 ) ;    // Speed majority voting
        dir = ( d3 & ( d1 ^ d2 ) ) | ( d1 & d2 ) ;  // Dir majority voting
        f1 = ( s1 != speed && d1 != dir ) ; // Flag module 1
        f2 = ( s2 != speed && d2 != dir ) ; // Flag module 2
        f3 = ( s3 != speed && d3 != dir ) ; // Flag module 3
    end
    else    // In normal conditon just pass the values of one copy
    begin
        speed = s1 ;
        dir = d1 ;
        {f1, f2, f3} = 0 ;
    end
end

assign fault = ( state == 1 ) ? {f3, f2, f1} : 0 ;

endmodule