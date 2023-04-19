function [state_mu, state_mu0, state_mu1, prob_mu_s0, prob_mu_s1] = gen_state_mu(prob_state_mu, num_trials, randperm_array)
    % GEN_STATE_MU generates state of a trial during the slider phase
	% INPUT:
    	% prob_state_mu = proportion of state = 0 during slider
    	% num_trials = number of trials in a block 
     	% randperm_array = array with indices to shuffle the state_mu array
     % OUTPUT:
     	% state_mu = array with trial states for the slider phase
      	% state_mu0 = array with shuffled trail states for the slider phase when s = 0 during choice phase
		% state_mu1 = array with shuffled trail states for the slider phase when s = 1 during choice phase
  		% prob_mu_s0 = probability of s = 0 (during slider phase) when s = 0 during choice phase
    	% prob_mu_s1 = probability of s = 0 (during slider phase) when s = 1 during choice phase
  
    state_mu0 = [repelem(0,prob_state_mu*num_trials./2,1)];
    state_mu1 = repelem(1,(1-prob_state_mu)*num_trials./2,1);
    state_mu = [state_mu0;state_mu1];
    
    state_mu0 = state_mu(randperm_array);
    state_mu1 = state_mu(randperm_array);

    prob_mu_s0 = mean(state_mu0); % should not exceed prob_state_mu
    prob_mu_s1 = mean(state_mu1); % should not exceed 1-prob_state_mu
    state_mu = [state_mu0; state_mu1];
end