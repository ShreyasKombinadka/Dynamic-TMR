module err_in #(
    parameter
    cmd_l = 4,
    lfsr_ini = 5
)(
    input clk, rst,
    input state,
    input [(2*cmd_l)-1:0] cmd_raw,
    output reg [(2*cmd_l)-1:0] cmd_out
);

reg [3:0] lfsr ;
reg [1:0] clk_2 ;
reg clk_2_prev ;

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        clk_2 <= 0 ;
        clk_2_prev <= 0 ;
        lfsr <= lfsr_ini ;
    end
    else
    begin
        clk_2 <= clk_2 + 1 ;
        
        if(clk_2[1] != clk_2_prev && clk_2[1] == 1) lfsr <= {lfsr[2:0], (lfsr[3] ^ lfsr[2])} ;
        clk_2_prev <= clk_2 ;
    end
end

always @(*)
begin
    if(state)
    begin
        if(lfsr[1:0] == 2'b11) cmd_out = {(cmd_raw[(2 * cmd_l)-1:cmd_l] + lfsr[3:2]), (cmd_raw[cmd_l-1:0] - lfsr[3:2])} ;
        else if(lfsr[1:0] == 2'b00) cmd_out = {(cmd_raw[(2 * cmd_l)-1:cmd_l] - lfsr[3:2]), (cmd_raw[cmd_l-1:0] + lfsr[3:2])} ;
        else cmd_out = cmd_raw ;
    end
    else cmd_out = cmd_raw ;
end

endmodule
