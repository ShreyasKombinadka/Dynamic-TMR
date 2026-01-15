function [3:0] cmd_ctrl ;   // Command smoothing function
input [3:0] current ;       // Current value
input [3:0] target ;        // Desired value
begin

    cmd_ctrl = current ;

    if (cmd_ctrl < target) cmd_ctrl = cmd_ctrl + 1 ;        // Increase
    else if (cmd_ctrl > target) cmd_ctrl = cmd_ctrl - 1 ;   // Decrese

end
endfunction