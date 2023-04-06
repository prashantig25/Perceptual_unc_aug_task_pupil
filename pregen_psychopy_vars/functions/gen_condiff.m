function [condiff, con_left, con_right]= gen_condiff(avg_vis,contrast_level,s,num_trials) 
    % GEN_CONDIFF generates contrast difference, contrast level of left
    % patch and right patch for a given number of trials in a block

    % avg_vis = average contrast level between two patches
    % contrast_level = maximum contrast level
    % s = state of trials in a block
    % num_trials = number of trials in a block

    % initialise vars
    condiff = NaN(num_trials,1);
    con_left = NaN(num_trials,1);
    con_right = NaN(num_trials,1);

    % ,contrast difference 
    for i = 1:length(s)
        condiff(i,1) = rand()*contrast_level;
    end
    
    % contrast left and right
    
    for i = 1:length(s)
        if s(i) == 0
            con_left(i) = avg_vis - condiff(i);
            con_right(i) = avg_vis + condiff(i);
        else
            con_left(i) = avg_vis + condiff(i);
            con_right(i) = avg_vis - condiff(i);
        end
    end
end