function [contrast,condition,congruence,row_id] = repeat_vars(con,cond,cong,num_trials)
    % REPEAT_VARS creates arrays for the entire block with contrast,
    % condition and congruence of a block

    % con = high or low contrast of a block
    % condition = condition of a block
    % congruence = whether the slider phase is congruent/incongruent
    
    % block contrast
    contrast = repelem(con,num_trials,1);
    
    % condition
    condition = repelem(cond,num_trials,1);
    
    % congruence
    congruence = repelem(cong,num_trials,1);
    
    % row_id 
    row_id = [0:num_trials-1].';
end
