module ham_dec_14_10_tb ;
reg [13:0] data_i ;
reg en ;
wire [9:0] data_o ;
wire err ;

ham_dec_14_10 hamming_decoder(.data_i(data_i), .en(en), .data_o(data_o), .err(err));

reg clk ;
initial clk = 0 ;
always #5 clk = ~clk ;

initial
begin
    data_i = 0 ; en = 0 ;
    @(negedge clk) ; en = 1 ;
    @(negedge clk) ; ham_en_14_10(50, 0) ;
    @(negedge clk) ; ham_en_14_10(100, 0) ;
    @(negedge clk) ; ham_en_14_10(50, 5) ;
    @(negedge clk) ; ham_en_14_10(100, 10) ;
    @(negedge clk) ; $finish ;
end

task ham_en_14_10 ;
input [9:0] data ;
input [3:0] err_in ;

reg [3:0] parity ;
begin
    parity = 0 ;
    parity[0] = (data[0] ^ data[1] ^ data[3] ^ data[4] ^ data[6] ^ data[8]) ;
    parity[1] = (data[0] ^ data[2] ^ data[3] ^ data[5] ^ data[6] ^ data[9]) ;
    parity[2] = (data[1] ^ data[2] ^ data[3] ^ data[7] ^ data[8] ^ data[9]) ;
    parity[3] = (data[4] ^ data[5] ^ data[6] ^ data[7] ^ data[8] ^ data[9]) ;

    data_i = {data[9:4], parity[3], data[3:1], parity[2], data[0], parity[1:0]};
    if(err_in != 0) data_i[err_in-1] =  data_i[err_in-1] ;
end
endtask

initial
begin
    $monitor("Time : %0t | pre : %b | post : %b ", $time, data_i, hamming_decoder.temp);
end

endmodule