`timescale 1ns / 1ps

module PMC_tb ;
reg clk, rst ;
reg [3:0] speed ;
reg [3:0] dir ;
reg [1:0] mode ;
reg f1, f2, b1, b2;
wire [3:0] speed_o ;
wire [3:0] dir_o ;

PMC dut( .clk(clk), .rst(rst), .speed(speed), .dir(dir), .mode(mode), .f1(f1), .f2(f2), .b1(b1), .b2(b2), .speed_o(speed_o), .dir_o(dir_o) );

initial clk = 0 ;
always #5 clk = ~clk ;

initial begin
    rst = 1 ; speed = 0 ; dir = 0 ; mode = 0 ; {f1, f2, b1, b2} = 0 ; repeat(2) @(negedge clk) ;
    rst = 0 ; repeat(10) @(negedge clk) ;
    speed = 10 ; dir = 5 ; input_sim() ;
    speed = 10 ; dir = 6 ; mode = 1 ; input_sim() ;
    speed = 15 ; dir = 2 ; mode = 2 ; input_sim() ;
    speed = 10 ; dir = 5 ; mode = 3 ; input_sim() ;
    
    @(negedge clk) ; $finish ;
end

task input_sim ;
integer i ;
begin
    for(i = 0 ; i < 7 ; i = i + 1)
    begin
        case(i)
            0 : {f1, f2, b1, b2} = 4'b0011 ;
            1 : {f1, f2, b1, b2} = 4'b1100 ;
            2 : {f1, f2, b1, b2} = 4'b0111 ;
            3 : {f1, f2, b1, b2} = 4'b1011 ;
            4 : {f1, f2, b1, b2} = 4'b0100 ;
            5 : {f1, f2, b1, b2} = 4'b1000 ;
            6 : {f1, f2, b1, b2} = 4'b1111 ;
        endcase
        repeat(10) @(negedge clk) ;
    end
end
endtask

endmodule