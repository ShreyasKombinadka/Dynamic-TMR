module ctrl (
    input rst,
    input state,
    output reg [2:0] en
);

always @( * )
begin
    if ( rst )
    begin
        en = 0 ;
    end
    else
    begin
        case ( state )
            0 : en = 3'b001 ;
            1 : en = 3'b111 ;
            default : en = 3'b111 ;
        endcase
    end
end