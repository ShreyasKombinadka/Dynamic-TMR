module data_dec #(
    parameter
    data_l = 14,
    cmd_l = 4
)(
    input clk, rst,
    input avl,
    input [data_l-1:0] data,
    output reg [1:0] mode,
    output reg [cmd_l-1:0] speed_cmd,
    output reg [cmd_l-1:0] dir_cmd,
    output reg [3:0] err_rate
);

wire [(cmd_l + cmd_l + 2)-1:0] data_temp ;
wire err ;

ham_dec_14_10 hamming_decoder(.data_i(data), .en(avl), .data_o(data_temp), .err(err)) ;

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        mode <= 0 ;
        speed_cmd <= 0 ;
        dir_cmd <= 0 ;
        err_rate <= 0 ;
    end
    else if(avl)
    begin
        mode <= data_temp[1:0] ;
        speed_cmd <= data_temp[(cmd_l + 2)-1:2] ;
        dir_cmd <= data_temp[(cmd_l + cmd_l + 2)-1:(cmd_l + 2)] ;

        err_rate <= (err) ? err_rate + 1 : 0 ;
    end
end
endmodule