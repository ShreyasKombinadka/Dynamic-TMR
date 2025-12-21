function [3:0] cmd_ctrl ; // Praportional control function
input [3:0] current ;   // Current value
input [3:0] target ;    // Desired value
begin

    cmd_ctrl = current ;

    if (cmd_ctrl < target) cmd_ctrl = cmd_ctrl+ 1 ;
    else if (cmd_ctrl > target) cmd_ctrl = cmd_ctrl - 1 ;

end
endfunction