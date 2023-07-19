function [state_mu,state_mu0,state_mu1,prob_mu_s0,prob_mu_s1] = gen_state_mu(prob_state_mu,num_trials,randperm_array)
    % GEN_STATE_MU generates state of a trial during the slider phase

    % prob_state_mu = proportion of state = 0 during slider
    % num_trials = number of trials in a block

    state_mu0 = [repelem(0,prob_state_mu*num_trials./2,1)];
    state_mu1 = repelem(1,(1-prob_state_mu)*num_trials./2,1);
    state_mu = [state_mu0;state_mu1];
    
    state_mu0 = state_mu(randperm_array);
    state_mu1 = state_mu(randperm_array);

    prob_mu_s0=mean(state_mu0); % should not exceed prob_state_mu
    prob_mu_s1=mean(state_mu1); % should not exceed 1-prob_state_mu
    state_mu = [state_mu0;state_mu1];
end