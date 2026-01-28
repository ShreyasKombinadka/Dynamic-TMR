module ctrl #(
    parameter
    max_tmr_fault_count = 5,    // Max faults for tmr
    max_err_rate_received = 5   // Max err rate in the received data
)(
    input clk, rst,         // Clock and Reset
    input f1, f2,           // Front sensors
    input b1, b2,           // Back sensors
    input [3:0] err_rate,   // Rate of errors in received data
    input [2:0] fault,      // Fault flags
    output reg [2:0] en,    // Enable signal for TMR modules
    output reg state        // Operation state
);

reg [2:0] def_tmr ; // Default TMR block for normal condition
reg [2:0] dis_tmr ; // TMR unit to be disabled
reg state_prev ;    // Previous state
reg restart ;       // Soft reset

reg [3:0] tmr1_fault_count ;    // Fault counter for TMR1
reg [3:0] tmr2_fault_count ;    // Fault counter for TMR2
reg [3:0] tmr3_fault_count ;    // Fault counter for TMR3

always @( * )
begin
    state = ((( f2 & b2 ) & ( f1 | b1 )) | (( f1 & b1 ) & ( b2 | f2 ))) | ( err_rate > max_err_rate_received ) ; // Activate only when 3 or more sesors are triggered or error rate crosses 50%

    en = 0 ;
    if(state) en = ~(dis_tmr) ; // Only the modules that are not flagged for disabling
    else en = def_tmr ; // Default condition
end

always  @(posedge clk or posedge rst)
begin
    if (rst | restart)
    begin
        dis_tmr <= 0 ;
        tmr1_fault_count <= 0 ;
        tmr2_fault_count <= 0 ;
        tmr3_fault_count <= 0 ;
        restart <= 0 ;
        if(rst)
        begin
            def_tmr <= 3'b001 ; // By default set TMR1 as default block
            state_prev <= 0 ;
        end
    end

    else if(state)
    begin
        // Fault counters incriment if fault percist multiple clk cycles
        tmr1_fault_count <= (fault[0]) ? tmr1_fault_count + 1 : 0 ;
        tmr2_fault_count <= (fault[1]) ? tmr2_fault_count + 1 : 0 ;
        tmr3_fault_count <= (fault[2]) ? tmr3_fault_count + 1 : 0 ;

        // If fault count reaches max limit flag the module to be disabled
        dis_tmr[0] <= (tmr1_fault_count == max_tmr_fault_count) ? 1 : dis_tmr[0] ;
        dis_tmr[1] <= (tmr2_fault_count == max_tmr_fault_count) ? 1 : dis_tmr[1] ;
        dis_tmr[2] <= (tmr3_fault_count == max_tmr_fault_count) ? 1 : dis_tmr[2] ;
    end

    // 
    if((state != state_prev && state == 0) || ((dis_tmr[2] & dis_tmr[0]) | (dis_tmr[1] & (dis_tmr[0] | dis_tmr[2]))))
    begin
        restart <= 1 ;

        if(state == 0)
        begin
            if(~dis_tmr[0]) def_tmr <= 3'b001 ;
            else if(~dis_tmr[1]) def_tmr <= 3'b010 ;
            else if(~dis_tmr[2]) def_tmr <= 3'b100 ;
            else def_tmr <= 3'b001 ;
        end
    end

    if(state != state_prev) state_prev <= state ;
end

endmodule
