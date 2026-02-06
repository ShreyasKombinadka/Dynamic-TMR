module ham_dec_14_10 (
    input [13:0] data_i,
    input en,
    output [9:0] data_o,
    output err
);

reg [3:0] parity_r ;
reg [3:0] parity_c ;
reg [3:0] syn ;
reg [13:0] temp ;

always @(*)
begin
    parity_c = 0 ;
    parity_r = 0 ;
    syn = 0 ;

    parity_r = {data_i[7], data_i[3], data_i[1], data_i[0]} ;

    parity_c[0] = (data_i[2] ^ data_i[4] ^ data_i[6] ^ data_i[8] ^ data_i[10] ^ data_i[12]) ;
    parity_c[1] = (data_i[2] ^ data_i[5] ^ data_i[6] ^ data_i[9] ^ data_i[10] ^ data_i[13]) ;
    parity_c[2] = (data_i[4] ^ data_i[5] ^ data_i[6] ^ data_i[11] ^ data_i[12] ^ data_i[13]) ;
    parity_c[3] = (data_i[8] ^ data_i[9] ^ data_i[10] ^ data_i[11] ^ data_i[12] ^ data_i[13]) ;

    syn = parity_c ^ parity_r ;

    temp = data_i ;
    if(syn) temp[syn-1] = ~temp[syn-1] ;
end

assign data_o = (en) ? {temp[13], temp[12], temp[11], temp[10], temp[9], temp[8], temp[6], temp[5], temp[4], temp[2]} : 0 ;
assign err = (en && syn != 0) ? 1 : 0 ;

endmodule