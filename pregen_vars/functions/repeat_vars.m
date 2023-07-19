function [vars, row_id] = repeat_vars(var, num_trials)
    % REPEAT_VARS creates arrays for the entire block with contrast,
    % condition and congruence of a block
    % INPUT:
        % var = variable that needs to be repeated e.g. contrast,
        % condition, congruence
        % num_trials = number of trials in a block
    % OUTPUT:
        % vars = array with repeated var
        % row_id = array containing row number used to index missed trials for end of block repetitions
    
    vars = repelem(var,num_trials,1);
    row_id = [0:num_trials-1]';
end
