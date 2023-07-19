function [condiff, con_left, con_right]= gen_condiff(avg_vis, contrast_low, contrast_high, s, num_trials, choice, rand_condiff) 
    % GEN_CONDIFF generates contrast difference, contrast level of left
    % patch and right patch for a given number of trials in a block
    % INPUT:
        % avg_vis = average contrast level between two patches
        % contrast_level = maximum contrast level
        % s = state of trials in a block
        % num_trials = number of trials in a block
        % choice = whether the generated contrast differences are for the
        % choice or slider phase
        % rand_condiff = array with random number between 0-1. Dimensions
        % should be num_trials*1
    % OUTPUT:
        % condiff = contrast difference for trials in a block
        % con_left = contrast of left patch for trials in a block
        % con_right = contrast of right patch for trials in a block

    % INITIALIZE VARS
    con_left = NaN(num_trials, 1);
    con_right = NaN(num_trials, 1);

    % CONTRAST DIFFERENCE FOR EACH TRIAL
    if choice == 1 % for the choice phase
        condiff = (contrast_high-contrast_low).*rand_condiff + contrast_low;
    else % for the mu phase
        condiff = repelem(contrast_high, num_trials, 1);
    end
    
    % INDICES WHERE S = 0
    zero_indices = find(s == 0);
    
    % STATE DEPENDENT CONTRAST VALUES FOR LEFT & RIGHT PATCH
    con_left(zero_indices) = avg_vis - condiff(zero_indices);
    con_right(zero_indices) = avg_vis + condiff(zero_indices);
    
    % INDICES WHERE S = 1
    non_zero_indices = find(s ~= 0);
    
    % STATE DEPENDENT CONTRAST VALUES FOR LEFT & RIGHT PATCH
    con_left(non_zero_indices) = avg_vis + condiff(non_zero_indices);
    con_right(non_zero_indices) = avg_vis - condiff(non_zero_indices);
end