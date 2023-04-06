function [con_left_mu,con_right_mu] = gen_condiff_mu(avg_vis,contrast_level,num_trials,state_mu)
    % GEN_CONDIFF_MU generatescontrast difference, contrast levels of
    % left/right patches during the slider phase

    % avg_vis = average contrast level between two patches
    % contrast_level = maximum contrast level
    % state_mu = state of trial during slider phase in a block
    % num_trials = number of trials in a block

    con_left_mu = NaN(num_trials,1);
    con_right_mu = NaN(num_trials,1);
    for i = 1:num_trials
        if state_mu(i) == 0
            con_left_mu(i) = avg_vis - contrast_level;
            con_right_mu(i) = avg_vis + contrast_level;
        else
            con_left_mu(i) = avg_vis + contrast_level;
            con_right_mu(i) = avg_vis - contrast_level;
        end
    end
    
end