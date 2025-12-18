module ctrl (
    input f1, f2,   // Front sensors (active low)
    input b1, b2,   // Back sensors (active low)
    input [3:0] err_rate,
    output reg [2:0] en,
    output reg state
);

always @( * )
begin
    state = ((( f2 & b2 ) & ( f1 | b1 )) | (( f1 & b1 ) & ( b2 | f2 ))) | ( err_rate > 5 ) ; // Activate only when 3 or more sesors are triggered
    en = 0 ;
    
    case ( state )
        0 : en = 3'b001 ;
        1 : en = 3'b111 ;
        default : en = 3'b111 ;
    endcase
end