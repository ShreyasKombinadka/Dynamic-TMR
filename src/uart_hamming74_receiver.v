// ==================== uart_hamming74_receiver.v (final, corrected) ====================
`timescale 1ns / 1ps
module uart_hamming74_receiver(
    input  wire clk,              // 50 MHz clock
    input  wire rst,              // async reset (active high)
    input  wire rx,               // UART RX input
    output reg  [3:0] speed,      // decoded 4-bit speed
    output reg  [3:0] dir,        // decoded 4-bit direction
    output reg         mode,      // single-bit mode select (auto/manual)
    output reg  [3:0] error_rate  // total corrected bits per frame (0-15)
);

    // UART parameters
    parameter integer CLK_FREQ = 50000000;
    parameter integer BAUD     = 9600;
    localparam integer BAUD_CNT = (CLK_FREQ + (BAUD/2)) / BAUD; // = 5208

    // UART receiver registers
    reg [12:0] baud_cnt;
    reg [3:0]  bit_idx;
    reg [7:0]  rx_shift;
    reg        rx_busy;
    reg        rx_d, rx_dd;
    reg        rx_byte_valid;

    // Byte buffers
    reg [1:0]  byte_count;
    reg [7:0]  rx_buffer0, rx_buffer1, rx_buffer2;

    // Startup stabilization delay (prevents early byte loss)
    reg [15:0] startup_cnt;
    wire       ready = (startup_cnt == 16'hFFFF);

    always @(posedge clk or posedge rst) begin
        if (rst)
            startup_cnt <= 16'd0;
        else if (!ready)
            startup_cnt <= startup_cnt + 1'b1;
    end

    // Synchronize RX input
    always @(posedge clk) begin
        rx_dd <= rx;
        rx_d  <= rx_dd;
    end

    // UART 8N1 receiver
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            baud_cnt      <= 13'd0;
            bit_idx       <= 4'd0;
            rx_shift      <= 8'd0;
            rx_busy       <= 1'b0;
            rx_byte_valid <= 1'b0;
        end else begin
            rx_byte_valid <= 1'b0;
            if (ready) begin
                if (!rx_busy) begin
                    if (rx_d == 1'b0) begin
                        rx_busy  <= 1'b1;
                        baud_cnt <= BAUD_CNT/2;
                        bit_idx  <= 4'd0;
                    end
                end else begin
                    if (baud_cnt == BAUD_CNT-1) begin
                        baud_cnt <= 13'd0;
                        if (bit_idx < 4'd8) begin
                            rx_shift <= {rx_d, rx_shift[7:1]};
                            bit_idx  <= bit_idx + 1'b1;
                        end else begin
                            rx_busy       <= 1'b0;
                            rx_byte_valid <= 1'b1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end
            end
        end
    end

    // ---- Hamming(7,4) decoder ----
    task decode_hamming74;
        input  [7:0] code_in;
        output [7:0] result;
        reg    [6:0] r, t;
        reg    [2:0] syndrome;
        reg    [3:0] d;
        reg    [3:0] count;
        integer bit;
    begin
        r = code_in[6:0];
        syndrome[0] = r[6] ^ r[4] ^ r[2] ^ r[0];
        syndrome[1] = r[5] ^ r[4] ^ r[1] ^ r[0];
        syndrome[2] = r[3] ^ r[2] ^ r[1] ^ r[0];
        t = r;
        case (syndrome)
            3'b001: t[0] = ~t[0];
            3'b010: t[1] = ~t[1];
            3'b011: t[2] = ~t[2];
            3'b100: t[3] = ~t[3];
            3'b101: t[4] = ~t[4];
            3'b110: t[5] = ~t[5];
            3'b111: t[6] = ~t[6];
            default: ;
        endcase
        count = 4'd0;
        for (bit = 0; bit < 7; bit = bit + 1)
            if (r[bit] != t[bit]) count = count + 1'b1;
        d = {t[6], t[5], t[3], t[0]};
        result = {count, d};
    end
    endtask

    // ---- Byte collector & frame decode ----
    reg [7:0] temp;
    reg [3:0] err_sum;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            byte_count <= 2'd0;
            speed      <= 4'd0;
            dir        <= 4'd0;
            mode       <= 1'b0;
            error_rate <= 4'd0;
            rx_buffer0 <= 8'd0;
            rx_buffer1 <= 8'd0;
            rx_buffer2 <= 8'd0;
        end else if (rx_byte_valid) begin
            case (byte_count)
                2'd0: rx_buffer0 <= rx_shift;
                2'd1: rx_buffer1 <= rx_shift;
                2'd2: rx_buffer2 <= rx_shift;
                default: ;
            endcase

            byte_count <= byte_count + 1'b1;

            if (byte_count == 2'd2) begin
                err_sum = 4'd0;

                decode_hamming74(rx_buffer0, temp);
                speed <= temp[3:0];
                err_sum = err_sum + temp[7:4];

                decode_hamming74(rx_buffer1, temp);
                dir <= temp[3:0];
                err_sum = err_sum + temp[7:4];

                decode_hamming74(rx_buffer2, temp);
                mode <= temp[0]; // 1-bit mode (manual/auto)
                err_sum = err_sum + temp[7:4];

                error_rate <= err_sum;
                byte_count <= 2'd0;
            end
        end
    end
endmodule
