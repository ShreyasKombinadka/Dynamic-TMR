module ctrl (
    input f1, f2,   // Front sensors
    input b1, b2,   // Back sensors
    input [3:0] err_rate,   // Rate of errors in received data
    output reg [2:0] en,    // Enable signal for TMR modules
    output reg state    // Operation state
);

always @( * )
begin
    state = ((( f2 & b2 ) & ( f1 | b1 )) | (( f1 & b1 ) & ( b2 | f2 ))) | ( err_rate > 5 ) ; // Activate only when 3 or more sesors are triggered or error rate crosses 50%
    en = 0 ;
    
    case ( state )
        0 : en = 3'b001 ;   // Normal operation
        1 : en = 3'b111 ;   // TMR operation
        default : en = 3'b111 ;
    endcase
end

endmodule