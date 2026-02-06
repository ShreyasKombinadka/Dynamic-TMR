module receiver #(
        parameter
        clk_f = 50_000_000,             // Clock frequency
        range = 1_000_000,              // Range
        t = 300,                        // Bit duration
        data_l = 14,                    // Length of data to be sent
        cmd_l = 4                      // Command length
)(
    input clk, rst,                     // Clock and Reset
    input s,                            // SASS transmission line
    output [1:0] mode,
    output [cmd_l-1:0] speed_cmd,
    output [cmd_l-1:0] dir_cmd,
    output [3:0] err_rate
);

wire avl ;
wire [data_l-1:0] data_r ;
sass_r #(.data_l(data_l), .clk_f(clk_f), .range(range), .t(t)) SASS_Receiver(.clk(clk), .rst(rst), .s(s), .avl(avl), .data(data_r));

data_dec #(.data_l(data_l), .cmd_l(cmd_l)) Decoder(.clk(clk), .rst(rst),
            .avl(avl), .data(data_r), .mode(mode), .speed_cmd(speed_cmd), .dir_cmd(dir_cmd), .err_rate(err_rate));

endmodule
